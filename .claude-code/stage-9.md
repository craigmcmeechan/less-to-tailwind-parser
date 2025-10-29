# Claude Code Instructions: Stage 9 - Backend DOM Matching & Tailwind Generation

## Overview

Implement backend service that receives DOM captures from Chrome extension, matches elements to compiled LESS rules, and generates Tailwind class suggestions.

**Stage:** 9 of 9  
**Duration:** Expected 1.5 weeks  
**Complexity:** ⭐⭐⭐⭐ (Most Complex)  
**Files to Create:** 10-12  
**Tests Required:** 25+ unit tests  

---

## Dependencies

⚠️ **Stage 9 requires Stage 4 to be complete and working.**

Stage 4 output (compiled LESS rules in database) is the input to Stage 9.

---

## Objectives

1. ✅ Receive DOM capture JSON from Chrome extension
2. ✅ Store DOM tree hierarchically in database
3. ✅ Implement real CSS selector matching
4. ✅ Calculate CSS specificity for each match
5. ✅ Resolve CSS cascade (specificity + order)
6. ✅ Filter by media query context
7. ✅ Match DOM elements to LESS rules
8. ✅ Map matched rules to Tailwind classes
9. ✅ Generate confidence scores
10. ✅ Return results with audit trail

---

## Files to Create

### Core Services
```
src/part2/services/
├── captureService.ts                # Receive and store DOM
├── cssSelectorMatcher.ts            # Real CSS selector matching
├── specificityResolver.ts           # Cascade resolution
├── mediaQueryMatcher.ts             # Media query filtering
├── tailwindMapperService.ts         # Map to Tailwind
├── confidenceScorerService.ts       # Calculate confidence
└── matchingService.ts               # Main matching logic
```

### API Layer
```
src/part2/routes/
├── captureRoutes.ts                 # POST/GET endpoints
└── validationMiddleware.ts          # Input validation

src/part2/models/
├── captureDTO.ts                    # Data transfer objects
└── responseDTO.ts                   # Response models
```

### Database
```
src/part2/migrations/
├── 09-create-element-captures-table.sql
├── 09-create-captured-elements-table.sql
└── 09-create-element-rule-matches-table.sql
```

### Tests
```
tests/unit/
├── cssSelectorMatcher.test.ts
├── specificityResolver.test.ts
├── mediaQueryMatcher.test.ts
├── matchingService.test.ts
└── confidenceScorer.test.ts

tests/integration/
├── fullCaptureFlow.integration.test.ts
└── matchingAccuracy.integration.test.ts

tests/fixtures/
├── dom-payloads/
│   ├── simple-element.json
│   ├── nested-tree.json
│   └── complex-page.json
└── expected-matches/
    └── matches.json
```

---

## Implementation Requirements

### 1. CSS Selector Matcher Service

**Must implement real CSS selector matching:**

```typescript
export class CssSelectorMatcher {
  matches(
    element: CapturedElement,
    selector: string,
    elementMap: Map<string, CapturedElement>
  ): boolean
  
  // Must handle:
  // - Class selectors: .className
  // - ID selectors: #id
  // - Tag selectors: div
  // - Attribute selectors: [data-id="123"]
  // - Pseudo-classes: :hover, :focus
  // - Descendant: .parent .child
  // - Child: .parent > .child
  // - Adjacent: .element + .sibling
  // - General sibling: .element ~ .sibling
}
```

**Key algorithms:**
```typescript
private matchesSingleSelector(element, selector): boolean
// .class, #id, tag, [attr]

private matchesDescendant(element, selector): boolean
// .parent .child

private matchesChildCombinator(element, selector): boolean
// .parent > .child

private matchesAttribute(element, selector): boolean
// [attr], [attr=value], [attr*=value], etc
```

### 2. Specificity Resolver

**Must calculate CSS cascade correctly:**

```typescript
export class SpecificityResolver {
  findApplicableRules(
    element: CapturedElement,
    viewport: { width: number, height: number }
  ): Promise<CompiledRule[]>  // In cascade order (winner first)
  
  // Algorithm:
  // 1. Query less_rules matching element selectors
  // 2. Filter by media query (if present)
  // 3. Sort by:
  //    a. Specificity (IDs DESC, classes DESC, elements DESC)
  //    b. Rule order (later wins)
  // 4. Return in cascade order (first is winner)
}
```

### 3. Media Query Matcher

**Must filter rules by viewport:**

```typescript
export class MediaQueryMatcher {
  matches(
    mediaQuery: string | null,
    viewport: { width: number, height: number }
  ): boolean
  
  // Handle:
  // - No media query: null (always matches)
  // - min-width, max-width
  // - min-height, max-height
  // - orientation (portrait/landscape)
}
```

### 4. Tailwind Mapper Service

**Must map properties to Tailwind classes:**

```typescript
export class TailwindMapperService {
  async mapToTailwind(
    properties: Record<string, string>
  ): Promise<string[]>  // Returns Tailwind class names
  
  // Logic:
  // 1. Load theme_tokens from Part 1
  // 2. For each property:
  //    a. Look up exact match in theme_tokens
  //    b. If no match, try fuzzy matching
  //    c. Add to results if confident
  // 3. Return Tailwind class names
}
```

### 5. Confidence Scorer

**Must calculate weighted confidence:**

```typescript
export class ConfidenceScorer {
  score(
    element: CapturedElement,
    rule: CompiledRule
  ): number  // 0.0 to 1.0
  
  // Weights:
  // - color: 1.0 (critical)
  // - background-color: 1.0
  // - font-size: 0.9 (important)
  // - margin/padding: 0.4 (less critical)
  // - display: 0.2 (layout)
  //
  // Formula:
  // confidence = (matched_weight_sum / total_rule_weight)
}
```

### 6. Main Matching Service

**Orchestrates the full process:**

```typescript
export class MatchingService {
  async matchElements(
    captureId: string
  ): Promise<void>
  
  // Algorithm:
  // 1. Get all captured_elements for captureId
  // 2. For each element:
  //    a. Find matching LESS rules (CSS selector)
  //    b. Filter by media query
  //    c. Resolve cascade (specificity + order)
  //    d. Get winning rule
  //    e. Calculate confidence
  //    f. Map properties to Tailwind
  //    g. Store in element_rule_matches
  // 3. Mark capture as complete
}
```

### 7. Capture Service

**Receive and store DOM:**

```typescript
export class CaptureService {
  async receiveCapture(payload: CapturePayload): Promise<string>
  // 1. Validate payload
  // 2. Store capture metadata
  // 3. Store element tree hierarchically
  // 4. Return captureId
  
  private async storeElementTree(
    captureId: string,
    element: DomElement,
    parentId?: string,
    depth?: number
  ): Promise<void>
  // Recursively store DOM tree
}
```

---

## API Endpoints

### POST /api/capture - Receive DOM

**Request:**
```json
{
  "url": "https://example.com",
  "timestamp": "2025-10-29T14:00:00Z",
  "viewport": { "width": 1920, "height": 1080 },
  "element": {
    "id": "elem-1",
    "tag": "div",
    "classes": ["button"],
    "computedStyles": { "color": "#333", "font-size": "16px" },
    "children": [...]
  }
}
```

**Response (201):**
```json
{
  "captureId": "550e8400-e29b-41d4-a716-446655440000",
  "status": "processing"
}
```

### GET /api/capture/:id - Retrieve Results

**Response (200):**
```json
{
  "captureId": "...",
  "status": "complete",
  "elements": [
    {
      "elementId": "elem-1",
      "tag": "div",
      "classes": ["button"],
      "matches": [
        {
          "selector": ".button",
          "confidence": 0.85,
          "tailwindClasses": ["px-4", "py-2", "bg-blue-500"]
        }
      ]
    }
  ]
}
```

---

## Database Schema

### element_captures
```sql
CREATE TABLE element_captures (
  id UUID PRIMARY KEY,
  url VARCHAR(2048),
  viewport_width INT,
  viewport_height INT,
  total_elements INT,
  status VARCHAR(50),  -- processing|complete|error
  created_at TIMESTAMP
);
```

### captured_elements
```sql
CREATE TABLE captured_elements (
  id UUID PRIMARY KEY,
  capture_id UUID,
  parent_id UUID,
  tag VARCHAR(50),
  classes TEXT[],
  computed_styles JSONB,
  tree_depth INT,
  FOREIGN KEY (capture_id) REFERENCES element_captures(id),
  FOREIGN KEY (parent_id) REFERENCES captured_elements(id)
);
```

### element_rule_matches
```sql
CREATE TABLE element_rule_matches (
  id SERIAL PRIMARY KEY,
  element_id UUID,
  less_rule_id INT,
  selector VARCHAR(1024),
  confidence DECIMAL(3,2),
  matched_properties JSONB,
  tailwind_classes TEXT[],
  FOREIGN KEY (element_id) REFERENCES captured_elements(id),
  FOREIGN KEY (less_rule_id) REFERENCES less_rules(id)
);
```

---

## Testing Requirements

### Unit Tests (25+ tests)

```typescript
// cssSelectorMatcher.test.ts
- Class selector: .button
- ID selector: #main
- Tag selector: div
- Attribute: [data-id="123"]
- Pseudo-class: :hover
- Descendant: .parent .child
- Child: .parent > .child
- Attribute: [attr*=value]

// specificityResolver.test.ts
- Calculate specificity correctly
- Cascade: higher specificity wins
- Cascade: same specificity, later rule wins
- Media query filtering

// matchingService.test.ts
- Match single element
- Match nested tree
- Calculate confidence
- Return results

// confidenceScorer.test.ts
- Weight critical properties (color)
- Weight less-important properties (margin)
- Overall confidence calculation
```

### Integration Tests

```typescript
// fullCaptureFlow.integration.test.ts
- POST /api/capture
- Store element tree
- Match elements
- GET /api/capture/:id
- Verify all elements have matches

// matchingAccuracy.integration.test.ts
- Complex nested DOM
- Media query context
- Cascade resolution
- Confidence scores
```

---

## Edge Cases to Handle

1. **Large DOM trees** (1000+ elements)
   - Test: Performance test
   - Solution: Batch processing

2. **No matching rules**
   - Element: <div> (generic)
   - Solution: Return empty matches

3. **Multiple matching rules**
   - Solution: Return in cascade order (winner first)

4. **Pseudo-classes**
   - :hover, :focus, :active
   - Solution: Match selector, note state not active

5. **Responsive elements**
   - Different styles at different viewports
   - Solution: Only match rules for captured viewport

---

## Validation Workflow

```bash
# 1. Unit tests
npm test -- cssSelectorMatcher.test.ts
npm test -- matchingService.test.ts
✅ All tests pass

# 2. Integration tests
npm test -- fullCaptureFlow.integration.test.ts
✅ Full flow works

# 3. Manual testing
curl -X POST http://localhost:3000/api/capture \
  -d @test-payload.json
✅ Returns captureId

curl http://localhost:3000/api/capture/[id]
✅ Returns matches with confidence scores

# 4. Validation
npm test -- stage-9
✅ All tests pass (>90% coverage)
```

---

## Performance Targets

- Small capture (50 elements): <500ms
- Medium capture (500 elements): <3s
- Large capture (5000 elements): <30s

---

## Success Criteria

Stage 9 is complete when:

- [ ] API receives DOM payloads
- [ ] Elements stored hierarchically
- [ ] CSS selector matching works for all selector types
- [ ] Cascade resolution correct (specificity + order)
- [ ] Media queries filter correctly
- [ ] Confidence scores reasonable (0.6-1.0)
- [ ] Tailwind mappings accurate
- [ ] Tests pass (>90% coverage)
- [ ] Full end-to-end flow works
- [ ] Can match complex nested DOMs

---

## Resources

- `docs/stages/09_DOM_TO_TAILWIND.md` - Detailed guide
- `docs/ARCHITECTURE.md` - System design
- Stage 4 output (`less_rules` table) - Critical input

---

**Last Updated:** October 29, 2025
