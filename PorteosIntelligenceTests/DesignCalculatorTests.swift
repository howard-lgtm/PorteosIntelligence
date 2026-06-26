import XCTest
@testable import PorteosIntelligence

final class DesignCalculatorTests: XCTestCase {

    // MARK: - Standard Inputs

    func testDesignCalculations() {
        // (85 × 0.4) + (75 × 0.2) + (90 × 0.3) + (80 × 0.1)
        // = 34.0 + 15.0 + 27.0 + 8.0 = 84.0
        let inputs = DesignCalculator.DesignInputs(
            sustainabilityScore: 85,
            aestheticQuality:    75,
            energyEfficiency:    90,
            buildQuality:        80
        )
        let metrics = DesignCalculator.calculate(inputs: inputs)

        XCTAssertEqual(metrics.overallDesignScore,   84.0, accuracy: 0.01)
        XCTAssertEqual(metrics.sustainabilityRating, "Excellent")
    }

    // MARK: - Low Scores → "Poor"

    func testLowScores() {
        // (30 × 0.4) + (30 × 0.2) + (30 × 0.3) + (30 × 0.1) = 30.0
        let inputs = DesignCalculator.DesignInputs(
            sustainabilityScore: 30,
            aestheticQuality:    30,
            energyEfficiency:    30,
            buildQuality:        30
        )
        let metrics = DesignCalculator.calculate(inputs: inputs)

        XCTAssertEqual(metrics.overallDesignScore,   30.0, accuracy: 0.01)
        XCTAssertEqual(metrics.sustainabilityRating, "Poor")
    }

    // MARK: - Grade Boundaries

    func testRatingBoundaries() {
        // Exactly 80 → "Excellent"
        let excellent = DesignCalculator.DesignInputs(
            sustainabilityScore: 80, aestheticQuality: 80,
            energyEfficiency: 80,   buildQuality: 80
        )
        XCTAssertEqual(DesignCalculator.calculate(inputs: excellent).sustainabilityRating, "Excellent")

        // Exactly 60 → "Good"
        let good = DesignCalculator.DesignInputs(
            sustainabilityScore: 60, aestheticQuality: 60,
            energyEfficiency: 60,   buildQuality: 60
        )
        XCTAssertEqual(DesignCalculator.calculate(inputs: good).sustainabilityRating, "Good")

        // Exactly 40 → "Fair"
        let fair = DesignCalculator.DesignInputs(
            sustainabilityScore: 40, aestheticQuality: 40,
            energyEfficiency: 40,   buildQuality: 40
        )
        XCTAssertEqual(DesignCalculator.calculate(inputs: fair).sustainabilityRating, "Fair")

        // Just below 40 → "Poor"
        let poor = DesignCalculator.DesignInputs(
            sustainabilityScore: 39, aestheticQuality: 39,
            energyEfficiency: 39,   buildQuality: 39
        )
        XCTAssertEqual(DesignCalculator.calculate(inputs: poor).sustainabilityRating, "Poor")
    }

    // MARK: - Zero Inputs → no crash, score 0

    func testZeroInputs() {
        let inputs = DesignCalculator.DesignInputs(
            sustainabilityScore: 0, aestheticQuality: 0,
            energyEfficiency: 0,   buildQuality: 0
        )
        let metrics = DesignCalculator.calculate(inputs: inputs)

        XCTAssertEqual(metrics.overallDesignScore,   0.0, accuracy: 0.01)
        XCTAssertEqual(metrics.sustainabilityRating, "Poor")
    }

    // MARK: - Perfect Score → 100, "Excellent"

    func testPerfectInputs() {
        let inputs = DesignCalculator.DesignInputs(
            sustainabilityScore: 100, aestheticQuality: 100,
            energyEfficiency: 100,   buildQuality: 100
        )
        let metrics = DesignCalculator.calculate(inputs: inputs)

        XCTAssertEqual(metrics.overallDesignScore,   100.0, accuracy: 0.01)
        XCTAssertEqual(metrics.sustainabilityRating, "Excellent")
    }
}
