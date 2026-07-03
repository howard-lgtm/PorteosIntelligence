import SwiftUI
import SwiftData

// MARK: - CircularEconomyDashboardView
// V2.06 — Figma module order + inset grids, no mock sparklines.

struct CircularEconomyDashboardView: View {

    @Bindable var deal: PropertyDeal

    private var accent: Color { ProfileType.circular.accentColor }

    private var dealDisplayName: String {
        deal.propertyName.isEmpty ? "Untitled Deal" : deal.propertyName
    }

    private var porteosScore: PorteosScoreCalculator.PorteosMetrics {
        PropertyDealViewModel(deal: deal).porteosScore
    }

    private var hasData: Bool { deal.circularKgMaterialsUsed > 0 || deal.circularRecycledContentPct > 0 || deal.circularCO2Embodied > 0 }

    private var metrics: CircularEconomyCalculator.FullMetrics {
        CircularEconomyCalculator.calculateFull(inputs: CircularEconomyCalculator.FullInputs(
            totalConstructionCost:  deal.circularTotalConstructionCost,
            repurposedMaterialCost: deal.circularRepurposedMaterialCost,
            co2Embodied:            deal.circularCO2Embodied,
            kgMaterialsUsed:        deal.circularKgMaterialsUsed,
            kgMaterialsReturned:    deal.circularKgMaterialsReturned,
            kgMaterialsDisposed:    deal.circularKgMaterialsDisposed,
            recycledContentPct:     deal.circularRecycledContentPct,
            renewableContentPct:    deal.circularRenewableContentPct,
            wasteGenerated:         deal.circularWasteGenerated,
            operationalCarbon:      deal.circularOperationalCarbon,
            buildingAreaM2:         deal.circularBuildingAreaM2,
            waterRecyclingRate:     deal.circularWaterRecyclingRate
        ))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            DashboardCLIHeader(profile: .circular, dealName: dealDisplayName)
            TerminalStructuralDivider()

            if hasData {
                ScrollView {
                    VStack(alignment: .leading, spacing: DesignTokens.blockSpacing) {
                        DashboardHeroScore(
                            score: porteosScore.finalScore,
                            grade: porteosScore.scoreGrade,
                            dealName: dealDisplayName,
                            profile: .circular
                        )
                        ValidationLogModule(
                            messages: DataValidator.validate(deal: deal),
                            accentColor: accent
                        )
                        MarketTrendGrid(deal: deal, profileKey: "circular", accent: accent)
                        module01MaterialFlow
                        module02CarbonLifecycle
                        module03ResourceEfficiency
                        CircularSensitivityBlock(deal: deal)
                    }
                    .padding(DesignTokens.blockGutter)
                }
            } else {
                emptyState
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignTokens.canvasBase)
    }

    private var module01MaterialFlow: some View {
        TerminalBlock(command: "01 // MATERIAL_FLOW_LOG", accentColor: accent) {
            TerminalMetricGrid(fixedColumnCount: 2) {
                TerminalMetricCell(label: "Recycled Content",
                                   value: pct(metrics.recycledContentPct),
                                   state: recycledState(metrics.recycledContentPct))
                TerminalMetricCell(label: "Renewable Content",
                                   value: pct(metrics.renewableContentPct),
                                   state: metrics.renewableContentPct >= 20 ? .optimal : .neutral)
                TerminalMetricCell(label: "Virgin Material Input", value: kg(metrics.virginMaterialInput))
                TerminalMetricCell(label: "Waste Generated",
                                   value: kg(metrics.wasteGenerated),
                                   state: wasteState(metrics.wasteGenerated))
                TerminalMetricCell(label: "Recovery Rate",
                                   value: pct(metrics.recoveryRate),
                                   state: metrics.recoveryRate >= 80 ? .optimal : .neutral)
            }
        }
    }

    private var module02CarbonLifecycle: some View {
        TerminalBlock(command: "02 // CARBON_LIFECYCLE_SUMMARY", accentColor: accent) {
            TerminalMetricGrid(fixedColumnCount: 2) {
                TerminalMetricCell(label: "Embodied Carbon", value: tco2e(metrics.embodiedCarbon))
                TerminalMetricCell(label: "Operational Carbon (Annual)",
                                   value: "\(tco2e(metrics.operationalCarbon))/yr")
                TerminalMetricCell(label: "Total Lifecycle Carbon (30Y)", value: tco2e(metrics.totalLifecycle30Y))
                TerminalMetricCell(label: "Carbon Intensity",
                                   value: "\(metrics.carbonIntensity.formatted(.number.precision(.fractionLength(3)))) tCO2e/m²",
                                   state: carbonIntensityState(metrics.carbonIntensity))
                TerminalMetricCell(label: "MCI Score",
                                   value: metrics.mciScore.formatted(.number.precision(.fractionLength(2))),
                                   state: mciState(metrics.mciScore))
            }
        }
    }

    private var module03ResourceEfficiency: some View {
        TerminalBlock(command: "03 // RESOURCE_EFFICIENCY", accentColor: accent) {
            TerminalMetricGrid(fixedColumnCount: 2) {
                TerminalMetricCell(label: "Water Recycling Rate",
                                   value: pct(metrics.waterRecyclingRate),
                                   state: metrics.waterRecyclingRate >= 60 ? .optimal : .neutral)
                TerminalMetricCell(label: "Material Circularity Score",
                                   value: "\(metrics.materialCircularityScore.formatted(.number.precision(.fractionLength(1))))/100")
                TerminalMetricCell(label: "Carbon Efficiency Score",
                                   value: "\(metrics.carbonEfficiencyScore.formatted(.number.precision(.fractionLength(1))))/100")
                TerminalMetricCell(label: "Overall CE Score",
                                   value: "\(metrics.overallCEScore.formatted(.number.precision(.fractionLength(1))))/100",
                                   state: ceScoreState(metrics.overallCEScore))
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            VStack(spacing: 8) {
                Text("porteos@system ~ % ls ./circular_data")
                    .font(DesignTokens.cliPromptFont())
                    .foregroundStyle(DesignTokens.textDim)
                Text("No circular economy data available")
                    .font(DesignTokens.rowValueFont())
                    .foregroundStyle(DesignTokens.textSecondary)
                Text("Click [ ./EDIT_DEAL ] to add material flow data")
                    .font(DesignTokens.cliPromptFont())
                    .foregroundStyle(DesignTokens.textSecondary)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func pct(_ v: Double, dp: Int = 1) -> String {
        "\(v.formatted(.number.precision(.fractionLength(dp))))%"
    }

    private func kg(_ v: Double) -> String {
        "\(v.formatted(.number.precision(.fractionLength(0)))) kg"
    }

    private func tco2e(_ v: Double) -> String {
        "\(v.formatted(.number.precision(.fractionLength(2)))) tCO2e"
    }

    private func recycledState(_ v: Double) -> MetricState {
        if v >= 30 { return .optimal }
        if v >= 15 { return .warning }
        return .danger
    }

    private func wasteState(_ v: Double) -> MetricState {
        guard deal.circularKgMaterialsUsed > 0 else { return .neutral }
        return (v / deal.circularKgMaterialsUsed) > 0.10 ? .danger : .neutral
    }

    private func carbonIntensityState(_ v: Double) -> MetricState {
        if v < 0.1  { return .optimal }
        if v <= 0.3 { return .warning }
        return .danger
    }

    private func mciState(_ v: Double) -> MetricState {
        if v >= 0.8 { return .optimal }
        if v >= 0.6 { return .warning }
        return .danger
    }

    private func ceScoreState(_ v: Double) -> MetricState {
        if v >= 70 { return .optimal }
        if v >= 50 { return .warning }
        return v < 30 ? .danger : .neutral
    }
}

#Preview("Full Data") {
    let deal = PropertyDeal(
        propertyName:               "Eco Campus — Phase 1",
        circularTotalConstructionCost:  4_200_000,
        circularRepurposedMaterialCost: 1_260_000,
        circularCO2Embodied:            850_000,
        circularKgMaterialsUsed:        2_400_000,
        circularKgMaterialsReturned:    1_800_000,
        circularKgMaterialsDisposed:    120_000,
        circularRecycledContentPct:     35,
        circularRenewableContentPct:    22,
        circularWasteGenerated:         180_000,
        circularOperationalCarbon:      42,
        circularBuildingAreaM2:         8_500,
        circularWaterRecyclingRate:     68
    )
    return ScrollView {
        CircularEconomyDashboardView(deal: deal)
    }
    .frame(width: 720, height: 800)
    .background(DesignTokens.canvasBase)
}

#Preview("Empty State") {
    CircularEconomyDashboardView(deal: PropertyDeal())
        .frame(width: 720, height: 400)
        .background(DesignTokens.canvasBase)
}
