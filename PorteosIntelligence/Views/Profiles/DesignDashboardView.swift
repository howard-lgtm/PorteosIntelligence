import SwiftUI
import SwiftData

// MARK: - DesignDashboardView
// V2.06 — Figma module order + inset grids, no mock sparklines.

struct DesignDashboardView: View {

    @Bindable var deal: PropertyDeal

    private var accent: Color { ProfileType.design.accentColor }

    private var dealDisplayName: String {
        deal.propertyName.isEmpty ? "Untitled Deal" : deal.propertyName
    }

    private var porteosScore: PorteosScoreCalculator.PorteosMetrics {
        PropertyDealViewModel(deal: deal).porteosScore
    }

    private var hasData: Bool { deal.designGFA > 0 || deal.designNIA > 0 || deal.designSpaceUtilization > 0 }

    private var metrics: DesignCalculator.FullMetrics {
        DesignCalculator.calculateFull(inputs: DesignCalculator.FullInputs(
            gfa:               deal.designGFA,
            nia:               deal.designNIA,
            circulationPct:    deal.designCirculationPct,
            spaceUtilization:  deal.designSpaceUtilization,
            daylighting:       deal.designDaylighting,
            co2ppm:            deal.designCO2ppm,
            ach:               deal.designACH,
            thermalComfort:    deal.designThermalComfort,
            acousticComfort:   deal.designAcousticComfort,
            biophilicCount:    deal.designBiophilicCount,
            greenWallM2:       deal.designGreenWallM2,
            viewsToNaturePct:  deal.designViewsToNaturePct,
            naturalMaterialsPct: deal.designNaturalMaterialsPct,
            movablePartitionPct: deal.designMovablePartitionPct,
            multiUseSpaces:    deal.designMultiUseSpaces,
            adaptabilityScore: deal.designAdaptabilityScore
        ))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            DashboardCLIHeader(profile: .design, dealName: dealDisplayName)
            TerminalStructuralDivider()

            if hasData {
                ScrollView {
                    VStack(alignment: .leading, spacing: DesignTokens.blockSpacing) {
                        DashboardHeroScore(
                            score: porteosScore.finalScore,
                            grade: porteosScore.scoreGrade,
                            dealName: dealDisplayName,
                            profile: .design
                        )
                        ValidationLogModule(
                            messages: DataValidator.validate(deal: deal),
                            accentColor: accent
                        )
                        MarketTrendGrid(deal: deal, profileKey: "design", accent: accent)
                        module01SpaceEfficiency
                        module02Wellness
                        module03Biophilic
                        module04Adaptability
                        DesignSensitivityBlock(deal: deal)
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

    private var module01SpaceEfficiency: some View {
        TerminalBlock(command: "01 // SPACE_EFFICIENCY", accentColor: accent) {
            TerminalMetricGrid(fixedColumnCount: 2) {
                TerminalMetricCell(label: "Gross Floor Area (GFA)", value: m2(metrics.gfa))
                TerminalMetricCell(label: "Net Internal Area (NIA)", value: m2(metrics.nia))
                TerminalMetricCell(label: "Net-to-Gross Ratio",
                                   value: pct(metrics.netToGrossRatio),
                                   state: netToGrossState(metrics.netToGrossRatio))
                TerminalMetricCell(label: "Circulation",
                                   value: pct(metrics.circulationPct),
                                   state: metrics.circulationPct > 20 ? .warning : .neutral)
                TerminalMetricCell(label: "Space Utilization Rate",
                                   value: pct(metrics.spaceUtilization),
                                   state: metrics.spaceUtilization >= 90 ? .optimal : .neutral)
            }
        }
    }

    private var module02Wellness: some View {
        TerminalBlock(command: "02 // WELLNESS_METRICS", accentColor: accent) {
            TerminalMetricGrid(fixedColumnCount: 2) {
                TerminalMetricCell(label: "Daylighting Coverage",
                                   value: pct(metrics.daylighting),
                                   state: metrics.daylighting >= 80 ? .optimal : .neutral)
                TerminalMetricCell(label: "CO2 Levels",
                                   value: "\(metrics.co2ppm.formatted(.number.precision(.fractionLength(0)))) ppm",
                                   state: co2State(metrics.co2ppm))
                TerminalMetricCell(label: "Air Changes Per Hour",
                                   value: "\(metrics.ach.formatted(.number.precision(.fractionLength(1)))) ACH",
                                   state: metrics.ach >= 4 ? .optimal : .neutral)
                TerminalMetricCell(label: "Thermal Comfort Score",
                                   value: pct(metrics.thermalComfort),
                                   state: metrics.thermalComfort >= 90 ? .optimal : .neutral)
                TerminalMetricCell(label: "Acoustic Comfort Score",
                                   value: pct(metrics.acousticComfort),
                                   state: metrics.acousticComfort >= 85 ? .optimal : .neutral)
            }
        }
    }

    private var module03Biophilic: some View {
        TerminalBlock(command: "03 // BIOPHILIC_ELEMENTS", accentColor: accent) {
            TerminalMetricGrid(fixedColumnCount: 2) {
                TerminalMetricCell(label: "Biophilic Elements", value: "\(metrics.biophilicCount)")
                TerminalMetricCell(label: "Green Wall Coverage", value: m2(metrics.greenWallM2))
                TerminalMetricCell(label: "Views to Nature",
                                   value: pct(metrics.viewsToNaturePct),
                                   state: metrics.viewsToNaturePct >= 70 ? .optimal : .neutral)
                TerminalMetricCell(label: "Natural Materials",
                                   value: pct(metrics.naturalMaterialsPct),
                                   state: metrics.naturalMaterialsPct >= 40 ? .optimal : .neutral)
            }
        }
    }

    private var module04Adaptability: some View {
        TerminalBlock(command: "04 // ADAPTABILITY", accentColor: accent) {
            TerminalMetricGrid(fixedColumnCount: 2) {
                TerminalMetricCell(label: "Movable Partition",
                                   value: pct(metrics.movablePartitionPct),
                                   state: metrics.movablePartitionPct >= 30 ? .optimal : .neutral)
                TerminalMetricCell(label: "Multi-Use Spaces", value: "\(metrics.multiUseSpaces)")
                TerminalMetricCell(label: "Adaptability Score",
                                   value: "\(metrics.adaptabilityScore.formatted(.number.precision(.fractionLength(0))))/100",
                                   state: adaptabilityState(metrics.adaptabilityScore))
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            VStack(spacing: 8) {
                Text("porteos@system ~ % ls ./design_data")
                    .porteosCliPrompt()
                    .foregroundStyle(DesignTokens.textDim)
                Text("No design data available")
                    .porteosRowValue()
                    .foregroundStyle(DesignTokens.textSecondary)
                Text("Click [ ./EDIT_DEAL ] to add design metrics")
                    .porteosCliPrompt()
                    .foregroundStyle(DesignTokens.textSecondary)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func m2(_ v: Double) -> String {
        UnitSystemService.shared.formatArea(v, country: deal.locationCountry)
    }

    private func pct(_ v: Double, dp: Int = 1) -> String {
        "\(v.formatted(.number.precision(.fractionLength(dp))))%"
    }

    private func netToGrossState(_ v: Double) -> MetricState {
        if v >= 80 { return .optimal }
        if v >= 70 { return .warning }
        return .danger
    }

    private func co2State(_ v: Double) -> MetricState {
        if v < 800  { return .optimal }
        if v <= 1000 { return .warning }
        return .danger
    }

    private func adaptabilityState(_ v: Double) -> MetricState {
        if v >= 75 { return .optimal }
        if v >= 50 { return .warning }
        return v < 25 ? .danger : .neutral
    }
}

#Preview("Full Data") {
    let deal = PropertyDeal(
        propertyName:          "Lisbon HQ — Floor 3",
        designGFA:             2_400,
        designNIA:             1_980,
        designCirculationPct:  17.5,
        designSpaceUtilization: 92,
        designDaylighting:     84,
        designCO2ppm:          720,
        designACH:             5.2,
        designThermalComfort:  91,
        designAcousticComfort: 88,
        designBiophilicCount:  14,
        designGreenWallM2:     48,
        designViewsToNaturePct: 74,
        designNaturalMaterialsPct: 42,
        designMovablePartitionPct: 35,
        designMultiUseSpaces:  6,
        designAdaptabilityScore: 82
    )
    return ScrollView {
        DesignDashboardView(deal: deal)
    }
    .frame(width: 660, height: 900)
    .background(DesignTokens.canvasBase)
}

#Preview("Empty State") {
    DesignDashboardView(deal: PropertyDeal())
        .frame(width: 660, height: 400)
        .background(DesignTokens.canvasBase)
}
