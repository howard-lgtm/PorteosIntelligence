# Calculator System — Pure Function Financial Metrics

Complete guide to the calculator pattern, financial formulas, and metric calculation architecture.

---

## Table of Contents

1. [Overview](#overview)
2. [Calculator Pattern](#calculator-pattern)
3. [Calculator Modules](#calculator-modules)
4. [Real Estate Calculator](#real-estate-calculator)
5. [Hospitality Calculator](#hospitality-calculator)
6. [Design Calculator](#design-calculator)
7. [Circular Economy Calculator](#circular-economy-calculator)
8. [Porteos Score Calculator](#porteos-score-calculator)
9. [Adding New Metrics](#adding-new-metrics)
10. [Testing Calculators](#testing-calculators)

---

## Overview

Calculators are **pure Swift structs** that perform financial and performance calculations. They have no state, no side effects, and are completely separate from the UI and data layers.

### Why Pure Functions?

✅ **Testable:** No mocks, no dependencies, just input → output  
✅ **Reusable:** Used in ViewModels, PDF export, API responses, tests  
✅ **Predictable:** Same inputs always produce same outputs  
✅ **Fast:** No async/await, no network calls, instant results  
✅ **Maintainable:** Easy to understand and modify formulas  

### Architecture

```
PropertyDeal (Model)
     ↓
     Raw input data
     ↓
PropertyDealViewModel (ViewModel)
     ↓
     Calls calculators with deal data
     ↓
RealEstateCalculator / HospitalityCalculator / etc.
     ↓
     Pure functions, no side effects
     ↓
     Returns calculated metrics
     ↓
Dashboard Views (UI)
     ↓
     Displays results
```

---

## Calculator Pattern

### Template Structure

**Location:** `PorteosIntelligence/Calculators/`

```swift
import Foundation

struct ExampleCalculator {
    
    // MARK: - Primary Metrics
    
    /// Calculate metric with clear formula
    /// - Parameters:
    ///   - input1: Description of first input
    ///   - input2: Description of second input
    /// - Returns: Calculated result (units specified)
    static func metricName(input1: Double, input2: Double) -> Double {
        guard input2 != 0 else { return 0 }  // Guard against division by zero
        return (input1 / input2) * 100
    }
    
    // MARK: - Composite Metrics
    
    /// Calculate complex metric using other functions
    static func complexMetric(
        value1: Double,
        value2: Double
    ) -> (result: Double, status: String) {
        let intermediate = metricName(input1: value1, input2: value2)
        let status = intermediate > 10 ? "Good" : "Poor"
        return (intermediate, status)
    }
    
    // MARK: - Thresholds
    
    static let excellentThreshold: Double = 15.0
    static let goodThreshold: Double = 10.0
    static let acceptableThreshold: Double = 5.0
}
```

### Key Principles

1. **Static methods only** — No instance state
2. **Guard against edge cases** — Division by zero, negative values
3. **Return 0 for invalid inputs** — Don't crash, degrade gracefully
4. **Document formulas** — Comments explain calculation logic
5. **Constants for thresholds** — Centralize magic numbers
6. **Tuples for multi-value returns** — `(result, status, category)`

### Formula Documentation

**See:** [`PorteosIntelligence/02_DATA_METRICS_AND_LOGIC.md`](PorteosIntelligence/02_DATA_METRICS_AND_LOGIC.md)

All formulas are documented with:
- Industry-standard definitions
- Real estate investment theory
- Threshold interpretations
- Example calculations

---

## Calculator Modules

### Overview

| Calculator | Metrics Count | Use Case |
|------------|---------------|----------|
| **RealEstateCalculator** | 12 | Residential, commercial, multi-family |
| **HospitalityCalculator** | 10 | Hotels, resorts, short-term rentals |
| **DesignCalculator** | 8 | Space efficiency, biophilic design |
| **CircularEconomyCalculator** | 9 | Sustainability, carbon, materials |
| **PorteosScoreCalculator** | 1 (composite) | 0-100 overall score + grade |

### File Locations

```
PorteosIntelligence/Calculators/
├── RealEstateCalculator.swift        (~300 lines)
├── HospitalityCalculator.swift       (~250 lines)
├── DesignCalculator.swift            (~200 lines)
├── CircularEconomyCalculator.swift   (~220 lines)
└── PorteosScoreCalculator.swift      (~400 lines)
```

---

## Real Estate Calculator

**File:** `PorteosIntelligence/Calculators/RealEstateCalculator.swift`

### Core Metrics

#### 1. Net Operating Income (NOI)

```swift
/// Calculate Net Operating Income
/// Formula: Gross Potential Income - Vacancy Loss - Operating Expenses
/// - Returns: Annual NOI in currency units
static func netOperatingIncome(
    grossPotentialIncome: Double,
    vacancyRate: Double,
    operatingExpenses: Double
) -> Double {
    let vacancyLoss = grossPotentialIncome * (vacancyRate / 100.0)
    let effectiveGrossIncome = grossPotentialIncome - vacancyLoss
    return effectiveGrossIncome - operatingExpenses
}
```

**Interpretation:**
- Positive NOI = Property generates cash flow
- Negative NOI = Property loses money operationally
- Higher is better

#### 2. Cap Rate (Capitalization Rate)

```swift
/// Calculate Capitalization Rate
/// Formula: (NOI / Purchase Price) × 100
/// - Returns: Cap rate as percentage
static func capRate(noi: Double, purchasePrice: Double) -> Double {
    guard purchasePrice > 0 else { return 0 }
    return (noi / purchasePrice) * 100
}
```

**Interpretation:**
- 8%+ = Excellent
- 6-8% = Good
- 4-6% = Acceptable
- <4% = Poor

**Thresholds:**
```swift
static let excellentCapRate: Double = 8.0
static let goodCapRate: Double = 6.0
static let acceptableCapRate: Double = 4.0
```

#### 3. Debt Service Coverage Ratio (DSCR)

```swift
/// Calculate Debt Service Coverage Ratio
/// Formula: NOI / Annual Debt Service
/// - Returns: DSCR as ratio (e.g., 1.25 = 125% coverage)
static func dscr(noi: Double, annualDebtService: Double) -> Double {
    guard annualDebtService > 0 else { return 0 }
    return noi / annualDebtService
}
```

**Interpretation:**
- >1.4 = Excellent (40% cushion)
- 1.25-1.4 = Good (lender minimum)
- 1.0-1.25 = Acceptable (break-even)
- <1.0 = Critical (can't cover debt)

#### 4. Loan-to-Value (LTV)

```swift
/// Calculate Loan-to-Value ratio
/// Formula: (Loan Amount / Property Value) × 100
/// - Returns: LTV as percentage
static func ltv(loanAmount: Double, propertyValue: Double) -> Double {
    guard propertyValue > 0 else { return 0 }
    return (loanAmount / propertyValue) * 100
}
```

**Interpretation:**
- <70% = Conservative financing
- 70-80% = Standard
- 80-90% = Aggressive
- >90% = High risk

#### 5. Cash-on-Cash Return

```swift
/// Calculate Cash-on-Cash return
/// Formula: (Annual Pre-Tax Cash Flow / Total Cash Invested) × 100
/// - Returns: Return as percentage
static func cashOnCashReturn(
    annualCashFlow: Double,
    totalCashInvested: Double
) -> Double {
    guard totalCashInvested > 0 else { return 0 }
    return (annualCashFlow / totalCashInvested) * 100
}
```

**Interpretation:**
- >12% = Excellent
- 8-12% = Good
- 5-8% = Acceptable
- <5% = Poor

#### 6. Gross Yield

```swift
/// Calculate Gross Yield
/// Formula: (Annual Rental Income / Purchase Price) × 100
/// - Returns: Yield as percentage
static func grossYield(
    annualRentalIncome: Double,
    purchasePrice: Double
) -> Double {
    guard purchasePrice > 0 else { return 0 }
    return (annualRentalIncome / purchasePrice) * 100
}
```

### Usage in ViewModel

```swift
// PropertyDealViewModel.swift

@Observable
final class PropertyDealViewModel {
    let deal: PropertyDeal
    
    var noi: Double {
        RealEstateCalculator.netOperatingIncome(
            grossPotentialIncome: deal.grossPotentialIncome,
            vacancyRate: deal.vacancyRate,
            operatingExpenses: deal.operatingExpenses
        )
    }
    
    var capRate: Double {
        RealEstateCalculator.capRate(
            noi: noi,
            purchasePrice: deal.purchasePrice
        )
    }
    
    var dscr: Double {
        RealEstateCalculator.dscr(
            noi: noi,
            annualDebtService: deal.annualDebtService
        )
    }
    
    // ... other metrics
}
```

---

## Hospitality Calculator

**File:** `PorteosIntelligence/Calculators/HospitalityCalculator.swift`

### Core Metrics

#### 1. Average Daily Rate (ADR)

```swift
/// Calculate Average Daily Rate
/// Formula: Room Revenue / Rooms Sold
/// - Returns: Average rate per room in currency units
static func averageDailyRate(
    roomRevenue: Double,
    roomsSold: Int
) -> Double {
    guard roomsSold > 0 else { return 0 }
    return roomRevenue / Double(roomsSold)
}
```

#### 2. Occupancy Rate

```swift
/// Calculate Occupancy Rate
/// Formula: (Rooms Sold / Available Room Nights) × 100
/// - Returns: Occupancy as percentage
static func occupancyRate(
    roomsSold: Int,
    availableRoomNights: Int
) -> Double {
    guard availableRoomNights > 0 else { return 0 }
    return (Double(roomsSold) / Double(availableRoomNights)) * 100
}
```

**Interpretation:**
- 80%+ = Excellent
- 70-80% = Good
- 60-70% = Acceptable
- <60% = Poor

#### 3. Revenue Per Available Room (RevPAR)

```swift
/// Calculate RevPAR
/// Formula: ADR × Occupancy Rate (or Room Revenue / Available Rooms)
/// - Returns: Revenue per room in currency units
static func revPAR(adr: Double, occupancyRate: Double) -> Double {
    return adr * (occupancyRate / 100.0)
}

// Alternative formula
static func revPAR(roomRevenue: Double, availableRooms: Int) -> Double {
    guard availableRooms > 0 else { return 0 }
    return roomRevenue / Double(availableRooms)
}
```

**Interpretation:**
- Higher RevPAR = Better performance
- Compare to market benchmark for area
- Increases via higher ADR or occupancy

#### 4. Gross Operating Profit (GOP)

```swift
/// Calculate Gross Operating Profit
/// Formula: Total Revenue - Operating Expenses
/// - Returns: GOP in currency units
static func grossOperatingProfit(
    totalRevenue: Double,
    operatingExpenses: Double
) -> Double {
    return totalRevenue - operatingExpenses
}
```

#### 5. GOP Margin

```swift
/// Calculate GOP Margin (profitability percentage)
/// Formula: (GOP / Total Revenue) × 100
/// - Returns: Margin as percentage
static func gopMargin(gop: Double, totalRevenue: Double) -> Double {
    guard totalRevenue > 0 else { return 0 }
    return (gop / totalRevenue) * 100
}
```

**Interpretation:**
- 40%+ = Excellent
- 30-40% = Good
- 20-30% = Acceptable
- <20% = Poor

#### 6. Sensitivity Analysis

```swift
/// Calculate sensitivity scenarios for hospitality properties
/// - Returns: Tuple with base, upside, downside, stress scenarios
static func sensitivityAnalysis(
    baseGOP: Double,
    baseOccupancy: Double,
    baseADR: Double,
    roomCount: Int
) -> (
    base: Double,
    upside: Double,
    downside: Double,
    combinedStress: Double
) {
    let availableRooms = roomCount * 365
    
    // Base scenario
    let base = baseGOP
    
    // Upside: +10% occupancy, +5% ADR
    let upsideOccupancy = baseOccupancy * 1.10
    let upsideADR = baseADR * 1.05
    let upsideRevPAR = revPAR(adr: upsideADR, occupancyRate: upsideOccupancy)
    let upside = upsideRevPAR * Double(availableRooms) * 0.35  // Assume 35% GOP margin
    
    // Downside: -10% occupancy
    let downsideOccupancy = baseOccupancy * 0.90
    let downsideRevPAR = revPAR(adr: baseADR, occupancyRate: downsideOccupancy)
    let downside = downsideRevPAR * Double(availableRooms) * 0.35
    
    // Combined stress: -10% occupancy, -5% ADR
    let stressOccupancy = baseOccupancy * 0.90
    let stressADR = baseADR * 0.95
    let stressRevPAR = revPAR(adr: stressADR, occupancyRate: stressOccupancy)
    let combinedStress = stressRevPAR * Double(availableRooms) * 0.35
    
    return (base, upside, downside, combinedStress)
}
```

**Used in:** `HospitalitySensitivityBlock` view component

---

## Design Calculator

**File:** `PorteosIntelligence/Calculators/DesignCalculator.swift`

### Core Metrics

#### 1. Space Efficiency

```swift
/// Calculate space efficiency ratio
/// Formula: (Usable Area / Total Area) × 100
/// - Returns: Efficiency as percentage
static func spaceEfficiency(
    usableArea: Double,
    totalArea: Double
) -> Double {
    guard totalArea > 0 else { return 0 }
    return (usableArea / totalArea) * 100
}
```

**Interpretation:**
- 85%+ = Excellent
- 75-85% = Good
- 65-75% = Acceptable
- <65% = Poor (too much wasted space)

#### 2. Biophilic Score

```swift
/// Calculate biophilic design score
/// Combines: natural light, green space, views
/// - Returns: Score 0-100
static func biophilicScore(
    naturalLightScore: Double,      // 0-100
    greenSpacePercent: Double,      // % of property
    viewQualityScore: Double        // 0-100
) -> Double {
    let lightWeight = 0.4
    let greenWeight = 0.35
    let viewWeight = 0.25
    
    let normalizedGreen = min(greenSpacePercent, 30.0) / 30.0 * 100  // Cap at 30%
    
    return (naturalLightScore * lightWeight) +
           (normalizedGreen * greenWeight) +
           (viewQualityScore * viewWeight)
}
```

#### 3. Wellness Index

```swift
/// Calculate overall wellness index
/// Combines: air quality, acoustics, ergonomics, biophilia
/// - Returns: Index 0-100
static func wellnessIndex(
    airQualityScore: Double,
    acousticScore: Double,
    ergonomicScore: Double,
    biophilicScore: Double
) -> Double {
    return (airQualityScore + acousticScore + ergonomicScore + biophilicScore) / 4.0
}
```

---

## Circular Economy Calculator

**File:** `PorteosIntelligence/Calculators/CircularEconomyCalculator.swift`

### Core Metrics

#### 1. Material Circularity Index

```swift
/// Calculate material circularity index
/// Formula: (Recycled Content + Recyclable Output) / 2
/// - Returns: Index 0-100
static func materialCircularityIndex(
    recycledContentPercent: Double,
    recyclableOutputPercent: Double
) -> Double {
    return (recycledContentPercent + recyclableOutputPercent) / 2.0
}
```

#### 2. Carbon Lifecycle

```swift
/// Calculate total carbon footprint
/// Formula: Embodied Carbon + (Operational Carbon × Lifespan)
/// - Returns: Total carbon in tonnes CO2e
static func totalCarbonFootprint(
    embodiedCarbon: Double,         // tonnes CO2e
    operationalCarbonAnnual: Double, // tonnes CO2e per year
    lifespanYears: Int
) -> Double {
    return embodiedCarbon + (operationalCarbonAnnual * Double(lifespanYears))
}
```

#### 3. Resource Efficiency

```swift
/// Calculate resource efficiency score
/// Combines: water, energy, waste reduction
/// - Returns: Score 0-100
static func resourceEfficiencyScore(
    waterEfficiency: Double,        // 0-100
    energyEfficiency: Double,       // 0-100
    wasteReductionPercent: Double   // 0-100
) -> Double {
    return (waterEfficiency + energyEfficiency + wasteReductionPercent) / 3.0
}
```

---

## Porteos Score Calculator

**File:** `PorteosIntelligence/Calculators/PorteosScoreCalculator.swift` (~400 lines)

### Composite Scoring Algorithm

The Porteos Score is a **0-100 weighted composite** of metrics across all profiles.

```swift
struct PorteosScoreResult {
    let finalScore: Double          // 0-100
    let grade: String               // A, B+, B, C+, C, D, F
    let components: [String: Double] // Breakdown by category
    let warnings: [String]          // Regulatory flags
}

static func calculate(deal: PropertyDeal) -> PorteosScoreResult {
    var components: [String: Double] = [:]
    var warnings: [String] = []
    
    // 1. Real Estate Financials (40% weight)
    components["capRate"] = scoreCapRate(deal.capRate)
    components["dscr"] = scoreDSCR(deal.dscr)
    components["ltv"] = scoreLTV(deal.ltv)
    components["cashReturn"] = scoreCashOnCash(deal.cashOnCashReturn)
    
    // 2. Hospitality Performance (20% weight, if applicable)
    if deal.propertyType.contains("Hotel") || deal.propertyType.contains("Hospitality") {
        components["revpar"] = scoreRevPAR(deal.revpar, market: deal.locationCity)
        components["occupancy"] = scoreOccupancy(deal.occupancyRate)
        components["gopMargin"] = scoreGOPMargin(deal.gopMargin)
    }
    
    // 3. Design Quality (15% weight)
    components["spaceEfficiency"] = scoreSpaceEfficiency(deal.spaceEfficiency)
    components["biophilic"] = deal.biophilicScore  // Already 0-100
    
    // 4. Circular Economy (15% weight)
    components["materialCircularity"] = deal.materialCircularityIndex
    components["carbonEfficiency"] = scoreCarbonEfficiency(deal.carbonIntensity)
    
    // 5. Regulatory Compliance (10% weight)
    let regulatoryScore = scoreRegulatory(deal)
    components["regulatory"] = regulatoryScore.score
    warnings.append(contentsOf: regulatoryScore.warnings)
    
    // Weighted average
    let finalScore = calculateWeightedScore(components: components, propertyType: deal.propertyType)
    let grade = assignGrade(score: finalScore)
    
    return PorteosScoreResult(
        finalScore: finalScore,
        grade: grade,
        components: components,
        warnings: warnings
    )
}
```

### Component Scoring Functions

```swift
private static func scoreCapRate(_ capRate: Double) -> Double {
    // Score cap rate on 0-100 scale
    if capRate >= 8.0 { return 100 }
    if capRate >= 6.0 { return 80 }
    if capRate >= 4.0 { return 60 }
    if capRate >= 2.0 { return 40 }
    return 20
}

private static func scoreDSCR(_ dscr: Double) -> Double {
    // DSCR >1.4 = 100, <1.0 = 0
    if dscr >= 1.4 { return 100 }
    if dscr >= 1.25 { return 80 }
    if dscr >= 1.1 { return 60 }
    if dscr >= 1.0 { return 40 }
    return max(0, dscr * 40)  // Linear scale below 1.0
}
```

### Grading System

```swift
private static func assignGrade(score: Double) -> String {
    switch score {
    case 93...100: return "A"
    case 90..<93:  return "A-"
    case 87..<90:  return "B+"
    case 83..<87:  return "B"
    case 80..<83:  return "B-"
    case 77..<80:  return "C+"
    case 73..<77:  return "C"
    case 70..<73:  return "C-"
    case 67..<70:  return "D+"
    case 60..<67:  return "D"
    default:       return "F"
    }
}
```

### Property-Type Aware Weighting

```swift
private static func calculateWeightedScore(
    components: [String: Double],
    propertyType: String
) -> Double {
    var weights: [String: Double] = [:]
    
    if propertyType.contains("Hotel") || propertyType.contains("Hospitality") {
        // Hospitality properties: emphasize RevPAR, occupancy
        weights = [
            "capRate": 0.15,
            "dscr": 0.15,
            "revpar": 0.20,
            "occupancy": 0.15,
            "gopMargin": 0.10,
            "spaceEfficiency": 0.08,
            "biophilic": 0.07,
            "materialCircularity": 0.05,
            "regulatory": 0.05
        ]
    } else {
        // Residential/Commercial: emphasize cap rate, DSCR
        weights = [
            "capRate": 0.25,
            "dscr": 0.25,
            "cashReturn": 0.15,
            "ltv": 0.10,
            "spaceEfficiency": 0.08,
            "biophilic": 0.07,
            "materialCircularity": 0.05,
            "regulatory": 0.05
        ]
    }
    
    var score: Double = 0
    for (key, value) in components {
        if let weight = weights[key] {
            score += value * weight
        }
    }
    
    return min(100, max(0, score))  // Clamp to 0-100
}
```

---

## Adding New Metrics

### Example: Add Property Tax to NOI Calculation

**Step 1: Update Calculator**

```swift
// RealEstateCalculator.swift

static func netOperatingIncome(
    grossPotentialIncome: Double,
    vacancyRate: Double,
    operatingExpenses: Double,
    propertyTax: Double  // ← NEW PARAMETER
) -> Double {
    let vacancyLoss = grossPotentialIncome * (vacancyRate / 100.0)
    let effectiveGrossIncome = grossPotentialIncome - vacancyLoss
    return effectiveGrossIncome - operatingExpenses - propertyTax  // ← INCLUDE TAX
}
```

**Step 2: Update ViewModel**

```swift
// PropertyDealViewModel.swift

var noi: Double {
    RealEstateCalculator.netOperatingIncome(
        grossPotentialIncome: deal.grossPotentialIncome,
        vacancyRate: deal.vacancyRate,
        operatingExpenses: deal.operatingExpenses,
        propertyTax: deal.propertyTaxAnnual  // ← PASS NEW FIELD
    )
}
```

**Step 3: Add Tests**

```swift
// RealEstateCalculatorTests.swift

func testNOIWithPropertyTax() {
    let noi = RealEstateCalculator.netOperatingIncome(
        grossPotentialIncome: 100000,
        vacancyRate: 5,
        operatingExpenses: 30000,
        propertyTax: 10000
    )
    
    // GPI: 100,000
    // Vacancy (5%): 5,000
    // EGI: 95,000
    // OpEx: 30,000
    // Tax: 10,000
    // NOI: 55,000
    XCTAssertEqual(noi, 55000, accuracy: 0.01)
}
```

**Step 4: Update Formula Documentation**

```markdown
// 02_DATA_METRICS_AND_LOGIC.md

## Net Operating Income (NOI)

**Formula:** EGI - OpEx - Property Tax

**Components:**
- Effective Gross Income = GPI - Vacancy Loss
- Operating Expenses
- Property Tax (annual)

**Interpretation:**
Positive NOI indicates property generates cash flow after all operating costs and taxes.
```

---

## Testing Calculators

### Unit Test Structure

**Location:** `PorteosIntelligenceTests/`

**Example: RealEstateCalculatorTests.swift**

```swift
import XCTest
@testable import PorteosIntelligence

final class RealEstateCalculatorTests: XCTestCase {
    
    func testCapRate() {
        // Given
        let noi: Double = 50000
        let purchasePrice: Double = 1000000
        
        // When
        let capRate = RealEstateCalculator.capRate(
            noi: noi,
            purchasePrice: purchasePrice
        )
        
        // Then
        XCTAssertEqual(capRate, 5.0, accuracy: 0.01)
    }
    
    func testCapRateZeroPurchasePrice() {
        // Edge case: Division by zero
        let capRate = RealEstateCalculator.capRate(noi: 50000, purchasePrice: 0)
        XCTAssertEqual(capRate, 0.0)
    }
    
    func testDSCR() {
        let noi: Double = 100000
        let debtService: Double = 80000
        
        let dscr = RealEstateCalculator.dscr(
            noi: noi,
            annualDebtService: debtService
        )
        
        XCTAssertEqual(dscr, 1.25, accuracy: 0.01)
    }
    
    func testNOI() {
        let noi = RealEstateCalculator.netOperatingIncome(
            grossPotentialIncome: 100000,
            vacancyRate: 5,
            operatingExpenses: 30000
        )
        
        // GPI: 100,000
        // Vacancy (5%): 5,000
        // EGI: 95,000
        // OpEx: 30,000
        // NOI: 65,000
        XCTAssertEqual(noi, 65000, accuracy: 0.01)
    }
}
```

### Testing Best Practices

1. **Test happy path:** Normal inputs, expected outputs
2. **Test edge cases:** Zero, negative, very large numbers
3. **Test guards:** Division by zero returns 0 (not crash)
4. **Use accuracy:** Floating-point comparisons need tolerance
5. **Document expected results:** Show calculation in comments

### Running Tests

```bash
# In Xcode
⌘U

# Via command line
xcodebuild test -scheme PorteosIntelligence -destination 'platform=macOS'
```

---

## Summary

**Calculator System:**
- 5 calculator modules (RE, Hospitality, Design, Circular, Score)
- Pure Swift structs (no state, no side effects)
- ~1,400 lines of calculation code
- 100% testable with unit tests

**Key Patterns:**
- Static methods only
- Guard against edge cases
- Return 0 for invalid inputs
- Centralize thresholds as constants
- Document formulas in code

**Integration:**
- ViewModels call calculators with Model data
- Results displayed in dashboard Views
- Same calculations used in PDF export, API, tests

**Critical Rules:**
- NEVER put calculation logic in Models
- NEVER put business logic in Views
- ALWAYS test new metrics with unit tests
- ALWAYS document formula sources

**Next:** See [`BROWSER_EXTENSION_GUIDE.md`](BROWSER_EXTENSION_GUIDE.md) for scraper architecture.
