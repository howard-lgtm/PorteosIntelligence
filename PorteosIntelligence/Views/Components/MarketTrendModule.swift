import SwiftUI
import SwiftData

// MARK: - MarketTrendModule
//
// Terminal-block widget that surfaces city-level market intelligence for
// whichever deal is currently open. All data is derived locally from the
// MarketTrend time-series store — zero network calls, runs in <100ms.

struct MarketTrendModule: View {

    let city:    String
    let profile: String     // "realEstate" | "hospitality" | "design" | "circular"
    let accent:  Color

    @Environment(\.modelContext) private var modelContext

    // MARK: Tokens

    private let shellBg      = Color(hex: "#0F1115")
    private let shellSurface = Color(hex: "#1A1D24")
    private let shellBorder  = Color(hex: "#2E333F")
    private let tp1          = Color(hex: "#F8F9FA")
    private let tp2          = Color(hex: "#94A3B8")
    private let tp3          = Color(hex: "#64748B")

    // MARK: Body

    var body: some View {
        TerminalBlock(command: "MARKET_TREND // \(city.uppercased())", accentColor: accent) {
            VStack(alignment: .leading, spacing: 0) {

                // ── Heat level row ─────────────────────────────────────────────
                let heat = TrendAnalyzer.calculateMarketHeat(for: city, context: modelContext)
                heatRow(heat)

                divider

                // ── Key metric trends ──────────────────────────────────────────
                let metrics = keyMetrics(for: profile)
                if metrics.isEmpty {
                    emptyRow("NO_TREND_DATA — import deals to build history")
                } else {
                    ForEach(Array(metrics.enumerated()), id: \.offset) { idx, row in
                        metricTrendRow(label: row.label, metricName: row.metric,
                                       profile: profile, higherIsBetter: row.higherIsBetter)
                        if idx < metrics.count - 1 { divider }
                    }
                }

                divider

                // ── Portfolio activity ─────────────────────────────────────────
                activityRow(heat: heat)
            }
        }
    }

    // MARK: – Sub-views

    private func heatRow(_ heat: MarketHeat) -> some View {
        HStack(spacing: 8) {
            Text("MARKET_HEAT")
                .font(.custom("JetBrains Mono", size: 10))
                .foregroundStyle(tp3)

            Spacer()

            Text(heat.level)
                .font(.custom("JetBrains Mono", size: 10).weight(.bold))
                .foregroundStyle(heatColor(heat.level))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(heatColor(heat.level).opacity(0.12))
                .clipShape(Rectangle())

            Text("·")
                .foregroundStyle(tp3)
                .font(.custom("JetBrains Mono", size: 10))

            Text("\(String(format: "%.1f", heat.importVelocity)) deals/wk")
                .font(.custom("JetBrains Mono", size: 10))
                .foregroundStyle(tp2)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private func metricTrendRow(
        label:          String,
        metricName:     String,
        profile:        String,
        higherIsBetter: Bool
    ) -> some View {
        let trend      = TrendAnalyzer.calculateTrend(
            for: city, profile: profile, metric: metricName, context: modelContext
        )
        let arrow      = directionArrow(trend.direction)
        let arrowColor = arrowTint(direction: trend.direction, higherIsBetter: higherIsBetter)
        let hasTrend   = trend.confidence > 0
        let bmFallback: String? = {
            guard !hasTrend, let bm = MarketBenchmarks.benchmark(for: city),
                  let v = benchmarkValue(bm, metric: metricName) else { return nil }
            return "BM: \(String(format: "%.1f", v))"
        }()

        return HStack(spacing: 8) {
            Text(label)
                .font(.custom("JetBrains Mono", size: 10))
                .foregroundStyle(tp3)
                .frame(minWidth: 120, alignment: .leading)

            Spacer()

            if hasTrend {
                Text(arrow)
                    .font(.custom("JetBrains Mono", size: 9).weight(.bold))
                    .foregroundStyle(arrowColor)
                Text("\(String(format: "%.1f", abs(trend.strength)))% (6mo)")
                    .font(.custom("JetBrains Mono", size: 10))
                    .foregroundStyle(tp2)
                    .monospacedDigit()
                confidencePips(trend.confidence)
            } else if let fallback = bmFallback {
                Text(fallback)
                    .font(.custom("JetBrains Mono", size: 10))
                    .foregroundStyle(tp3.opacity(0.7))
            } else {
                Text("NO_DATA")
                    .font(.custom("JetBrains Mono", size: 10))
                    .foregroundStyle(tp3.opacity(0.5))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
    }

    private func directionArrow(_ dir: TrendDirection) -> String {
        switch dir {
        case .up:     return "▲"
        case .down:   return "▼"
        case .stable: return "→"
        }
    }

    private func activityRow(heat: MarketHeat) -> some View {
        let descriptor = FetchDescriptor<PropertyDeal>(
            predicate: #Predicate { d in d.locationCity == city }
        )
        let deals    = (try? modelContext.fetch(descriptor)) ?? []
        let imported = deals.count
        let acquired = deals.filter { $0.status == .acquired }.count
        let pipeline = deals.filter { $0.status == .pipeline }.count

        return HStack(spacing: 12) {
            statPill("IMPORTED",  "\(imported)", tp2)
            statPill("ACQUIRED",  "\(acquired)", Color(hex: "#10B981"))
            statPill("PIPELINE",  "\(pipeline)",  Color(hex: "#3B82F6"))
            Spacer()
            if imported > 0 {
                Text("\(Int(heat.acquisitionRate * 100))% conv.")
                    .font(.custom("JetBrains Mono", size: 10))
                    .foregroundStyle(tp3)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private func statPill(_ label: String, _ value: String, _ color: Color) -> some View {
        HStack(spacing: 3) {
            Text(value)
                .font(.custom("JetBrains Mono", size: 11).weight(.bold))
                .foregroundStyle(color)
                .monospacedDigit()
            Text(label)
                .font(.custom("JetBrains Mono", size: 9))
                .foregroundStyle(tp3)
        }
    }

    private func confidencePips(_ confidence: Double) -> some View {
        let filled = Int((confidence * 5).rounded())
        return HStack(spacing: 2) {
            ForEach(0..<5, id: \.self) { i in
                Rectangle()
                    .fill(i < filled ? tp2 : shellBorder)
                    .frame(width: 3, height: 8)
            }
        }
    }

    private func emptyRow(_ msg: String) -> some View {
        Text(msg)
            .font(.custom("JetBrains Mono", size: 10))
            .foregroundStyle(tp3.opacity(0.6))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
    }

    private var divider: some View {
        Rectangle().fill(shellBorder).frame(height: 1)
    }

    // MARK: – Helpers

    private struct MetricSpec {
        let label: String; let metric: String; let higherIsBetter: Bool
    }

    private func keyMetrics(for profile: String) -> [MetricSpec] {
        switch profile {
        case "realEstate":
            return [
                MetricSpec(label: "CAP RATE",       metric: "capRate",       higherIsBetter: true),
                MetricSpec(label: "PURCHASE PRICE",  metric: "purchasePrice", higherIsBetter: false),
                MetricSpec(label: "VACANCY RATE",    metric: "vacancyRate",   higherIsBetter: false),
            ]
        case "hospitality":
            return [
                MetricSpec(label: "ADR",             metric: "adr",           higherIsBetter: true),
                MetricSpec(label: "OCCUPANCY RATE",  metric: "occupancyRate", higherIsBetter: true),
                MetricSpec(label: "RevPAR",          metric: "revPAR",        higherIsBetter: true),
            ]
        case "design":
            return [
                MetricSpec(label: "DAYLIGHTING",     metric: "daylighting",   higherIsBetter: true),
                MetricSpec(label: "SPACE UTIL",      metric: "spaceUtil",     higherIsBetter: true),
            ]
        case "circular":
            return [
                MetricSpec(label: "RECYCLED CONTENT", metric: "recycledContent", higherIsBetter: true),
                MetricSpec(label: "WATER RECYCLING",  metric: "waterRecycling",  higherIsBetter: true),
            ]
        default: return []
        }
    }

    private func arrowTint(direction: TrendDirection, higherIsBetter: Bool) -> Color {
        switch direction {
        case .stable: return Color(hex: "#64748B")
        case .up:     return higherIsBetter ? Color(hex: "#10B981") : Color(hex: "#EF4444")
        case .down:   return higherIsBetter ? Color(hex: "#EF4444") : Color(hex: "#10B981")
        }
    }

    private func heatColor(_ level: String) -> Color {
        switch level {
        case "HOT":  return Color(hex: "#EF4444")
        case "WARM": return Color(hex: "#F59E0B")
        case "COOL": return Color(hex: "#3B82F6")
        default:     return Color(hex: "#64748B")   // COLD
        }
    }

    /// Returns the relevant benchmark value for a given metric key, so the
    /// module can display a fallback when no historical trend data exists.
    private func benchmarkValue(_ bm: CityMetrics, metric: String) -> Double? {
        switch metric {
        case "capRate":       return bm.avgCapRate
        case "vacancyRate":   return bm.avgVacancyRate
        case "interestRate":  return bm.avgInterestRate
        case "adr":           return bm.avgADR
        case "occupancyRate": return bm.avgOccupancyRate
        default:              return nil
        }
    }
}
