import XCTest
@testable import PorteosIntelligence

final class RealEstateCalculatorTests: XCTestCase {

    // MARK: - Unit Price

    func testPricePerSqft() {
        let result = RealEstateCalculator.pricePerSqft(
            purchasePrice: 500_000,
            totalArea: 2_000
        )
        XCTAssertEqual(result, 250.0, accuracy: 0.01)
    }

    func testPricePerSqftZeroArea() {
        // Edge case: division by zero must return 0, not crash/NaN
        let result = RealEstateCalculator.pricePerSqft(
            purchasePrice: 500_000,
            totalArea: 0
        )
        XCTAssertEqual(result, 0.0)
    }
}
