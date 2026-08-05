import Foundation

struct PorteosScoreCalculator {

    // MARK: - Inputs

    struct PorteosInputs {
        var capRate:           Double  // e.g. 5.5 for 5.5%
        var revPAR:            Double  // in euros
        var designScore:       Double = 0   // 0–100
        var circularScore:     Double = 0   // 0–100
        var totalRevenue:      Double = 0   // absolute scale bonus
        var dscr:              Double = 0   // Debt Service Coverage Ratio (NOI / ADS)
        var ltv:               Double = 0   // Loan-to-Value %
        var cashOnCash:        Double = 0   // Cash-on-Cash return %
        var weightRealEstate:  Double       // 0–100
        var weightHospitality: Double       // 0–100
        var weightDesign:      Double = 0   // 0–100
        var weightCircular:    Double = 0   // 0–100
        // Regulatory advisory inputs
        var heritageOrListed:  Bool   = false
        var planningStatus:    String = "unknown"
        var strLicenceStatus:  String = "unknown"
    }

    // MARK: - Outputs

    struct PorteosMetrics {
        var finalScore: Double  // 0–100
        var scoreGrade: String  // "A" | "B" | "C" | "D" | "F"
    }

    // MARK: - Calculate

    static func calculate(inputs: PorteosInputs) -> PorteosMetrics {
        // ── Detect which profiles are actually populated ───────────────────────
        // An unfilled profile (all metrics at zero/default) should not penalise
        // the score. Its weight is redistributed to the real estate component
        // so the deal is judged only on what data exists.
        let hospPopulated    = inputs.revPAR > 0
        let designPopulated  = inputs.designScore > 0
        let circularPopulated = inputs.circularScore > 0

        let hospWeight    = hospPopulated     ? inputs.weightHospitality : 0
        let designWeight  = designPopulated   ? inputs.weightDesign      : 0
        let circularWeight = circularPopulated ? inputs.weightCircular    : 0

        // Redistribute unused weights back to real estate so total always = 100
        let unusedWeight  = (inputs.weightHospitality - hospWeight)
                          + (inputs.weightDesign      - designWeight)
                          + (inputs.weightCircular    - circularWeight)
        let reWeight      = inputs.weightRealEstate + unusedWeight

        // ── Base score from yield + active profile dimensions ─────────────────
        let normalizedCapRate = min(max((inputs.capRate / 10.0) * 100, 0), 100)
        let normalizedRevPAR  = min(max((inputs.revPAR  / 200.0) * 100, 0), 100)

        var finalScore = (normalizedCapRate       * (reWeight       / 100))
                       + (normalizedRevPAR        * (hospWeight     / 100))
                       + (inputs.designScore      * (designWeight   / 100))
                       + (inputs.circularScore    * (circularWeight / 100))

        // ── Revenue scale bonus ───────────────────────────────────────────────
        if inputs.totalRevenue > 5_000_000 { finalScore += 10 }
        else if inputs.totalRevenue > 1_000_000 { finalScore += 5 }

        // ── DSCR safety floor — most important leverage risk signal ───────────
        // Below 1.0: NOI cannot service the debt → deal is operationally insolvent
        if inputs.dscr > 0 {
            switch inputs.dscr {
            case ..<0.8:   finalScore -= 25  // severe: loan payments destroy all income
            case 0.8..<1.0: finalScore -= 15  // dangerous: cannot service debt from NOI
            case 1.0..<1.1: finalScore -= 5   // tight: no buffer
            case 2.0...:   finalScore += 8   // strong: plenty of coverage
            default: break
            }
        }

        // ── LTV leverage penalty ──────────────────────────────────────────────
        if inputs.ltv > 0 {
            switch inputs.ltv {
            case 90...:    finalScore -= 20  // over-leveraged, high distress risk
            case 80..<90:  finalScore -= 10  // aggressive, limited equity buffer
            case 65..<80:  break             // acceptable range
            case ..<65:    finalScore += 5   // conservative equity position
            default: break
            }
        }

        // ── Cash-on-cash return reward ────────────────────────────────────────
        if inputs.cashOnCash > 0 {
            switch inputs.cashOnCash {
            case 20...:    finalScore += 10
            case 12..<20:  finalScore += 5
            case 8..<12:   finalScore += 2
            default: break
            }
        }

        // ── Regulatory advisory adjustments ───────────────────────────────────
        if inputs.heritageOrListed {
            finalScore -= 5   // unknown renovation constraints
            if inputs.planningStatus == "none" { finalScore -= 3 }  // stacked risk
        }
        if inputs.strLicenceStatus == "none" { finalScore -= 4 }
        if inputs.planningStatus == "approved" { finalScore += 4 }
        if inputs.strLicenceStatus == "approved" { finalScore += 5 }

        finalScore = min(max(finalScore, 0), 100)

        return PorteosMetrics(finalScore: finalScore, scoreGrade: grade(for: finalScore))
    }

    // MARK: - Grade
    // Aligned with VibeGrade thresholds — single scale used everywhere in the app.

    private static func grade(for score: Double) -> String {
        switch score {
        case 80...: return "A"
        case 65...: return "B"   // matches VibeGrade.from() — was 60, now 65
        case 50...: return "C"   // matches VibeGrade.from() — was 40, now 50
        case 35...: return "D"   // matches VibeGrade.from() — was 20, now 35
        default:    return "F"
        }
    }
}
