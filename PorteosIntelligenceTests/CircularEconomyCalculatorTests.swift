import XCTest
@testable import PorteosIntelligence

final class CircularEconomyCalculatorTests: XCTestCase {

    // MARK: - Case 1: High Performance
    // Repurposed: 80%, Recovery: 90%, Carbon intensity: 0.1 kg CO2/kg (perfect)
    // Expected:
    //   materialCircularityScore = (80 + 90) / 2 = 85
    //   carbonEfficiencyScore    = max(0, 100 - ((0.1 - 0.1) / 0.9 * 100)) = 100
    //   overallCEScore           = (85 * 0.7) + (100 * 0.3) = 89.5  → > 80

    func testHighPerformance() {
        let inputs = CircularEconomyCalculator.CircularEconomyInputs(
            totalConstructionCost:  1_000_000,
            repurposedMaterialCost:   800_000,  // 80%
            co2Embodied:               10_000,  // kg CO2e
            kgMaterialsUsed:          100_000,  // → carbonIntensity = 0.1
            kgMaterialsReturned:       90_000,  // → recoveryRatio = 90%
            kgMaterialsDisposed:       10_000,
            vendorCount:                    10,
            averageHourlyRate:            50.0
        )
        let metrics = CircularEconomyCalculator.calculate(inputs: inputs)

        XCTAssertEqual(metrics.materialCircularityScore, 85.0,  accuracy: 0.01)
        XCTAssertEqual(metrics.carbonEfficiencyScore,   100.0,  accuracy: 0.01)
        XCTAssertEqual(metrics.overallCEScore,           89.5,  accuracy: 0.01)
        XCTAssertGreaterThan(metrics.overallCEScore, 80)
    }

    // MARK: - Case 2: Low Performance
    // Repurposed: 0%, Recovery: 0%, Carbon intensity: 2.0 kg CO2/kg
    // Expected:
    //   materialCircularityScore = 0
    //   carbonEfficiencyScore    = max(0, 100 - (1.9 / 0.9 * 100)) = max(0, -111) = 0
    //   overallCEScore           = 0  → < 20

    func testLowPerformance() {
        let inputs = CircularEconomyCalculator.CircularEconomyInputs(
            totalConstructionCost:  1_000_000,
            repurposedMaterialCost:         0,  // 0%
            co2Embodied:              200_000,  // kg CO2e → intensity = 2.0
            kgMaterialsUsed:          100_000,
            kgMaterialsReturned:            0,  // nothing recovered
            kgMaterialsDisposed:      100_000,
            vendorCount:                    2,
            averageHourlyRate:            20.0
        )
        let metrics = CircularEconomyCalculator.calculate(inputs: inputs)

        XCTAssertEqual(metrics.materialCircularityScore, 0.0, accuracy: 0.01)
        XCTAssertEqual(metrics.carbonEfficiencyScore,    0.0, accuracy: 0.01)
        XCTAssertEqual(metrics.overallCEScore,           0.0, accuracy: 0.01)
        XCTAssertLessThan(metrics.overallCEScore, 20)
    }

    // MARK: - Case 3: Division by Zero — kgMaterialsUsed = 0

    func testDivisionByZeroMaterialsUsed() {
        let inputs = CircularEconomyCalculator.CircularEconomyInputs(
            totalConstructionCost:  500_000,
            repurposedMaterialCost: 250_000,
            co2Embodied:             10_000,
            kgMaterialsUsed:              0,  // trigger div-by-zero guard
            kgMaterialsReturned:      5_000,
            kgMaterialsDisposed:      5_000,
            vendorCount:                  5,
            averageHourlyRate:           40.0
        )
        // Must not crash; carbonEfficiencyScore must be 0 (not NaN/inf)
        let metrics = CircularEconomyCalculator.calculate(inputs: inputs)

        XCTAssertFalse(metrics.carbonEfficiencyScore.isNaN,
                       "carbonEfficiencyScore must not be NaN when kgMaterialsUsed is 0")
        XCTAssertFalse(metrics.overallCEScore.isNaN,
                       "overallCEScore must not be NaN when kgMaterialsUsed is 0")
        XCTAssertEqual(metrics.carbonEfficiencyScore, 0.0, accuracy: 0.01)
    }

    // MARK: - Case 4: Division by Zero — totalConstructionCost = 0

    func testDivisionByZeroConstructionCost() {
        let inputs = CircularEconomyCalculator.CircularEconomyInputs(
            totalConstructionCost:        0,  // trigger div-by-zero guard
            repurposedMaterialCost:  10_000,
            co2Embodied:              1_000,
            kgMaterialsUsed:         10_000,
            kgMaterialsReturned:      8_000,
            kgMaterialsDisposed:      2_000,
            vendorCount:                  3,
            averageHourlyRate:           35.0
        )
        let metrics = CircularEconomyCalculator.calculate(inputs: inputs)

        XCTAssertFalse(metrics.materialCircularityScore.isNaN,
                       "materialCircularityScore must not be NaN when totalConstructionCost is 0")
        XCTAssertEqual(metrics.materialCircularityScore,
                       (0 + 80.0) / 2,    // repurposedPct = 0 (guarded), recoveryRatio = 80
                       accuracy: 0.01)
    }

    // MARK: - Case 5: Perfect Score — all inputs ideal

    func testPerfectScore() {
        let inputs = CircularEconomyCalculator.CircularEconomyInputs(
            totalConstructionCost:  1_000_000,
            repurposedMaterialCost: 1_000_000,  // 100%
            co2Embodied:               10_000,  // carbonIntensity = 0.1 → score = 100
            kgMaterialsUsed:          100_000,
            kgMaterialsReturned:      100_000,  // 100% recovery
            kgMaterialsDisposed:            0,
            vendorCount:                   20,
            averageHourlyRate:            60.0
        )
        let metrics = CircularEconomyCalculator.calculate(inputs: inputs)

        XCTAssertEqual(metrics.materialCircularityScore, 100.0, accuracy: 0.01)
        XCTAssertEqual(metrics.carbonEfficiencyScore,    100.0, accuracy: 0.01)
        XCTAssertEqual(metrics.overallCEScore,           100.0, accuracy: 0.01)
    }
}
