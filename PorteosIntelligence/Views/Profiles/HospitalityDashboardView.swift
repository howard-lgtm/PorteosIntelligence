import SwiftUI
import SwiftData

// MARK: - HospitalityDashboardView

struct HospitalityDashboardView: View {

    @Bindable var deal: PropertyDeal

    // MARK: Tokens

    private let shellBg       = Color(hex: "#0F1115")
    private let shellSurface  = Color(hex: "#1A1D24")
    private let shellElevated = Color(hex: "#23262E")
    private let shellBorder   = Color(hex: "#2E333F")
    private let accentTeal    = Color(hex: "#14B8A6")
    private let textPrimary   = Color(hex: "#F8F9FA")
    private let textSecondary = Color(hex: "#94A3B8")
    private let textTertiary  = Color(hex: "#64748B")

    // MARK: Computed

    private var hasData: Bool { deal.hospitalityRoomCount > 0 }

    private var metrics: HospitalityCalculator.FullMetrics {
        HospitalityCalculator.calculateFull(inputs: HospitalityCalculator.FullInputs(
            roomCount:        deal.hospitalityRoomCount,
            adr:              deal.hospitalityADR,
            occupancyRate:    deal.hospitalityOccupancyRate,
            fbRevenue:        deal.hospitalityFBRevenue,
            spaRevenue:       deal.hospitalitySpaRevenue,
            meetingRevenue:   deal.hospitalityMeetingRevenue,
            otherRevenue:     deal.hospitalityOtherRevenue,
            opExRatio:        deal.hospitalityOpExRatio,
            directBookingPct: deal.hospitalityDirectBookingPct,
            otaBookingPct:    deal.hospitalityOTABookingPct,
            distributionCost: deal.hospitalityDistributionCost
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
                        module01OperationalStats
                        module02ProfitabilityMatrix
                        module03DistributionLog
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
            Text("profile --hospitality --asset=\"\(deal.propertyName.isEmpty ? "Untitled Deal" : deal.propertyName)\"")
                .font(.custom("JetBrains Mono", size: 11).weight(.bold))
                .foregroundStyle(accentTeal)
                .lineLimit(1)
            Spacer()
        }
        .padding(.horizontal, 16)
        .frame(height: 32)
        .background(shellSurface)
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: Module 01 // OPERATIONAL_STATS
    // ─────────────────────────────────────────────────────────────────────────

    private var module01OperationalStats: some View {
        TerminalBlock(command: "01 // OPERATIONAL_STATS", accentColor: accentTeal, contentPadding: 0) {
            VStack(spacing: 0) {
                TerminalMetricRow(label: "ADR (Avg Daily Rate)", value: eur(metrics.adr),           state: .neutral)
                rowDivider
                TerminalMetricRow(label: "Occupancy Rate",       value: pct(metrics.occupancyRate), state: occupancyState(metrics.occupancyRate))
                rowDivider
                TerminalMetricRow(label: "RevPAR",               value: eur(metrics.revPAR),        state: .neutral)
                rowDivider
                TerminalMetricRow(label: "TrevPAR",              value: eur(metrics.trevPAR),       state: .neutral)
            }
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: Module 02 // PROFITABILITY_MATRIX
    // ─────────────────────────────────────────────────────────────────────────

    private var module02ProfitabilityMatrix: some View {
        TerminalBlock(command: "02 // PROFITABILITY_MATRIX", accentColor: accentTeal, contentPadding: 0) {
            VStack(spacing: 0) {
                summaryRow(label: "GOP (Gross Operating Profit)", value: eur(metrics.gop))
                rowDivider
                TerminalMetricRow(label: "GOP Margin",       value: pct(metrics.gopMargin),    state: gopMarginState(metrics.gopMargin))
                rowDivider
                TerminalMetricRow(label: "GOPPAR",           value: eur(metrics.gopPAR),       state: .neutral)
                rowDivider
                TerminalMetricRow(label: "EBITDA Margin (est.)", value: pct(metrics.ebitdaMargin), state: ebitdaMarginState(metrics.ebitdaMargin))
            }
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: Module 03 // DISTRIBUTION_LOG
    // ─────────────────────────────────────────────────────────────────────────

    private var module03DistributionLog: some View {
        TerminalBlock(command: "03 // DISTRIBUTION_LOG", accentColor: accentTeal, contentPadding: 0) {
            VStack(spacing: 0) {
                TerminalMetricRow(label: "Direct Booking",     value: pct(metrics.directBookingPct), state: metrics.directBookingPct >= 50 ? .optimal : .neutral)
                rowDivider
                TerminalMetricRow(label: "OTA Booking",        value: pct(metrics.otaBookingPct),    state: metrics.otaBookingPct > 40 ? .warning : .neutral)
                rowDivider
                TerminalMetricRow(label: "Distribution Cost",  value: eur(metrics.distributionCost), state: .neutral)
                rowDivider
                TerminalMetricRow(label: "Cost of Acquisition", value: pct(metrics.costOfAcquisition, dp: 2), state: .neutral)
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
                Text("porteos@system ~ % ls ./hospitality_data")
                    .font(.custom("JetBrains Mono", size: 11))
                    .foregroundStyle(textTertiary)
                Text("No hospitality data available")
                    .font(.custom("JetBrains Mono", size: 14))
                    .foregroundStyle(textSecondary)
                Text("Click [ ./EDIT_DEAL ] to add operational metrics")
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

    private func eur(_ v: Double) -> String {
        v.formatted(.currency(code: "EUR").precision(.fractionLength(0)))
    }

    private func pct(_ v: Double, dp: Int = 1) -> String {
        "\(v.formatted(.number.precision(.fractionLength(dp))))%"
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: Threshold Logic
    // ─────────────────────────────────────────────────────────────────────────

    private func occupancyState(_ v: Double) -> MetricState {
        if v >= 80 { return .optimal }
        if v >= 70 { return .warning }
        return .danger
    }

    private func gopMarginState(_ v: Double) -> MetricState {
        if v >= 40 { return .optimal }
        if v >= 30 { return .warning }
        return .danger
    }

    private func ebitdaMarginState(_ v: Double) -> MetricState {
        if v >= 30 { return .optimal }
        if v >= 20 { return .warning }
        return .danger
    }
}

// MARK: - Preview

#Preview("Full Data") {
    let deal = PropertyDeal(
        propertyName:              "Lisbon Boutique Hotel",
        hospitalityRoomCount:      80,
        hospitalityADR:            185,
        hospitalityOccupancyRate:  78,
        hospitalityFBRevenue:      620_000,
        hospitalitySpaRevenue:     140_000,
        hospitalityMeetingRevenue: 95_000,
        hospitalityOtherRevenue:   30_000,
        hospitalityOpExRatio:      58,
        hospitalityDirectBookingPct: 52,
        hospitalityOTABookingPct:    36,
        hospitalityDistributionCost: 180_000
    )
    return ScrollView {
        HospitalityDashboardView(deal: deal)
    }
    .frame(width: 660, height: 800)
    .background(Color(hex: "#0F1115"))
}

#Preview("Empty State") {
    HospitalityDashboardView(deal: PropertyDeal())
        .frame(width: 660, height: 400)
        .background(Color(hex: "#0F1115"))
}
