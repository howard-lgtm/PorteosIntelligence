import SwiftUI
import SwiftData

// MARK: - HospitalityDashboardView
// V2.06 — Figma module order + inset grids, no mock sparklines.

struct HospitalityDashboardView: View {

    @Bindable var deal: PropertyDeal

    private var accent: Color { ProfileType.hospitality.accentColor }

    private var dealDisplayName: String {
        deal.propertyName.isEmpty ? "Untitled Deal" : deal.propertyName
    }

    private var porteosScore: PorteosScoreCalculator.PorteosMetrics {
        PropertyDealViewModel(deal: deal).porteosScore
    }

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
            DashboardCLIHeader(profile: .hospitality, dealName: dealDisplayName)
            TerminalStructuralDivider()

            if hasData {
                ScrollView {
                    VStack(alignment: .leading, spacing: DesignTokens.blockSpacing) {
                        DashboardHeroScore(
                            score: porteosScore.finalScore,
                            grade: porteosScore.scoreGrade,
                            dealName: dealDisplayName,
                            profile: .hospitality
                        )
                        ValidationLogModule(
                            messages: DataValidator.validate(deal: deal),
                            accentColor: accent
                        )
                        MarketTrendGrid(deal: deal, profileKey: "hospitality", accent: accent)
                        module01OperationalStats
                        module02ProfitabilityMatrix
                        module03DistributionLog
                        HospitalitySensitivityBlock(deal: deal)
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

    private var module01OperationalStats: some View {
        TerminalBlock(command: "01 // OPERATIONAL_STATS", accentColor: accent) {
            TerminalMetricGrid(fixedColumnCount: 2) {
                TerminalMetricCell(label: "ADR", value: eur(metrics.adr))
                TerminalMetricCell(label: "OCCUPANCY", value: pct(metrics.occupancyRate),
                                   state: occupancyState(metrics.occupancyRate))
                TerminalMetricCell(label: "REVPAR", value: eur(metrics.revPAR))
                TerminalMetricCell(label: "TREVPAR", value: eur(metrics.trevPAR))
            }
        }
    }

    private var module02ProfitabilityMatrix: some View {
        TerminalBlock(command: "02 // PROFITABILITY_MATRIX", accentColor: accent) {
            TerminalMetricGrid(fixedColumnCount: 2) {
                TerminalMetricCell(label: "GOP", value: eurCompact(metrics.gop))
                TerminalMetricCell(label: "GOP MARGIN", value: pct(metrics.gopMargin),
                                   state: gopMarginState(metrics.gopMargin))
                TerminalMetricCell(label: "GOPPAR", value: eur(metrics.gopPAR))
                TerminalMetricCell(label: "EBITDA", value: eurCompact(metrics.gop * 0.85))
            }
        }
    }

    private var module03DistributionLog: some View {
        TerminalBlock(command: "03 // DISTRIBUTION_LOG", accentColor: accent) {
            TerminalMetricGrid(fixedColumnCount: 2) {
                TerminalMetricCell(label: "DIRECT BOOKING", value: pct(metrics.directBookingPct),
                                   state: metrics.directBookingPct >= 50 ? .optimal : .neutral)
                TerminalMetricCell(label: "OTA MIX", value: pct(metrics.otaBookingPct),
                                   state: metrics.otaBookingPct > 40 ? .warning : .neutral)
                TerminalMetricCell(label: "DISTRIB. COST", value: eurPerRoom(metrics.distributionCost))
                TerminalMetricCell(label: "CAC",
                                   value: eur(cacEstimate))
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            VStack(spacing: 8) {
                Text("porteos@system ~ % ls ./hospitality_data")
                    .font(DesignTokens.cliPromptFont())
                    .foregroundStyle(DesignTokens.textDim)
                Text("No hospitality data available")
                    .font(DesignTokens.rowValueFont())
                    .foregroundStyle(DesignTokens.textSecondary)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var cacEstimate: Double {
        guard deal.hospitalityRoomCount > 0 else { return 0 }
        return metrics.distributionCost / (Double(deal.hospitalityRoomCount) * 820)
    }

    private func eur(_ v: Double) -> String {
        v.formatted(.currency(code: "EUR").precision(.fractionLength(0)))
    }

    private func eurCompact(_ v: Double) -> String {
        if abs(v) >= 1_000_000 {
            return "€ \( (v / 1_000_000).formatted(.number.precision(.fractionLength(1))) )M"
        }
        return eur(v)
    }

    private func eurPerRoom(_ v: Double) -> String {
        guard deal.hospitalityRoomCount > 0 else { return eur(v) }
        let perRoom = v / Double(deal.hospitalityRoomCount)
        return "€ \(perRoom.formatted(.number.precision(.fractionLength(0)))) / rm"
    }

    private func pct(_ v: Double, dp: Int = 1) -> String {
        "\(v.formatted(.number.precision(.fractionLength(dp))))%"
    }

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
}

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
    .background(DesignTokens.canvasBase)
}
