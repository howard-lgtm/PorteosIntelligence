import XCTest
@testable import PorteosIntelligence

final class HospitalityCalculatorTests: XCTestCase {

    // MARK: - Standard Inputs

    private let standardInputs = HospitalityCalculator.HospitalityInputs(
        roomCount:      50,
        adr:            120.0,
        occupancyRate:  75.0,
        fbRevenue:      450_000.0,
        spaRevenue:     120_000.0,
        meetingRevenue: 180_000.0,
        otherRevenue:    25_000.0,
        opExRatio:       35.0
    )

    // MARK: - Tests

    func testHospitalityCalculations() {
        let metrics = HospitalityCalculator.calculate(inputs: standardInputs)

        XCTAssertEqual(metrics.availableRoomNights, 18_250)
        XCTAssertEqual(metrics.annualRoomRevenue,   1_642_500.0, accuracy: 0.01)
        XCTAssertEqual(metrics.totalRevenue,        2_417_500.0, accuracy: 0.01)
        XCTAssertEqual(metrics.revPAR,                     90.0, accuracy: 0.01)
        XCTAssertEqual(metrics.trevPAR,                  132.46, accuracy: 0.01)
        XCTAssertEqual(metrics.gop,                 1_571_375.0, accuracy: 0.01)
        XCTAssertEqual(metrics.gopPAR,                    86.10, accuracy: 0.01)
    }

    func testZeroInputs() {
        let inputs = HospitalityCalculator.HospitalityInputs(
            roomCount:      0,
            adr:            0,
            occupancyRate:  0,
            fbRevenue:      0,
            spaRevenue:     0,
            meetingRevenue: 0,
            otherRevenue:   0,
            opExRatio:      0
        )

        let metrics = HospitalityCalculator.calculate(inputs: inputs)

        XCTAssertEqual(metrics.availableRoomNights, 0)
        XCTAssertEqual(metrics.annualRoomRevenue,   0, accuracy: 0.01)
        XCTAssertEqual(metrics.totalRevenue,        0, accuracy: 0.01)
        XCTAssertEqual(metrics.revPAR,              0, accuracy: 0.01)
        XCTAssertEqual(metrics.trevPAR,             0, accuracy: 0.01,
                       "trevPAR must be 0 (not NaN/crash) when availableRoomNights is 0")
        XCTAssertEqual(metrics.gop,                 0, accuracy: 0.01)
        XCTAssertEqual(metrics.gopPAR,              0, accuracy: 0.01,
                       "gopPAR must be 0 (not NaN/crash) when availableRoomNights is 0")
    }
}
