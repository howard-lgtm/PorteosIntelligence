import SwiftUI
import SwiftData

// MARK: - CircularEconomyDashboardView

struct CircularEconomyDashboardView: View {

    @Bindable var deal: PropertyDeal

    // MARK: Tokens

    private let shellBg       = Color(hex: "#0F1115")
    private let shellSurface  = Color(hex: "#1A1D24")
    private let shellElevated = Color(hex: "#23262E")
    private let shellBorder   = Color(hex: "#2E333F")
    private let accentBlue    = Color(hex: "#3B82F6")
    private let textPrimary   = Color(hex: "#F8F9FA")
    private let textSecondary = Color(hex: "#94A3B8")
    private let textTertiary  = Color(hex: "#64748B")

    // MARK: Computed

    private var hasData: Bool { deal.circularKgMaterialsUsed > 0 }

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

    // MARK: Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            cliHeader
            Rectangle().fill(shellBorder).frame(height: 1)

            if hasData {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        module01MaterialFlow
                        module02CarbonLifecycle
                        module03ResourceEfficiency
                    }
                    .padding(16)
                }
            } else {
                emptyState
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(shellBg)
    }

    // MARK: CLI Header

    private var cliHeader: some View {
        HStack(spacing: 0) {
            Text("porteos@system ~ % ")
                .font(.custom("JetBrains Mono", size: 11))
                .foregroundStyle(textTertiary)
            Text("profile --circular --asset=\"\(deal.propertyName.isEmpty ? "Untitled Deal" : deal.propertyName)\"")
                .font(.custom("JetBrains Mono", size: 11).weight(.bold))
                .foregroundStyle(accentBlue)
                .lineLimit(1)
            Spacer()
        }
        .padding(.horizontal, 16)
        .frame(height: 32)
        .background(shellSurface)
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: Module 01 // MATERIAL_FLOW_LOG
    // ─────────────────────────────────────────────────────────────────────────

    private var module01MaterialFlow: some View {
        TerminalBlock(command: "01 // MATERIAL_FLOW_LOG", accentColor: accentBlue, contentPadding: 0) {
            VStack(spacing: 0) {
                TerminalMetricRow(label: "Recycled Content",    value: pct(metrics.recycledContentPct),  state: recycledState(metrics.recycledContentPct))
                rowDivider
                TerminalMetricRow(label: "Renewable Content",   value: pct(metrics.renewableContentPct), state: metrics.renewableContentPct >= 20 ? .optimal : .neutral)
                rowDivider
                TerminalMetricRow(label: "Virgin Material Input", value: kg(metrics.virginMaterialInput), state: .neutral)
                rowDivider
                TerminalMetricRow(label: "Waste Generated",     value: kg(metrics.wasteGenerated),       state: wasteState(metrics.wasteGenerated))
                rowDivider
                TerminalMetricRow(label: "Recovery Rate",       value: pct(metrics.recoveryRate),        state: metrics.recoveryRate >= 80 ? .optimal : .neutral)
            }
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: Module 02 // CARBON_LIFECYCLE_SUMMARY
    // ─────────────────────────────────────────────────────────────────────────

    private var module02CarbonLifecycle: some View {
        TerminalBlock(command: "02 // CARBON_LIFECYCLE_SUMMARY", accentColor: accentBlue, contentPadding: 0) {
            VStack(spacing: 0) {
                TerminalMetricRow(label: "Embodied Carbon",          value: tco2e(metrics.embodiedCarbon),           state: .neutral)
                rowDivider
                TerminalMetricRow(label: "Operational Carbon (Annual)", value: "\(tco2e(metrics.operationalCarbon))/yr", state: .neutral)
                rowDivider
                summaryRow(label: "Total Lifecycle Carbon (30Y)",    value: tco2e(metrics.totalLifecycle30Y))
                rowDivider
                TerminalMetricRow(label: "Carbon Intensity",         value: "\(metrics.carbonIntensity.formatted(.number.precision(.fractionLength(3)))) tCO2e/m²", state: carbonIntensityState(metrics.carbonIntensity))
                rowDivider
                TerminalMetricRow(label: "MCI Score",                value: metrics.mciScore.formatted(.number.precision(.fractionLength(2))), state: mciState(metrics.mciScore))
            }
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: Module 03 // RESOURCE_EFFICIENCY
    // ─────────────────────────────────────────────────────────────────────────

    private var module03ResourceEfficiency: some View {
        TerminalBlock(command: "03 // RESOURCE_EFFICIENCY", accentColor: accentBlue, contentPadding: 0) {
            VStack(spacing: 0) {
                TerminalMetricRow(label: "Water Recycling Rate",       value: pct(metrics.waterRecyclingRate),       state: metrics.waterRecyclingRate >= 60 ? .optimal : .neutral)
                rowDivider
                TerminalMetricRow(label: "Material Circularity Score", value: "\(metrics.materialCircularityScore.formatted(.number.precision(.fractionLength(1))))/100", state: .neutral)
                rowDivider
                TerminalMetricRow(label: "Carbon Efficiency Score",    value: "\(metrics.carbonEfficiencyScore.formatted(.number.precision(.fractionLength(1))))/100",    state: .neutral)
                rowDivider
                summaryRow(label: "Overall CE Score", value: "\(metrics.overallCEScore.formatted(.number.precision(.fractionLength(1))))/100", state: ceScoreState(metrics.overallCEScore))
            }
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: Empty State
    // ─────────────────────────────────────────────────────────────────────────

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            VStack(spacing: 8) {
                Text("porteos@system ~ % ls ./circular_data")
                    .font(.custom("JetBrains Mono", size: 11))
                    .foregroundStyle(textTertiary)
                Text("No circular economy data available")
                    .font(.custom("JetBrains Mono", size: 14))
                    .foregroundStyle(textSecondary)
                Text("Click [ ./EDIT_DEAL ] to add material flow data")
                    .font(.custom("JetBrains Mono", size: 11))
                    .foregroundStyle(textSecondary)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: Shared Components
    // ─────────────────────────────────────────────────────────────────────────

    private func summaryRow(label: String, value: String, state: MetricState = .neutral) -> some View {
        let valueColor: Color = {
            switch state {
            case .optimal:           return Color(hex: "#10B981")
            case .warning:           return Color(hex: "#F59E0B")
            case .danger, .critical: return Color(hex: "#EF4444")
            default:                 return textPrimary
            }
        }()
        return HStack(spacing: 0) {
            Text(label.uppercased())
                .font(.custom("Inter", size: 11).weight(.bold))
                .tracking(0.08)
                .foregroundStyle(textSecondary)
            Spacer()
            Text(value)
                .font(.custom("JetBrains Mono", size: 16).weight(.bold))
                .monospacedDigit()
                .foregroundStyle(valueColor)
        }
        .padding(.horizontal, 12)
        .frame(height: 36)
        .background(shellElevated)
    }

    private var rowDivider: some View {
        Rectangle().fill(shellBorder).frame(height: 1)
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: Formatters
    // ─────────────────────────────────────────────────────────────────────────

    private func pct(_ v: Double, dp: Int = 1) -> String {
        "\(v.formatted(.number.precision(.fractionLength(dp))))%"
    }

    private func kg(_ v: Double) -> String {
        "\(v.formatted(.number.precision(.fractionLength(0)))) kg"
    }

    private func tco2e(_ v: Double) -> String {
        "\(v.formatted(.number.precision(.fractionLength(2)))) tCO2e"
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: Threshold Logic
    // ─────────────────────────────────────────────────────────────────────────

    private func recycledState(_ v: Double) -> MetricState {
        if v >= 30 { return .optimal }
        if v >= 15 { return .warning }
        return .danger
    }

    /// Waste is flagged red if > 10 % of total materials used.
    private func wasteState(_ v: Double) -> MetricState {
        guard deal.circularKgMaterialsUsed > 0 else { return .neutral }
        return (v / deal.circularKgMaterialsUsed) > 0.10 ? .danger : .neutral
    }

    private func carbonIntensityState(_ v: Double) -> MetricState {
        if v < 0.1  { return .optimal }
        if v <= 0.3 { return .warning }
        return .danger
    }

    /// MCI 0–1 scale: Green ≥ 0.8, Amber 0.6–0.79, Red < 0.6
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

// MARK: - Preview

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
    .frame(width: 660, height: 900)
    .background(Color(hex: "#0F1115"))
}

#Preview("Empty State") {
    CircularEconomyDashboardView(deal: PropertyDeal())
        .frame(width: 660, height: 400)
        .background(Color(hex: "#0F1115"))
}
