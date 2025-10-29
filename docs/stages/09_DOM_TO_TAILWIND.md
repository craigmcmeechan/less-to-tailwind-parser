# STAGE 9: BACKEND DOM MATCHING & TAILWIND GENERATION

**Duration:** 1 week  
**Status:** ⏳ Ready (after Stage 8 complete)  
**Dependencies:** Stage 8 (Chrome Extension) + Part 1 complete (database with `less_rules`)  
**Blocks:** Nothing (final stage)

---

## Overview

Stage 9 implements the backend service that receives DOM captures from the Chrome extension, matches elements to LESS CSS rules, and generates Tailwind class suggestions.

**Key Deliverable:** Backend API endpoint that accepts DOM trees, performs intelligent matching, and returns Tailwind suggestions.

---

## Objectives

1. ✅ `POST /api/capture` endpoint receives DOM tree JSON
2. ✅ Store captured elements hierarchically in database
3. ✅ Store capture metadata (URL, timestamp, viewport)
4. ✅ For each element: query LESS rules matching element classes
5. ✅ Compare computed styles to rule properties
6. ✅ Calculate confidence score for each match
7. ✅ Map matched properties to Tailwind classes (via `theme_tokens`)
8. ✅ `GET /api/capture/:id` endpoint returns results with suggestions
9. ✅ Error handling for malformed payloads
10. ✅ Performance: handle large DOM trees efficiently

---

## Existing Codebase

**Already Complete:**
- Part 1: `less_rules` table with indexed selectors
- Part 1: `theme_tokens` table with Tailwind mappings
- Database connection and schema

**What Needs Building (Stage 9):**
- `captured_elements` table (hierarchy)
- `element_captures` table (metadata)
- `element_rule_matches` table (mapping audit)
- Backend API service
- Matching engine
- Tailwind mapper service

---

## Technical Specifications

### Database Tables

#### 1. `element_captures` - Capture Session

```sql
CREATE TABLE element_captures (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  url VARCHAR(2048) NOT NULL,
  viewport_width INTEGER,
  viewport_height INTEGER,
  extension_version VARCHAR(20),
  total_elements INTEGER,
  status VARCHAR(50) DEFAULT 'processing', -- processing, complete, error
  error_message TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_captures_url ON element_captures(url);
CREATE INDEX idx_captures_created ON element_captures(created_at DESC);
CREATE INDEX idx_captures_status ON element_captures(status);
```

#### 2. `captured_elements` - DOM Tree

```sql
CREATE TABLE captured_elements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  capture_id UUID NOT NULL,
  parent_id UUID,
  tag VARCHAR(50),
  classes TEXT[],
  ids TEXT[],
  attributes JSONB,
  computed_styles JSONB NOT NULL,
  text_content VARCHAR(500),
  tree_depth INTEGER,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (capture_id) REFERENCES element_captures(id) ON DELETE CASCADE,
  FOREIGN KEY (parent_id) REFERENCES captured_elements(id) ON DELETE SET NULL
);

CREATE INDEX idx_elements_capture ON captured_elements(capture_id);
CREATE INDEX idx_elements_parent ON captured_elements(parent_id);
CREATE INDEX idx_elements_classes ON captured_elements USING GIN(classes);
CREATE INDEX idx_elements_tag ON captured_elements(tag);
```

#### 3. `element_rule_matches` - Mapping Result

```sql
CREATE TABLE element_rule_matches (
  id SERIAL PRIMARY KEY,
  element_id UUID NOT NULL,
  less_rule_id INTEGER NOT NULL,
  selector VARCHAR(1024),
  confidence DECIMAL(3,2), -- 0.00 to 1.00
  matched_properties JSONB, -- {"property": {"actual": val, "expected": val}}
  tailwind_classes TEXT[] DEFAULT ARRAY[]::TEXT[],
  tailwind_confidence DECIMAL(3,2),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (element_id) REFERENCES captured_elements(id) ON DELETE CASCADE,
  FOREIGN KEY (less_rule_id) REFERENCES less_rules(id)
);

CREATE INDEX idx_matches_element ON element_rule_matches(element_id);
CREATE INDEX idx_matches_rule ON element_rule_matches(less_rule_id);
CREATE INDEX idx_matches_confidence ON element_rule_matches(confidence DESC);
```

---

## API Specification

### POST /api/capture - Receive DOM

**Request:**
```json
{
  "url": "https://example.com/page",
  "timestamp": "2025-10-29T14:00:00Z",
  "viewport": {"width": 1920, "height": 1080},
  "element": {
    "id": "elem-1",
    "tag": "div",
    "classes": ["asc-about-header"],
    "ids": [],
    "attributes": {"data-id": "123"},
    "computedStyles": {
      "font-size": "12px",
      "color": "#333333",
      "margin": "0px 30px"
    },
    "textContent": "About Header",
    "children": [...]
  }
}
```

**Response (201 Created):**
```json
{
  "captureId": "550e8400-e29b-41d4-a716-446655440000",
  "message": "Capture received and queued for processing",
  "status": "processing"
}
```

**Error Response (400 Bad Request):**
```json
{
  "error": "Invalid payload",
  "details": "Missing required field: url"
}
```

---

### GET /api/capture/:id - Retrieve Results

**Response (200 OK):**
```json
{
  "captureId": "550e8400-e29b-41d4-a716-446655440000",
  "url": "https://example.com",
  "status": "complete",
  "createdAt": "2025-10-29T14:00:00Z",
  "viewport": {"width": 1920, "height": 1080},
  "elements": [
    {
      "elementId": "elem-1",
      "tag": "div",
      "classes": ["asc-about-header"],
      "computedStyles": {
        "font-size": "12px",
        "color": "#333333"
      },
      "matches": [
        {
          "selector": ".asc-about-header",
          "lessRuleId": 42,
          "confidence": 0.75,
          "matchedProperties": {
            "font-size": {"actual": "12px", "expected": "12px"},
            "color": {"actual": "#333333", "expected": "#333333"}
          },
          "tailwindClasses": ["text-xs", "text-gray-700"],
          "tailwindConfidence": 0.85
        }
      ],
      "suggestedTailwind": ["text-xs", "text-gray-700"],
      "children": [...]
    }
  ]
}
```

**Response (202 Accepted) - Still Processing:**
```json
{
  "status": "processing",
  "progress": "Processed 45/120 elements"
}
```

---

## Implementation

### Service Layer

#### 1. CaptureService - Receive & Store

```typescript
// src/part2/services/captureService.ts

export class CaptureService {
  async receiveCapture(payload: CapturePayload): Promise<string> {
    // Validate payload
    validateCapturePayload(payload);
    
    // Store capture metadata
    const captureId = await this.storeCapture({
      url: payload.url,
      viewportWidth: payload.viewport.width,
      viewportHeight: payload.viewport.height,
      totalElements: countElements(payload.element)
    });
    
    // Store element hierarchy
    await this.storeElementTree(captureId, payload.element);
    
    // Queue for processing
    await this.queueForMatching(captureId);
    
    logger.info('Capture received', { captureId, url: payload.url });
    return captureId;
  }

  private async storeElementTree(
    captureId: string, 
    element: DomElement,
    parentId?: string,
    depth = 0
  ): Promise<void> {
    // Store element
    const elementId = await database.query(
      `INSERT INTO captured_elements (...) VALUES (...) RETURNING id`,
      [captureId, parentId, element.tag, element.classes, ...]
    );
    
    // Recursively store children
    for (const child of element.children || []) {
      await this.storeElementTree(captureId, child, elementId, depth + 1);
    }
  }
}
```

#### 2. MatchingService - Core Logic

```typescript
// src/part2/services/matchingService.ts

export class MatchingService {
  async matchElements(captureId: string): Promise<void> {
    logger.info('Starting element matching', { captureId });
    
    // Get all elements for this capture
    const elements = await database.query(
      `SELECT * FROM captured_elements WHERE capture_id = $1`,
      [captureId]
    );
    
    for (const element of elements.rows) {
      await this.matchSingleElement(element, captureId);
    }
    
    // Mark capture as complete
    await database.query(
      `UPDATE element_captures SET status = 'complete', updated_at = NOW() 
       WHERE id = $1`,
      [captureId]
    );
    
    logger.info('Matching complete', { captureId, elementCount: elements.rowCount });
  }

  private async matchSingleElement(element: any, captureId: string): Promise<void> {
    // Find matching LESS rules
    const matches = await this.findMatchingRules(element);
    
    for (const match of matches) {
      // Calculate confidence
      const confidence = this.calculateConfidence(
        element.computed_styles,
        match.properties
      );
      
      // Map to Tailwind
      const tailwindClasses = await this.mapToTailwind(match.properties);
      
      // Store match
      await database.query(
        `INSERT INTO element_rule_matches (...) VALUES (...)`,
        [
          element.id,
          match.id,
          match.selector,
          confidence,
          JSON.stringify(this.getMatchedProperties(element.computed_styles, match)),
          tailwindClasses,
          0.85
        ]
      );
    }
  }

  private async findMatchingRules(element: any): Promise<Rule[]> {
    // Query rules by element classes
    const classes = element.classes || [];
    if (classes.length === 0) return [];
    
    const result = await database.query(
      `SELECT * FROM less_rules 
       WHERE selector LIKE ANY($1)
       ORDER BY selector_specificity DESC`,
      [classes.map(c => `%${c}%`)]
    );
    
    return result.rows;
  }

  private calculateConfidence(
    computedStyles: Record<string, string>,
    ruleProperties: Record<string, string>
  ): number {
    let matches = 0;
    
    for (const [prop, expectedValue] of Object.entries(ruleProperties)) {
      const actualValue = computedStyles[prop];
      if (actualValue && this.valuesMatch(actualValue, expectedValue)) {
        matches++;
      }
    }
    
    return matches / Object.keys(ruleProperties).length;
  }

  private valuesMatch(actual: string, expected: string): boolean {
    // Normalize values for comparison
    const normalizeValue = (val: string) => val.toLowerCase().trim();
    return normalizeValue(actual) === normalizeValue(expected);
  }

  private getMatchedProperties(
    computedStyles: Record<string, string>,
    rule: Rule
  ): Record<string, any> {
    const matched: Record<string, any> = {};
    
    for (const [prop, expectedValue] of Object.entries(rule.properties)) {
      const actualValue = computedStyles[prop];
      if (actualValue) {
        matched[prop] = {
          actual: actualValue,
          expected: expectedValue,
          match: this.valuesMatch(actualValue, expectedValue)
        };
      }
    }
    
    return matched;
  }
}
```

#### 3. TailwindMapperService - Generate Classes

```typescript
// src/part2/services/tailwindMapperService.ts

export class TailwindMapperService {
  private themeTokens: Map<string, string> = new Map();
  
  async initialize(): Promise<void> {
    // Load theme tokens from database
    const result = await database.query(
      `SELECT css_value, tailwind_class FROM theme_tokens`
    );
    
    for (const row of result.rows) {
      this.themeTokens.set(row.css_value, row.tailwind_class);
    }
  }

  async mapToTailwind(properties: Record<string, string>): Promise<string[]> {
    const classes: string[] = [];
    
    for (const [prop, value] of Object.entries(properties)) {
      const tailwindClass = this.themeTokens.get(value);
      if (tailwindClass) {
        classes.push(tailwindClass);
      } else {
        // Try fuzzy matching for similar values
        const fuzzyMatch = this.fuzzyMatchThemeToken(value);
        if (fuzzyMatch) {
          classes.push(fuzzyMatch);
        }
      }
    }
    
    return classes;
  }

  private fuzzyMatchThemeToken(value: string): string | null {
    // For values like "12px", find closest theme token
    const valueNum = parseFloat(value);
    if (isNaN(valueNum)) return null;
    
    let closest: [string, number] | null = null;
    let minDist = Infinity;
    
    for (const [token] of this.themeTokens) {
      const tokenNum = parseFloat(token);
      if (isNaN(tokenNum)) continue;
      
      const dist = Math.abs(valueNum - tokenNum);
      if (dist < minDist) {
        minDist = dist;
        closest = [token, dist];
      }
    }
    
    // Only accept if reasonably close
    if (closest && closest[1] < 5) {
      return this.themeTokens.get(closest[0]) || null;
    }
    
    return null;
  }
}
```

---

## Testing Requirements

### Unit Tests

```typescript
// tests/matching.test.ts

describe('Element Matching', () => {
  it('should match element to LESS rule by class', async () => {
    const element = {
      classes: ['asc-about-header'],
      computedStyles: {
        'font-size': '12px',
        'color': '#333333'
      }
    };
    
    const matches = await matchingService.findMatchingRules(element);
    expect(matches.length).toBeGreaterThan(0);
    expect(matches[0].selector).toContain('asc-about-header');
  });

  it('should calculate confidence correctly', () => {
    const computed = {
      'font-size': '12px',
      'color': '#333333',
      'margin': '0px'
    };
    
    const rule = {
      'font-size': '12px',
      'color': '#333333'
    };
    
    const confidence = matchingService.calculateConfidence(computed, rule);
    expect(confidence).toBe(1.0);
  });

  it('should map properties to Tailwind', async () => {
    const props = {
      'font-size': '12px',
      'color': '#333333'
    };
    
    const classes = await tailwindMapper.mapToTailwind(props);
    expect(classes).toContain('text-xs');
    expect(classes).toContain('text-gray-700');
  });
});
```

### Integration Tests

```typescript
// tests/capture.integration.test.ts

describe('Full Capture Pipeline', () => {
  it('should receive, store, and match DOM', async () => {
    const payload = {
      url: 'http://test.com',
      viewport: { width: 1920, height: 1080 },
      element: createMockElement()
    };
    
    const captureId = await captureService.receiveCapture(payload);
    expect(captureId).toBeDefined();
    
    // Process
    await matchingService.matchElements(captureId);
    
    // Retrieve
    const result = await retrievalService.getCaptureWithMatches(captureId);
    expect(result.elements).toHaveLength(1);
    expect(result.elements[0].matches).toHaveLength(1);
    expect(result.elements[0].suggestedTailwind).toBeDefined();
  });
});
```

---

## Performance Considerations

### Optimization Strategies

1. **Batch Queries** - Insert multiple elements in one query
2. **Index Strategy** - `captured_elements(capture_id, classes)` for fast class lookups
3. **Caching** - Cache theme tokens in memory after first load
4. **Async Processing** - Queue large captures for background processing
5. **Limit Depth** - Skip elements below certain nesting depth

### Expected Performance

- Small capture (50 elements): ~500ms
- Medium capture (500 elements): ~3s
- Large capture (5000 elements): ~30s

### Handling Large Payloads

```typescript
// Check payload size
if (JSON.stringify(payload).length > 50 * 1024 * 1024) {
  throw new ValidationError('Payload exceeds 50MB limit');
}

// Process asynchronously if large
if (elementCount > 1000) {
  await queueForAsyncProcessing(captureId);
  return { status: 'queued', estimatedTime: '60 seconds' };
}
```

---

## Error Handling

See [ERROR_HANDLING.md](../../ERROR_HANDLING.md)

### Specific Scenarios

```typescript
// Invalid payload
if (!payload.url || !payload.element) {
  throw new ValidationError('Missing required fields', { payload });
}

// Database errors
try {
  await database.query(...);
} catch (error) {
  await database.query(
    `UPDATE element_captures SET status = 'error', error_message = $1 WHERE id = $2`,
    [error.message, captureId]
  );
  throw new DatabaseError('Failed to store capture', { captureId });
}

// Rule matching errors
if (matches.length === 0) {
  logger.warn('No LESS rules matched element', { element });
  // Continue - it's okay if no matches found
}
```

---

## Logging Strategy

See [LOGGING_GUIDE.md](../../LOGGING_GUIDE.md)

```typescript
logger.info('Capture received', { 
  captureId, 
  url: payload.url, 
  elementCount: countElements(payload.element) 
});

logger.debug('Processing element', { 
  elementId, 
  classes, 
  computedStyleCount: Object.keys(styles).length 
});

logger.info('Matching complete', { 
  captureId, 
  totalMatches, 
  avgConfidence: (total / count).toFixed(2) 
});
```

---

## Acceptance Criteria

✅ **All Must Pass:**

- [ ] `POST /api/capture` endpoint receives JSON correctly
- [ ] Payload validation rejects invalid data
- [ ] Captures stored hierarchically in database
- [ ] Capture metadata tracked (URL, viewport, timestamp)
- [ ] For each element: LESS rules queried by classes
- [ ] Confidence score calculated for each match
- [ ] Properties mapped to Tailwind classes
- [ ] `GET /api/capture/:id` returns results with suggestions
- [ ] Handles empty elements gracefully
- [ ] Handles large captures (1000+ elements)
- [ ] Error messages user-friendly and logged
- [ ] Code follows CODE_STANDARDS.md
- [ ] Tests pass (>80% coverage)
- [ ] Performance acceptable (see benchmarks)
- [ ] Integration test: full pipeline end-to-end

---

## Deliverables Checklist

- [ ] Database migrations create all tables
- [ ] CaptureService implemented
- [ ] MatchingService implemented
- [ ] TailwindMapperService implemented
- [ ] RetrievalService implemented
- [ ] Express routes: POST /api/capture, GET /api/capture/:id
- [ ] Unit tests passing (>80% coverage)
- [ ] Integration test passing
- [ ] Error handling per spec
- [ ] Logging at appropriate levels
- [ ] Performance benchmarks documented

---

## Success Verification

1. **Send test capture:**
   ```bash
   curl -X POST http://localhost:3000/api/capture \
     -H "Content-Type: application/json" \
     -d @test-payload.json
   ```
   → Response includes `captureId`

2. **Retrieve results:**
   ```bash
   curl http://localhost:3000/api/capture/{captureId}
   ```
   → Response shows elements with Tailwind suggestions

3. **Run tests:**
   ```bash
   npm test -- stage9
   ```
   → All tests pass

4. **Check database:**
   ```sql
   SELECT COUNT(*) FROM element_captures;
   SELECT COUNT(*) FROM captured_elements;
   SELECT COUNT(*) FROM element_rule_matches;
   ```
   → Data populated correctly

---

**Project Complete! 🎉**

Both Part 1 (LESS extraction) and Part 2 (DOM capture + matching) finished.

---

**Document Version:** 1.0  
**Last Updated:** October 29, 2025
