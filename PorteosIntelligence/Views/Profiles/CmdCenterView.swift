import SwiftUI
import SwiftData

// MARK: - CmdCenterView

struct CmdCenterView: View {

    @Query private var deals: [PropertyDeal]

    // MARK: Tokens

    private let shellBg       = Color(hex: "#0F1115")
    private let shellSurface  = Color(hex: "#1A1D24")
    private let shellElevated = Color(hex: "#23262E")
    private let shellBorder   = Color(hex: "#2E333F")
    private let accentGrey    = Color(hex: "#94A3B8")
    private let textPrimary   = Color(hex: "#F8F9FA")
    private let textSecondary = Color(hex: "#94A3B8")
    private let textTertiary  = Color(hex: "#64748B")

    // MARK: Aggregates

    private var totalValue: Double {
        deals.reduce(0) { $0 + $1.purchasePrice }
    }

    private var avgScore: Double? {
        let scores = deals.compactMap(\.porteosScore).filter { $0 > 0 }
        guard !scores.isEmpty else { return nil }
        return scores.reduce(0, +) / Double(scores.count)
    }

    private func count(_ status: DealStatus) -> Int {
        deals.filter { $0.status == status }.count
    }

    private var recentDeals: [PropertyDeal] {
        Array(deals.sorted { $0.updatedAt > $1.updatedAt }.prefix(5))
    }

    // Average profile weights across all deals (fallback: 25% each)
    private var avgWeights: (re: Double, hosp: Double, design: Double, circular: Double) {
        guard !deals.isEmpty else { return (25, 25, 25, 25) }
        let n = Double(deals.count)
        return (
            deals.reduce(0) { $0 + $1.weightRealEstate }  / n,
            deals.reduce(0) { $0 + $1.weightHospitality } / n,
            deals.reduce(0) { $0 + $1.weightDesign }      / n,
            deals.reduce(0) { $0 + $1.weightCircular }    / n
        )
    }

    // MARK: Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            cliHeader
            Rectangle().fill(shellBorder).frame(height: 1)

            if deals.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        module01PortfolioSummary
                        module02ProfileDistribution
                        module03RecentActivity
                    }
                    .padding(16)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(shellBg)
    }

    // MARK: CLI Header

    private var cliHeader: some View {
        HStack(spacing: 0) {
            Text("porteos@system ~ % ")
                .font(.custom("JetBrains Mono", size: 13))
                .foregroundStyle(textTertiary)
            Text("portfolio --overview")
                .font(.custom("JetBrains Mono", size: 13).weight(.bold))
                .foregroundStyle(accentGrey)
            Spacer()
        }
        .padding(.horizontal, 16)
        .frame(height: 36)
        .background(shellSurface)
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: Module 01 // PORTFOLIO_SUMMARY
    // ─────────────────────────────────────────────────────────────────────────

    private var module01PortfolioSummary: some View {
        TerminalBlock(command: "01 // PORTFOLIO_SUMMARY", accentColor: accentGrey, contentPadding: 0) {
            VStack(spacing: 12) {
                summaryRow(label: "Total Portfolio Value", value: eur(totalValue))
                TerminalMetricRow(label: "Total Deals",       value: "\(deals.count)", state: .neutral)
                TerminalMetricRow(
                    label: "Avg Porteos Score",
                    value: avgScore.map { "\(Int($0.rounded()))" } ?? "—",
                    state: .neutral
                )
                TerminalMetricRow(label: "Pipeline",  value: "\(count(.pipeline))",  state: .neutral)
                TerminalMetricRow(label: "Under Review", value: "\(count(.review))", state: count(.review)   > 0 ? .warning : .neutral)
                TerminalMetricRow(label: "Viable",    value: "\(count(.viable))",    state: count(.viable)   > 0 ? .optimal : .neutral)
                TerminalMetricRow(label: "Acquired",  value: "\(count(.acquired))",  state: count(.acquired) > 0 ? .optimal : .neutral)
                TerminalMetricRow(label: "Rejected",  value: "\(count(.rejected))",  state: count(.rejected) > 0 ? .danger  : .neutral)
            }
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: Module 02 // PROFILE_DISTRIBUTION
    // ─────────────────────────────────────────────────────────────────────────

    private var module02ProfileDistribution: some View {
        let w = avgWeights
        let profiles: [(label: String, pct: Double, color: Color)] = [
            ("Real Estate",  w.re,       Color(hex: "#C25E30")),
            ("Hospitality",  w.hosp,     Color(hex: "#14B8A6")),
            ("Design",       w.design,   Color(hex: "#A855F7")),
            ("Circular",     w.circular, Color(hex: "#3B82F6")),
        ]
        return TerminalBlock(command: "02 // PROFILE_DISTRIBUTION", accentColor: accentGrey, contentPadding: 0) {
            VStack(spacing: 12) {
                ForEach(Array(profiles.enumerated()), id: \.offset) { idx, profile in
                    weightRow(label: profile.label, pct: profile.pct, accent: profile.color)
                }
            }
        }
    }

    private func weightRow(label: String, pct: Double, accent: Color) -> some View {
        HStack(spacing: 12) {
            Text(label.uppercased())
                .font(.custom("JetBrains Mono", size: 13).weight(.bold))
                .tracking(0.08)
                .foregroundStyle(textTertiary)
                .frame(width: 120, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle().fill(shellBorder)
                    Rectangle()
                        .fill(accent)
                        .frame(width: max(0, geo.size.width * (pct / 100)))
                }
                .clipShape(Rectangle())
            }
            .frame(height: 6)

            Text("\(pct.formatted(.number.precision(.fractionLength(1))))%")
                .font(.custom("JetBrains Mono", size: 14).weight(.bold))
                .monospacedDigit()
                .foregroundStyle(accent)
                .frame(width: 52, alignment: .trailing)
        }
        .padding(.horizontal, 12)
        .frame(height: 40)
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: Module 03 // RECENT_ACTIVITY
    // ─────────────────────────────────────────────────────────────────────────

    private var module03RecentActivity: some View {
        TerminalBlock(command: "03 // RECENT_ACTIVITY  [last 5]", accentColor: accentGrey, contentPadding: 0) {
            VStack(spacing: 12) {
                ForEach(Array(recentDeals.enumerated()), id: \.element.id) { idx, deal in
                    activityRow(deal)
                }
            }
        }
    }

    private func activityRow(_ deal: PropertyDeal) -> some View {
        HStack(spacing: 0) {
            Text(deal.propertyName.isEmpty ? "Untitled Deal" : deal.propertyName)
                .font(.custom("JetBrains Mono", size: 13))
                .foregroundStyle(textSecondary)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 12)

            Text(deal.status.rawValue.uppercased())
                .font(.custom("JetBrains Mono", size: 12))
                .foregroundStyle(statusColor(deal.status))
                .frame(width: 80, alignment: .center)

            Text(deal.updatedAt, style: .date)
                .font(.custom("JetBrains Mono", size: 12))
                .foregroundStyle(textTertiary)
                .frame(width: 104, alignment: .trailing)
                .padding(.trailing, 12)
        }
        .frame(height: 32)
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: Empty State
    // ─────────────────────────────────────────────────────────────────────────

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            VStack(spacing: 8) {
                Text("porteos@system ~ % ls ./deals")
                    .font(.custom("JetBrains Mono", size: 13))
                    .foregroundStyle(textTertiary)
                Text("No deals in portfolio")
                    .font(.custom("JetBrains Mono", size: 14))
                    .foregroundStyle(textSecondary)
                Text("Click [ ./NEW_DEAL ] or [ ./IMPORT_DEALS ] to begin")
                    .font(.custom("JetBrains Mono", size: 13))
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
                .font(.custom("JetBrains Mono", size: 13).weight(.bold))
                .tracking(0.08)
                .foregroundStyle(textSecondary)
            Spacer()
            Text(value)
                .font(.custom("JetBrains Mono", size: 17).weight(.bold))
                .monospacedDigit()
                .foregroundStyle(valueColor)
        }
        .padding(.horizontal, 12)
        .frame(height: 40)
        .background(shellElevated)
    }

    private var rowDivider: some View {
        Rectangle().fill(shellBorder).frame(height: 1)
    }

    private func eur(_ v: Double) -> String {
        v.formatted(.currency(code: "EUR").precision(.fractionLength(0)))
    }

    private func statusColor(_ status: DealStatus) -> Color {
        switch status {
        case .viable:   return Color(hex: "#10B981")
        case .review:   return Color(hex: "#F59E0B")
        case .rejected: return Color(hex: "#EF4444")
        case .acquired: return Color(hex: "#3B82F6")
        case .pipeline: return Color(hex: "#64748B")
        }
    }
}

// MARK: - Preview

#Preview("With Deals") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: PropertyDeal.self, configurations: config)
    let ctx = container.mainContext
    ctx.insert(PropertyDeal(propertyName: "Lisbon Office A", purchasePrice: 1_250_000, status: .viable))
    ctx.insert(PropertyDeal(propertyName: "Porto Warehouse", purchasePrice: 875_000,   status: .pipeline))
    ctx.insert(PropertyDeal(propertyName: "Cascais Villa",   purchasePrice: 2_100_000, status: .review))
    return CmdCenterView()
        .modelContainer(container)
        .frame(width: 660, height: 900)
        .background(Color(hex: "#0F1115"))
}

#Preview("Empty") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: PropertyDeal.self, configurations: config)
    return CmdCenterView()
        .modelContainer(container)
        .frame(width: 660, height: 400)
        .background(Color(hex: "#0F1115"))
}
