# Porteos Intelligence — Data Model Guide

Complete guide to the SwiftData schema, relationships, migration strategy, and safe modification practices.

---

## Table of Contents

1. [Schema Overview](#schema-overview)
2. [Core Model: PropertyDeal](#core-model-propertydeal)
3. [Related Models](#related-models)
4. [Relationships](#relationships)
5. [Migration Strategy](#migration-strategy)
6. [Adding Fields Safely](#adding-fields-safely)
7. [Calculated vs Persisted Fields](#calculated-vs-persisted-fields)
8. [Common Patterns](#common-patterns)
9. [Database Location & Backup](#database-location--backup)
10. [Troubleshooting](#troubleshooting)

---

## Schema Overview

**Version:** Build 3 (Sept 2026)  
**Persistence:** SwiftData (Core Data successor)  
**Location:** `~/Library/Containers/net.htdstudio.PorteosIntelligence/Data/Library/Application Support/default.store`

### Models (6 Total)

| Model | Purpose | File | Lines | Relationships |
|-------|---------|------|-------|---------------|
| **`PropertyDeal`** | Core deal entity | `PropertyDeal.swift` | 474 | → `DealImage[]`, `DealScenario[]`, `ResearchMessage[]` |
| **`DealImage`** | Property photos | `DealImage.swift` | ~50 | ← `PropertyDeal` |
| **`DealScenario`** | Alternative financing | `DealScenario.swift` | ~80 | ← `PropertyDeal` |
| **`ResearchMessage`** | AI chat history | `ResearchMessage.swift` | ~60 | ← `PropertyDeal` |
| **`EmailImportRecord`** | Dedup tracking | `EmailImportRecord.swift` | ~40 | (standalone) |
| **`MarketTrend`** | Historical snapshots | `MarketTrend.swift` | ~70 | (standalone) |

### Schema Registration

**Location:** `PorteosIntelligenceApp.swift:12-19`

```swift
let schema = Schema([
    PropertyDeal.self,
    DealScenario.self,
    EmailImportRecord.self,
    MarketTrend.self,
    DealImage.self,
    ResearchMessage.self,
])
```

**Critical:** All models MUST be registered here.

---

## Core Model: PropertyDeal

**File:** `PorteosIntelligence/Models/PropertyDeal.swift`  
**Lines:** 474  
**Properties:** 80+

### Structure

```swift
@Model
final class PropertyDeal {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var updatedAt: Date
    
    // BASE fields (16)
    var propertyName: String
    var address: String
    var propertyType: String
    var totalArea: Double        // m² or ft²
    var landArea: Double
    var locationCity: String
    var locationCountry: String
    // ... more base fields
    
    // REAL ESTATE financials (20)
    var purchasePrice: Double
    var closingCosts: Double
    var renovationBudget: Double
    var grossPotentialIncome: Double
    var vacancyRate: Double
    var operatingExpenses: Double
    // ... more RE fields
    
    // HOSPITALITY metrics (15)
    var roomCount: Int
    var averageDailyRate: Double
    var occupancyRate: Double
    // ... more hospitality fields
    
    // DESIGN metrics (8)
    var totalFloorArea: Double
    var usableFloorArea: Double
    var biophilicScore: Double
    // ... more design fields
    
    // CIRCULAR ECONOMY (10)
    var carbonEmbodied: Double
    var carbonOperational: Double
    var recyclableContentPercent: Double
    // ... more circular fields
    
    // REGULATORY advisory (7)
    var zoningClass: String
    var floorAreaRatio: Double
    var maxBuildingHeight: Double
    var planningStatus: String
    var heritageOrListed: Bool
    var strLicenceStatus: String
    // ... more regulatory fields
    
    // GEOCODING (4)
    var latitude: Double?
    var longitude: Double?
    var geocodeStatusRaw: String
    var marketId: String
    
    // RELATIONSHIPS
    @Relationship(deleteRule: .cascade) var images: [DealImage] = []
    @Relationship(deleteRule: .cascade) var scenarios: [DealScenario] = []
    @Relationship(deleteRule: .cascade) var researchMessages: [ResearchMessage] = []
    
    // METADATA
    var notes: String = ""
    var sourceURL: String = ""
    var porteosScore: Double?  // Cached score, regenerated on load
    
    // EXTERNAL STORAGE for large data
    @Attribute(.externalStorage) var comparablesData: Data?
}
```

### Field Categories

| Category | Count | Purpose |
|----------|-------|---------|
| **Base** | 16 | Property identification, location, type |
| **Real Estate** | 20 | Purchase, financing, income, expenses |
| **Hospitality** | 15 | Rooms, ADR, occupancy, F&B revenue |
| **Design** | 8 | Space efficiency, biophilic elements |
| **Circular Economy** | 10 | Carbon, materials, resource efficiency |
| **Regulatory** | 7 | Zoning, planning, heritage flags |
| **Geocoding** | 4 | Lat/lon, geocode status, market ID |
| **Metadata** | 5 | Notes, source, score cache |

**Total: 85 properties** (excluding relationships and computed properties)

### Computed Properties

**Never persisted to database:**

```swift
var currencySymbol: String {
    // Inferred from locationCountry
    // Returns: €, $, £, kr, etc.
}

var geocodeStatus: GeocodeStatus {
    // Parsed from geocodeStatusRaw string
}
```

**Why computed?**
- Eliminates data drift
- Always reflects current data
- Reduces schema complexity

---

## Related Models

### DealImage

**File:** `DealImage.swift`  
**Purpose:** Property photos and media

```swift
@Model
final class DealImage {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    
    @Attribute(.externalStorage) var imageData: Data?
    var caption: String = ""
    var sortOrder: Int = 0
    
    var deal: PropertyDeal?  // Inverse relationship
}
```

**Key Points:**
- `@Attribute(.externalStorage)` → Stored outside main SQLite file (for large images)
- `sortOrder` → User can reorder gallery
- Cascade delete: Delete deal → deletes all images

### DealScenario

**File:** `DealScenario.swift`  
**Purpose:** Alternative financing scenarios ("What if interest rate is 5%?")

```swift
@Model
final class DealScenario {
    @Attribute(.unique) var id: UUID
    var name: String
    
    var loanAmount: Double
    var interestRate: Double
    var loanTermYears: Int
    
    var deal: PropertyDeal?
}
```

**Use Case:**
- User creates base deal with 4% interest
- Adds scenario: "High Rate" with 6% interest
- Compares DSCR, cash-on-cash across scenarios

### ResearchMessage

**File:** `ResearchMessage.swift`  
**Purpose:** AI chat history for RESEARCH tab

```swift
@Model
final class ResearchMessage {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    
    var role: String  // "user" or "assistant"
    var content: String
    
    var deal: PropertyDeal?
}
```

**Key Points:**
- Persists full conversation
- User can export chat via COPY button
- Delete deal → deletes chat history

### EmailImportRecord

**File:** `EmailImportRecord.swift`  
**Purpose:** Deduplication tracking for email imports

```swift
@Model
final class EmailImportRecord {
    @Attribute(.unique) var emailUID: String
    var importedAt: Date
    var sourceEmail: String
}
```

**Why separate model?**
- Standalone dedup logic (not tied to PropertyDeal)
- Prevents re-importing same email

### MarketTrend

**File:** `MarketTrend.swift`  
**Purpose:** Historical score snapshots over time

```swift
@Model
final class MarketTrend {
    @Attribute(.unique) var id: UUID
    var recordedAt: Date
    
    var dealID: UUID
    var porteosScore: Double
    var capRate: Double
    var occupancyRate: Double
    // ... other metrics
}
```

**Use Case:**
- Daily snapshots of deal metrics
- Render sparklines showing score changes
- Not currently fully implemented (future feature)

---

## Relationships

### Relationship Types

| From | To | Type | Delete Rule |
|------|-----|------|-------------|
| `PropertyDeal` | `DealImage` | One-to-many | `.cascade` |
| `PropertyDeal` | `DealScenario` | One-to-many | `.cascade` |
| `PropertyDeal` | `ResearchMessage` | One-to-many | `.cascade` |

**Cascade Delete:** Delete parent → automatically deletes children.

### Example: Adding a Relationship

```swift
// In PropertyDeal.swift
@Relationship(deleteRule: .cascade) var customItems: [CustomItem] = []

// In CustomItem.swift
@Model
final class CustomItem {
    @Attribute(.unique) var id: UUID
    var name: String
    
    var deal: PropertyDeal?  // Inverse
}
```

**Critical:**
1. Add to parent: `@Relationship(deleteRule: .cascade)`
2. Add inverse to child: `var deal: PropertyDeal?`
3. Register in `Schema([..., CustomItem.self])`
4. **Rebuild app** — schema change requires migration

---

## Migration Strategy

### Current Strategy: Backup + Reset

**Location:** `PorteosIntelligenceApp.swift:26-87`

**How it works:**

1. App tries to initialize `ModelContainer`
2. **If schema matches:** Success, app starts
3. **If schema mismatch:**
   - Backs up `.store`, `.store-shm`, `.store-wal` to `~/Documents/PorteosBackups/deals-TIMESTAMP.store`
   - Shows alert to user
   - Deletes old database
   - Creates fresh empty database
   - App starts with empty state

**Pros:**
- ✅ Never leaves app in broken state
- ✅ User can recover from backup (with help)

**Cons:**
- ⚠️ **Data loss** (all deals deleted)
- ⚠️ Requires manual restore

### Future: Lightweight Migrations

**Goal:** Add fields without data loss.

**Requires:**
1. Version `@Model` with schema versions
2. Define migration plans
3. SwiftData automatic lightweight migration (works for simple changes)

**Not yet implemented** — planned for future release.

---

## Adding Fields Safely

### Safe Changes (Lightweight Migration)

✅ **Adding optional fields:**
```swift
var newField: String = ""           // ✅ OK (has default)
var newOptionalField: String?       // ✅ OK (optional)
var newDoubleField: Double = 0.0    // ✅ OK (has default)
```

✅ **Adding relationships with empty default:**
```swift
@Relationship(deleteRule: .cascade) var newItems: [NewItem] = []  // ✅ OK
```

❌ **Dangerous Changes:**
```swift
var existingField: String = ""
// REMOVE THIS FIELD ❌ → Data loss!

var existingOptional: String?
// CHANGE TO: var existingOptional: String = "" ❌ → Migration may fail!
```

### Step-by-Step: Adding a Field

**Example:** Add `propertyTaxAnnual: Double` to `PropertyDeal`

**1. Edit Model:**
```swift
// PropertyDeal.swift — Real Estate section
var operatingExpenses: Double
var propertyTaxAnnual: Double = 0.0  // ← NEW FIELD (default value required)
```

**2. Update Calculators** (if field affects metrics):
```swift
// RealEstateCalculator.swift
static func netOperatingIncome(
    gpi: Double,
    opex: Double,
    propertyTax: Double  // ← NEW PARAMETER
) -> Double {
    return gpi - opex - propertyTax
}
```

**3. Update ViewModels:**
```swift
// PropertyDealViewModel.swift
var noi: Double {
    RealEstateCalculator.netOperatingIncome(
        gpi: deal.grossPotentialIncome,
        opex: deal.operatingExpenses,
        propertyTax: deal.propertyTaxAnnual  // ← USE NEW FIELD
    )
}
```

**4. Update Views** (if user needs to input this field):
```swift
// FullDealEditSheet.swift — REAL ESTATE tab
TextField("Property Tax (Annual)", value: $deal.propertyTaxAnnual, format: .number)
    .textFieldStyle(TerminalTextFieldStyle())
```

**5. Test Migration:**
```
1. Build and run
2. If schema mismatch alert appears:
   → Click Continue
   → Database reset (expected)
3. Create test deal, fill new field
4. Verify calculators use new value
```

**6. Document Change:**
- Update [`DATA_MODEL_GUIDE.md`](DATA_MODEL_GUIDE.md) (this file)
- Update [`ARCHITECTURE.md`](ARCHITECTURE.md) if significant
- Add to commit message: "Add propertyTaxAnnual field to PropertyDeal"

---

## Calculated vs Persisted Fields

### Persisted (Stored in DB)

✅ **User inputs:**
- `purchasePrice`, `operatingExpenses`, `roomCount`, etc.

✅ **Metadata:**
- `createdAt`, `updatedAt`, `sourceURL`, etc.

✅ **Cached performance:**
- `porteosScore` (recalculated on load, but cached for list sorting)

❌ **Never persist:**
- Cap rate, NOI, DSCR, cash-on-cash return
- Porteos score components (stored as single `porteosScore` only)
- Any derived metric

### Computed (Calculated in ViewModel)

```swift
// PropertyDealViewModel.swift

var capRate: Double {
    RealEstateCalculator.capRate(
        noi: deal.grossPotentialIncome - deal.operatingExpenses,
        purchasePrice: deal.purchasePrice
    )
}

var dscr: Double {
    RealEstateCalculator.dscr(
        noi: capRate * deal.purchasePrice / 100,
        debtService: deal.debtService
    )
}
```

**Why not persist calculated fields?**
1. **Data drift:** If formula changes, persisted values become stale
2. **Storage:** Wastes disk space
3. **Complexity:** Must remember to update calculated fields on every input change
4. **Single source of truth:** Raw data is truth, calculations are views

**Exception:** `porteosScore` is cached for performance (list sorting), but recalculated on app launch.

---

## Common Patterns

### Pattern 1: Optional with Default in UI

```swift
// Model
var vacancyRate: Double = 0.0  // Default 0

// ViewModel (presents as optional for UX)
var vacancyRateDisplay: String {
    deal.vacancyRate > 0 ? "\(deal.vacancyRate)%" : "—"
}
```

### Pattern 2: String Enum Storage

```swift
// Model
var dealStatusRaw: String = "pipeline"

// Computed property
var dealStatus: DealStatus {
    get { DealStatus(rawValue: dealStatusRaw) ?? .pipeline }
    set { dealStatusRaw = newValue.rawValue }
}

// Enum
enum DealStatus: String, Codable, CaseIterable {
    case pipeline, viable, review, rejected, acquired
}
```

**Why not store enum directly?**
- SwiftData requires raw representable types
- String storage is safer for migrations

### Pattern 3: External Storage for Large Data

```swift
@Attribute(.externalStorage) var imageData: Data?
@Attribute(.externalStorage) var comparablesData: Data?
```

**Use when:**
- Field can exceed 100KB (images, JSON blobs)
- Keeps main SQLite file small and fast

---

## Database Location & Backup

### Location

**Production DB:**
```
~/Library/Containers/net.htdstudio.PorteosIntelligence/Data/Library/Application Support/default.store
```

**Backup Folder (auto-created on migration failure):**
```
~/Documents/PorteosBackups/deals-TIMESTAMP.store
```

### Manual Backup

```bash
# Quit Porteos Intelligence first

# Copy database
cp -R ~/Library/Containers/net.htdstudio.PorteosIntelligence/Data/Library/Application\ Support/default.store \
     ~/Desktop/porteos-backup-$(date +%Y%m%d).store

# Copy WAL and SHM files too (important!)
cp ~/Library/Containers/net.htdstudio.PorteosIntelligence/Data/Library/Application\ Support/default.store-shm \
   ~/Desktop/porteos-backup-$(date +%Y%m%d).store-shm
cp ~/Library/Containers/net.htdstudio.PorteosIntelligence/Data/Library/Application\ Support/default.store-wal \
   ~/Desktop/porteos-backup-$(date +%Y%m%d).store-wal
```

### Manual Restore

```bash
# Quit Porteos Intelligence

# Delete current database
rm ~/Library/Containers/net.htdstudio.PorteosIntelligence/Data/Library/Application\ Support/default.store*

# Copy backup
cp ~/Desktop/porteos-backup-TIMESTAMP.store* \
   ~/Library/Containers/net.htdstudio.PorteosIntelligence/Data/Library/Application\ Support/

# Rename
mv ~/Library/Containers/net.htdstudio.PorteosIntelligence/Data/Library/Application\ Support/porteos-backup-TIMESTAMP.store \
   ~/Library/Containers/net.htdstudio.PorteosIntelligence/Data/Library/Application\ Support/default.store

# Relaunch app
```

---

## Troubleshooting

### "Schema mismatch" on Launch

**Cause:** Model changed, SwiftData can't migrate automatically.

**Solution:**
1. Alert appears: "Data Store Reset" → Click Continue
2. Database backed up to `~/Documents/PorteosBackups/`
3. App creates fresh database
4. Import deals manually or restore from backup

**Prevention:** Test schema changes on a copy of the database first.

### "Deal not saving"

**Symptoms:** Edit deal, click Save, changes don't persist.

**Debug:**
```swift
// Add to save handler
do {
    try context.save()
    print("✅ Saved successfully")
} catch {
    print("❌ Save failed: \(error)")
}
```

**Common causes:**
- `@Model` class not registered in `Schema([...])`
- Required field left nil (should have default value)
- Relationship misconfigured (missing inverse)

### "Duplicate deals appearing"

**Cause:** `@Attribute(.unique)` not working (SwiftData bug) or dedup logic broken.

**Fix:**
1. Verify `@Attribute(.unique) var id: UUID` on `PropertyDeal`
2. Check browser extension dedup logic in `DealIngestionServer.swift`
3. Check email dedup logic in `EmailMonitorService.swift`

### "Database file is huge"

**Cause:** Images stored inline instead of external storage.

**Fix:**
- Verify `DealImage.imageData` has `@Attribute(.externalStorage)`
- Compact database:
  ```bash
  # Quit app
  sqlite3 ~/Library/Containers/.../default.store "VACUUM;"
  ```

### "Migration backup folder filling up disk"

**Safe to delete backups older than 30 days:**
```bash
find ~/Documents/PorteosBackups/ -name "deals-*" -mtime +30 -delete
```

---

## Best Practices

### ✅ DO

- Add default values to new fields: `var newField: String = ""`
- Use optionals only when field truly might not exist: `var latitude: Double?`
- Keep models as "dumb" data containers (no business logic)
- Write unit tests for any complex model logic (enums, computed properties)
- Back up database before major schema changes
- Document all schema changes in this file

### ❌ DON'T

- Store calculated metrics (cap rate, NOI, etc.)
- Remove fields (migration will fail)
- Change field types (e.g., `String` → `Int`)
- Add required fields without defaults (migration will fail)
- Modify `@Relationship` without updating inverse
- Forget to register new models in `Schema([...])`

---

## Summary

**SwiftData Schema:**
- 6 models, 85+ properties on `PropertyDeal`
- Cascade delete relationships
- External storage for large data

**Migration:**
- Current: Backup + reset (data loss)
- Future: Lightweight migrations

**Safe Changes:**
- ✅ Add optional fields with defaults
- ❌ Remove/rename fields → data loss

**Critical Rules:**
- Models = data only (no business logic)
- Calculators = pure functions (no state)
- Computed properties = never persisted

**Next:** See [`ARCHITECTURE.md`](ARCHITECTURE.md) for how Models fit into the MVVM pattern.
