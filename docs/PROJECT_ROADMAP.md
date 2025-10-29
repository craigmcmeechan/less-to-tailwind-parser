# PROJECT ROADMAP: LESS to Tailwind Parser (REVISED PART 2)

## Executive Summary

**Two-Part System with Simplified Part 2:**

**Part 1 - LESS CSS Extraction (Weeks 1-6):** Transform LESS CSS files into PostgreSQL with extracted theme tokens and CSS rule selectors.

**Part 2 - Chrome Extension → Tailwind (Weeks 7-8):** Simple extension captures DOM elements → backend matches to LESS rules → generates Tailwind classes.

**Total Estimated Timeline:** 8-9 weeks

**Key Change:** Leveraging browser's cascade resolution (Chrome DevTools) instead of building cascade logic.

---

## Updated Project Goals

### Part 1: LESS Extraction
1. ✅ Store LESS hierarchical structure in PostgreSQL
2. ✅ Extract CSS selectors and rule blocks
3. ✅ Extract variables and mixins
4. ✅ Export Tailwind configuration from theme tokens

### Part 2: DOM Capture → Tailwind (Simplified)
1. 🆕 Chrome extension for element selection
2. 🆕 Capture DOM subtree with computed styles
3. 🆕 Backend matches elements to LESS rules
4. 🆕 Generate Tailwind suggestions per element

---

## PART 1: LESS Extraction (Unchanged)

### Stages 1-7: LESS to Database

| Stage | Name | Description | Duration |
|-------|------|-------------|----------|
| 1 | Database Foundation | PostgreSQL setup | 1 week |
| 2 | LESS File Scanning | Discover & store files | 1 week |
| 3 | Import Hierarchy | Parse @import relationships | 1.5 weeks |
| 4 | Rule Extraction | Extract CSS selectors & rules | 1.5 weeks |
| 5 | Variable Extraction | Extract @variables & mixins | 1 week |
| 6 | Tailwind Export | Generate config | 1 week |
| 7 | Integration (Part 1) | Full pipeline | 0.5 week |

**Part 1 Complete:** End of Week 6

---

## PART 2: DOM Capture → Tailwind (Simplified)

### Stage 8: Chrome Extension for DOM Capture

**Duration:** 1 week  
**Dependency:** Part 1 complete (for context, not required)

**Purpose:** Allow users to select HTML elements on any webpage and capture their DOM structure + computed styles.

**Deliverable:** Chrome extension (.zip) with:
- Element picker/selection UI
- DOM tree capture with computed styles
- Post to backend web service

**What Extension Does:**
1. User clicks extension icon
2. Extension enters selection mode (element highlighting)
3. User clicks element
4. Extension captures:
   - Full subtree (element + all children)
   - Computed CSS for each node
   - Element metadata (tag, classes, IDs, attributes)
5. Sends JSON payload to backend

**What Extension Does NOT Do:**
- Match selectors
- Generate Tailwind
- Store data
- Understand LESS

**Output Payload Example:**
```json
{
  "url": "https://example.com/page",
  "timestamp": "2025-10-29T14:00:00Z",
  "viewport": { "width": 1920, "height": 1080 },
  "selectedElement": {
    "id": "elem-1",
    "tag": "div",
    "classes": ["asc-about-header"],
    "attributes": {"data-id": "123"},
    "computedStyles": {
      "font-size": "12px",
      "color": "#333333",
      "margin": "0px 30px",
      "font-weight": "bold"
    },
    "children": [
      {
        "id": "elem-2",
        "tag": "h1",
        "computedStyles": { ... }
      }
    ]
  }
}
```

---

### Stage 9: Backend DOM Matching & Tailwind Generation

**Duration:** 1 week  
**Dependency:** Stage 8 complete + Part 1 database

**Purpose:** Receive captured DOM elements, match to LESS rules, generate Tailwind suggestions.

**Inputs:**
- DOM tree JSON from extension
- Part 1 database (`less_rules`, `theme_tokens`)

**Processing:**
1. Store DOM hierarchy in database (relational structure)
2. For each element in tree:
   - Query `less_rules` matching element's classes
   - Compare computed styles to rule properties
   - Map matched properties to `theme_tokens`
   - Generate Tailwind classes with confidence scores
3. Return mapping with suggestions

**Output:**
```json
{
  "captureId": "uuid",
  "url": "https://example.com/page",
  "elements": [
    {
      "domId": "elem-1",
      "tag": "div",
      "classes": ["asc-about-header"],
      "computedStyles": { "font-size": "12px", ... },
      "matchedRules": [
        {
          "lessRuleId": 42,
          "lessSelector": ".asc-about-header",
          "confidence": 0.95,
          "properties": {
            "font-size": { "value": "12px", "tailwindClass": "text-xs" },
            "color": { "value": "#333333", "tailwindClass": "text-gray-700" }
          }
        }
      ],
      "suggestedTailwind": ["text-xs", "text-gray-700", "font-bold"],
      "children": [...]
    }
  ]
}
```

---

## Part 2 Architecture (Simplified)

```
Chrome Extension                Backend Service
    ↓                                ↓
Element Picker           Stage 9: Matcher
    ↓                                ↓
DOM Tree Capture        Query less_rules
    ↓                                ↓
Computed Styles         Match elements
    ↓                                ↓
POST JSON ─────────────→ Store capture
                         ↓
                    Generate Tailwind
                         ↓
                    Return suggestions
```

---

## Part 2 Database Schema

### New Tables

#### `captured_elements` (Hierarchical DOM)

```sql
CREATE TABLE captured_elements (
  id UUID PRIMARY KEY,
  capture_id UUID NOT NULL, -- Groups elements from single capture
  parent_id UUID,           -- For hierarchy
  url VARCHAR(2048),
  tag VARCHAR(50),
  classes TEXT[],
  ids TEXT[],
  attributes JSONB,
  computed_styles JSONB,    -- From browser DevTools
  created_at TIMESTAMP,
  FOREIGN KEY (parent_id) REFERENCES captured_elements(id),
  FOREIGN KEY (capture_id) REFERENCES element_captures(id)
);

CREATE INDEX idx_captured_parent ON captured_elements(parent_id);
CREATE INDEX idx_captured_url ON captured_elements(url);
CREATE INDEX idx_captured_classes ON captured_elements USING GIN(classes);
```

#### `element_captures` (Metadata)

```sql
CREATE TABLE element_captures (
  id UUID PRIMARY KEY,
  url VARCHAR(2048),
  viewport_width INTEGER,
  viewport_height INTEGER,
  extension_version VARCHAR(20),
  created_at TIMESTAMP
);

CREATE INDEX idx_captures_url ON element_captures(url);
CREATE INDEX idx_captures_date ON element_captures(created_at);
```

#### `element_rule_matches` (Capture→LESS Mapping)

```sql
CREATE TABLE element_rule_matches (
  id SERIAL PRIMARY KEY,
  element_id UUID NOT NULL,
  less_rule_id INTEGER NOT NULL,
  selector VARCHAR(1024),
  confidence DECIMAL(3,2),
  matched_properties JSONB,
  tailwind_classes TEXT[],
  created_at TIMESTAMP,
  FOREIGN KEY (element_id) REFERENCES captured_elements(id),
  FOREIGN KEY (less_rule_id) REFERENCES less_rules(id)
);

CREATE INDEX idx_matches_element ON element_rule_matches(element_id);
CREATE INDEX idx_matches_rule ON element_rule_matches(less_rule_id);
```

---

## Stage 8: Chrome Extension Detailed

### Deliverables

1. **manifest.json** - Extension config
2. **popup.html/js** - Extension UI (picker mode toggle)
3. **content-script.js** - Page interaction (element selection)
4. **background.js** - Communication with backend
5. **README** - Installation & usage instructions

### Tech Stack

- Vanilla JavaScript (no framework)
- Chrome Extension APIs
- Fetch API for backend communication

### Core Functions

```javascript
// Element selection
function startElementPicker() { }
function captureElement(element) { }
function buildDomTree(element) { }
function getComputedStyles(element) { }

// Communication
function postToBackend(payload) { }
function handleResponse(response) { }
```

### User Flow

1. Visit any webpage
2. Click extension icon
3. Click "Capture Element"
4. Hover over elements (highlights)
5. Click element to capture
6. Extension shows "Captured & sent"
7. User returns to backend to view results

---

## Stage 9: Backend Matching Engine

### Deliverables

1. **Web Service Endpoint:** `POST /api/capture` - Receive DOM from extension
2. **Matching Service:** Query `less_rules`, match elements
3. **Tailwind Generator:** Convert matched properties to classes
4. **Results Endpoint:** `GET /api/capture/:id` - Retrieve suggestions

### Workflow

```
POST /api/capture {domTree, url, viewport}
    ↓
1. Store capture metadata
    ↓
2. Store element hierarchy
    ↓
3. For each element:
    - Query less_rules by classes
    - Compare computed_styles to rule properties
    - Calculate confidence
    - Map to theme_tokens → Tailwind
    - Store matches
    ↓
4. Return capture ID
    ↓
GET /api/capture/:id
    ↓
Return element tree with suggestions
```

### Matching Logic

**Input:** DOM element with computed styles + classes  
**Process:**
1. Find `less_rules` where selector contains element's classes
2. For each matched rule:
   - Compare rule properties to element's computed styles
   - Calculate confidence (% of properties matching)
   - Extract matched properties
   - Query `theme_tokens` for each property
   - Find Tailwind equivalents
3. Sort matches by confidence (highest first)
4. Return top matches

**Example:**

```
Element: <div class="asc-about-header">
Computed: { "font-size": "12px", "color": "#333333", "font-weight": "bold" }

Query less_rules: WHERE classes CONTAINS "asc-about-header"
Results: [Rule#42 with .asc-about-header selector]

Rule#42 Properties: 
  - font-size: 12px ✓ MATCH
  - color: @text-normal → #333333 ✓ MATCH
  - font-weight: bold ✓ MATCH
  - margin: 0 30px ✗ NO MATCH

Confidence: 3/4 = 0.75

Theme tokens:
  - "12px" → "text-xs"
  - "#333333" → "text-gray-700"
  - "bold" → "font-bold"

Tailwind output: ["text-xs", "text-gray-700", "font-bold"]
```

---

## Part 2 Simplified Benefits

✅ **No cascade logic needed** - Browser handles it  
✅ **Pseudo-classes visible** - If user hovers/interacts before capture  
✅ **Media queries resolved** - At capture viewport  
✅ **Simple extension** - Just capture, no intelligence  
✅ **Reprocessable** - Can re-match without re-capture  
✅ **User controls flow** - Explicit element selection  

---

## Key Differences from Original Part 2 Plan

| Original | Simplified |
|----------|-----------|
| Build cascade resolver | Use browser cascade |
| Parse HTML in backend | Extension captures DOM |
| Complex selector matching | Simple class-based matching |
| 4 stages (8-11) | 2 stages (8-9) |
| 2-3 weeks | 1-2 weeks |

---

## Timeline (Revised)

```
Week 1:    [══ Stage 1: DB ══]
Week 2:                   [══ Stage 2: Scan ══]
Week 3:                               [═ Stage 3 ═][═ Stage 4 ═]
Week 4:                        [════ Stages 3,4,5 (parallel) ════]
Week 5:                                              [═ Stage 5 ═][═ Stage 6 ═]
Week 6:                                                    [═ Stage 6 ═][S7]
                                                                      ↓
Week 7:    [════════ Stage 8: Chrome Extension ════════]
Week 8:                                   [════ Stage 9: Backend Matching ════]

Part 1 Complete: End Week 6
Part 2 Complete: End Week 8
```

---

**Document Version:** 2.1 (Simplified Part 2)  
**Last Updated:** October 29, 2025
