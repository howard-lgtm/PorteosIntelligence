import SwiftUI
import SwiftData

// MARK: - HospitalityDashboardView

struct HospitalityDashboardView: View {

    @Bindable var deal: PropertyDeal

    private var accent: Color { ProfileType.hospitality.accentColor }

    private var hasData: Bool {
        deal.hospitalityRoomCount > 0 ||
        deal.hospitalityADR > 0 ||
        deal.hospitalityOccupancyRate > 0 ||
        deal.hospitalityFBRevenue > 0 ||
        deal.hospitalitySpaRevenue > 0
    }

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

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            TerminalCLIHeader(
                command: "profile --hospitality --asset=\"\(deal.propertyName.isEmpty ? "Untitled Deal" : deal.propertyName)\"",
                accentColor: accent
            )
            TerminalStructuralDivider()

            if hasData {
                ScrollView {
                    VStack(alignment: .leading, spacing: DesignTokens.blockSpacing) {
                        SystemLogBlock(messages: DataValidator.validate(deal: deal))
                        module01OperationalStats
                        module02ProfitabilityMatrix
                        module03DistributionLog
                        HospitalitySensitivityBlock(deal: deal)
                        MarketTrendModule(city: deal.locationCity, profile: "hospitality",
                                          accent: accent)
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

    // MARK: Module 01 // OPERATIONAL_STATS

    private var module01OperationalStats: some View {
        TerminalBlock(command: "01 // OPERATIONAL_STATS", accentColor: accent) {
            TerminalMetricGrid {
                let adrTrend = mockTrend(from: metrics.adr)
                let occTrend = mockTrend(from: metrics.occupancyRate)
                let revTrend = mockTrend(from: metrics.revPAR)

                TerminalMetricCell(label: "ADR (Avg Daily Rate)",
                                   value: eur(metrics.adr),
                                   trend: adrTrend,
                                   trendColor: sparkColor(adrTrend))
                TerminalMetricCell(label: "Occupancy Rate",
                                   value: pct(metrics.occupancyRate),
                                   state: occupancyState(metrics.occupancyRate),
                                   trend: occTrend,
                                   trendColor: sparkColor(occTrend))
                TerminalMetricCell(label: "RevPAR",
                                   value: eur(metrics.revPAR),
                                   trend: revTrend,
                                   trendColor: sparkColor(revTrend))
                TerminalMetricCell(label: "TRevPAR", value: eur(metrics.trevPAR))
            }
        }
    }

    // MARK: Module 02 // PROFITABILITY_MATRIX

    private var module02ProfitabilityMatrix: some View {
        TerminalBlock(command: "02 // PROFITABILITY_MATRIX", accentColor: accent) {
            TerminalMetricGrid {
                TerminalMetricCell(label: "GOP (Gross Operating Profit)", value: eur(metrics.gop))
                TerminalMetricCell(label: "GOP Margin", value: pct(metrics.gopMargin),
                                   state: gopMarginState(metrics.gopMargin))
                TerminalMetricCell(label: "GOPPAR", value: eur(metrics.gopPAR))
                TerminalMetricCell(label: "EBITDA Margin (est.)", value: pct(metrics.ebitdaMargin),
                                   state: ebitdaMarginState(metrics.ebitdaMargin))
            }
        }
    }

    // MARK: Module 03 // DISTRIBUTION_LOG

    private var module03DistributionLog: some View {
        TerminalBlock(command: "03 // DISTRIBUTION_LOG", accentColor: accent) {
            TerminalMetricGrid {
                TerminalMetricCell(label: "Direct Booking", value: pct(metrics.directBookingPct),
                                   state: metrics.directBookingPct >= 50 ? .optimal : .neutral)
                TerminalMetricCell(label: "OTA Booking", value: pct(metrics.otaBookingPct),
                                   state: metrics.otaBookingPct > 40 ? .warning : .neutral)
                TerminalMetricCell(label: "Distribution Cost", value: eur(metrics.distributionCost))
                TerminalMetricCell(label: "Cost of Acquisition",
                                   value: pct(metrics.costOfAcquisition, dp: 2))
            }
        }
    }

    // MARK: Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            VStack(spacing: 8) {
                Text("porteos@system ~ % ls ./hospitality_data")
                    .font(DesignTokens.mono(size: 11))
                    .foregroundStyle(DesignTokens.textDim)
                Text("No hospitality data available")
                    .font(DesignTokens.mono(size: 12))
                    .foregroundStyle(DesignTokens.textSecondary)
                Text("Click [ ./EDIT_DEAL ] to add operational metrics")
                    .font(DesignTokens.mono(size: 11))
                    .foregroundStyle(DesignTokens.textSecondary)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: Formatters

    private func eur(_ v: Double) -> String {
        v.formatted(.currency(code: "EUR").precision(.fractionLength(0)))
    }

    private func pct(_ v: Double, dp: Int = 1) -> String {
        "\(v.formatted(.number.precision(.fractionLength(dp))))%"
    }

    // MARK: Threshold Logic

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
    .frame(width: 720, height: 800)
    .background(DesignTokens.canvasBase)
}

#Preview("Empty State") {
    HospitalityDashboardView(deal: PropertyDeal())
        .frame(width: 720, height: 400)
        .background(DesignTokens.canvasBase)
}
