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

    var body: some View {
        TerminalBlock(command: "MARKET_TREND // \(city.uppercased())",
                      accentColor: accent,
                      contentPadding: 0) {
            VStack(alignment: .leading, spacing: 0) {
                let heat = TrendAnalyzer.calculateMarketHeat(for: city, context: modelContext)
                heatRow(heat)

                divider

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

                activityRow(heat: heat)
            }
        }
    }

    private func heatRow(_ heat: MarketHeat) -> some View {
        HStack(spacing: 8) {
            Text("MARKET_HEAT")
                .porteosMetricLabel()
                .foregroundStyle(DesignTokens.textDim)

            Spacer()

            Text(heat.level)
                .porteosButtonPrimary()
                .foregroundStyle(heatColor(heat.level))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(heatColor(heat.level).opacity(0.12))
                .clipShape(Rectangle())

            Text("·")
                .foregroundStyle(DesignTokens.textDim)
                .porteosMetricLabel()

            Text("\(String(format: "%.1f", heat.importVelocity)) deals/wk")
                .porteosMetricLabel()
                .foregroundStyle(DesignTokens.textSecondary)
        }
        .padding(.horizontal, DesignTokens.blockGutter)
        .padding(.vertical, DesignTokens.metricCellPadding)
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
                .porteosMetricLabel()
                .foregroundStyle(DesignTokens.textDim)
                .frame(minWidth: 120, alignment: .leading)

            Spacer()

            if hasTrend {
                Text(arrow)
                    .porteosMeta()
                    .foregroundStyle(arrowColor)
                Text("\(String(format: "%.1f", abs(trend.strength)))% (6mo)")
                    .porteosMetricLabel()
                    .foregroundStyle(DesignTokens.textSecondary)
                    .monospacedDigit()
                confidencePips(trend.confidence)
            } else if let fallback = bmFallback {
                Text(fallback)
                    .porteosMetricLabel()
                    .foregroundStyle(DesignTokens.textDim.opacity(0.7))
            } else {
                Text("NO_DATA")
                    .porteosMetricLabel()
                    .foregroundStyle(DesignTokens.textDim.opacity(0.5))
            }
        }
        .padding(.horizontal, DesignTokens.blockGutter)
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
            statPill("IMPORTED",  "\(imported)", DesignTokens.textSecondary)
            statPill("ACQUIRED",  "\(acquired)", DesignTokens.statusAcquired)
            statPill("PIPELINE",  "\(pipeline)",  DesignTokens.statusInfo)
            Spacer()
            if imported > 0 {
                Text("\(Int(heat.acquisitionRate * 100))% conv.")
                    .porteosMetricLabel()
                    .foregroundStyle(DesignTokens.textDim)
            }
        }
        .padding(.horizontal, DesignTokens.blockGutter)
        .padding(.vertical, DesignTokens.metricCellPadding)
    }

    private func statPill(_ label: String, _ value: String, _ color: Color) -> some View {
        HStack(spacing: 3) {
            Text(value)
                .porteosRowValue()
                .foregroundStyle(color)
                .monospacedDigit()
            Text(label)
                .porteosMeta()
                .foregroundStyle(DesignTokens.textDim)
        }
    }

    private func confidencePips(_ confidence: Double) -> some View {
        let filled = Int((confidence * 5).rounded())
        return HStack(spacing: 2) {
            ForEach(0..<5, id: \.self) { i in
                Rectangle()
                    .fill(i < filled ? DesignTokens.textSecondary : DesignTokens.dividerStructural)
                    .frame(width: 3, height: 8)
            }
        }
    }

    private func emptyRow(_ msg: String) -> some View {
        Text(msg)
            .porteosMetricLabel()
            .foregroundStyle(DesignTokens.textDim.opacity(0.6))
            .padding(.horizontal, DesignTokens.blockGutter)
            .padding(.vertical, DesignTokens.metricCellPadding)
    }

    private var divider: some View {
        Rectangle().fill(DesignTokens.dividerStructural).frame(height: DesignTokens.dividerWidth)
    }

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
        case .stable: return DesignTokens.textDim
        case .up:     return higherIsBetter ? DesignTokens.statusGo : DesignTokens.statusCritical
        case .down:   return higherIsBetter ? DesignTokens.statusCritical : DesignTokens.statusGo
        }
    }

    private func heatColor(_ level: String) -> Color {
        switch level {
        case "HOT":  return DesignTokens.statusCritical
        case "WARM": return DesignTokens.statusWarn
        case "COOL": return DesignTokens.statusInfo
        default:     return DesignTokens.textDim
        }
    }

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
