import XCTest
@testable import PorteosIntelligence

final class PorteosScoreCalculatorTests: XCTestCase {

    // MARK: - 50/50 Weights, moderate inputs → ~50, Grade "C"

    func testBalancedWeights() {
        let inputs = PorteosScoreCalculator.PorteosInputs(
            capRate:           5.0,
            revPAR:            100.0,
            weightRealEstate:  50.0,
            weightHospitality: 50.0
        )
        let metrics = PorteosScoreCalculator.calculate(inputs: inputs)

        XCTAssertEqual(metrics.finalScore, 50.0, accuracy: 0.01)
        XCTAssertEqual(metrics.scoreGrade, "C")
    }

    // MARK: - 100% Real Estate, perfect cap rate → 100, Grade "A"

    func testPureRealEstatePerfect() {
        let inputs = PorteosScoreCalculator.PorteosInputs(
            capRate:           10.0,
            revPAR:            0.0,
            weightRealEstate:  100.0,
            weightHospitality: 0.0
        )
        let metrics = PorteosScoreCalculator.calculate(inputs: inputs)

        XCTAssertEqual(metrics.finalScore, 100.0, accuracy: 0.01)
        XCTAssertEqual(metrics.scoreGrade, "A")
    }

    // MARK: - 100% Hospitality, perfect RevPAR → 100, Grade "A"

    func testPureHospitalityPerfect() {
        let inputs = PorteosScoreCalculator.PorteosInputs(
            capRate:           0.0,
            revPAR:            200.0,
            weightRealEstate:  0.0,
            weightHospitality: 100.0
        )
        let metrics = PorteosScoreCalculator.calculate(inputs: inputs)

        XCTAssertEqual(metrics.finalScore, 100.0, accuracy: 0.01)
        XCTAssertEqual(metrics.scoreGrade, "A")
    }

    // MARK: - All zeros → 0, Grade "F"

    func testAllZeros() {
        let inputs = PorteosScoreCalculator.PorteosInputs(
            capRate:           0.0,
            revPAR:            0.0,
            weightRealEstate:  0.0,
            weightHospitality: 0.0
        )
        let metrics = PorteosScoreCalculator.calculate(inputs: inputs)

        XCTAssertEqual(metrics.finalScore, 0.0, accuracy: 0.01)
        XCTAssertEqual(metrics.scoreGrade, "F")
    }

    // MARK: - Grade boundary checks

    func testGradeBoundaries() {
        // Exactly 80 → "A"
        let a = PorteosScoreCalculator.PorteosInputs(
            capRate: 8.0, revPAR: 0, weightRealEstate: 100, weightHospitality: 0)
        XCTAssertEqual(PorteosScoreCalculator.calculate(inputs: a).scoreGrade, "A")

        // Exactly 60 → "B"
        let b = PorteosScoreCalculator.PorteosInputs(
            capRate: 6.0, revPAR: 0, weightRealEstate: 100, weightHospitality: 0)
        XCTAssertEqual(PorteosScoreCalculator.calculate(inputs: b).scoreGrade, "B")

        // Exactly 40 → "C"
        let c = PorteosScoreCalculator.PorteosInputs(
            capRate: 4.0, revPAR: 0, weightRealEstate: 100, weightHospitality: 0)
        XCTAssertEqual(PorteosScoreCalculator.calculate(inputs: c).scoreGrade, "C")

        // Exactly 20 → "D"
        let d = PorteosScoreCalculator.PorteosInputs(
            capRate: 2.0, revPAR: 0, weightRealEstate: 100, weightHospitality: 0)
        XCTAssertEqual(PorteosScoreCalculator.calculate(inputs: d).scoreGrade, "D")

        // Just below 20 → "F"
        let f = PorteosScoreCalculator.PorteosInputs(
            capRate: 1.9, revPAR: 0, weightRealEstate: 100, weightHospitality: 0)
        XCTAssertEqual(PorteosScoreCalculator.calculate(inputs: f).scoreGrade, "F")
    }

    // MARK: - Normalisation caps at 100 (inputs beyond perfect)

    func testNormalisationClamp() {
        let inputs = PorteosScoreCalculator.PorteosInputs(
            capRate:           20.0,   // > 10%, should clamp to 100
            revPAR:            500.0,  // > €200, should clamp to 100
            weightRealEstate:  50.0,
            weightHospitality: 50.0
        )
        let metrics = PorteosScoreCalculator.calculate(inputs: inputs)

        XCTAssertEqual(metrics.finalScore, 100.0, accuracy: 0.01)
        XCTAssertEqual(metrics.scoreGrade, "A")
    }
}
