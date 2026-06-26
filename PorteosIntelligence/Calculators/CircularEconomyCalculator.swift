import Foundation

struct CircularEconomyCalculator {

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Legacy API (used by PropertyDealViewModel / PorteosScoreCalculator)
    // ─────────────────────────────────────────────────────────────────────────

    struct CircularEconomyInputs {
        var totalConstructionCost:  Double
        var repurposedMaterialCost: Double
        var co2Embodied:            Double  // kg CO2e
        var kgMaterialsUsed:        Double
        var kgMaterialsReturned:    Double
        var kgMaterialsDisposed:    Double
        var vendorCount:            Int
        var averageHourlyRate:      Double
    }

    struct CircularEconomyMetrics {
        var materialCircularityScore: Double  // 0–100
        var carbonEfficiencyScore:    Double  // 0–100
        var overallCEScore:           Double  // 0–100
    }

    static func calculate(inputs: CircularEconomyInputs) -> CircularEconomyMetrics {
        let repurposedPct: Double = inputs.totalConstructionCost > 0
            ? clamp((inputs.repurposedMaterialCost / inputs.totalConstructionCost) * 100) : 0
        let totalTracked = inputs.kgMaterialsReturned + inputs.kgMaterialsDisposed
        let recoveryRatio: Double = totalTracked > 0
            ? clamp((inputs.kgMaterialsReturned / totalTracked) * 100) : 0
        let matScore = (repurposedPct + recoveryRatio) / 2
        let carbonScore: Double = inputs.kgMaterialsUsed > 0
            ? max(0, 100 - ((inputs.co2Embodied / inputs.kgMaterialsUsed - 0.1) / 0.9 * 100)) : 0
        return CircularEconomyMetrics(
            materialCircularityScore: matScore,
            carbonEfficiencyScore:    carbonScore,
            overallCEScore:           (matScore * 0.7) + (carbonScore * 0.3)
        )
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Full API (used by CircularEconomyDashboardView – all 3 modules)
    // ─────────────────────────────────────────────────────────────────────────

    struct FullInputs {
        // Core mass tracking (existing deal fields)
        var totalConstructionCost:  Double
        var repurposedMaterialCost: Double
        var co2Embodied:            Double   // kg CO2e (embodied)
        var kgMaterialsUsed:        Double
        var kgMaterialsReturned:    Double
        var kgMaterialsDisposed:    Double
        // Additional fields
        var recycledContentPct:     Double   // %
        var renewableContentPct:    Double   // %
        var wasteGenerated:         Double   // kg
        var operationalCarbon:      Double   // tCO2e/year
        var buildingAreaM2:         Double   // m²
        var waterRecyclingRate:     Double   // %
    }

    struct FullMetrics {
        // Module 01 – Material Flow
        var recycledContentPct:    Double
        var renewableContentPct:   Double
        var virginMaterialInput:   Double   // kg (derived)
        var wasteGenerated:        Double   // kg
        var recoveryRate:          Double   // % (derived)
        // Module 02 – Carbon Lifecycle
        var embodiedCarbon:        Double   // tCO2e (converted from kg)
        var operationalCarbon:     Double   // tCO2e/year
        var totalLifecycle30Y:     Double   // tCO2e
        var carbonIntensity:       Double   // tCO2e/m²
        var mciScore:              Double   // 0–1 Material Circularity Index
        // Module 03 – Resource Efficiency
        var waterRecyclingRate:    Double   // %
        var materialCircularityScore: Double // 0–100
        var carbonEfficiencyScore: Double   // 0–100
        var overallCEScore:        Double   // 0–100
    }

    static func calculateFull(inputs: FullInputs) -> FullMetrics {

        // ── Module 01 – Material Flow ─────────────────────────────────────────
        let totalTracked = inputs.kgMaterialsReturned + inputs.kgMaterialsDisposed
        let recoveryRate = totalTracked > 0
            ? clamp((inputs.kgMaterialsReturned / totalTracked) * 100) : 0
        let recycledKg  = inputs.kgMaterialsUsed * (inputs.recycledContentPct / 100)
        let renewableKg = inputs.kgMaterialsUsed * (inputs.renewableContentPct / 100)
        let virginInput = max(0, inputs.kgMaterialsUsed - recycledKg - renewableKg)

        // ── Module 02 – Carbon Lifecycle ─────────────────────────────────────
        let embodiedTCO2e   = inputs.co2Embodied / 1_000
        let total30Y        = embodiedTCO2e + (inputs.operationalCarbon * 30)
        let carbonIntensity = inputs.buildingAreaM2 > 0
            ? total30Y / inputs.buildingAreaM2 : 0
        // MCI: 1 − (disposed / used); higher = more circular
        let mciScore = inputs.kgMaterialsUsed > 0
            ? clamp01(1.0 - (inputs.kgMaterialsDisposed / inputs.kgMaterialsUsed)) : 0

        // ── Module 03 – Resource Efficiency / Scores ─────────────────────────
        let repurposedPct = inputs.totalConstructionCost > 0
            ? clamp((inputs.repurposedMaterialCost / inputs.totalConstructionCost) * 100) : 0
        let matScore      = (repurposedPct + recoveryRate) / 2
        let carbonScore: Double = inputs.kgMaterialsUsed > 0
            ? max(0, 100 - ((inputs.co2Embodied / inputs.kgMaterialsUsed - 0.1) / 0.9 * 100)) : 0
        let overallCE     = (matScore * 0.7) + (carbonScore * 0.3)

        return FullMetrics(
            recycledContentPct:       inputs.recycledContentPct,
            renewableContentPct:      inputs.renewableContentPct,
            virginMaterialInput:      virginInput,
            wasteGenerated:           inputs.wasteGenerated,
            recoveryRate:             recoveryRate,
            embodiedCarbon:           embodiedTCO2e,
            operationalCarbon:        inputs.operationalCarbon,
            totalLifecycle30Y:        total30Y,
            carbonIntensity:          carbonIntensity,
            mciScore:                 mciScore,
            waterRecyclingRate:       inputs.waterRecyclingRate,
            materialCircularityScore: matScore,
            carbonEfficiencyScore:    carbonScore,
            overallCEScore:           overallCE
        )
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Helpers
    // ─────────────────────────────────────────────────────────────────────────

    private static func clamp(_ v: Double) -> Double { min(max(v, 0), 100) }
    private static func clamp01(_ v: Double) -> Double { min(max(v, 0), 1) }
}
