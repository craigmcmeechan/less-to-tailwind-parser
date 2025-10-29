# ARCHITECTURE GUIDE (SIMPLIFIED PART 2)

This document describes the system architecture for both Part 1 (LESS extraction) and Part 2 (Chrome extension + backend matching).

## Table of Contents

1. [System Overview](#system-overview)
2. [Part 1: LESS Extraction](#part-1-less-extraction)
3. [Part 2: Extension + Backend](#part-2-extension--backend)
4. [Data Flow](#data-flow)
5. [Key Design Decisions](#key-design-decisions)

---

## System Overview

### Two-Part System (Simplified)

**Part 1 - LESS CSS Extraction (Weeks 1-6)**
- Scans LESS CSS files from multiple paths
- Parses imports and hierarchical structure
- Extracts CSS selectors, rules, variables, and mixins
- Stores in PostgreSQL with indexed selectors
- Exports Tailwind CSS configuration

**Part 2 - Chrome Extension → Tailwind (Weeks 7-8)**
- Chrome extension captures DOM elements with computed styles
- Backend receives captured DOM tree
- Backend matches elements to Part 1's LESS rules
- Backend generates Tailwind class suggestions
- Returns mapping with confidence scores

### Technology Stack

- **Runtime:** Node.js
- **Language:** TypeScript (Part 1), JavaScript (Extension)
- **Database:** PostgreSQL
- **Extension:** Chrome Extension APIs (vanilla JS, no frameworks)
- **LESS Parsing:** less.js
- **Backend:** Express or similar

---

## Part 1: LESS Extraction (Stages 1-7)

### Architecture Layers

```
┌─────────────────────────────────────────────────────┐
│  CLI / Entry Point (src/index.ts)                   │
│  - Orchestrate Part 1 pipeline                      │
└──────────────────┬──────────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────────┐
│  Service Layer (src/services/)                      │
│  - LessService: File scanning & processing          │
│  - RuleExtractionService: CSS rule extraction       │
│  - DatabaseService: Data persistence                │
│  - ExportService: Tailwind config generation        │
└──────────────────┬──────────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────────┐
│  Data Layer (src/database/)                         │
│  - Database connection & queries                    │
│  - Schema and migrations                            │
└──────────────────┬──────────────────────────────────┘
                   │
                PostgreSQL (less_rules indexed)
```

### Part 1 Output

- ✅ `less_rules` table with indexed selectors
- ✅ `less_variables` table with variables/mixins
- ✅ `theme_tokens` table with extracted theme values
- ✅ `tailwind.config.js` file for Part 1 users
- ✅ `tailwind_exports` table for audit

**Crucial for Part 2:** `less_rules` with queryable selectors

---

## Part 2: Extension + Backend (Stages 8-9)

### Architecture Overview

```
┌───────────────────────────┐
│  User's Browser           │
│                           │
│  [Chrome Extension]       │
│  - Element picker         │
│  - DOM capture            │
│  - Computed styles        │
│                           │
│  User selects element →   │
└───────────────┬───────────┘
                │ POST JSON
                │
        ┌───────▼──────────┐
        │  Backend Service │
        │  Stage 9         │
        │                  │
        │  POST /capture   │ ← Receive DOM tree
        │    ↓             │
        │  Store capture   │
        │    ↓             │
        │  Match elements  │ ← Query less_rules
        │    ↓             │
        │  Generate        │ ← Map to Tailwind
        │  Tailwind        │
        │    ↓             │
        │  Return ID       │ → User polls for results
        └────────┬─────────┘
                 │
        ┌────────▼─────────┐
        │ PostgreSQL       │
        │ (captured_*)     │
        └──────────────────┘
```

### Part 2 Components

#### 1. Chrome Extension (Stage 8)

**Responsibility:** Capture DOM and send to backend

**Files:**
- `manifest.json` - Extension config
- `popup.html/js` - UI
- `content-script.js` - Page interaction
- `background.js` - Backend communication

**Core Functions:**
```javascript
// User triggers capture mode
startCapture() 
  → Element picker mode enabled
  → User clicks element
  → captureElement(clickedNode)

// Extract DOM tree
buildDomTree(element)
  → Recursively build tree with children
  → For each node: getComputedStyles()
  → Return structured JSON

// Send to backend
postToBackend(payload)
  → POST /api/capture
  → Payload: {url, timestamp, viewport, elementTree}
  → On success: notify user
```

**Output:**
```json
{
  "url": "https://example.com",
  "timestamp": "2025-10-29T14:00:00Z",
  "viewport": {"width": 1920, "height": 1080},
  "element": {
    "id": "e1",
    "tag": "div",
    "classes": ["asc-about-header"],
    "computedStyles": {...},
    "children": [...]
  }
}
```

**What Extension Does NOT Do:**
- Match selectors
- Generate Tailwind
- Store anything
- Query database

---

#### 2. Backend Service (Stage 9)

**Responsibility:** Match elements to LESS rules and generate Tailwind

**Services:**
```
POST /api/capture
  → CaptureService.receive()
  → Store capture metadata
  → Store element hierarchy
  → MatchingService.matchElements()
  → Return capture ID

GET /api/capture/:id
  → RetrievalService.getCaptureWithMatches()
  → Return element tree + suggestions
```

**Core Logic:**

```
FOR each element in captured tree:
  1. Extract classes from element
  2. Query less_rules WHERE selector CONTAINS class
  3. For each matched rule:
     - Compare rule properties to element's computed styles
     - Calculate confidence (% matching)
     - Map properties to theme_tokens
     - Get Tailwind class equivalents
  4. Rank matches by confidence
  5. Return top suggestions
```

**Example Matching:**

```
Captured element:
  Tag: div
  Classes: ["asc-about-header"]
  Computed: {
    "font-size": "12px",
    "color": "#333333",
    "font-weight": "bold"
  }

Query: SELECT * FROM less_rules 
       WHERE selector LIKE '%asc-about-header%'

Result: Rule#42
  Selector: ".asc-about-header"
  Properties: {
    "font-size": "12px",
    "color": "@text-normal → #333333",
    "margin": "0 30px",
    "font-weight": "bold"
  }

Matching:
  - font-size: 12px → ✓ MATCH
  - color: #333333 → ✓ MATCH
  - font-weight: bold → ✓ MATCH
  - margin: 0 30px → ✗ NO MATCH (not in computed)

Confidence: 3/4 = 0.75

Tailwind Mapping (from theme_tokens):
  "12px" → "text-xs"
  "#333333" → "text-gray-700"
  "bold" → "font-bold"

Output: ["text-xs", "text-gray-700", "font-bold"]
```

---

## Data Flow

### Part 1: LESS to Database

```
LESS Files
    ↓ (Scan)
LessService → less_files
    ↓ (Import resolution)
Import hierarchy → less_imports
    ↓ (Rule extraction) ⭐ CRITICAL FOR PART 2
CSS selectors + rules → less_rules (INDEXED)
    ↓ (Variable extraction)
Variables + mixins → less_variables
    ↓ (Theme mapping)
Theme tokens → theme_tokens
```

### Part 2: Capture → Tailwind

```
User selects element
    ↓ (Extension)
captureElement(node)
    ↓ (Build DOM tree)
buildDomTree() → JSON payload
    ↓ (POST)
Backend /api/capture
    ↓ (Store)
captured_elements (hierarchical)
    ↓ (For each element)
    ├─ Query less_rules (matching selectors)
    ├─ Compare computed styles
    ├─ Calculate confidence
    ├─ Map to theme_tokens
    └─ Generate Tailwind
    ↓
element_rule_matches (audit trail)
    ↓
GET /api/capture/:id
    ↓
Return results with suggestions
```

---

## Part 2 Database Structure

### New Tables

#### `captured_elements` - Hierarchical DOM

```
id → UUID (primary key)
capture_id → UUID (groups elements from one capture)
parent_id → UUID (hierarchy: null = root)
url → VARCHAR
tag → VARCHAR
classes → TEXT[] (array of classes)
computed_styles → JSONB (from browser)
created_at → TIMESTAMP

Indexes:
  - (capture_id) - fast tree queries
  - (parent_id) - for hierarchy traversal
  - (classes) - GIN for class matching
```

#### `element_captures` - Metadata

```
id → UUID (primary key)
url → VARCHAR (webpage URL)
viewport_width → INTEGER
viewport_height → INTEGER
extension_version → VARCHAR
created_at → TIMESTAMP

Indexes:
  - (url) - find captures for URL
  - (created_at) - chronological queries
```

#### `element_rule_matches` - Mapping

```
id → SERIAL
element_id → UUID (foreign key → captured_elements)
less_rule_id → INTEGER (foreign key → less_rules)
selector → VARCHAR (matched selector)
confidence → DECIMAL (0.0-1.0)
matched_properties → JSONB (which properties matched)
tailwind_classes → TEXT[] (suggested classes)
created_at → TIMESTAMP

Indexes:
  - (element_id) - find matches for element
  - (less_rule_id) - find matches for rule
```

---

## Key Advantages of This Architecture

✅ **Simple Extension** - Just capture, post  
✅ **Browser Cascade** - Chrome resolves complex CSS  
✅ **Reprocessable** - Can re-match without re-capture  
✅ **Testable** - Mock DOM payloads, test matching logic  
✅ **Scalable** - Backend can cache matches, optimize queries  
✅ **User Control** - Explicit element selection  
✅ **No Pseudo-classes Guessing** - Only capture what's rendered  

---

## Part 2 Matching Strategy

### Why Computed Styles?

Extension extracts `element.getComputedStyle()` which includes:
- All applied styles (cascade resolved by browser)
- Pseudo-elements (if active during capture)
- Media queries (at capture viewport)
- JavaScript modifications (if any)

### Confidence Scoring

Confidence = (matching properties / total rule properties) × 100

```
Rule has 5 properties
Element's computed styles match 4 of them
Confidence = 4/5 = 0.80 (80%)
```

Used to rank suggestions (highest confidence first)

---

## Key Design Decision: Backend Matching

**Why not in extension?**
- Extension stays simple (less bugs, smaller binary)
- Full DOM context needed for hierarchy
- Can improve algorithm without extension update
- Reprocessable if matching logic changes
- Testable with mock payloads

**Why not build cascade resolver?**
- Browser already does it perfectly
- Complex CSS cascade rules are error-prone
- Saves weeks of development
- User sees exactly what browser renders

---

**Document Version:** 2.1 (Simplified Part 2)  
**Last Updated:** October 29, 2025
