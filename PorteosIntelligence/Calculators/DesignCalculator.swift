import Foundation

struct DesignCalculator {

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Legacy API (used by PorteosScoreCalculator via PropertyDealViewModel)
    // ─────────────────────────────────────────────────────────────────────────

    struct DesignInputs {
        var sustainabilityScore: Double  // 0–100
        var aestheticQuality:    Double  // 0–100
        var energyEfficiency:    Double  // 0–100 (normalised kWh/m²/year)
        var buildQuality:        Double  // 0–100
    }

    struct DesignMetrics {
        var overallDesignScore:   Double  // 0–100
        var sustainabilityRating: String  // "Excellent" | "Good" | "Fair" | "Poor"
    }

    static func calculate(inputs: DesignInputs) -> DesignMetrics {
        let score = (inputs.sustainabilityScore * 0.4)
                  + (inputs.aestheticQuality   * 0.2)
                  + (inputs.energyEfficiency   * 0.3)
                  + (inputs.buildQuality       * 0.1)
        return DesignMetrics(overallDesignScore: score, sustainabilityRating: rating(for: score))
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Full API (used by DesignDashboardView – all 4 modules)
    // ─────────────────────────────────────────────────────────────────────────

    struct FullInputs {
        // Module 01 – Space Efficiency
        var gfa:               Double  // Gross Floor Area (m²)
        var nia:               Double  // Net Internal Area (m²)
        var circulationPct:    Double  // %
        var spaceUtilization:  Double  // %
        // Module 02 – Wellness
        var daylighting:       Double  // % coverage
        var co2ppm:            Double  // ppm
        var ach:               Double  // Air Changes Per Hour
        var thermalComfort:    Double  // % score
        var acousticComfort:   Double  // % score
        // Module 03 – Biophilic
        var biophilicCount:    Int
        var greenWallM2:       Double  // m²
        var viewsToNaturePct:  Double  // %
        var naturalMaterialsPct: Double // %
        // Module 04 – Adaptability
        var movablePartitionPct: Double // %
        var multiUseSpaces:    Int
        var adaptabilityScore: Double  // 0–100
    }

    struct FullMetrics {
        // Module 01
        var gfa:               Double
        var nia:               Double
        var netToGrossRatio:   Double  // % (derived)
        var circulationPct:    Double
        var spaceUtilization:  Double
        // Module 02
        var daylighting:       Double
        var co2ppm:            Double
        var ach:               Double
        var thermalComfort:    Double
        var acousticComfort:   Double
        // Module 03
        var biophilicCount:    Int
        var greenWallM2:       Double
        var viewsToNaturePct:  Double
        var naturalMaterialsPct: Double
        // Module 04
        var movablePartitionPct: Double
        var multiUseSpaces:    Int
        var adaptabilityScore: Double
    }

    static func calculateFull(inputs: FullInputs) -> FullMetrics {
        let netToGross = inputs.gfa > 0 ? (inputs.nia / inputs.gfa) * 100 : 0
        return FullMetrics(
            gfa:               inputs.gfa,
            nia:               inputs.nia,
            netToGrossRatio:   netToGross,
            circulationPct:    inputs.circulationPct,
            spaceUtilization:  inputs.spaceUtilization,
            daylighting:       inputs.daylighting,
            co2ppm:            inputs.co2ppm,
            ach:               inputs.ach,
            thermalComfort:    inputs.thermalComfort,
            acousticComfort:   inputs.acousticComfort,
            biophilicCount:    inputs.biophilicCount,
            greenWallM2:       inputs.greenWallM2,
            viewsToNaturePct:  inputs.viewsToNaturePct,
            naturalMaterialsPct: inputs.naturalMaterialsPct,
            movablePartitionPct: inputs.movablePartitionPct,
            multiUseSpaces:    inputs.multiUseSpaces,
            adaptabilityScore: inputs.adaptabilityScore
        )
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Helpers
    // ─────────────────────────────────────────────────────────────────────────

    private static func rating(for score: Double) -> String {
        switch score {
        case 80...: return "Excellent"
        case 60...: return "Good"
        case 40...: return "Fair"
        default:    return "Poor"
        }
    }
}
