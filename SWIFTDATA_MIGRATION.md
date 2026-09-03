# SwiftData Schema Migration — Safe Practices Guide

How to safely modify the PropertyDeal schema and related models without losing user data.

---

## Table of Contents

1. [Current Migration Status](#current-migration-status)
2. [Types of Schema Changes](#types-of-schema-changes)
3. [Safe Changes (Lightweight Migration)](#safe-changes-lightweight-migration)
4. [Unsafe Changes (Requires Manual Migration)](#unsafe-changes-requires-manual-migration)
5. [Step-by-Step: Adding a Field](#step-by-step-adding-a-field)
6. [Step-by-Step: Adding a Relationship](#step-by-step-adding-a-relationship)
7. [Testing Schema Changes](#testing-schema-changes)
8. [Rollback Strategy](#rollback-strategy)
9. [Future: Versioned Migrations](#future-versioned-migrations)

---

## Current Migration Status

**Strategy:** Backup + Reset  
**Version:** Build 3 (Sept 2026)  
**Lightweight Migrations:** ❌ Not implemented  
**Data Loss Risk:** ⚠️ HIGH on schema changes

### How It Works Today

**Location:** [`PorteosIntelligenceApp.swift:26-87`](PorteosIntelligence/PorteosIntelligenceApp.swift)

```swift
var sharedModelContainer: ModelContainer = {
    let schema = Schema([
        PropertyDeal.self,
        DealScenario.self,
        EmailImportRecord.self,
        MarketTrend.self,
        DealImage.self,
        ResearchMessage.self,
    ])
    
    do {
        return try ModelContainer(for: schema, ...)
    } catch {
        // Schema mismatch → Backup + reset
        backupDatabase()
        showUserAlert()
        deleteOldDatabase()
        return try! ModelContainer(for: schema, ...)  // Fresh DB
    }
}
```

**On schema change:**
1. App tries to load existing database
2. SwiftData detects schema mismatch
3. **Automatic backup** to `~/Documents/PorteosBackups/deals-TIMESTAMP.store`
4. **Alert shown to user:** "Data store reset, backup created"
5. Old database deleted
6. Fresh empty database created
7. App starts with no deals

**⚠️ User must manually restore from backup** — no automatic migration.

---

## Types of Schema Changes

### Level 1: Safe (Lightweight Migration)

SwiftData can automatically migrate these changes **without data loss** (when lightweight migrations are enabled):

✅ **Adding optional properties:**
```swift
var newField: String?  // ✅ Safe
```

✅ **Adding properties with default values:**
```swift
var newField: String = ""       // ✅ Safe
var newField: Int = 0          // ✅ Safe
var newField: Double = 0.0     // ✅ Safe
var newField: Bool = false     // ✅ Safe
```

✅ **Adding relationships with empty defaults:**
```swift
@Relationship(deleteRule: .cascade) var items: [Item] = []  // ✅ Safe
```

✅ **Making required property optional:**
```swift
// Before:
var oldField: String = ""
// After:
var oldField: String?  // ✅ Safe (but loses default)
```

✅ **Changing delete rule on relationship:**
```swift
// Before:
@Relationship(deleteRule: .nullify) var items: [Item]
// After:
@Relationship(deleteRule: .cascade) var items: [Item]  // ✅ Safe
```

### Level 2: Risky (Manual Migration Required)

These changes **will cause data loss** with current backup+reset strategy:

❌ **Removing properties:**
```swift
var oldField: String = ""  // ❌ Remove this → data loss
```

❌ **Renaming properties:**
```swift
// Before:
var oldName: String
// After:
var newName: String  // ❌ SwiftData sees as remove+add → data loss
```

❌ **Changing property type:**
```swift
// Before:
var price: Int
// After:
var price: Double  // ❌ Type change → data loss
```

❌ **Making optional property required (without default):**
```swift
// Before:
var field: String?
// After:
var field: String  // ❌ No default → migration fails
```

❌ **Adding required property without default:**
```swift
var requiredField: String  // ❌ Existing records have no value → migration fails
```

❌ **Removing or renaming relationships:**
```swift
@Relationship var oldRelation: [Item]  // ❌ Remove → data loss
```

### Level 3: Complex (Advanced Migration Required)

These require custom migration logic (not yet supported):

🔶 **Splitting one property into multiple:**
```swift
// Before:
var fullName: String
// After:
var firstName: String
var lastName: String
// Requires: Parse fullName, split into first+last
```

🔶 **Merging properties:**
```swift
// Before:
var street: String
var city: String
// After:
var address: String  // Requires: Combine street + city
```

🔶 **Moving data between models:**
```swift
// Move PropertyDeal.notes → new NotesModel
```

---

## Safe Changes (Lightweight Migration)

### When Lightweight Migration Works

**Conditions:**
1. ✅ Only Level 1 changes (see above)
2. ✅ No data transformation needed
3. ✅ SwiftData can infer mapping automatically

**With current backup+reset strategy, even "safe" changes trigger reset.** This section describes what *would* work once lightweight migrations are implemented.

### Example: Add Optional Field

**Before:**
```swift
@Model
final class PropertyDeal {
    var propertyName: String
    var purchasePrice: Double
    // ... existing fields
}
```

**After:**
```swift
@Model
final class PropertyDeal {
    var propertyName: String
    var purchasePrice: Double
    var propertyTaxAnnual: Double?  // ← NEW OPTIONAL FIELD
    // ... existing fields
}
```

**Migration (automatic when lightweight enabled):**
- Existing records: `propertyTaxAnnual` = `nil`
- New records: User fills value
- No data loss

### Example: Add Field with Default

**Before:**
```swift
@Model
final class PropertyDeal {
    var propertyName: String
    var purchasePrice: Double
}
```

**After:**
```swift
@Model
final class PropertyDeal {
    var propertyName: String
    var purchasePrice: Double
    var tags: [String] = []  // ← NEW FIELD WITH DEFAULT
}
```

**Migration (automatic when lightweight enabled):**
- Existing records: `tags` = `[]` (empty array)
- New records: User can add tags
- No data loss

---

## Unsafe Changes (Requires Manual Migration)

### Why These Fail

SwiftData lightweight migration **cannot:**
- Recover removed data
- Infer renamed field mappings
- Convert types automatically
- Migrate complex transformations

**Current workaround:** Backup + reset strategy accepts data loss.

### Example: Remove Field (Data Loss)

**Before:**
```swift
@Model
final class PropertyDeal {
    var propertyName: String
    var oldField: String  // ← TO BE REMOVED
    var purchasePrice: Double
}
```

**After:**
```swift
@Model
final class PropertyDeal {
    var propertyName: String
    // oldField removed
    var purchasePrice: Double
}
```

**Result with current strategy:**
- ❌ Schema mismatch detected
- ❌ Database backed up
- ❌ Database reset (all deals lost)
- ❌ User must manually restore from backup

**Better future approach:**
1. Add `@available(*, deprecated)` to field
2. Stop displaying in UI
3. Leave in schema for 1-2 releases
4. Remove in later release with custom migration

### Example: Rename Field (Data Loss)

**Before:**
```swift
var closingCosts: Double
```

**After:**
```swift
var closingFees: Double  // Renamed from closingCosts
```

**Result:**
- ❌ SwiftData sees: Remove `closingCosts`, Add `closingFees`
- ❌ Treated as two separate changes
- ❌ Data loss on current backup+reset strategy

**Better future approach:**
- Use custom migration mapping to preserve data

---

## Step-by-Step: Adding a Field

### Prerequisites

1. ✅ Backup current database manually (belt-and-suspenders)
2. ✅ Test on a copy of production data
3. ✅ Communicate data loss risk to users

### Step 1: Add Field to Model

**File:** `PorteosIntelligence/Models/PropertyDeal.swift`

```swift
@Model
final class PropertyDeal {
    // ... existing fields ...
    
    // REAL ESTATE CORE FINANCIALS
    var purchasePrice: Double
    var closingCosts: Double
    var propertyTaxAnnual: Double = 0.0  // ← NEW FIELD (default required)
    
    // ... rest of fields ...
}
```

**Critical:** Always provide a default value (or make optional with `?`).

### Step 2: Update Dependent Code

**Calculators** (if field affects calculations):
```swift
// PorteosIntelligence/Calculators/RealEstateCalculator.swift

static func netOperatingIncome(
    gpi: Double,
    opex: Double,
    propertyTax: Double  // ← NEW PARAMETER
) -> Double {
    return gpi - opex - propertyTax
}
```

**ViewModels:**
```swift
// PorteosIntelligence/ViewModels/PropertyDealViewModel.swift

var noi: Double {
    RealEstateCalculator.netOperatingIncome(
        gpi: deal.grossPotentialIncome,
        opex: deal.operatingExpenses,
        propertyTax: deal.propertyTaxAnnual  // ← USE NEW FIELD
    )
}
```

**Views** (if user needs to input):
```swift
// PorteosIntelligence/Views/Sheets/FullDealEditSheet.swift

// REAL ESTATE tab, OpEx section
VStack(spacing: 8) {
    TerminalMetricRow(
        label: "Operating Expenses",
        value: $deal.operatingExpenses,
        format: .currency(code: "USD")
    )
    
    TerminalMetricRow(
        label: "Property Tax (Annual)",  // ← NEW INPUT
        value: $deal.propertyTaxAnnual,
        format: .currency(code: "USD")
    )
}
```

### Step 3: Test Locally

```bash
# 1. Clean build
⇧⌘K (in Xcode)

# 2. Build
⌘B

# Expected: Build succeeds, schema mismatch alert on launch

# 3. Click "Continue" on alert
# Database resets, app starts fresh

# 4. Create test deal
# 5. Fill new field: propertyTaxAnnual = 15000
# 6. Verify calculator uses value (check NOI calculation)
```

### Step 4: Update Tests

```swift
// PorteosIntelligenceTests/RealEstateCalculatorTests.swift

func testNOIWithPropertyTax() {
    let noi = RealEstateCalculator.netOperatingIncome(
        gpi: 100000,
        opex: 30000,
        propertyTax: 15000  // ← TEST NEW PARAMETER
    )
    
    XCTAssertEqual(noi, 55000, accuracy: 0.01)
}
```

### Step 5: Document Change

**Update:**
- [`DATA_MODEL_GUIDE.md`](DATA_MODEL_GUIDE.md) — Add field to PropertyDeal table
- [`ARCHITECTURE.md`](ARCHITECTURE.md) — If significant architectural impact
- Commit message — Describe schema change clearly

**Commit message template:**
```
Add propertyTaxAnnual field to PropertyDeal model

⚠️ SCHEMA CHANGE — Triggers database reset

Adds property tax field to Real Estate financials for more accurate NOI 
calculations. Defaults to 0.0 for existing deals (when database restored 
from backup).

- PropertyDeal: Add propertyTaxAnnual (Double, default 0.0)
- RealEstateCalculator: Update NOI to include property tax
- FullDealEditSheet: Add input field in RE tab
- Tests: Add coverage for new field
```

### Step 6: Communicate to Users

**Before releasing:**

**Email to beta testers:**
```
Subject: Porteos Intelligence — Database Reset Required in Next Update

We're adding a new property tax field for more accurate calculations. 
Due to current migration limitations, your database will reset on update.

Your deals will be backed up to:
~/Documents/PorteosBackups/deals-TIMESTAMP.store

We're working on seamless migrations for future updates. 
Contact support@htdstudio.net for help restoring from backup.
```

---

## Step-by-Step: Adding a Relationship

### Example: Add Tags Model

**Step 1: Create New Model**

```swift
// PorteosIntelligence/Models/DealTag.swift

import Foundation
import SwiftData

@Model
final class DealTag {
    @Attribute(.unique) var id: UUID
    var name: String
    var color: String  // Hex color
    
    var deal: PropertyDeal?  // Inverse relationship
    
    init(name: String, color: String) {
        self.id = UUID()
        self.name = name
        self.color = color
    }
}
```

**Step 2: Add to Schema Registration**

```swift
// PorteosIntelligenceApp.swift

let schema = Schema([
    PropertyDeal.self,
    DealScenario.self,
    EmailImportRecord.self,
    MarketTrend.self,
    DealImage.self,
    ResearchMessage.self,
    DealTag.self,  // ← ADD NEW MODEL
])
```

**Step 3: Add Relationship to PropertyDeal**

```swift
// PropertyDeal.swift

@Model
final class PropertyDeal {
    // ... existing fields ...
    
    @Relationship(deleteRule: .cascade) var tags: [DealTag] = []  // ← NEW RELATIONSHIP
    
    // ... rest of fields ...
}
```

**Step 4: Update UI to Display/Edit Tags**

```swift
// Example: Tag picker in FullDealEditSheet
ForEach(deal.tags) { tag in
    TagChip(name: tag.name, color: tag.color)
        .onTapGesture {
            deal.tags.removeAll { $0.id == tag.id }
        }
}

Button("Add Tag") {
    let newTag = DealTag(name: "Waterfront", color: "#06B6D4")
    newTag.deal = deal
    deal.tags.append(newTag)
}
```

**Step 5: Test**

- Build → Schema reset alert → Continue
- Create deal, add tags
- Delete deal → Verify tags also deleted (cascade)
- Verify tags persist across app restarts

---

## Testing Schema Changes

### Pre-Deployment Testing

**1. Test on Copy of Production DB**

```bash
# Copy production DB to test location
cp ~/Library/Containers/.../default.store ~/Desktop/test-migration.store

# Modify code to point at test DB (temporarily)
let testURL = URL(fileURLWithPath: "~/Desktop/test-migration.store")
let config = ModelConfiguration(url: testURL)
```

**2. Test with Variety of Data**

- Deals with all fields filled
- Deals with minimal fields
- Deals with relationships (images, scenarios)
- Old deals vs new deals

**3. Verify Backup Creation**

- Check `~/Documents/PorteosBackups/` folder
- Verify backed-up .store, .store-shm, .store-wal files
- Attempt manual restore

### Automated Testing

**Unit tests for new fields:**

```swift
func testNewFieldDefaultValue() {
    let deal = PropertyDeal()
    XCTAssertEqual(deal.propertyTaxAnnual, 0.0)
}

func testCalculatorWithNewField() {
    let noi = RealEstateCalculator.netOperatingIncome(
        gpi: 100000,
        opex: 30000,
        propertyTax: 15000
    )
    XCTAssertEqual(noi, 55000, accuracy: 0.01)
}
```

**Integration tests:**

```swift
func testDealSaveWithNewField() throws {
    let context = ModelContext(container)
    let deal = PropertyDeal()
    deal.propertyTaxAnnual = 15000
    
    context.insert(deal)
    try context.save()
    
    // Fetch and verify
    let descriptor = FetchDescriptor<PropertyDeal>()
    let deals = try context.fetch(descriptor)
    XCTAssertEqual(deals.first?.propertyTaxAnnual, 15000)
}
```

---

## Rollback Strategy

### If Migration Fails in Production

**Scenario:** Users report data loss, backup restore not working.

**Immediate Actions:**

1. **Pull release from distribution**
   - Remove TestFlight build
   - Halt further downloads

2. **Communicate to affected users**
   ```
   We're aware of a database issue in the latest update. 
   DO NOT delete the app. A fix is coming within 24 hours.
   Your data is backed up at ~/Documents/PorteosBackups/
   ```

3. **Revert code to previous schema**
   ```bash
   git revert <commit-hash>  # Revert schema change commit
   git push
   ```

4. **Release hotfix**
   - Build with old schema
   - Users can restore from backup without schema mismatch

5. **Provide restore script**
   ```bash
   # restore-from-backup.sh
   echo "Restoring Porteos Intelligence database..."
   
   # Quit app
   killall "Porteos Intelligence"
   
   # Find most recent backup
   BACKUP=$(ls -t ~/Documents/PorteosBackups/deals-*.store | head -1)
   
   # Copy to app container
   cp "$BACKUP" ~/Library/Containers/.../default.store
   
   echo "Restored from: $BACKUP"
   echo "Restart Porteos Intelligence"
   ```

---

## Future: Versioned Migrations

### Goal

Enable seamless schema changes without data loss.

### Implementation Plan

**Phase 1: Version Models**

```swift
@Model(version: 2)  // ← Add versioning
final class PropertyDeal {
    // ...
}
```

**Phase 2: Define Migration Plans**

```swift
let migrationPlan = SchemaMigrationPlan([
    MigrateV1toV2.self,
    MigrateV2toV3.self,
])

struct MigrateV1toV2: SchemaMigration {
    static var sourceVersion: Int = 1
    static var targetVersion: Int = 2
    
    static func migrate(context: ModelContext) throws {
        // Custom migration logic
        // Example: Rename field, transform data, merge properties
    }
}
```

**Phase 3: Test Migrations**

- Create test databases at each version
- Verify migration path from v1 → v2 → v3 → current
- Automated migration tests in CI

**Phase 4: Enable Lightweight + Custom Migrations**

```swift
let container = try ModelContainer(
    for: schema,
    migrationPlan: migrationPlan,
    configurations: [.init(allowAutomigration: true)]
)
```

**Benefits:**
- ✅ Add fields without data loss
- ✅ Rename fields with mapping
- ✅ Transform data during migration
- ✅ Users never see "database reset" alert

**Estimated Effort:** 16-24 hours development + testing

---

## Summary

**Current State:**
- ⚠️ Backup + reset on schema changes
- ⚠️ Data loss accepted
- ⚠️ Manual restore required

**Safe Changes (Level 1):**
- ✅ Add optional fields
- ✅ Add fields with defaults
- ✅ Add relationships with defaults

**Unsafe Changes (Level 2/3):**
- ❌ Remove/rename fields → Data loss
- ❌ Change types → Data loss
- ❌ Complex transformations → Not supported

**Best Practices:**
1. Always add defaults to new fields
2. Test on copy of production DB first
3. Communicate data loss risk to users
4. Document all schema changes
5. Verify backup creation

**Future:**
- Implement versioned migrations
- Enable lightweight + custom migrations
- Eliminate data loss on schema changes

**Critical:** Plan for lightweight migrations in next 2-3 releases to improve developer and user experience.
