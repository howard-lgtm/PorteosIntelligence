# Browser Extension Architecture — Property Scraping System

Complete guide to the Porteos Importer Chrome extension: scraper patterns, adding new sites, and debugging.

---

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Installation & Setup](#installation--setup)
4. [Scraper Pattern](#scraper-pattern)
5. [Supported Sites](#supported-sites)
6. [Adding a New Site](#adding-a-new-site)
7. [Data Extraction Utilities](#data-extraction-utilities)
8. [DealIngestionServer Protocol](#dealingestionserver-protocol)
9. [Testing Scrapers](#testing-scrapers)
10. [Debugging Common Issues](#debugging-common-issues)

---

## Overview

The **Porteos Importer** is a Chrome Manifest V3 extension that enables one-click property imports from 12 major real estate sites across 4 countries.

### Quick Stats

- **Version:** 3.0.0
- **File Size:** 56KB (`content.js`)
- **Sites Supported:** 12
- **Countries:** USA, Portugal, Spain, Sweden
- **Lines of Code:** ~1,500

### How It Works

```
User visits listing page
     ↓
Extension detects site
     ↓
Injects [ SEND TO PORTEOS ] button (bottom-right)
     ↓
User clicks button
     ↓
Site-specific scraper extracts data
     ↓
POST to http://localhost:9000/api/deals
     ↓
DealIngestionServer creates PropertyDeal
     ↓
Deal appears in app within 1-2 seconds
```

---

## Architecture

### Manifest V3 Structure

**File:** `BrowserExtension/PorteosImporter/manifest.json`

```json
{
  "manifest_version": 3,
  "name": "Porteos Importer",
  "version": "3.0.0",
  "permissions": [
    "activeTab",
    "scripting"
  ],
  "host_permissions": [
    "http://localhost:9000/*",
    "*://www.zillow.com/*",
    "*://www.idealista.pt/*",
    // ... more sites
  ],
  "content_scripts": [{
    "matches": [
      "*://www.zillow.com/*",
      // ... all supported sites
    ],
    "js": ["content.js"],
    "run_at": "document_idle"
  }]
}
```

**Key Fields:**
- **`host_permissions`:** Sites extension can scrape + localhost for API
- **`content_scripts`:** Runs `content.js` on matched sites
- **`run_at: "document_idle"`:** Waits for page load before injecting

### Content Script Architecture

**File:** `BrowserExtension/PorteosImporter/content.js` (1,487 lines)

```
┌────────────────────────────────────────────────┐
│           content.js (IIFE)                     │
├────────────────────────────────────────────────┤
│  ── Shared Utilities ──                        │
│  - parsePrice()                                │
│  - trySelect()                                 │
│  - extractJsonLd()                             │
│  - sqftToM2()                                  │
├────────────────────────────────────────────────┤
│  ── Site Detectors ──                          │
│  - detectSite()                                │
│    → Returns: "zillow", "idealista", etc.      │
├────────────────────────────────────────────────┤
│  ── Site Scrapers (12 functions) ──            │
│  - initZillow()                                │
│  - initIdealista()                             │
│  - initCasaSAPO()                              │
│  - ... (one per site)                          │
├────────────────────────────────────────────────┤
│  ── UI Injection ──                            │
│  - injectButton()                              │
│  - showToast()                                 │
├────────────────────────────────────────────────┤
│  ── API Communication ──                       │
│  - sendDealToPorteos(dealData)                 │
│    → POST to localhost:9000                    │
└────────────────────────────────────────────────┘
```

---

## Installation & Setup

### For Users

**Chrome/Arc/Edge/Brave:**
1. Visit `chrome://extensions`
2. Enable **Developer mode** (toggle, top-right)
3. Click **Load unpacked**
4. Select: `PorteosIntelligence/BrowserExtension/PorteosImporter/`
5. Extension appears with Porteos icon

**Requirements:**
- ✅ Porteos Intelligence app must be running
- ✅ HTTP server active on port 9000 (green `HTTP` indicator)

### For Developers

**After modifying content.js:**
1. Save changes
2. `chrome://extensions`
3. Find "Porteos Importer"
4. Click **↻** (reload icon)
5. Refresh listing page to test

**Changes require manual reload** — not automatic.

---

## Scraper Pattern

### General Structure

Each site gets its own `init` function:

```javascript
function initSiteName() {
  const buttonContainer = document.createElement("div");
  buttonContainer.id = "porteos-importer-button";
  buttonContainer.innerHTML = `
    <button id="porteos-send-button">
      [ SEND TO PORTEOS ]
    </button>
  `;
  buttonContainer.style = `
    position: fixed;
    bottom: 20px;
    right: 20px;
    z-index: 9999;
    font-family: 'JetBrains Mono', monospace;
  `;
  
  document.body.appendChild(buttonContainer);
  
  document.getElementById("porteos-send-button").addEventListener("click", () => {
    const dealData = extractSiteNameData();
    sendDealToPorteos(dealData);
  });
}

function extractSiteNameData() {
  return {
    propertyName: trySelect(".listing-title", "h1.title"),
    address: trySelect(".address", ".location"),
    purchasePrice: parsePrice(trySelect(".price", ".cost")),
    bedrooms: parseInt(trySelect(".beds")) || 0,
    bathrooms: parseInt(trySelect(".baths")) || 0,
    totalArea: parseNumber(trySelect(".sqft", ".area")),
    locationCity: extractCity(),
    locationCountry: "Country Name",
    sourceURL: window.location.href,
    images: extractImages(),
  };
}
```

### Data Shape

**Standard payload:**
```javascript
{
  // REQUIRED
  propertyName: string,
  purchasePrice: number,  // In local currency
  locationCity: string,
  locationCountry: string,
  
  // RECOMMENDED
  address: string,
  propertyType: string,  // "Residential - Single Family", "Hotel", etc.
  bedrooms: number,
  bathrooms: number,
  totalArea: number,     // In m² (convert from sqft if needed)
  
  // OPTIONAL
  landArea: number,
  yearBuilt: number,
  description: string,
  sourceURL: string,
  images: string[],      // URLs only (not base64)
  
  // GEO (optional, but helpful)
  latitude: number,
  longitude: number,
}
```

---

## Supported Sites

### United States

#### 1. Zillow.com

**URL Pattern:** `https://www.zillow.com/homedetails/*/`

**Key Selectors:**
```javascript
propertyName:  "h1[data-test='property-title']"
price:         "span[data-test='property-price']"
address:       "h1[data-test='property-title']"  // Full address in title
bedrooms:      "span[data-test='bed-value']"
bathrooms:     "span[data-test='bath-value']"
sqft:          "span[data-test='property-sqft']"
```

**Notes:**
- React-heavy site, hydration delays
- JSON-LD structured data available for price fallback
- Images in `<picture>` elements

#### 2. Realtor.com

**URL Pattern:** `https://www.realtor.com/realestateandhomes-detail/*/`

**Key Selectors:**
```javascript
price:   ".price-wrapper .price"
address: ".address"
beds:    ".bed .data-value"
baths:   ".bath .data-value"
sqft:    ".sqft .data-value"
```

#### 3. Redfin.com

**URL Pattern:** `https://www.redfin.com/*/home/*/`

**Key Selectors:**
```javascript
price:   ".statsValue"
address: ".street-address"
beds:    ".HomeStatsV2--bed .statsValue"
baths:   ".HomeStatsV2--bath .statsValue"
```

#### 4. Trulia.com

**URL Pattern:** `https://www.trulia.com/p/*/`

**Key Selectors:**
```javascript
price:   "[data-testid='home-price']"
address: "[data-testid='home-address']"
beds:    "[data-testid='bed']"
baths:   "[data-testid='bath']"
```

### Portugal

#### 5. Idealista.pt

**URL Pattern:** `https://www.idealista.pt/imovel/*/`

**Key Selectors:**
```javascript
price:   ".info-data-price span"
address: ".main-info__title-main"
beds:    ".info-data-rooms span" 
m²:      ".info-data-m2 span"
```

**Notes:**
- Prices in € with EU format: 1.350.000
- Area in m² (no conversion needed)

#### 6. Casa SAPO

**URL Pattern:** `https://casa.sapo.pt/*/`

**Key Selectors:**
```javascript
price:   ".property-price"
address: ".property-title"
beds:    ".property-features-item:contains('quartos')"
m²:      ".property-features-item:contains('m²')"
```

#### 7. RE/MAX Portugal

**URL Pattern:** `https://www.remax.pt/imoveis/*/`

**Key Selectors:**
```javascript
price:   ".property-price"
address: "h1.property-title"
beds:    ".specs .bed"
m²:      ".specs .area"
```

### Spain

#### 8. Idealista.com (Spain)

**URL Pattern:** `https://www.idealista.com/inmueble/*/`

**Similar to Idealista.pt, with Spain-specific parsing**

#### 9. Fotocasa.es

**URL Pattern:** `https://www.fotocasa.es/*/`

**Key Selectors:**
```javascript
price:   ".re-DetailHeader-price"
address: ".re-DetailHeader-propertyTitle"
beds:    ".re-DetailFeature--bed"
m²:      ".re-DetailFeature--surface"
```

### Sweden

#### 10. Hemnet.se

**URL Pattern:** `https://www.hemnet.se/bostad/*/`

**Key Selectors:**
```javascript
price:   ".property-info__price"
address: ".qa-property-heading"
beds:    ".property-info__item:contains('rum')"
m²:      ".property-info__item:contains('m²')"
```

**Notes:**
- Prices in SEK (Swedish Krona)
- "Rum" = rooms (approximate bedrooms)

#### 11. Booli.se

**URL Pattern:** `https://www.booli.se/annons/*/`

**Key Selectors:**
```javascript
price:   ".sold-property__price"
address: "h1.sold-property__address"
beds:    ".property-details__rooms"
m²:      ".property-details__living-area"
```

---

## Adding a New Site

### Example: Add Rightmove.co.uk

**Step 1: Update manifest.json**

```json
{
  "host_permissions": [
    // ... existing sites
    "*://www.rightmove.co.uk/*"  // ← ADD
  ],
  "content_scripts": [{
    "matches": [
      // ... existing sites
      "*://www.rightmove.co.uk/*"  // ← ADD
    ],
    "js": ["content.js"],
    "run_at": "document_idle"
  }]
}
```

**Step 2: Add site detector**

```javascript
// In detectSite() function
function detectSite() {
  const host = window.location.hostname;
  if (host.includes("zillow.com")) return "zillow";
  if (host.includes("idealista.pt")) return "idealista";
  // ... existing sites
  if (host.includes("rightmove.co.uk")) return "rightmove";  // ← ADD
  return null;
}
```

**Step 3: Create init function**

```javascript
function initRightmove() {
  // 1. Inject button
  const buttonContainer = document.createElement("div");
  buttonContainer.id = "porteos-importer-button";
  buttonContainer.innerHTML = `
    <button id="porteos-send-button">
      [ SEND TO PORTEOS ]
    </button>
  `;
  buttonContainer.style = `
    position: fixed;
    bottom: 20px;
    right: 20px;
    z-index: 9999;
    padding: 12px 24px;
    background: #1a1d24;
    color: #e5e7eb;
    border: 1px solid #06b6d4;
    font-family: 'JetBrains Mono', monospace;
    font-size: 11px;
    cursor: pointer;
    letter-spacing: 0.05em;
  `;
  
  document.body.appendChild(buttonContainer);
  
  // 2. Add click handler
  document.getElementById("porteos-send-button").addEventListener("click", () => {
    const dealData = extractRightmoveData();
    sendDealToPorteos(dealData);
  });
}
```

**Step 4: Create extraction function**

```javascript
function extractRightmoveData() {
  // Inspect Rightmove page, identify CSS selectors
  const propertyName = trySelect(
    "h1[data-test='property-header-title']",
    ".propertyHeader h1",
    "h1.property-header-title"
  );
  
  const priceText = trySelect(
    "div.propertyHeaderPrice strong",
    ".price"
  );
  const purchasePrice = parsePrice(priceText);  // Handles £1,350,000
  
  const address = trySelect(
    ".propertyHeaderAddress",
    "address.property-address"
  );
  
  const bedrooms = parseInt(trySelect(".beds", "[data-test='beds']")) || 0;
  const bathrooms = parseInt(trySelect(".baths", "[data-test='baths']")) || 0;
  
  const sqftText = trySelect(".sqft", ".property-size");
  const totalArea = sqftText ? sqftToM2(parseNumber(sqftText)) : 0;
  
  // Extract city from address (UK format: "City, Postcode")
  const cityMatch = address.match(/,\s*([A-Z][a-z\s]+?)\s+[A-Z]{1,2}\d/);
  const locationCity = cityMatch ? cityMatch[1].trim() : "";
  
  // Extract images
  const images = Array.from(document.querySelectorAll(".galleryImage img"))
    .map(img => img.src)
    .filter(src => src && !src.includes("placeholder"))
    .slice(0, 10);  // Limit to 10
  
  return {
    propertyName: propertyName || "Rightmove Property",
    address: address,
    purchasePrice: purchasePrice,
    propertyType: "Residential - Single Family",  // Default
    bedrooms: bedrooms,
    bathrooms: bathrooms,
    totalArea: totalArea,
    locationCity: locationCity,
    locationCountry: "United Kingdom",
    sourceURL: window.location.href,
    images: images,
  };
}
```

**Step 5: Add to router**

```javascript
// At bottom of content.js, in main() function
const site = detectSite();
if (site === "zillow") initZillow();
else if (site === "idealista") initIdealista();
// ... existing sites
else if (site === "rightmove") initRightmove();  // ← ADD
```

**Step 6: Test**

1. Reload extension: `chrome://extensions` → ↻
2. Visit: `https://www.rightmove.co.uk/properties/...`
3. Verify button appears (bottom-right)
4. Click **[ SEND TO PORTEOS ]**
5. Check Porteos app for new deal

**Step 7: Handle Edge Cases**

```javascript
function extractRightmoveData() {
  // ... extraction logic ...
  
  // Handle "POA" (Price on Application)
  if (priceText.includes("POA") || purchasePrice === 0) {
    showToast("⚠️ Price not available. Set manually in Porteos.", 3000);
    // Still send deal, just with 0 price
  }
  
  // Handle shared ownership (partial prices)
  if (priceText.includes("share")) {
    showToast("⚠️ Shared ownership detected. Verify price.", 3000);
  }
  
  return dealData;
}
```

---

## Data Extraction Utilities

### Shared Utility Functions

#### trySelect()

**Purpose:** Try multiple selectors, return first match

```javascript
function trySelect(...selectors) {
  for (const sel of selectors) {
    try {
      const el = document.querySelector(sel);
      if (el && el.textContent.trim()) {
        return el.textContent.trim();
      }
    } catch {
      // Skip invalid selector
    }
  }
  return "";
}
```

**Usage:**
```javascript
const price = trySelect(
  ".price-primary",     // Try first
  ".listing-price",     // Then try this
  "[data-test='price']" // Finally try this
);
```

#### parsePrice()

**Purpose:** Parse prices in EU (1.350.000) and US (1,350,000) formats

```javascript
function parsePrice(raw) {
  if (!raw) return 0;
  let s = String(raw).replace(/[^\d.,\s]/g, "").trim();  // Remove currency symbols
  if (!s) return 0;
  
  s = s.replace(/\s/g, "");  // Remove spaces
  
  const hasComma = s.includes(",");
  const hasDot = s.includes(".");
  
  if (hasComma && hasDot) {
    // Both present: determine which is thousands separator
    const lastComma = s.lastIndexOf(",");
    const lastDot = s.lastIndexOf(".");
    if (lastComma > lastDot) {
      // EU format: 1.350,50 → 1350.50
      s = s.replace(/\./g, "").replace(",", ".");
    } else {
      // US format: 1,350.50 → 1350.50
      s = s.replace(/,/g, "");
    }
  } else if (hasDot) {
    // Dot only: check if thousands separator or decimal
    const parts = s.split(".");
    if (parts.length > 2 || (parts.length === 2 && parts[1].length === 3)) {
      // Thousands: 1.350.000 → 1350000
      s = s.replace(/\./g, "");
    }
    // Else: decimal, keep as-is
  } else if (hasComma) {
    // Comma only: same logic
    const parts = s.split(",");
    if (parts.length > 2 || (parts.length === 2 && parts[1].length === 3)) {
      s = s.replace(/,/g, "");
    } else {
      s = s.replace(",", ".");
    }
  }
  
  const n = parseFloat(s);
  return isNaN(n) || n < 1000 ? 0 : n;  // Prices under 1000 assumed invalid
}
```

**Examples:**
```javascript
parsePrice("€1.350.000")      // → 1350000
parsePrice("$1,350,000")      // → 1350000
parsePrice("£350,000.50")     // → 350000.5
parsePrice("1 350 000 kr")    // → 1350000
parsePrice("POA")             // → 0 (invalid)
```

#### sqftToM2()

**Purpose:** Convert square feet to square meters

```javascript
function sqftToM2(sqft) {
  return Math.round(sqft / 10.764);
}
```

**Examples:**
```javascript
sqftToM2(1000)  // → 93 m²
sqftToM2(2500)  // → 232 m²
```

#### extractJsonLd()

**Purpose:** Extract structured data (JSON-LD) from page

```javascript
function extractJsonLd() {
  try {
    const el = document.querySelector('script[type="application/ld+json"]');
    return el ? JSON.parse(el.textContent) : null;
  } catch {
    return null;
  }
}

function priceFromJsonLd() {
  const ld = extractJsonLd();
  if (!ld) return 0;
  
  const items = Array.isArray(ld) ? ld : [ld];
  for (const item of items) {
    if (item?.price) {
      const n = parsePrice(String(item.price));
      if (n >= 1000) return n;
    }
    
    // Check offers array
    const offerList = Array.isArray(item?.offers) ? item.offers : item?.offers ? [item.offers] : [];
    for (const offer of offerList) {
      if (offer?.price) {
        const n = parsePrice(String(offer.price));
        if (n >= 1000) return n;
      }
    }
  }
  return 0;
}
```

**When to use:** Fallback when CSS selectors fail or change

---

## DealIngestionServer Protocol

### Request Format

**Endpoint:** `http://localhost:9000/api/deals`  
**Method:** POST  
**Content-Type:** `application/json`

```json
{
  "propertyName": "Modern Villa with Pool",
  "address": "123 Main Street",
  "purchasePrice": 1350000,
  "propertyType": "Residential - Single Family",
  "bedrooms": 4,
  "bathrooms": 3,
  "totalArea": 250,
  "locationCity": "Lisbon",
  "locationCountry": "Portugal",
  "sourceURL": "https://example.com/listing/123",
  "images": [
    "https://example.com/image1.jpg",
    "https://example.com/image2.jpg"
  ]
}
```

### Response Format

**Success (201 Created):**
```json
{
  "success": true,
  "dealId": "uuid-here",
  "message": "Deal created successfully"
}
```

**Error (400 Bad Request):**
```json
{
  "success": false,
  "error": "Missing required field: purchasePrice"
}
```

**Error (500 Internal Server Error):**
```json
{
  "success": false,
  "error": "Database error: ..."
}
```

### Server-Side Handling

**File:** `PorteosIntelligence/Services/DealIngestionServer.swift`

```swift
// Server receives POST, validates, creates PropertyDeal
func handleIngestRequest(_ request: HTTPRequest) -> HTTPResponse {
    guard let dealData = try? JSONDecoder().decode(IngestPayload.self, from: request.body) else {
        return .badRequest("Invalid JSON")
    }
    
    // Validate required fields
    guard !dealData.propertyName.isEmpty,
          dealData.purchasePrice > 0,
          !dealData.locationCity.isEmpty else {
        return .badRequest("Missing required fields")
    }
    
    // Create PropertyDeal
    let deal = PropertyDeal()
    deal.propertyName = dealData.propertyName
    deal.purchasePrice = dealData.purchasePrice
    // ... map all fields
    
    // Save to SwiftData
    context.insert(deal)
    try? context.save()
    
    // Download and attach images (async)
    Task {
        await downloadImages(urls: dealData.images, deal: deal)
    }
    
    return .created(["dealId": deal.id.uuidString])
}
```

---

## Testing Scrapers

### Manual Testing Checklist

**For each site:**
- [ ] Button appears on listing page
- [ ] Button positioned bottom-right, not overlapping content
- [ ] Click button → Toast: "Sending..."
- [ ] Deal appears in Porteos within 2 seconds
- [ ] Property name correct
- [ ] Price correct (verify format parsed correctly)
- [ ] Address/location correct
- [ ] Bedrooms/bathrooms correct
- [ ] Area correct (sqft converted to m² if needed)
- [ ] Images imported (up to 10)
- [ ] Test with multiple listings (different formats)

### Edge Case Testing

- [ ] **High-end properties:** €10.000.000+ prices parse correctly
- [ ] **POA listings:** "Price on Application" → 0 or null
- [ ] **Shared ownership:** Partial prices noted
- [ ] **New construction:** Missing bed/bath data handled
- [ ] **Land only:** No building area, only land area
- [ ] **Currency variations:** €, $, £, kr all parse
- [ ] **React hydration delays:** Button still works after delay
- [ ] **Multiple calls:** Rapid clicks don't create duplicates

### Automated Testing (Future)

```javascript
// test-scrapers.js (not yet implemented)

describe("parsePrice", () => {
  it("parses EU format", () => {
    expect(parsePrice("€1.350.000")).toBe(1350000);
  });
  
  it("parses US format", () => {
    expect(parsePrice("$1,350,000")).toBe(1350000);
  });
  
  it("handles invalid input", () => {
    expect(parsePrice("POA")).toBe(0);
  });
});
```

---

## Debugging Common Issues

### Button Doesn't Appear

**Symptoms:** Extension loaded, but no button on page

**Debug steps:**
1. Open Console (F12 → Console)
2. Look for errors: "Content script blocked", "CSP violation"
3. Verify site in `manifest.json` → `host_permissions` and `matches`
4. Check `detectSite()` returns correct site name
5. Verify `run_at: "document_idle"` (React sites need this)

**Fix:** Add site to manifest, reload extension

### Button Appears But Clicking Does Nothing

**Debug:**
1. Console → Check for: `Failed to fetch`, `CORS error`
2. Verify Porteos app is running
3. Check `HTTP` indicator in app is **green**
4. Test server: `curl http://localhost:9000/api/deals`

**Fix:** Start Porteos app, verify port 9000 not blocked

### Wrong Data Extracted

**Debug:**
1. Inspect page (Right-click → Inspect)
2. Find actual CSS selectors for price, address, etc.
3. Compare with selectors in `content.js`
4. Site may have changed HTML structure

**Fix:** Update selectors in extraction function

### Price Parses as 0

**Debug:**
1. Console.log raw price text: `console.log(priceText)`
2. Check format: EU (1.350.000) vs US (1,350,000)?
3. Currency symbol removed? (£, €, $, kr)
4. `parsePrice()` handles both formats

**Fix:** Adjust `parsePrice()` if new format encountered

### Images Don't Import

**Debug:**
1. Check `images` array in payload: `console.log(dealData.images)`
2. Verify URLs are absolute (not relative)
3. Check images aren't lazy-loaded placeholders
4. Max 10 images enforced by `slice(0, 10)`

**Fix:** Update image selector, filter out placeholders

---

## Summary

**Browser Extension:**
- Chrome Manifest V3, 12 site scrapers
- 1,487 lines of JavaScript
- Pattern: Detect → Inject → Extract → Send

**Adding Sites:**
1. Update `manifest.json` (host_permissions + matches)
2. Add to `detectSite()`
3. Create `initSiteName()` + `extractSiteNameData()`
4. Add to router
5. Test, handle edge cases

**Key Utilities:**
- `trySelect()` — Multi-selector fallback
- `parsePrice()` — Handle EU/US formats
- `sqftToM2()` — Convert area units
- `extractJsonLd()` — Structured data fallback

**Testing:**
- Manual checklist per site
- Edge cases (high prices, POA, shared ownership)
- Verify dedup logic in DealIngestionServer

**Critical:** Always test on live pages before releasing. Sites change HTML frequently.

**Next:** See [`MULTI_WINDOW_SYSTEM.md`](MULTI_WINDOW_SYSTEM.md) for cross-window state sync.
