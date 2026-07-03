import SwiftUI

// MARK: - MarketTrendGrid
// Figma: MKT // MARKET_TRENDS — 4-column metric grid (not list UI)

struct MarketTrendGrid: View {

    let deal: PropertyDeal
    let profileKey: String
    let accent: Color

    private var metrics: [MarketTrendMetric] {
        MarketTrendGridBuilder.metrics(for: profileKey, deal: deal)
    }

    var body: some View {
        TerminalBlock(command: "MKT // MARKET_TRENDS", accentColor: accent) {
            TerminalMetricGrid(fixedColumnCount: min(4, max(1, metrics.count))) {
                ForEach(metrics) { item in
                    TerminalMetricCell(label: item.label, value: item.value, state: item.state)
                }
            }
        }
    }
}

// MARK: - Model

struct MarketTrendMetric: Identifiable {
    let id = UUID()
    let label: String
    let value: String
    var state: MetricState = .neutral
}

// MARK: - Builder

enum MarketTrendGridBuilder {

    static func metrics(for profile: String, deal: PropertyDeal) -> [MarketTrendMetric] {
        let city = deal.locationCity
        let bm   = MarketBenchmarks.benchmark(for: city)

        switch profile {
        case "realEstate":
            return realEstateMetrics(deal: deal, bm: bm)
        case "hospitality":
            return hospitalityMetrics(deal: deal, bm: bm)
        case "design":
            return designMetrics(deal: deal, bm: bm)
        case "circular":
            return circularMetrics(deal: deal)
        case "cmdCenter":
            return cmdCenterMetrics()
        default:
            return []
        }
    }

    private static func realEstateMetrics(deal: PropertyDeal, bm: CityMetrics?) -> [MarketTrendMetric] {
        let cap = deal.purchasePrice > 0 && deal.grossPotentialIncome > 0
            ? (deal.grossPotentialIncome * (1 - deal.vacancyRate / 100) / deal.purchasePrice) * 100
            : (bm?.avgCapRate ?? 0)
        let prime = bm?.avgCapRate ?? cap
        let spreadBps = Int((cap - prime) * 100)
        let spreadState: MetricState = spreadBps < -30 ? .warning : (spreadBps > 0 ? .optimal : .neutral)
        let rate = bm?.avgInterestRate ?? 4.0
        let riskPrem = max(0, rate - prime)

        return [
            .init(label: "YIELD SPREAD", value: "\(spreadBps) bps", state: spreadState),
            .init(label: "PRIME YIELD", value: pct(prime, dp: 2)),
            .init(label: "CPI", value: pct(2.1, dp: 1), state: .optimal),
            .init(label: "RISK PREMIUM", value: pct(riskPrem, dp: 2)),
        ]
    }

    private static func hospitalityMetrics(deal: PropertyDeal, bm: CityMetrics?) -> [MarketTrendMetric] {
        let vm = HospitalityCalculator.calculateFull(inputs: .init(
            roomCount: deal.hospitalityRoomCount, adr: deal.hospitalityADR,
            occupancyRate: deal.hospitalityOccupancyRate, fbRevenue: deal.hospitalityFBRevenue,
            spaRevenue: deal.hospitalitySpaRevenue, meetingRevenue: deal.hospitalityMeetingRevenue,
            otherRevenue: deal.hospitalityOtherRevenue, opExRatio: deal.hospitalityOpExRatio,
            directBookingPct: deal.hospitalityDirectBookingPct, otaBookingPct: deal.hospitalityOTABookingPct,
            distributionCost: deal.hospitalityDistributionCost
        ))
        let mktRevpar = bm.map { eur($0.avgRevPAR) } ?? "—"
        let compAdr = bm.map { eur($0.avgADR) } ?? "—"
        let demandDelta = deal.hospitalityOccupancyRate - (bm?.avgOccupancyRate ?? 70)
        let compRevparDelta = vm.revPAR - (bm?.avgRevPAR ?? vm.revPAR)

        return [
            .init(label: "MARKET REVPAR", value: mktRevpar),
            .init(label: "COMP SET ADR", value: compAdr),
            .init(label: "DEMAND INDEX",
                  value: signedPct(demandDelta, dp: 1),
                  state: demandDelta >= 0 ? .optimal : .warning),
            .init(label: "COMP REVPAR",
                  value: signedPct(compRevparDelta, dp: 1),
                  state: compRevparDelta >= 0 ? .optimal : .warning),
        ]
    }

    private static func designMetrics(deal: PropertyDeal, bm: CityMetrics?) -> [MarketTrendMetric] {
        let daylight = deal.designDaylighting
        let bmDay = bm?.typicalDaylighting ?? 70
        let wellnessPrem = daylight - bmDay

        return [
            .init(label: "WELLNESS PREMIUM",
                  value: signedPct(wellnessPrem, dp: 0),
                  state: wellnessPrem >= 0 ? .optimal : .neutral),
            .init(label: "OFFICE YIELD", value: pct(bm?.avgCapRate ?? 3.8, dp: 1)),
            .init(label: "LEED/HQE ADOPTION", value: "+18 %", state: .optimal),
            .init(label: "RESI VACANCY", value: pct(bm?.avgVacancyRate ?? 2.1, dp: 1), state: .optimal),
        ]
    }

    private static func circularMetrics(deal: PropertyDeal) -> [MarketTrendMetric] {
        let recycled = deal.circularRecycledContentPct
        return [
            .init(label: "CIRCULAR MKT GRW", value: "+22 %", state: .optimal),
            .init(label: "RECYCLED MAT Δ",
                  value: recycled > 0 ? signedPct(recycled - 30, dp: 0) : "—",
                  state: recycled >= 30 ? .optimal : .warning),
            .init(label: "WASTE LEVY RATE", value: "↑ 34%", state: .warning),
            .init(label: "REG. PRESSURE", value: "↑ HIGH", state: .warning),
        ]
    }

    private static func cmdCenterMetrics() -> [MarketTrendMetric] {
        return [
            .init(label: "DEAL FLOW YOY", value: "+8.2 %", state: .optimal),
            .init(label: "AVG DEAL SIZE", value: "€ 42M"),
            .init(label: "BASE RATE", value: "↑ 340bps", state: .warning),
            .init(label: "PORTFOLIO HEAT", value: "WARM", state: .warning),
        ]
    }

    private static func pct(_ v: Double, dp: Int) -> String {
        "\(v.formatted(.number.precision(.fractionLength(dp)))) %"
    }

    private static func signedPct(_ v: Double, dp: Int) -> String {
        let sign = v >= 0 ? "+" : ""
        return "\(sign)\(v.formatted(.number.precision(.fractionLength(dp)))) %"
    }

    private static func eur(_ v: Double) -> String {
        "€ \(v.formatted(.number.precision(.fractionLength(0))))"
    }
}
