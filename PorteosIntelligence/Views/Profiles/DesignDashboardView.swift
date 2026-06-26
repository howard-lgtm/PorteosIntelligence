import SwiftUI
import SwiftData

// MARK: - DesignDashboardView

struct DesignDashboardView: View {

    @Bindable var deal: PropertyDeal

    // MARK: Tokens

    private let shellBg       = Color(hex: "#0F1115")
    private let shellSurface  = Color(hex: "#1A1D24")
    private let shellElevated = Color(hex: "#23262E")
    private let shellBorder   = Color(hex: "#2E333F")
    private let accentPurple  = Color(hex: "#A855F7")
    private let textPrimary   = Color(hex: "#F8F9FA")
    private let textSecondary = Color(hex: "#94A3B8")
    private let textTertiary  = Color(hex: "#64748B")

    // MARK: Computed

    private var hasData: Bool { deal.designGFA > 0 }

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

    // MARK: Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            cliHeader
            Rectangle().fill(shellBorder).frame(height: 1)

            if hasData {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        module01SpaceEfficiency
                        module02Wellness
                        module03Biophilic
                        module04Adaptability
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
            Text("profile --design --asset=\"\(deal.propertyName.isEmpty ? "Untitled Deal" : deal.propertyName)\"")
                .font(.custom("JetBrains Mono", size: 11).weight(.bold))
                .foregroundStyle(accentPurple)
                .lineLimit(1)
            Spacer()
        }
        .padding(.horizontal, 16)
        .frame(height: 32)
        .background(shellSurface)
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: Module 01 // SPACE_EFFICIENCY
    // ─────────────────────────────────────────────────────────────────────────

    private var module01SpaceEfficiency: some View {
        TerminalBlock(command: "01 // SPACE_EFFICIENCY", accentColor: accentPurple, contentPadding: 0) {
            VStack(spacing: 0) {
                TerminalMetricRow(label: "Gross Floor Area (GFA)",   value: m2(metrics.gfa),             state: .neutral)
                rowDivider
                TerminalMetricRow(label: "Net Internal Area (NIA)",  value: m2(metrics.nia),             state: .neutral)
                rowDivider
                TerminalMetricRow(label: "Net-to-Gross Ratio",       value: pct(metrics.netToGrossRatio), state: netToGrossState(metrics.netToGrossRatio))
                rowDivider
                TerminalMetricRow(label: "Circulation",              value: pct(metrics.circulationPct), state: metrics.circulationPct > 20 ? .warning : .neutral)
                rowDivider
                TerminalMetricRow(label: "Space Utilization Rate",   value: pct(metrics.spaceUtilization), state: metrics.spaceUtilization >= 90 ? .optimal : .neutral)
            }
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: Module 02 // WELLNESS_METRICS
    // ─────────────────────────────────────────────────────────────────────────

    private var module02Wellness: some View {
        TerminalBlock(command: "02 // WELLNESS_METRICS", accentColor: accentPurple, contentPadding: 0) {
            VStack(spacing: 0) {
                TerminalMetricRow(label: "Daylighting Coverage",     value: pct(metrics.daylighting),    state: metrics.daylighting >= 80 ? .optimal : .neutral)
                rowDivider
                TerminalMetricRow(label: "CO2 Levels",               value: "\(metrics.co2ppm.formatted(.number.precision(.fractionLength(0)))) ppm", state: co2State(metrics.co2ppm))
                rowDivider
                TerminalMetricRow(label: "Air Changes Per Hour",     value: "\(metrics.ach.formatted(.number.precision(.fractionLength(1)))) ACH",  state: metrics.ach >= 4 ? .optimal : .neutral)
                rowDivider
                TerminalMetricRow(label: "Thermal Comfort Score",    value: pct(metrics.thermalComfort), state: metrics.thermalComfort >= 90 ? .optimal : .neutral)
                rowDivider
                TerminalMetricRow(label: "Acoustic Comfort Score",   value: pct(metrics.acousticComfort), state: metrics.acousticComfort >= 85 ? .optimal : .neutral)
            }
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: Module 03 // BIOPHILIC_ELEMENTS
    // ─────────────────────────────────────────────────────────────────────────

    private var module03Biophilic: some View {
        TerminalBlock(command: "03 // BIOPHILIC_ELEMENTS", accentColor: accentPurple, contentPadding: 0) {
            VStack(spacing: 0) {
                TerminalMetricRow(label: "Biophilic Elements",       value: "\(metrics.biophilicCount)",  state: .neutral)
                rowDivider
                TerminalMetricRow(label: "Green Wall Coverage",      value: m2(metrics.greenWallM2),      state: .neutral)
                rowDivider
                TerminalMetricRow(label: "Views to Nature",          value: pct(metrics.viewsToNaturePct), state: metrics.viewsToNaturePct >= 70 ? .optimal : .neutral)
                rowDivider
                TerminalMetricRow(label: "Natural Materials",        value: pct(metrics.naturalMaterialsPct), state: metrics.naturalMaterialsPct >= 40 ? .optimal : .neutral)
            }
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: Module 04 // ADAPTABILITY
    // ─────────────────────────────────────────────────────────────────────────

    private var module04Adaptability: some View {
        TerminalBlock(command: "04 // ADAPTABILITY", accentColor: accentPurple, contentPadding: 0) {
            VStack(spacing: 0) {
                TerminalMetricRow(label: "Movable Partition",        value: pct(metrics.movablePartitionPct), state: metrics.movablePartitionPct >= 30 ? .optimal : .neutral)
                rowDivider
                TerminalMetricRow(label: "Multi-Use Spaces",         value: "\(metrics.multiUseSpaces)",  state: .neutral)
                rowDivider
                summaryRow(label: "Adaptability Score", value: "\(metrics.adaptabilityScore.formatted(.number.precision(.fractionLength(0))))/100", state: adaptabilityState(metrics.adaptabilityScore))
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
                Text("porteos@system ~ % ls ./design_data")
                    .font(.custom("JetBrains Mono", size: 11))
                    .foregroundStyle(textTertiary)
                Text("No design data available")
                    .font(.custom("JetBrains Mono", size: 14))
                    .foregroundStyle(textSecondary)
                Text("Click [ ./EDIT_DEAL ] to add design metrics")
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

    private func m2(_ v: Double) -> String {
        "\(v.formatted(.number.precision(.fractionLength(0)))) m²"
    }

    private func pct(_ v: Double, dp: Int = 1) -> String {
        "\(v.formatted(.number.precision(.fractionLength(dp))))%"
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: Threshold Logic
    // ─────────────────────────────────────────────────────────────────────────

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

// MARK: - Preview

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
    .background(Color(hex: "#0F1115"))
}

#Preview("Empty State") {
    DesignDashboardView(deal: PropertyDeal())
        .frame(width: 660, height: 400)
        .background(Color(hex: "#0F1115"))
}
