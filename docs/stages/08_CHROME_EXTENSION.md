# STAGE 8: CHROME EXTENSION FOR DOM CAPTURE

**Duration:** 1 week  
**Status:** ⏳ Ready (after Part 1 complete)  
**Dependencies:** Part 1 complete (not strictly required, but context helpful)  
**Enables:** Stage 9 (Backend Matching)

---

## Overview

Stage 8 delivers a Chrome extension that allows users to select HTML elements on any webpage and capture their DOM structure with computed CSS styles. The extension sends this data to a backend service for processing.

**Key Deliverable:** Chrome extension (.zip) ready to load for user testing.

---

## Objectives

1. ✅ Chrome extension that loads and activates without errors
2. ✅ Element picker UI (highlight elements on hover)
3. ✅ DOM tree capture with full hierarchy
4. ✅ Computed CSS extraction for each element
5. ✅ Capture viewport dimensions
6. ✅ Post JSON payload to backend
7. ✅ User feedback on capture/send success
8. ✅ Error handling for network issues

---

## Requirements

### User Experience

**What User Sees:**
1. Click extension icon
2. Click "Capture Element" button
3. Page elements highlight on hover (visual feedback)
4. Click element to capture
5. See message: "Captured and sent to server"
6. Can click "View Results" to see suggestions

### What Gets Captured

For selected element AND all descendants:

```json
{
  "element": {
    "id": "unique-id-1",           // Generated locally
    "tag": "div",
    "classes": ["class1", "class2"],
    "ids": [],
    "attributes": {
      "data-id": "123",
      "aria-label": "text"
    },
    "computedStyles": {            // From getComputedStyle()
      "font-size": "12px",
      "color": "#333",
      "margin": "0px",
      "padding": "10px",
      ... (all computed styles)
    },
    "textContent": "Element text",
    "children": [
      {
        "id": "unique-id-2",
        "tag": "span",
        ... (recursive)
      }
    ]
  }
}
```

### What Extension Does NOT Do

- ❌ Analyze or match selectors
- ❌ Generate Tailwind classes
- ❌ Store any data locally
- ❌ Query database
- ❌ Modify webpage

---

## Technical Specifications

### File Structure

```
extension/
├── manifest.json              # Extension config
├── popup/
│   ├── popup.html            # Extension UI
│   ├── popup.js              # UI logic
│   └── styles.css
├── content/
│   ├── content-script.js     # Page interaction
│   └── content-styles.css    # Hover highlighting
├── background/
│   └── background.js         # Backend communication
├── icons/
│   ├── icon-16.png
│   ├── icon-48.png
│   └── icon-128.png
└── README.md                 # Installation & usage
```

### manifest.json

```json
{
  "manifest_version": 3,
  "name": "LESS to Tailwind - DOM Capture",
  "version": "1.0",
  "description": "Capture HTML elements for Tailwind conversion",
  "permissions": [
    "activeTab",
    "scripting",
    "tabs"
  ],
  "host_permissions": [
    "<all_urls>"
  ],
  "action": {
    "default_popup": "popup/popup.html",
    "default_title": "LESS to Tailwind Capture"
  },
  "background": {
    "service_worker": "background/background.js"
  },
  "content_scripts": [
    {
      "matches": ["<all_urls>"],
      "js": ["content/content-script.js"],
      "css": ["content/content-styles.css"]
    }
  ]
}
```

---

## Implementation Details

### Part 1: Popup UI (popup/popup.js)

```javascript
// States
let captureMode = false;

// Button handlers
document.getElementById('capture-btn').addEventListener('click', () => {
  captureMode = true;
  startCapture();
});

document.getElementById('cancel-btn').addEventListener('click', () => {
  captureMode = false;
  stopCapture();
});

// Start capture: tell content script to enter picker mode
function startCapture() {
  chrome.tabs.query({active: true, currentWindow: true}, (tabs) => {
    chrome.tabs.sendMessage(tabs[0].id, {action: 'startCapture'});
  });
}

// Stop capture
function stopCapture() {
  chrome.tabs.query({active: true, currentWindow: true}, (tabs) => {
    chrome.tabs.sendMessage(tabs[0].id, {action: 'stopCapture'});
  });
}
```

### Part 2: Content Script (content/content-script.js)

```javascript
// Global state
let captureMode = false;
let selectedElement = null;

// Listen for messages from popup
chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
  if (message.action === 'startCapture') {
    enterCaptureMode();
    sendResponse({status: 'capture started'});
  } else if (message.action === 'stopCapture') {
    exitCaptureMode();
    sendResponse({status: 'capture stopped'});
  }
});

// CAPTURE MODE: Show picker UI
function enterCaptureMode() {
  captureMode = true;
  document.body.style.cursor = 'pointer';
  
  document.addEventListener('mouseover', highlightElement);
  document.addEventListener('mouseout', clearHighlight);
  document.addEventListener('click', captureElement, true);
}

// Exit capture mode
function exitCaptureMode() {
  captureMode = false;
  document.body.style.cursor = 'default';
  
  document.removeEventListener('mouseover', highlightElement);
  document.removeEventListener('mouseout', clearHighlight);
  document.removeEventListener('click', captureElement, true);
  clearHighlight();
}

// Highlight element on hover
function highlightElement(e) {
  if (!captureMode) return;
  e.target.classList.add('capture-highlight');
}

// Clear highlight
function clearHighlight(e) {
  if (e && e.target) {
    e.target.classList.remove('capture-highlight');
  } else {
    document.querySelectorAll('.capture-highlight')
      .forEach(el => el.classList.remove('capture-highlight'));
  }
}

// Capture element + subtree
function captureElement(e) {
  if (!captureMode) return;
  e.preventDefault();
  e.stopPropagation();
  
  const element = e.target;
  exitCaptureMode();
  
  const domTree = buildDomTree(element);
  const payload = {
    url: window.location.href,
    timestamp: new Date().toISOString(),
    viewport: {
      width: window.innerWidth,
      height: window.innerHeight
    },
    element: domTree
  };
  
  // Send to background script
  chrome.runtime.sendMessage({
    action: 'sendToBackend',
    payload: payload
  });
}

// Build DOM tree recursively
function buildDomTree(element, depth = 0) {
  if (depth > 50) return null; // Prevent infinite recursion
  
  const tree = {
    id: generateId(),
    tag: element.tagName.toLowerCase(),
    classes: Array.from(element.classList),
    ids: element.id ? [element.id] : [],
    attributes: extractAttributes(element),
    computedStyles: getComputedStyles(element),
    textContent: element.textContent.substring(0, 200), // First 200 chars
    children: []
  };
  
  // Recursively add children
  for (let child of element.children) {
    const childTree = buildDomTree(child, depth + 1);
    if (childTree) {
      tree.children.push(childTree);
    }
  }
  
  return tree;
}

// Extract non-empty attributes
function extractAttributes(element) {
  const attrs = {};
  for (let attr of element.attributes) {
    if (!['class', 'id', 'style'].includes(attr.name)) {
      attrs[attr.name] = attr.value;
    }
  }
  return attrs;
}

// Get computed styles
function getComputedStyles(element) {
  const computed = window.getComputedStyle(element);
  const styles = {};
  
  // Get all CSS properties (expensive but necessary)
  for (let prop of computed) {
    const value = computed.getPropertyValue(prop);
    if (value && value !== 'auto' && value !== 'normal') {
      styles[prop] = value;
    }
  }
  
  return styles;
}

// Generate unique IDs
function generateId() {
  return 'elem-' + Math.random().toString(36).substr(2, 9);
}
```

### Part 3: Background Script (background/background.js)

```javascript
const BACKEND_URL = 'http://localhost:3000/api/capture';

// Listen for messages from content script
chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
  if (message.action === 'sendToBackend') {
    postToBackend(message.payload, sender.tab.id);
  }
});

// POST to backend
async function postToBackend(payload, tabId) {
  try {
    const response = await fetch(BACKEND_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(payload)
    });
    
    if (!response.ok) {
      throw new Error(`HTTP ${response.status}`);
    }
    
    const result = await response.json();
    
    // Notify popup of success
    chrome.runtime.sendMessage({
      action: 'captureSuccess',
      captureId: result.captureId,
      tabId: tabId
    });
  } catch (error) {
    console.error('Backend error:', error);
    
    // Notify popup of failure
    chrome.runtime.sendMessage({
      action: 'captureError',
      error: error.message,
      tabId: tabId
    });
  }
}
```

### Part 4: Highlighting CSS (content/content-styles.css)

```css
.capture-highlight {
  outline: 3px solid #FF6B6B !important;
  outline-offset: 2px !important;
  box-shadow: 0 0 0 3px rgba(255, 107, 107, 0.3) !important;
  background-color: rgba(255, 107, 107, 0.1) !important;
}

.capture-indicator {
  position: fixed;
  top: 10px;
  right: 10px;
  padding: 10px 15px;
  background: #222;
  color: white;
  border-radius: 4px;
  font-size: 12px;
  z-index: 99999;
}
```

---

## Testing Requirements

### Manual Testing

- [ ] Install extension in Chrome (unpacked mode)
- [ ] Click extension icon - popup appears
- [ ] Click "Capture Element" - mode activated, cursor changes
- [ ] Hover over elements - highlight shows correctly
- [ ] Click element - capture happens
- [ ] Payload sent to backend (check network tab)
- [ ] Success/error message appears
- [ ] Test with deeply nested elements
- [ ] Test with various viewport sizes

### Edge Cases

- [ ] Very large pages (don't crash)
- [ ] Pages with iframes (handle gracefully)
- [ ] Capture element with no computed styles
- [ ] Network timeout - show error message
- [ ] Backend unavailable - show error message
- [ ] Capturing same element twice - works correctly

---

## Unit Testing (Stage 8)

```typescript
// tests/domCapture.test.js

describe('DOM Tree Building', () => {
  it('should build tree for simple element', () => {
    const html = '<div class="test"><span>text</span></div>';
    const tree = buildDomTree(parseHtml(html));
    
    expect(tree.tag).toBe('div');
    expect(tree.classes).toContain('test');
    expect(tree.children).toHaveLength(1);
    expect(tree.children[0].tag).toBe('span');
  });

  it('should handle deeply nested elements', () => {
    const html = '<div><div><div><div></div></div></div></div>';
    const tree = buildDomTree(parseHtml(html));
    
    // Check it builds correctly
    let depth = 0;
    let current = tree;
    while (current.children.length > 0) {
      depth++;
      current = current.children[0];
    }
    expect(depth).toBe(3);
  });

  it('should extract all computed styles', () => {
    const element = createMockElement();
    const styles = getComputedStyles(element);
    
    expect(styles).toHaveProperty('font-size');
    expect(styles).toHaveProperty('color');
    expect(styles).toHaveProperty('margin');
  });
});
```

---

## Logging & Debugging

Use console for extension debugging:
- Content script: `console.log` appears in page console
- Background script: `console.log` appears in extension background console
- Popup: `console.log` appears in popup console

```javascript
// Enable verbose logging
const DEBUG = true;

function log(message, data) {
  if (DEBUG) {
    console.log(`[CAPTURE] ${message}`, data || '');
  }
}

// Usage
log('Entering capture mode');
log('Payload size', JSON.stringify(payload).length);
log('Backend response', result);
```

---

## Error Handling

See [ERROR_HANDLING.md](../../ERROR_HANDLING.md)

### Specific Scenarios

```javascript
// Network error
if (!response.ok) {
  showNotification(`Error: Server returned ${response.status}`, 'error');
  return;
}

// No backend available
try {
  await fetch(BACKEND_URL);
} catch (error) {
  showNotification('Backend unavailable - check server', 'error');
  return;
}

// Large payload
if (JSON.stringify(payload).length > 10 * 1024 * 1024) {
  showNotification('Element tree too large (>10MB)', 'error');
  return;
}
```

---

## Code Standards

See [CODE_STANDARDS.md](../../CODE_STANDARDS.md)

### JavaScript Extension Standards

- ✅ Use `const`/`let` (no `var`)
- ✅ No inline event handlers
- ✅ Check element existence before accessing
- ✅ Use `async/await` (not callbacks)
- ✅ Error messages in user-friendly language
- ✅ Avoid global variables (use closure/module pattern)

---

## Acceptance Criteria

✅ **All Must Pass:**

- [ ] Extension loads without errors
- [ ] Popup UI displays correctly
- [ ] Element picker highlights on hover
- [ ] Full DOM tree captured (including children)
- [ ] Computed styles extracted for all elements
- [ ] Viewport dimensions captured
- [ ] Payload posted to backend (verify with DevTools Network)
- [ ] Success/error messages appear to user
- [ ] Works on multiple websites
- [ ] No memory leaks on repeated captures
- [ ] Handles network timeouts gracefully
- [ ] Code follows CODE_STANDARDS.md
- [ ] Logging at appropriate levels
- [ ] Error handling per ERROR_HANDLING.md
- [ ] README includes installation instructions

---

## Deliverables Checklist

- [ ] manifest.json configured correctly
- [ ] popup.html with capture controls
- [ ] popup.js with button handlers
- [ ] content-script.js with picker logic
- [ ] background.js with backend communication
- [ ] content-styles.css for highlighting
- [ ] Icons (16x16, 48x48, 128x128)
- [ ] Unit tests for DOM building
- [ ] Extension builds (no console errors)
- [ ] README with setup instructions
- [ ] Network traffic verified (capture posting to backend)

---

## Success Verification

1. **Extension loads:**
   ```
   chrome://extensions/
   → Load unpacked
   → Select extension/ directory
   → Extension appears, enabled
   ```

2. **Element picker works:**
   - Click extension icon
   - Click "Capture"
   - Hover page elements → highlight shows
   - Click element → capture completes

3. **Data sent to backend:**
   - DevTools Network tab
   - POST to http://localhost:3000/api/capture
   - Payload visible in Network tab
   - Response shows captureId

4. **Testing suite passes:**
   ```bash
   npm test -- stage8
   ```

---

**Next Stage:** When Stage 8 passes all criteria, proceed to [Stage 9: Backend DOM Matching](./09_DOM_TO_TAILWIND.md)

---

**Document Version:** 1.0  
**Last Updated:** October 29, 2025
