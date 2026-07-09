# Porteos Intelligence — Global Intelligence Profile
## Cursor Engineering Handoff

Created: 2026-07-08
Figma file: https://www.figma.com/design/7XdLK0I2aWj7KVkvhnJEyE
Figma page: 03 — Dashboards (scroll right past existing 5 profiles)
Status: Design complete → engineering handoff
Epic: P10 — Global Intelligence

---

## What this profile does

Profile 6 (Cmd+5). Answers "Where are my assets, what markets am I in,
and what external signals matter there?" — distinct from Command Center.

Three pillars:
1. Geographic map — every deal plotted by geocoded coordinates
2. Market news — daily-refreshed headlines scoped to selected location
3. AI briefing — local LLM digest of signals relevant to the portfolio

Refresh cadence: daily. NOT a live data app.

---

## Figma frames (PNGs already in this directory)

| Frame | Node ID | State |
|---|---|---|
| dashboard-global-intelligence-default | 313:458 | Map + news feed, idle |
| dashboard-global-intelligence-pin-selected | 313:632 | Pin active, asset context |
| dashboard-global-intelligence-market-PT | 313:815 | Market filter: Portugal |
| dashboard-global-intelligence-geocode-empty | 313:1000 | No geocodes yet |
| dashboard-global-intelligence-news-expanded | 313:1174 | Accordion row open |
| dashboard-global-intelligence-ai-variants | 313:1334 | 3 AI modules side-by-side |

---

## Shell layout (unchanged from existing 5 profiles)

    +--------------------------------------------------------------+ h:40
    | PORTEOS_TERMINAL    porteos@geo ~ % intel --map --market=PT  |
    +--------------+---------------------------+-------------------+ h:728
    |  NAV  260px  |   CENTER PANE  658px     |  INSPECTOR 280px  |
    |              |  01 // GEO_PORTFOLIO_MAP  |                   |
    |              |  top 60% (437px)          |                   |
    |              |  02 // MARKET_NEWS_FEED   |                   |
    |              |  bottom 40% (291px)       |                   |
    +--------------+---------------------------+-------------------+ h:32
    | $ porteos@geo ~                              UTY: 1/3        |
    +--------------------------------------------------------------+
    Total: 1200 x 800

---

## New ProfileType entry

    case globalIntelligence

    var accent: Color {
        case .globalIntelligence: return Color(hex: "#06B6D4") // cyan
    }
    var shortcut: KeyEquivalent {
        case .globalIntelligence: return "5" // Cmd+5
    }
    var navLabel: String {
        case .globalIntelligence: return "GLOBAL_INTELLIGENCE"
    }
    var headerCommand: String {
        case .globalIntelligence: return "intel --map --market=PT"
    }

---

## Architecture

### 1. Map — Apple MapKit (zero cost, native, recommended)

No external SDK. No API key. No per-call costs.
CLGeocoder converts address+city to lat/lng on deal save.
Use .colorScheme(.dark) — Figma frames show chrome overlay design,
not a pixel-perfect map render. MapKit dark tiles are the base.

Pin colors by deal status:
  .pipeline → #444444 (dim)
  .review   → #D97706 (amber)
  .viable   → #16A34A (green)
  .acquired → #06B6D4 (cyan)

Selected pin: 8x8 filled square + 2px #06B6D4 outer ring (12x12)
All pins: 0px corner radius (square glyphs, no teardrops)

Zoom controls: [ + ] [ - ] [ FIT ALL ] text buttons, bottom-right of map
Pin legend: // PIN_STATUS  square PIPELINE  square REVIEW  square VIABLE  square ACQUIRED

Geocoding on deal save:
  CLGeocoder.geocodeAddressString(address + ", " + locationCity)
  Store: latitude, longitude, geocodeStatus (.ok/.pending/.failed), geocodedAt

### 2. News — RSS aggregation by market (zero cost)

MarketFeedRegistry: dictionary keyed by marketId ("PT", "PT-LIS", "DE-BER")
pointing to curated RSS feed URLs. Fetch daily, cache locally (JSON on disk).
No portfolio data sent externally.

Starter feeds:
  "PT"     → jornaldenegocios.pt/rss, add CBRE PT RSS
  "PT-LIS" → Lisbon-specific real estate feeds
  "PT-ALG" → Algarve feeds
  "DE-BER" → tagesspiegel.de/wirtschaft/rss

Market scoping:
  Pin selected → filter by deal.cityCode + deal.countryCode, 60d window
  Market focus → filter by countryCode, 60d window
  No pin/market → all feeds sorted by date

Topic tag extraction: keyword match on title (no ML needed)
  YIELDS: yield, cap rate, bps, rendimento
  RATES: rate, ECB, mortgage, spread, taxa
  TOURISM: tourism, occupancy, hospitality, turismo
  REGULATION: regulation, carbon, EU, compliance

v2 extension: Reddit RSS (free, no auth), Eurostat RSS, ECB press releases
All slot into MarketFeedRegistry as additional URL entries.

### 3. AI briefing — Ollama local LLM (no data leaves device)

Design shows: // LOCAL LLM · NO DATA LEAVES DEVICE
Ollama runs on Apple Silicon. Recommended model: llama3.2:3b or phi4-mini.

v1 scope (no open-ended chat):
  Input: cached news for active market + deal summaries in scope
  Output: 5 bullet SIGNAL items in format "> SIGNAL N  [observation]"
  Trigger: profile open if briefing stale >8h, or [ REGENERATE ] tap

Ollama endpoint: http://localhost:11434/api/generate
Method: POST, model: "llama3.2:3b", stream: false

Fallback when Ollama offline:
  // AGENT_OFFLINE — local model not running
  // Start Ollama: open Terminal → ollama serve
  [ RETRY ]   [ DISMISS ]

AI variant recommendation:
  Variant A (Briefing block): SHIP IN V1 — simplest, no streaming needed
  Variant B (Agent console): v2 — streaming + single prompt input
  Variant C (Signal cards): v2 — parse bullet output into 4 structured cards

---

## Data model additions (add to Deal)

  var latitude:      Double?
  var longitude:     Double?
  var geocodeStatus: GeocodeStatus  // .ok | .pending | .failed
  var geocodedAt:    Date?
  var countryCode:   String         // "PT", "DE", "ES"
  var cityCode:      String         // "LIS", "BER", "MAD"
  var marketId:      String         // computed: countryCode + "-" + cityCode

New: NewsArticle (id, title, summary, source, url, publishedAt, marketIds, topicTags)
New: NewsCache (articles dict keyed by marketId, refreshedAt timestamp)

---

## Interaction spec

Frame 1 Default:
  All geocoded deals → pins on map. Non-geocoded → deal list only.
  News: all markets. Inspector: // SELECT_PIN_OR_MARKET idle.

Frame 2 Pin selected:
  Tap pin → GeoAssetContextCard (between map and news)
  Inspector → deal stats (status, score, price, area, geocode)
  News → filtered to deal.marketId, 60d
  [ OPEN IN REAL ESTATE ] → navigate to RE profile with deal active

Frame 3 Market focus:
  Market filter input → map animates to country region
  N ASSETS IN MARKET chip = deals filtered by countryCode
  Inspector → // MARKET_CONTEXT aggregate KPIs

Frame 4 Geocode empty:
  Trigger: pending geocode count > 0
  Map → // GEOCODE_PENDING overlay (amber left border)
  [ GEOCODE NOW ] → geocodeDeal() for all pending, inline progress
  News still loads normally (not blocked)

Frame 5 News expanded:
  [ + ] expands row, collapses any other open row (one at a time)
  Expanded: full summary + source URL + topic tag pills
  [ - ] collapses

Frame 6 AI variants:
  All three designs on screen — engineering picks one before implementing

---

## New Swift files to create

  Views/GlobalIntelligence/
    GlobalIntelligenceDashboard.swift
    GeoPortfolioMapView.swift
    GeoPin.swift
    PinLegend.swift
    ZoomControls.swift
    MarketFilterBar.swift
    MarketNewsFeedModule.swift
    NewsFeedRow.swift
    GeoAssetContextCard.swift
    MarketContextInspector.swift
    GeoAssetInspector.swift

  Services/
    GeocodingService.swift
    NewsAggregatorService.swift
    MarketFeedRegistry.swift
    RSSParser.swift
    IntelAgentService.swift

---

## Implementation order for Cursor

1. ProfileType — add .globalIntelligence (accent #06B6D4 + Cmd+5 + nav label)
2. GlobalIntelligenceDashboard — split layout shell (map top 60%, news bottom 40%)
3. GeoPortfolioMapView — MapKit + GeoPin + PinLegend + ZoomControls
4. GeocodingService — run on deal save, persist lat/lng + geocodeStatus
5. NewsAggregatorService — RSS fetch PT + DE starter feeds, daily JSON cache
6. MarketNewsFeedModule — rows + filter bar + accordion expand
7. IntelAgentService — Ollama integration, briefing prompt, Variant A UI

---

Figma file: 7XdLK0I2aWj7KVkvhnJEyE
Page: 03 — Dashboards
Design: Porteos Intelligence — 2026-07-08
