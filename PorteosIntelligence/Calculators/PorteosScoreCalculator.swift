import Foundation

struct PorteosScoreCalculator {

    // MARK: - Inputs

    struct PorteosInputs {
        var capRate:           Double  // e.g. 5.5 for 5.5%
        var revPAR:            Double  // in euros
        var designScore:       Double = 0  // 0–100 (overallDesignScore from DesignCalculator)
        var circularScore:     Double = 0  // 0–100 (overallCircularScore from CircularCalculator)
        // RevPAR is efficiency-based (revenue per available room) and does not scale with
        // room count by design. totalRevenue captures the absolute scale of the operation.
        var totalRevenue:      Double = 0  // in euros — used for scale bonus
        var weightRealEstate:  Double  // 0–100
        var weightHospitality: Double  // 0–100
        var weightDesign:      Double = 0  // 0–100
        var weightCircular:    Double = 0  // 0–100
    }

    // MARK: - Outputs

    struct PorteosMetrics {
        var finalScore: Double  // 0–100
        var scoreGrade: String  // "A" | "B" | "C" | "D" | "F"
    }

    // MARK: - Calculate

    static func calculate(inputs: PorteosInputs) -> PorteosMetrics {
        // Normalize real estate and hospitality metrics to a 0–100 scale
        let normalizedCapRate = min(max((inputs.capRate / 10.0)   * 100, 0), 100)
        let normalizedRevPAR  = min(max((inputs.revPAR  / 200.0)  * 100, 0), 100)

        // Design and Circular scores are already on a 0–100 scale
        var finalScore = (normalizedCapRate      * (inputs.weightRealEstate  / 100))
                       + (normalizedRevPAR       * (inputs.weightHospitality / 100))
                       + (inputs.designScore     * (inputs.weightDesign      / 100))
                       + (inputs.circularScore   * (inputs.weightCircular    / 100))

        // Scale bonus: RevPAR is an efficiency ratio and cannot reflect the absolute size
        // of an operation — two deals can share the same RevPAR regardless of room count.
        // totalRevenue captures portfolio scale and rewards larger operations.
        if inputs.totalRevenue > 5_000_000 {
            finalScore += 10
        } else if inputs.totalRevenue > 1_000_000 {
            finalScore += 5
        }
        finalScore = min(finalScore, 100)

        return PorteosMetrics(
            finalScore: finalScore,
            scoreGrade: grade(for: finalScore)
        )
    }

    // MARK: - Grade

    private static func grade(for score: Double) -> String {
        switch score {
        case 80...: return "A"
        case 60...: return "B"
        case 40...: return "C"
        case 20...: return "D"
        default:    return "F"
        }
    }
}
