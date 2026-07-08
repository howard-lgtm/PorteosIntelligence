# Porteos Intelligence — Global Intelligence Profile (Figma Brief)

**Created:** 8 July 2026  
**Status:** Design exploration — pre-engineering  
**Punchlist:** `P10` in `PorteosIntelligence/Documentation/PACKAGE_v1_PUNCHLIST.md`  
**Audience:** Figma designer, Figma AI / Make, external design partner

---

## Copy everything below the line into Figma

---

## PROMPT START

You are designing **Profile 6 — Global Intelligence** for **Porteos Intelligence**, a native **macOS** property-deal intelligence app (SwiftUI). This is a **new center-pane profile** added alongside the existing five profiles. Preserve the institutional **terminal aesthetic** — do not soften into a consumer map or news app.

### What already exists (do not redesign)

| Profile | Role | Accent |
|---------|------|--------|
| **Command Center** (⌘0) | Portfolio CRM — pipeline, scores, recent activity | `#94A3B8` neutral |
| Real Estate (⌘1) | Deal financials dashboard | `#C25E30` rust |
| Hospitality (⌘2) | Hotel ops dashboard | `#14B8A6` teal |
| Design (⌘3) | Spatial / wellness dashboard | `#A855F7` purple |
| Circular Economy (⌘4) | Material flow / carbon dashboard | `#3B82F6` blue |

**Global Intelligence is NOT Command Center.** Command Center answers *“How is my portfolio doing?”* Global Intelligence answers *“Where are my assets, what markets am I in, and what external signals matter there?”*

### Product vision — Global Intelligence

A **geo-anchored intelligence layer** for the deal portfolio:

1. **Map** — MapKit-style geographic view showing every deal as a pin at its **real-world location** (geocoded from address + city). Not live GPS tracking; static portfolio geography updated when deals are saved.
2. **Market focus** — User can zoom to a country, region, or city (e.g. Portugal, Lisbon, Algarve) and see aggregated portfolio exposure.
3. **News intelligence** — Curated **market-driven headlines** relevant to the selected geography or selected pin. Realistic cadence: **daily refresh**, not live tickers. Show items from the **last 30–60 days**.
4. **Pin → context** — Selecting a map pin immediately populates a side panel or lower module with: deal summary, Porteos Score, status, and **news filtered to that asset’s city/market** (30–60 day window).
5. **AI layer (exploratory)** — Propose how an **intelligence agent** fits the terminal UI. Not a chat bubble app. Think: CLI briefing, signal digest, or `// INTEL_AGENT` module. See §AI concepts below.

### Platform & shell (unchanged)

- **macOS desktop** — default window **1200×800**
- **3-pane shell:** Navigation 260px · Center (this profile) · Inspector 280px · bottom command bar 32px
- **Font:** JetBrains Mono only
- **Corners:** 0px on all internal elements
- **Tokens:** `Design-system/Figma/porteos.tokens.json` v2.06

**New profile accent (proposed):** `#06B6D4` cyan — geographic / signal identity. Use only for headers, active map chrome, and profile indicators — never per-metric coloring.

**CLI identity:**
- Nav label: `GLOBAL_INTELLIGENCE`
- Header host: `porteos@geo ~ %`
- Command line: `intel --map --market=PT`
- Module prefix style: `01 // GEO_PORTFOLIO_MAP`, `02 // MARKET_NEWS_FEED`, etc.

---

## Screens to design (minimum 6 frames @ 1200×800)

### Frame 1 — `dashboard-global-intelligence` (default)

Center pane with **split layout** (design both options, pick one as primary):

**Option A — Map-primary (recommended)**  
- Top 60%: stylized map canvas (terminal-dark basemap treatment — not Apple Maps default colors)  
- Bottom 40%: `02 // MARKET_NEWS_FEED` — scrollable headline list  
- Left nav + inspector unchanged

**Option B — Map + right intel column**  
- Left 65%: map  
- Right 35%: stacked modules — selected market summary + news feed

Include **5–8 sample pins** across Portugal and Spain with realistic deal names from our fixtures:
- Lisbon Office Block A (Lisbon)
- Casa Hibiscos (Luz, Algarve)
- Porto Boutique Hotel (Porto)
- Berlin Office Block (Berlin) — shows multi-country portfolio

### Frame 2 — Pin selected

Same layout with **one pin active** (rust/cyan ring). Inspector or inline panel shows:

```
// ASSET_CONTEXT
LISBON OFFICE BLOCK A
Lisbon, Portugal · Commercial · REVIEW
Score 71 / 100 · Grade B
€1,250,000 · 425 m²
```

News feed below filters to **Lisbon / Portugal commercial real estate** (30–60 days).

### Frame 3 — Market focus (no pin)

User typed or selected **Portugal** in a market filter bar:

```
porteos@geo ~ % intel --market="Portugal" --window=60d
```

Map zoomed to Portugal. News feed shows national headlines (CBRE, interest rates, tourism, zoning). Show deal count chip: `4 ASSETS IN MARKET`.

### Frame 4 — Empty / sparse geo

Portfolio has deals but **no geocode yet** — show terminal empty state on map:

```
// GEOCODE_PENDING
3 deals lack coordinates — run ./geocode --all
[ GEOCODE NOW ]
```

Do not show a blank white map.

### Frame 5 — News article expanded (accordion row)

Headline row collapsed:

```
2026-06-12 · Jornal Económico · YIELD
Lisbon prime office yields compress 15 bps in Q2    [ + ]
```

Expanded:

```
Full summary text wraps across multiple lines in JetBrains Mono rowValue style.
Source link as terminal command: open https://… 
Tags: [ LISBON ] [ OFFICE ] [ YIELDS ]
[ − ]
```

### Frame 6 — AI intelligence module (3 variants — explore all)

Design **three** treatments on separate sub-frames; engineering will pick one:

| Variant | Label | Description |
|---------|-------|-------------|
| **A — Briefing block** | `03 // DAILY_INTEL_BRIEF` | 3–5 bullet signals generated overnight. No chat. `[ REGENERATE ]` button. |
| **B — Agent console** | `03 // INTEL_AGENT` | Mini terminal log: `> scanning PT market…` `> 4 headlines matched` `> risk: REG. PRESSURE ↑`. Optional single prompt line at bottom. |
| **C — Signal cards** | `03 // MARKET_SIGNALS` | Reuse metric grid anatomy — 4 cells: `REG. PRESSURE`, `RATE OUTLOOK`, `TOURISM INDEX`, `SUPPLY PIPELINE`. |

**AI guardrails for design:**
- No rounded chat bubbles, no avatar, no “Ask me anything” consumer UX
- Feels like **intelligence briefing**, not ChatGPT
- Privacy note line: `// LOCAL LLM · NO DATA LEAVES DEVICE` (optional footer meta)

---

## Map visual treatment (critical)

Apple MapKit will render underneath in engineering — Figma designs the **chrome overlay**, not a photorealistic map export.

**Do:**
- Dark desaturated basemap mock (near `#0A0A0A` land, `#1A1D24` water, `#333` borders)
- Pins as **terminal glyphs** — small square or crosshair, 1px border, profile-accent fill on selected
- Cluster badge: `[ 3 ]` square chip when pins overlap
- Zoom controls as `[ + ]` `[ − ]` `[ FIT ALL ]` text buttons — not iOS circular buttons
- Optional grid overlay at low opacity (engineering flourish)

**Don’t:**
- Default Apple Maps colors
- Rounded pin teardrops
- Drop shadows on pins
- Color per deal type on the map (use status: pipeline=dim, review=amber, viable=green — semantic only)

**Pin legend module** (small, bottom-left of map):

```
// PIN_STATUS
■ PIPELINE  ■ REVIEW  ■ VIABLE  ■ ACQUIRED
```

---

## News feed module spec

**Module header:** `02 // MARKET_NEWS_FEED` or `MKT // INTEL_HEADLINES`

**Filter bar** (meta-bold labels):

| Control | Type | Example |
|---------|------|---------|
| Market | combobox | Portugal · Lisbon · Luz · All |
| Window | segmented | 30d · 60d |
| Topic | multi-tag | REAL ESTATE · HOSPITALITY · REGULATION · RATES |

**Row anatomy:**

```
[DATE] · [SOURCE] · [TOPIC_TAG]
Headline in rowValue — wraps 2 lines collapsed, full on expand
[ + ]
```

**Sample headlines** (use in mock):

1. `2026-06-28 · Idealista / CBRE · YIELDS` — Lisbon prime office yields hold at 5.5% amid supply pause  
2. `2026-06-15 · Reuters · RATES` — ECB holds rates; Portuguese mortgage spreads narrow  
3. `2026-06-02 · Jornal de Negócios · TOURISM` — Algarve hospitality occupancy up 4% YoY entering peak season  
4. `2026-05-20 · EC · REGULATION` — EU embodied carbon reporting rules enter enforcement phase  

**Footer meta:** `Last refresh: 2026-07-08 06:00 UTC · 12 articles · ./refresh --news`

---

## Navigation integration

Add to left nav **below Circular Economy**:

```
GLOBAL_INTELLIGENCE    ⌘5
```

When active, center pane = this profile. Inspector can show:
- Selected deal quick stats (if pin selected)
- Or market summary (if market focus)
- Or `// SELECT_PIN_OR_MARKET` idle prompt

**Top header bar** center slot:

```
porteos@geo ~ % intel --map --market=PT
```

---

## Relationship to existing components (reuse)

| Component | Reuse |
|-----------|-------|
| `DashboardCLIHeader` | Yes — new profile variant |
| `TerminalBlock` | Yes — `01 //`, `02 //` modules |
| `TerminalMetricGrid` / `TerminalMetricCell` | Yes — market summary KPIs |
| `ValidationLogModule` | Optional — geocode warnings |
| `MarketTrendGrid` | Adapt — `MKT // GLOBAL_SIGNALS` |
| Glossary accordion pattern | Yes — news row expand |
| `AIVibePanel` | Reference only — different job, same terminal tone |

**New components to spec in Figma:**

- `TerminalMapCanvas` — map container with overlay chrome  
- `GeoPin` — deal pin + selected state  
- `MarketFilterBar` — grep-style filter row  
- `NewsFeedRow` — accordion headline row  
- `GeoAssetContextCard` — pin selection summary  
- `IntelBriefBlock` — AI variant A/B/C  

Add to `porteos.components.json` when finalized.

---

## Data assumptions (for realistic mocks)

Engineering will add later — design as if present:

| Field | Source |
|-------|--------|
| `latitude`, `longitude` | Geocoded from `address` + `locationCity` |
| `geocodeStatus` | `ok` · `pending` · `failed` |
| `marketTags` | Derived from city/country benchmarks |
| News articles | Cached feed keyed by `marketId` + date window |
| `newsRefreshedAt` | Timestamp of last daily pull |

Deals without coordinates still appear in **deal list** but not on map until geocoded.

---

## Deliverables checklist

| # | Deliverable | Priority |
|---|-------------|----------|
| 1 | 6 frames @ 1200×800 (states above) | P0 |
| 2 | Map overlay + pin component (variants: default, selected, cluster) | P0 |
| 3 | News feed module with 4+ realistic rows + expand state | P0 |
| 4 | Market filter bar + 30d/60d window toggle | P0 |
| 5 | 3 AI module variants (briefing / agent console / signal cards) | P1 |
| 6 | Nav + header integration frame (show profile in full shell) | P1 |
| 7 | Empty / geocode-pending state | P1 |
| 8 | Component page entries + token notes for cyan accent | P2 |
| 9 | `GLOBAL_INTELLIGENCE_HANDOFF.md` — frame list, copy deck, interaction notes | P2 |

**Export:** PNG reference frames + Figma link. Name frames:

```
dashboard-global-intelligence-default
dashboard-global-intelligence-pin-selected
dashboard-global-intelligence-market-PT
dashboard-global-intelligence-geocode-empty
dashboard-global-intelligence-news-expanded
dashboard-global-intelligence-ai-variants
```

---

## Anti-patterns (reject in review)

- Consumer travel map (pins with photos, cards with hero images)
- Bloomberg-style neon ticker tape
- Chat-first AI (speech bubbles, floating assistant orb)
- White map background
- Per-deal random pin colors
- Live “breaking news” red banners — this is **daily intelligence**, not CNN

---

## PROMPT END

---

## Internal notes (engineering — not for Figma)

- **ProfileType** will gain `.globalIntelligence` with accent `#06B6D4`
- **MapKit** `Map` + `Annotation` in SwiftUI; geocoding via `CLGeocoder` on save
- **News** — v1 likely RSS/API cache per `MarketBenchmarks` city; no scraping
- **AI** — extend `AIAnalysisService` with market context prompt; local LLM optional
- **Cmd Center** stays portfolio CRM; no merge with Global Intelligence
- Punchlist epic: **P10**
