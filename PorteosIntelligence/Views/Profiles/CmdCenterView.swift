import SwiftUI
import SwiftData

// MARK: - CmdCenterView
// V2.06 portfolio command center — hero KPIs, inset grids, CRM pipeline.

struct CmdCenterView: View {

    @Query private var deals: [PropertyDeal]

    private var accent: Color { ProfileType.cmdCenter.accentColor }

    // MARK: Aggregates

    private var totalValue: Double {
        deals.reduce(0) { $0 + $1.purchasePrice }
    }

    private var portfolioAverageScore: Double {
        let validScores = deals.compactMap(\.porteosScore).filter { $0 > 0 }
        guard !validScores.isEmpty else { return 0 }
        return validScores.reduce(0, +) / Double(validScores.count)
    }

    private var hasScoredDeals: Bool {
        !deals.compactMap(\.porteosScore).filter({ $0 > 0 }).isEmpty
    }

    private var portfolioGrade: String {
        guard hasScoredDeals else { return "—" }
        let s = portfolioAverageScore
        if s >= 80 { return "A" }
        if s >= 70 { return "B" }
        if s >= 60 { return "C" }
        if s >= 50 { return "D" }
        return "F"
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

    private var crmDeals: [PropertyDeal] {
        deals
            .filter { $0.status == .pipeline || $0.status == .review }
            .sorted { $0.updatedAt > $1.updatedAt }
    }

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

    private var portfolioValidation: [ValidationMessage] {
        var msgs: [ValidationMessage] = []
        if hasScoredDeals && portfolioAverageScore < 80 {
            msgs.append(.init(
                severity: .warning,
                field: "AVG_SCORE",
                message: "portfolio avg \(Int(portfolioAverageScore.rounded())) below target threshold 80"
            ))
        }
        let withoutCarbon = deals.filter { $0.circularKgMaterialsUsed <= 0 && $0.circularRecycledContentPct <= 0 }.count
        if withoutCarbon >= 2 {
            msgs.append(.init(
                severity: .warning,
                field: "CARBON_COVER",
                message: "\(withoutCarbon)/\(deals.count) profiles lack carbon assessment"
            ))
        }
        return msgs
    }

    // MARK: Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            DashboardCLIHeader(profile: .cmdCenter, dealName: "Portfolio")
            TerminalStructuralDivider()

            if deals.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: DesignTokens.blockSpacing) {
                        heroKPIStrip
                        ValidationLogModule(messages: portfolioValidation, accentColor: accent)
                        MarketTrendGrid(deal: deals[0], profileKey: "cmdCenter", accent: accent)
                        module01DealPipeline
                        module02ProfileHealth
                        module03ProfileDistribution
                        module04PipelineCRM
                        module05RecentActivity
                        module06SystemStatus
                    }
                    .padding(DesignTokens.blockGutter)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignTokens.canvasBase)
    }

    // MARK: Hero KPI Strip

    private var heroKPIStrip: some View {
        TerminalMetricGrid {
            TerminalHeroMetricCell(
                label: "Total Portfolio Value",
                value: eur(totalValue),
                identityAccent: accent
            )
            TerminalHeroMetricCell(
                label: "Total Deals",
                value: "\(deals.count)",
                subtitle: "IN PORTFOLIO"
            )
            TerminalHeroMetricCell(
                label: "Avg Porteos Score",
                value: hasScoredDeals ? "\(Int(portfolioAverageScore.rounded()))" : "—",
                subtitle: hasScoredDeals ? "GRADE \(portfolioGrade)" : "NO SCORED DEALS",
                state: scoreState
            )
        }
    }

    // MARK: Module 01 // DEAL_PIPELINE

    private var module01DealPipeline: some View {
        TerminalBlock(command: "01 // DEAL_PIPELINE", accentColor: accent) {
            TerminalMetricGrid {
                TerminalMetricCell(label: "Pipeline", value: "\(count(.pipeline))", state: .neutral)
                TerminalMetricCell(label: "Under Review", value: "\(count(.review))",
                                   state: count(.review) > 0 ? .warning : .neutral)
                TerminalMetricCell(label: "Viable", value: "\(count(.viable))",
                                   state: count(.viable) > 0 ? .optimal : .neutral)
                TerminalMetricCell(label: "Acquired", value: "\(count(.acquired))",
                                   state: count(.acquired) > 0 ? .optimal : .neutral)
                TerminalMetricCell(label: "Rejected", value: "\(count(.rejected))",
                                   state: count(.rejected) > 0 ? .danger : .neutral)
            }
        }
    }

    // MARK: Module 02 // PROFILE_HEALTH

    private var module02ProfileHealth: some View {
        let re   = avgRealEstateScore
        let hosp = avgHospitalityScore
        let des  = avgDesignScore
        let circ = avgCircularScore
        return TerminalBlock(command: "02 // PROFILE_HEALTH  [avg score per profile]", accentColor: accent) {
            TerminalMetricGrid {
                TerminalProfileHealthCell(label: "Real Estate",  score: re.score,   dealCount: re.count,
                                          accent: ProfileType.realEstate.accentColor)
                TerminalProfileHealthCell(label: "Hospitality",  score: hosp.score, dealCount: hosp.count,
                                          accent: ProfileType.hospitality.accentColor)
                TerminalProfileHealthCell(label: "Design",       score: des.score,  dealCount: des.count,
                                          accent: ProfileType.design.accentColor)
                TerminalProfileHealthCell(label: "Circular",     score: circ.score, dealCount: circ.count,
                                          accent: ProfileType.circular.accentColor)
            }
        }
    }

    // MARK: Module 03 // PROFILE_DISTRIBUTION

    private var module03ProfileDistribution: some View {
        let w = avgWeights
        return TerminalBlock(command: "03 // PROFILE_DISTRIBUTION", accentColor: accent) {
            TerminalMetricGrid {
                TerminalDistributionCell(label: "Real Estate",  pct: w.re,       accent: ProfileType.realEstate.accentColor)
                TerminalDistributionCell(label: "Hospitality",  pct: w.hosp,     accent: ProfileType.hospitality.accentColor)
                TerminalDistributionCell(label: "Design",       pct: w.design,   accent: ProfileType.design.accentColor)
                TerminalDistributionCell(label: "Circular",     pct: w.circular, accent: ProfileType.circular.accentColor)
            }
        }
    }

    // MARK: Module 04 // PIPELINE_CRM

    private var module04PipelineCRM: some View {
        TerminalBlock(command: "04 // PIPELINE_CRM  [active outreach]", accentColor: accent) {
            if crmDeals.isEmpty {
                crmEmptyState
            } else {
                VStack(spacing: 0) {
                    crmHeaderRow
                    TerminalStructuralDivider()
                    ForEach(Array(crmDeals.enumerated()), id: \.element.id) { idx, deal in
                        crmDealRow(deal)
                        if idx < crmDeals.count - 1 {
                            TerminalStructuralDivider()
                        }
                    }
                }
                .clipShape(Rectangle())
                .overlay {
                    Rectangle().strokeBorder(DesignTokens.dividerStructural, lineWidth: DesignTokens.dividerWidth)
                }
            }
        }
    }

    private var crmEmptyState: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("NO ACTIVE PIPELINE DEALS")
                .porteosMetricLabel()
                .foregroundStyle(DesignTokens.textDim)
            Text("Deals in Pipeline or Under Review appear here for outreach tracking.")
                .porteosMeta()
                .foregroundStyle(DesignTokens.textSecondary)
        }
        .padding(DesignTokens.metricCellPadding)
        .frame(maxWidth: .infinity, minHeight: DesignTokens.metricCellMinHeight, alignment: .leading)
        .background(DesignTokens.surfaceElevated)
        .overlay {
            Rectangle().strokeBorder(DesignTokens.dividerStructural, lineWidth: DesignTokens.dividerWidth)
        }
    }

    private var crmHeaderRow: some View {
        HStack(spacing: 0) {
            crmColumnHeader("DEAL", width: nil, alignment: .leading)
            crmColumnHeader("MARKET", width: 88)
            crmColumnHeader("VALUE", width: 96, alignment: .trailing)
            crmColumnHeader("STATUS", width: 72)
            crmColumnHeader("LAST TOUCH", width: 88, alignment: .trailing)
        }
        .padding(.horizontal, DesignTokens.metricCellPadding)
        .frame(height: DesignTokens.crmRowHeight)
        .background(DesignTokens.surfacePanel)
    }

    private func crmDealRow(_ deal: PropertyDeal) -> some View {
        HStack(spacing: 0) {
            Text(deal.propertyName.isEmpty ? "Untitled Deal" : deal.propertyName)
                .porteosRowValue()
                .foregroundStyle(DesignTokens.textPrimary)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(deal.locationCity.isEmpty ? "—" : deal.locationCity.uppercased())
                .porteosRowLabel()
                .foregroundStyle(DesignTokens.textSecondary)
                .lineLimit(1)
                .frame(width: 88, alignment: .leading)

            Text(eur(deal.purchasePrice))
                .porteosRowValue()
                .monospacedDigit()
                .foregroundStyle(DesignTokens.textPrimary)
                .lineLimit(1)
                .frame(width: 96, alignment: .trailing)

            Text(deal.status.rawValue.uppercased())
                .porteosRowLabel()
                .foregroundStyle(statusColor(deal.status))
                .frame(width: 72, alignment: .center)

            Text(relativeDate(deal.updatedAt))
                .porteosMeta()
                .foregroundStyle(DesignTokens.textDim)
                .frame(width: 88, alignment: .trailing)
        }
        .padding(.horizontal, DesignTokens.metricCellPadding)
        .frame(height: DesignTokens.crmRowHeight)
        .background(DesignTokens.surfaceElevated)
    }

    private func crmColumnHeader(_ title: String, width: CGFloat?, alignment: Alignment = .center) -> some View {
        Group {
            if let width {
                Text(title)
                    .porteosMeta()
                    .foregroundStyle(DesignTokens.textDim)
                    .frame(width: width, alignment: alignment)
            } else {
                Text(title)
                    .porteosMeta()
                    .foregroundStyle(DesignTokens.textDim)
                    .frame(maxWidth: .infinity, alignment: alignment)
            }
        }
    }

    // MARK: Module 05 // RECENT_ACTIVITY

    private var module05RecentActivity: some View {
        TerminalBlock(command: "05 // RECENT_ACTIVITY  [last 5]", accentColor: accent) {
            VStack(spacing: 0) {
                ForEach(Array(recentDeals.enumerated()), id: \.element.id) { idx, deal in
                    activityRow(deal)
                    if idx < recentDeals.count - 1 {
                        TerminalStructuralDivider()
                    }
                }
            }
            .clipShape(Rectangle())
            .overlay {
                Rectangle().strokeBorder(DesignTokens.dividerStructural, lineWidth: DesignTokens.dividerWidth)
            }
        }
    }

    private func activityRow(_ deal: PropertyDeal) -> some View {
        HStack(spacing: 0) {
            Text(deal.propertyName.isEmpty ? "Untitled Deal" : deal.propertyName)
                .porteosRowValue()
                .foregroundStyle(DesignTokens.textPrimary)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(deal.status.rawValue.uppercased())
                .porteosRowLabel()
                .foregroundStyle(statusColor(deal.status))
                .frame(width: 80, alignment: .center)

            Text(deal.updatedAt, style: .date)
                .porteosMeta()
                .foregroundStyle(DesignTokens.textDim)
                .frame(width: 96, alignment: .trailing)
        }
        .padding(.horizontal, DesignTokens.metricCellPadding)
        .frame(height: DesignTokens.crmRowHeight)
        .background(DesignTokens.surfaceElevated)
    }

    // MARK: Module 06 // SYSTEM_STATUS

    private var module06SystemStatus: some View {
        let srv = DealIngestionServer.shared
        let ems = EmailMonitorService.shared

        return TerminalBlock(command: "06 // SYSTEM_STATUS", accentColor: ProfileType.circular.accentColor) {
            VStack(spacing: 0) {
                systemStatusRow(
                    label: "INGESTION_SERVER",
                    isActive: srv.isRunning,
                    detail: srv.isRunning
                        ? "ACTIVE (localhost:\(srv.port))  [\(srv.requestCount) req]"
                        : "STOPPED",
                    action: srv.isRunning ? "[ STOP ]" : "[ START ]",
                    actionColor: srv.isRunning ? DesignTokens.statusCritical : DesignTokens.statusGo
                ) {
                    if srv.isRunning { srv.stop() } else { srv.start() }
                }

                TerminalStructuralDivider()

                systemStatusRow(
                    label: "EMAIL_MONITOR",
                    isActive: ems.isMonitoring,
                    detail: ems.isMonitoring
                        ? "ACTIVE  [last: \(ems.lastCheckDate.map { relativeTime($0) } ?? "—")]"
                        : (ems.isConfigured ? "STOPPED" : "NOT_CONFIGURED")
                )

                if let err = srv.errorMessage {
                    TerminalStructuralDivider()
                    HStack(spacing: 8) {
                        Text("SERVER_ERR")
                            .porteosMeta()
                            .foregroundStyle(DesignTokens.textDim)
                            .frame(width: 120, alignment: .leading)
                        Text(err)
                            .porteosMeta()
                            .foregroundStyle(DesignTokens.statusCritical)
                            .lineLimit(2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, DesignTokens.metricCellPadding)
                    .frame(minHeight: DesignTokens.rowHeightData)
                }
            }
            .clipShape(Rectangle())
            .overlay {
                Rectangle().strokeBorder(DesignTokens.dividerStructural, lineWidth: DesignTokens.dividerWidth)
            }
        }
    }

    private func systemStatusRow(
        label: String,
        isActive: Bool,
        detail: String,
        action: String? = nil,
        actionColor: Color = DesignTokens.textDim,
        onAction: (() -> Void)? = nil
    ) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .porteosRowLabel()
                .foregroundStyle(DesignTokens.textDim)
                .frame(width: 140, alignment: .leading)

            Circle()
                .fill(isActive ? DesignTokens.statusGo : DesignTokens.textDim)
                .frame(width: 6, height: 6)

            Text(detail)
                .porteosRowValue()
                .foregroundStyle(isActive ? DesignTokens.statusGo : DesignTokens.textDim)
                .lineLimit(1)

            Spacer(minLength: 0)

            if let action, let onAction {
                Button(action: onAction) {
                    Text(action)
                        .porteosMeta()
                        .foregroundStyle(actionColor)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, DesignTokens.metricCellPadding)
        .frame(height: DesignTokens.rowHeightButton)
        .background(DesignTokens.surfaceElevated)
    }

    // MARK: Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            VStack(spacing: 8) {
                Text("porteos@system ~ % ls ./deals")
                    .porteosCliPrompt()
                    .foregroundStyle(DesignTokens.textDim)
                Text("No deals in portfolio")
                    .porteosRowValue()
                    .foregroundStyle(DesignTokens.textSecondary)
                Text("Click [ ./NEW_DEAL ] or [ ./IMPORT_DEALS ] to begin")
                    .porteosCliPrompt()
                    .foregroundStyle(DesignTokens.textSecondary)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: Sub-score helpers

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

    // MARK: Formatting

    private func eur(_ v: Double) -> String {
        v.formatted(.currency(code: "EUR").precision(.fractionLength(0)))
    }

    private func statusColor(_ status: DealStatus) -> Color {
        switch status {
        case .viable:   return DesignTokens.statusGo
        case .review:   return DesignTokens.statusWarn
        case .rejected: return DesignTokens.statusCritical
        case .acquired: return ProfileType.circular.accentColor
        case .pipeline: return DesignTokens.textSecondary
        }
    }

    private func relativeTime(_ date: Date) -> String {
        let s = Int(-date.timeIntervalSinceNow)
        if s < 60   { return "\(s)s ago" }
        if s < 3600 { return "\(s / 60)m ago" }
        return "\(s / 3600)h ago"
    }

    private func relativeDate(_ date: Date) -> String {
        let days = Int(-date.timeIntervalSinceNow / 86400)
        if days == 0 { return "TODAY" }
        if days == 1 { return "1D AGO" }
        if days < 7  { return "\(days)D AGO" }
        return date.formatted(.dateTime.month(.abbreviated).day())
    }
}

// MARK: - Preview

#Preview("With Deals") {
    CmdCenterView()
        .modelContainer(for: PropertyDeal.self, inMemory: true)
        .frame(width: 720, height: 900)
        .background(DesignTokens.canvasBase)
}

#Preview("Empty") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: PropertyDeal.self, configurations: config)
    return CmdCenterView()
        .modelContainer(container)
        .frame(width: 720, height: 400)
        .background(DesignTokens.canvasBase)
}
