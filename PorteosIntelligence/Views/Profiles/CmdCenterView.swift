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

    /// True average across all deals that carry a Porteos Score.
    /// Returns 0 when no scored deals exist (distinguishable from a real 0 via
    /// the companion `hasScoredDeals` guard used at call sites).
    private var portfolioAverageScore: Double {
        let validScores = deals.compactMap { $0.porteosScore }
        guard !validScores.isEmpty else { return 0 }
        return validScores.reduce(0, +) / Double(validScores.count)
    }

    private var hasScoredDeals: Bool {
        deals.contains { $0.porteosScore != nil }
    }

    private var scoreState: MetricState {
        guard hasScoredDeals else { return .neutral }
        let s = portfolioAverageScore
        if s >= 80 { return .optimal }
        if s >= 60 { return .warning }
        return .danger
    }

    private func count(_ status: DealStatus) -> Int {
        deals.filter { $0.status == status }.count
    }

    private var recentDeals: [PropertyDeal] {
        Array(deals.sorted { $0.updatedAt > $1.updatedAt }.prefix(5))
    }

    // ── Per-profile sub-scores (same normalization used by PorteosScoreCalculator) ──

    /// Normalised cap-rate score: (capRate / 10) × 100, clamped 0–100.
    private func realEstateSubScore(_ deal: PropertyDeal) -> Double? {
        guard deal.grossPotentialIncome > 0 else { return nil }
        let m = RealEstateCalculator.calculateFull(inputs: .init(
            grossPotentialIncome:   deal.grossPotentialIncome,
            vacancyRate:            deal.vacancyRate,
            otherIncome:            deal.otherIncome,
            operatingExpenses:      deal.operatingExpenses,
            opexPropertyManagement: deal.opexPropertyManagement,
            opexPropertyTax:        deal.opexPropertyTax,
            opexInsurance:          deal.opexInsurance,
            opexUtilities:          deal.opexUtilities,
            opexMaintenance:        deal.opexMaintenance,
            opexCapitalReserves:    deal.opexCapitalReserves,
            purchasePrice:          deal.purchasePrice,
            closingCosts:           deal.closingCosts,
            renovationBudget:       deal.renovationBudget,
            loanAmount:             deal.loanAmount,
            interestRate:           deal.interestRate,
            amortizationMonths:     deal.amortizationMonths,
            exitCapRate:            deal.exitCapRate
        ))
        return min(max((m.capRate / 10.0) * 100, 0), 100)
    }

    /// Normalised RevPAR score: (revPAR / 200) × 100, clamped 0–100.
    private func hospitalitySubScore(_ deal: PropertyDeal) -> Double? {
        guard deal.hospitalityADR > 0, deal.hospitalityRoomCount > 0 else { return nil }
        let m = HospitalityCalculator.calculate(inputs: .init(
            roomCount:      deal.hospitalityRoomCount,
            adr:            deal.hospitalityADR,
            occupancyRate:  deal.hospitalityOccupancyRate,
            fbRevenue:      deal.hospitalityFBRevenue,
            spaRevenue:     deal.hospitalitySpaRevenue,
            meetingRevenue: deal.hospitalityMeetingRevenue,
            otherRevenue:   deal.hospitalityOtherRevenue,
            opExRatio:      deal.hospitalityOpExRatio
        ))
        return min(max((m.revPAR / 200.0) * 100, 0), 100)
    }

    /// Weighted composite of wellness + efficiency metrics (0–100).
    /// DesignCalculator.calculateFull does not return a single overallDesignScore,
    /// so it is derived here using the same spirit as PorteosScoreCalculator.
    private func designSubScore(_ deal: PropertyDeal) -> Double? {
        guard deal.designGFA > 0 || deal.designNIA > 0 else { return nil }
        let m = DesignCalculator.calculateFull(inputs: .init(
            gfa:                 deal.designGFA,
            nia:                 deal.designNIA,
            circulationPct:      deal.designCirculationPct,
            spaceUtilization:    deal.designSpaceUtilization,
            daylighting:         deal.designDaylighting,
            co2ppm:              deal.designCO2ppm,
            ach:                 deal.designACH,
            thermalComfort:      deal.designThermalComfort,
            acousticComfort:     deal.designAcousticComfort,
            biophilicCount:      deal.designBiophilicCount,
            greenWallM2:         deal.designGreenWallM2,
            viewsToNaturePct:    deal.designViewsToNaturePct,
            naturalMaterialsPct: deal.designNaturalMaterialsPct,
            movablePartitionPct: deal.designMovablePartitionPct,
            multiUseSpaces:      deal.designMultiUseSpaces,
            adaptabilityScore:   deal.designAdaptabilityScore
        ))
        let s = (m.netToGrossRatio   * 0.20)
              + (m.spaceUtilization  * 0.20)
              + (m.daylighting       * 0.20)
              + (m.thermalComfort    * 0.20)
              + (m.acousticComfort   * 0.15)
              + (m.adaptabilityScore * 0.05)
        return min(max(s, 0), 100)
    }

    /// `overallCEScore` from CircularEconomyCalculator.calculateFull (already 0–100).
    private func circularSubScore(_ deal: PropertyDeal) -> Double? {
        guard deal.circularKgMaterialsUsed > 0 || deal.circularRecycledContentPct > 0 else { return nil }
        let m = CircularEconomyCalculator.calculateFull(inputs: .init(
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
        return min(max(m.overallCEScore, 0), 100)
    }

    /// Returns (avg score 0-100, qualifying deal count) for each profile.
    private var avgRealEstateScore: (score: Double, count: Int) {
        let s = deals.compactMap { realEstateSubScore($0) }
        return s.isEmpty ? (0, 0) : (s.reduce(0, +) / Double(s.count), s.count)
    }
    private var avgHospitalityScore: (score: Double, count: Int) {
        let s = deals.compactMap { hospitalitySubScore($0) }
        return s.isEmpty ? (0, 0) : (s.reduce(0, +) / Double(s.count), s.count)
    }
    private var avgDesignScore: (score: Double, count: Int) {
        let s = deals.compactMap { designSubScore($0) }
        return s.isEmpty ? (0, 0) : (s.reduce(0, +) / Double(s.count), s.count)
    }
    private var avgCircularScore: (score: Double, count: Int) {
        let s = deals.compactMap { circularSubScore($0) }
        return s.isEmpty ? (0, 0) : (s.reduce(0, +) / Double(s.count), s.count)
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
                    VStack(alignment: .leading, spacing: 8) {
                        module01PortfolioSummary
                        module02ProfileHealth
                        module03ProfileDistribution
                        module04RecentActivity
                        module05SystemStatus
                    }
                    .padding(12)
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
            VStack(spacing: 0) {
                summaryRow(label: "Total Portfolio Value", value: eur(totalValue))
                TerminalMetricRow(label: "Total Deals",    value: "\(deals.count)", state: .neutral)
                TerminalMetricRow(
                    label: "Avg Porteos Score",
                    value: hasScoredDeals ? String(format: "%.1f / 100", portfolioAverageScore) : "—",
                    state: scoreState
                )
                TerminalMetricRow(label: "Pipeline",     value: "\(count(.pipeline))",  state: .neutral)
                TerminalMetricRow(label: "Under Review", value: "\(count(.review))",    state: count(.review)   > 0 ? .warning : .neutral)
                TerminalMetricRow(label: "Viable",       value: "\(count(.viable))",    state: count(.viable)   > 0 ? .optimal : .neutral)
                TerminalMetricRow(label: "Acquired",     value: "\(count(.acquired))",  state: count(.acquired) > 0 ? .optimal : .neutral)
                TerminalMetricRow(label: "Rejected",     value: "\(count(.rejected))",  state: count(.rejected) > 0 ? .danger  : .neutral)
            }
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: Module 02 // PROFILE_HEALTH
    // ─────────────────────────────────────────────────────────────────────────

    private var module02ProfileHealth: some View {
        let re   = avgRealEstateScore
        let hosp = avgHospitalityScore
        let des  = avgDesignScore
        let circ = avgCircularScore
        return TerminalBlock(command: "02 // PROFILE_HEALTH  [avg score per profile]",
                             accentColor: accentGrey, contentPadding: 0) {
            VStack(spacing: 0) {
                profileHealthRow(key: "REAL_ESTATE_AVG",  score: re.score,   count: re.count,   accent: Color(hex: "#C25E30"))
                profileHealthRow(key: "HOSPITALITY_AVG",  score: hosp.score, count: hosp.count, accent: Color(hex: "#14B8A6"))
                profileHealthRow(key: "DESIGN_AVG",       score: des.score,  count: des.count,  accent: Color(hex: "#A855F7"))
                profileHealthRow(key: "CIRCULAR_AVG",     score: circ.score, count: circ.count, accent: Color(hex: "#3B82F6"))
            }
        }
    }

    /// Renders one profile health row:
    ///   KEY:    value (color-coded by ≥80/≥60/<60)
    ///   ────    1px score bar below
    private func profileHealthRow(key: String, score: Double, count: Int, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 0) {
                Text(key)
                    .font(.custom("JetBrains Mono", size: 11).weight(.medium))
                    .tracking(0.04)
                    .foregroundStyle(textTertiary)

                Text(":")
                    .font(.custom("JetBrains Mono", size: 11))
                    .foregroundStyle(textTertiary)

                Spacer()

                Text(count > 0 ? String(format: "%.1f", score) : "—")
                    .font(.custom("JetBrains Mono", size: 14).weight(.bold))
                    .monospacedDigit()
                    .foregroundStyle(count > 0 ? profileScoreColor(score) : textTertiary)

                if count > 0 {
                    Text("  /100  (\(count))")
                        .font(.custom("JetBrains Mono", size: 11))
                        .foregroundStyle(textTertiary)
                }
            }
            .padding(.horizontal, 12)
            .frame(height: 28)

            // 1px score bar — accent fill up to score/100, shell-border remainder
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle().fill(shellBorder)
                    Rectangle()
                        .fill(count > 0 ? accent : shellBorder)
                        .frame(width: count > 0 ? max(0, geo.size.width * (score / 100)) : 0)
                }
                .clipShape(Rectangle())
            }
            .frame(height: 1)
        }
    }

    /// Color thresholds for per-profile scores: ≥80 green, ≥60 amber, <60 red.
    private func profileScoreColor(_ score: Double) -> Color {
        if score >= 80 { return Color(hex: "#10B981") }
        if score >= 60 { return Color(hex: "#F59E0B") }
        return Color(hex: "#EF4444")
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: Module 03 // PROFILE_DISTRIBUTION
    // ─────────────────────────────────────────────────────────────────────────

    private var module03ProfileDistribution: some View {
        let w = avgWeights
        let profiles: [(label: String, pct: Double, color: Color)] = [
            ("Real Estate",  w.re,       Color(hex: "#C25E30")),
            ("Hospitality",  w.hosp,     Color(hex: "#14B8A6")),
            ("Design",       w.design,   Color(hex: "#A855F7")),
            ("Circular",     w.circular, Color(hex: "#3B82F6")),
        ]
        return TerminalBlock(command: "03 // PROFILE_DISTRIBUTION", accentColor: accentGrey, contentPadding: 0) {
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
                .font(.custom("JetBrains Mono", size: 11).weight(.bold))
                .tracking(0.06)
                .foregroundStyle(textTertiary)
                .frame(width: 112, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle().fill(shellBorder)
                    Rectangle()
                        .fill(accent)
                        .frame(width: max(0, geo.size.width * (pct / 100)))
                }
                .clipShape(Rectangle())
            }
            .frame(height: 4)

            Text("\(pct.formatted(.number.precision(.fractionLength(1))))%")
                .font(.custom("JetBrains Mono", size: 14).weight(.bold))
                .monospacedDigit()
                .foregroundStyle(accent)
                .frame(width: 52, alignment: .trailing)
        }
        .padding(.horizontal, 12)
        .frame(height: 32)
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: Module 04 // RECENT_ACTIVITY
    // ─────────────────────────────────────────────────────────────────────────

    private var module04RecentActivity: some View {
        TerminalBlock(command: "04 // RECENT_ACTIVITY  [last 5]", accentColor: accentGrey, contentPadding: 0) {
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

    // MARK: Module 05 // SYSTEM_STATUS
    // ─────────────────────────────────────────────────────────────────────────

    private var module05SystemStatus: some View {
        let srv = DealIngestionServer.shared
        let ems = EmailMonitorService.shared

        return TerminalBlock(command: "05 // SYSTEM_STATUS", accentColor: Color(hex: "#3B82F6")) {
            VStack(spacing: 0) {
                // Ingestion server row
                HStack(spacing: 0) {
                    Text("INGESTION_SERVER")
                        .font(.custom("JetBrains Mono", size: 10))
                        .foregroundStyle(textTertiary)
                        .frame(width: 148, alignment: .leading)
                    HStack(spacing: 5) {
                        Circle()
                            .fill(srv.isRunning ? Color(hex: "#10B981") : textTertiary)
                            .frame(width: 5, height: 5)
                        Text(srv.isRunning
                             ? "ACTIVE (localhost:\(srv.port))  [\(srv.requestCount) req]"
                             : "STOPPED")
                            .font(.custom("JetBrains Mono", size: 11))
                            .foregroundStyle(srv.isRunning ? Color(hex: "#10B981") : textTertiary)
                    }
                    Spacer()
                    Button {
                        if srv.isRunning { srv.stop() } else { srv.start() }
                    } label: {
                        Text(srv.isRunning ? "[ STOP ]" : "[ START ]")
                            .font(.custom("JetBrains Mono", size: 9))
                            .foregroundStyle(srv.isRunning ? Color(hex: "#EF4444") : Color(hex: "#10B981"))
                    }
                    .buttonStyle(.plain)
                }
                .frame(height: 28)

                Rectangle().fill(Color(hex: "#2E333F")).frame(height: 1)

                // Email monitor row
                HStack(spacing: 0) {
                    Text("EMAIL_MONITOR")
                        .font(.custom("JetBrains Mono", size: 10))
                        .foregroundStyle(textTertiary)
                        .frame(width: 148, alignment: .leading)
                    HStack(spacing: 5) {
                        Circle()
                            .fill(ems.isMonitoring ? Color(hex: "#10B981") : textTertiary)
                            .frame(width: 5, height: 5)
                        Text(ems.isMonitoring
                             ? "ACTIVE  [last: \(ems.lastCheckDate.map { relativeTime($0) } ?? "—")]"
                             : (ems.isConfigured ? "STOPPED" : "NOT_CONFIGURED"))
                            .font(.custom("JetBrains Mono", size: 11))
                            .foregroundStyle(ems.isMonitoring ? Color(hex: "#10B981") : textTertiary)
                    }
                    Spacer()
                }
                .frame(height: 28)

                if let err = srv.errorMessage {
                    Rectangle().fill(Color(hex: "#2E333F")).frame(height: 1)
                    HStack {
                        Text("SERVER_ERR")
                            .font(.custom("JetBrains Mono", size: 9))
                            .foregroundStyle(textTertiary)
                            .frame(width: 148, alignment: .leading)
                        Text(err)
                            .font(.custom("JetBrains Mono", size: 9))
                            .foregroundStyle(Color(hex: "#EF4444"))
                            .lineLimit(2)
                    }
                    .frame(minHeight: 24).padding(.vertical, 2)
                }
            }
        }
    }

    private func relativeTime(_ date: Date) -> String {
        let s = Int(-date.timeIntervalSinceNow)
        if s < 60   { return "\(s)s ago" }
        if s < 3600 { return "\(s / 60)m ago" }
        return "\(s / 3600)h ago"
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
