import SwiftUI
import SwiftData

// MARK: - AIVibePanel
// Figma img_00_6 — AI Vibe idle + result states inside InspectorPane.

struct AIVibePanel: View {

    @Bindable var deal: PropertyDeal
    let refreshID: UUID

    @Environment(\.modelContext) private var modelContext

    @State private var result:          AnalysisResult? = nil
    @State private var phase:           AnalysisPhase?  = nil
    @State private var analyzedID:      UUID?           = nil
    @State private var benchmarkApplied: String?        = nil
    @State private var analysisTask:    Task<Void, Never>? = nil  // cancels in-flight on regenerate

    private var isRunning: Bool {
        phase == .analyzingRules || phase == .generatingNarrative
    }

    private var activeModelName: String { LLMAnalysisService.shared.modelName }
    private static let signalLabels = [
        "LOCATION SCORE", "MARKET TIMING", "CASH FLOW", "RISK PROFILE", "ESG COMPLIANCE"
    ]

    // MARK: Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if isRunning {
                    runningState
                } else if let r = result, analyzedID == deal.id {
                    resultView(r)
                } else {
                    idleState
                }
            }
        }
        .frame(maxWidth: .infinity)
        .onAppear { restoreStoredAnalysis() }
        .onChange(of: deal.id) { _, _ in
            result = nil
            analyzedID = nil
            restoreStoredAnalysis()
        }
        .onChange(of: refreshID) { _, _ in
            result = nil
            analyzedID = nil
        }
    }

    // MARK: Idle

    private var idleState: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Run button at top — always visible without scrolling
            runButton(label: "[ RUN ANALYSIS ]")

            fullWidthDivider

            statusBox(
                title: "PORTEOS AI",
                lines: [
                    "No analysis yet.",
                    "Apply market benchmarks below to baseline missing fields, then run."
                ]
            )

            fullWidthDivider

            benchmarkApplySection

            metadataBlock(lastRun: lastRunLabel)

            footerHint
        }
    }

    // MARK: Running

    private var runningState: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("AI VIBE CHECK")

            VStack(alignment: .leading, spacing: 8) {
                logLine(">", "scanning real estate metrics...")
                logLine(">", "scanning hospitality metrics...")
                logLine(">", "scanning design metrics...")
                logLine(">", "scanning circular economy metrics...")
                if phase == .generatingNarrative {
                    logLine(">", "[ ANALYZING_RULES... ] done")
                    logLine(">", "[ GENERATING_NARRATIVE... ] calling local LLM...")
                } else {
                    logLine(">", "[ ANALYZING_RULES... ]")
                }
            }
            .padding(.horizontal, DesignTokens.blockGutter)
            .padding(.vertical, 12)
        }
    }

    // MARK: Result

    @ViewBuilder
    private func resultView(_ r: AnalysisResult) -> some View {
        resultHero(r)
        fullWidthDivider

        // Action row: always at top of results, never hidden by scrolling
        runButton(label: "[ REGENERATE ]")
        fullWidthDivider

        if case .done(let llmOffline) = phase, llmOffline {
            llmOfflineBanner
            fullWidthDivider
        }

        // Benchmark apply: second most important — show before signals
        benchmarkApplySection
        fullWidthDivider

        if let swot = r.swot {
            swotSection(swot)
            fullWidthDivider
        } else if !r.summary.isEmpty {
            // SWOT didn't parse — show raw LLM response so it's not silently lost
            rawLLMSection(r.summary)
            fullWidthDivider
        }

        dealMetricsSection
        fullWidthDivider

        let barSignals = topBarSignals(from: r)
        if !barSignals.isEmpty {
            sectionHeader("AI SIGNALS")
            VStack(spacing: 0) {
                ForEach(Array(barSignals.enumerated()), id: \.offset) { idx, item in
                    AISignalBarRow(
                        label: item.label,
                        score: item.score,
                        detail: item.detail,
                        barColor: sentimentColor(item.sentiment)
                    )
                    if idx < barSignals.count - 1 { insetDivider }
                }
            }
            fullWidthDivider
        }

        let suggestions = r.allSignals.compactMap { signal -> AnalysisSignal? in
            signal.action == nil ? nil : signal
        }
        if !suggestions.isEmpty {
            sectionHeader("SUGGESTIONS")
            VStack(spacing: 0) {
                ForEach(Array(suggestions.enumerated()), id: \.offset) { idx, signal in
                    suggestionRow(signal)
                    if idx < suggestions.count - 1 { insetDivider }
                }
            }
            fullWidthDivider
        }

        metadataBlock(lastRun: lastRunLabel)
        footerHint
    }

    // MARK: Hero

    private func resultHero(_ r: AnalysisResult) -> some View {
        let gradeColor   = Color(hex: r.grade.hexColor)
        let verdictColor = Color(hex: r.verdict.hexColor)
        let scoreText    = deal.porteosScore.map { "\(Int($0.rounded()))" } ?? "—"

        return VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 12) {
                Text(scoreText)
                    .porteosScoreHero()
                    .monospacedDigit()
                    .foregroundStyle(DesignTokens.textPrimary)

                VStack(alignment: .leading, spacing: 2) {
                    Text("PORTEOS AI")
                        .porteosMeta()
                        .foregroundStyle(DesignTokens.textDim)
                    Text(deal.propertyName.isEmpty ? "Untitled Deal" : deal.propertyName)
                        .porteosRowValue()
                        .foregroundStyle(DesignTokens.textPrimary)
                        .lineLimit(2)
                }

                Spacer(minLength: 0)

                Text(r.grade.rawValue)
                    .porteosScoreGrade()
                    .foregroundStyle(gradeColor)
                    .frame(width: 36, height: 36)
                    .background(DesignTokens.surfaceElevated)
                    .overlay {
                        Rectangle().strokeBorder(gradeColor.opacity(0.45), lineWidth: DesignTokens.dividerWidth)
                    }
                    .clipShape(Rectangle())
            }
            .padding(.horizontal, DesignTokens.blockGutter)
            .padding(.vertical, 14)

            // Verdict bar
            HStack {
                Text("VERDICT")
                    .porteosMeta()
                    .foregroundStyle(DesignTokens.textDim)
                Spacer()
                Text(r.verdict.label)
                    .porteosMeta()
                    .foregroundStyle(verdictColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(verdictColor.opacity(0.12))
                    .overlay { Rectangle().strokeBorder(verdictColor.opacity(0.5), lineWidth: 1) }
            }
            .padding(.horizontal, DesignTokens.blockGutter)
            .padding(.vertical, 8)
            .background(DesignTokens.surfaceElevated)
        }
        .background(DesignTokens.surfaceElevated)
    }

    // MARK: SWOT — delegates to isolated View struct so @State lives at the right level

    @ViewBuilder
    private func swotSection(_ swot: SWOTAnalysis) -> some View {
        sectionHeader("SWOT ANALYSIS")
        SWOTAccordionView(swot: swot)
    }

    // MARK: Rows

    private func suggestionRow(_ signal: AnalysisSignal) -> some View {
        HStack(alignment: .center, spacing: 8) {
            Text(signal.message)
                .porteosRowValue()
                .foregroundStyle(DesignTokens.textSecondary)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let action = signal.action {
                Button { applyAction(action) } label: {
                    Text("[ APPLY ]")
                        .porteosButtonPrimary()
                        .foregroundStyle(DesignTokens.accentRust)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, DesignTokens.blockGutter)
        .padding(.vertical, 10)
        .background(DesignTokens.surfacePanel)
    }

    // MARK: Shared chrome

    private func statusBox(title: String, lines: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .porteosButtonPrimary()
                .foregroundStyle(DesignTokens.textPrimary)
            ForEach(lines, id: \.self) { line in
                Text(line)
                    .porteosRowValue()
                    .foregroundStyle(DesignTokens.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DesignTokens.blockGutter)
        .background(DesignTokens.surfacePanel)
        .overlay {
            Rectangle().strokeBorder(DesignTokens.dividerStructural, lineWidth: DesignTokens.dividerWidth)
        }
        .padding(DesignTokens.blockGutter)
    }

    private func metadataBlock(lastRun: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            metadataLine("MODEL", activeModelName)
            metadataLine("LAST RUN", lastRun)
        }
        .padding(.horizontal, DesignTokens.blockGutter)
        .padding(.vertical, 10)
    }

    private func metadataLine(_ key: String, _ value: String) -> some View {
        HStack(spacing: 8) {
            Text(key)
                .porteosMeta()
                .foregroundStyle(DesignTokens.textDim)
            Text(value)
                .porteosMeta()
                .foregroundStyle(DesignTokens.textSecondary)
        }
    }

    private var footerHint: some View {
        Text("CMD+ENTER to run / ESC to close")
            .porteosMeta()
            .foregroundStyle(DesignTokens.textDim)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, DesignTokens.blockGutter)
            .padding(.vertical, 10)
    }

    private func runButton(label: String) -> some View {
        Button { runAnalysis() } label: {
            Text(label)
                .porteosButtonPrimary()
                .foregroundStyle(DesignTokens.canvasBase)
                .frame(maxWidth: .infinity)
                .frame(height: DesignTokens.rowHeightButton)
                .background(DesignTokens.accentRust)
                .clipShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, DesignTokens.blockGutter)
        .padding(.vertical, 10)
        .keyboardShortcut(.return, modifiers: .command)
    }

    private var llmOfflineBanner: some View {
        HStack(spacing: 6) {
            Text("~")
                .porteosButtonPrimary()
                .foregroundStyle(DesignTokens.statusWarn)
            Text("Local LLM offline. Using rule-based analysis only.")
                .porteosRowLabel()
                .foregroundStyle(DesignTokens.textSecondary)
        }
        .padding(.horizontal, DesignTokens.blockGutter)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignTokens.surfacePanel)
    }

    // MARK: Raw LLM fallback

    @ViewBuilder
    private func rawLLMSection(_ text: String) -> some View {
        sectionHeader("LLM RESPONSE")
        Text(text)
            .porteosMeta()
            .foregroundStyle(DesignTokens.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, DesignTokens.blockGutter)
            .padding(.vertical, 8)
    }

    // MARK: Deal Metrics section

    @ViewBuilder
    private var dealMetricsSection: some View {
        let bm = cityBenchmark
        let metrics = computedMetrics
        if metrics.capRate > 0 || metrics.loanToValue > 0 || metrics.debtServiceCoverageRatio > 0 {
            sectionHeader("DEAL METRICS")
            VStack(spacing: 0) {
                if metrics.capRate > 0 {
                    metricsRow(
                        "CAP RATE",
                        String(format: "%.2f%%", metrics.capRate),
                        benchmark: bm.map { String(format: "%.1f%%", $0.avgCapRate) },
                        good: bm.map { metrics.capRate >= $0.avgCapRate } ?? true
                    )
                    insetDivider
                }
                if metrics.loanToValue > 0 {
                    metricsRow(
                        "LTV",
                        String(format: "%.1f%%", metrics.loanToValue),
                        benchmark: "≤65% safe",
                        good: metrics.loanToValue <= 65
                    )
                    insetDivider
                }
                if metrics.debtServiceCoverageRatio > 0 {
                    metricsRow(
                        "DSCR",
                        String(format: "%.2fx", metrics.debtServiceCoverageRatio),
                        benchmark: "≥1.25 safe",
                        good: metrics.debtServiceCoverageRatio >= 1.25
                    )
                    insetDivider
                }
                if metrics.netOperatingIncome > 0 {
                    metricsRow(
                        "NOI",
                        "€\(Int(metrics.netOperatingIncome))",
                        benchmark: nil,
                        good: true
                    )
                    insetDivider
                }
                if metrics.cashOnCashReturn > 0 {
                    metricsRow(
                        "CASH-ON-CASH",
                        String(format: "%.1f%%", metrics.cashOnCashReturn),
                        benchmark: "≥8% target",
                        good: metrics.cashOnCashReturn >= 8
                    )
                }
            }
        }
    }

    private var computedMetrics: RealEstateCalculator.FullMetrics {
        RealEstateCalculator.calculateFull(inputs: .init(
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
    }

    private func metricsRow(
        _ label: String,
        _ value: String,
        benchmark: String?,
        good: Bool
    ) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .porteosMeta()
                .foregroundStyle(DesignTokens.textDim)
                .frame(maxWidth: .infinity, alignment: .leading)
            if let bm = benchmark {
                Text(bm)
                    .porteosMeta()
                    .foregroundStyle(DesignTokens.textDim)
            }
            Text(value)
                .porteosMeta()
                .foregroundStyle(good ? DesignTokens.statusGo : DesignTokens.statusCritical)
                .monospacedDigit()
        }
        .padding(.horizontal, DesignTokens.blockGutter)
        .padding(.vertical, 7)
        .background(DesignTokens.surfacePanel)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .porteosModuleCmd()
            .foregroundStyle(DesignTokens.textDim)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, DesignTokens.blockGutter)
            .padding(.vertical, 10)
    }

    private func logLine(_ prefix: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(prefix)
                .porteosRowValue()
                .foregroundStyle(DesignTokens.accentRust)
            Text(text)
                .porteosRowValue()
                .foregroundStyle(DesignTokens.textSecondary)
        }
    }

    private var fullWidthDivider: some View {
        Rectangle()
            .fill(DesignTokens.dividerStructural)
            .frame(height: DesignTokens.dividerWidth)
    }

    private var insetDivider: some View {
        Rectangle()
            .fill(DesignTokens.dividerStructural)
            .frame(height: DesignTokens.dividerWidth)
            .padding(.horizontal, DesignTokens.blockGutter)
    }

    // MARK: Signal mapping

    private struct BarSignalItem {
        let label: String
        let score: Int
        let detail: String
        let sentiment: AnalysisSignal.Sentiment
    }

    private func topBarSignals(from r: AnalysisResult) -> [BarSignalItem] {
        let signals = r.allSignals.filter { $0.action == nil }
        return Array(signals.prefix(5).enumerated()).map { idx, signal in
            BarSignalItem(
                label: idx < Self.signalLabels.count ? Self.signalLabels[idx] : "SIGNAL \(idx + 1)",
                score: scoreForSignal(signal, index: idx),
                detail: signal.message,
                sentiment: signal.sentiment
            )
        }
    }

    private func scoreForSignal(_ signal: AnalysisSignal, index: Int) -> Int {
        switch signal.sentiment {
        case .positive: return min(99, 88 + index)
        case .neutral:  return 75 + index
        case .warning:  return max(45, 68 - index * 2)
        case .critical: return max(25, 42 - index * 3)
        }
    }

    private var lastRunLabel: String {
        guard deal.aiAnalysisText != nil, analyzedID == deal.id else { return "Never" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: deal.updatedAt, relativeTo: Date())
    }

    // MARK: Analysis

    private func restoreStoredAnalysis() {
        guard let stored = deal.aiAnalysisText, !stored.isEmpty, result == nil else { return }
        analyzedID = deal.id
        result = quickResult(from: stored)
    }

    private func runAnalysis() {
        // Cancel any in-flight analysis before starting a new one
        analysisTask?.cancel()
        phase = .analyzingRules

        analysisTask = Task {
            let r = await AIAnalysisService.shared.analyze(
                deal,
                context: modelContext,
                onPhaseChange: { [self] newPhase in
                    self.phase = newPhase
                }
            )
            guard !Task.isCancelled else { return }
            await MainActor.run {
                result     = r
                analyzedID = deal.id
                deal.aiAnalysisText = r.formattedText
                try? modelContext.save()
            }
        }
    }

    private func quickResult(from text: String) -> AnalysisResult {
        let grade = VibeGrade.from(score: deal.porteosScore)
        let name  = deal.propertyName.isEmpty ? "This asset" : deal.propertyName
        return AnalysisResult(
            grade:                     grade,
            verdict:                   DealVerdict.from(grade: grade),
            headline:                  "\(name) — previously analysed. Tap regenerate to refresh.",
            realEstateSignals:         [],
            hospitalitySignals:        [],
            designSignals:             [],
            circularSignals:           [],
            marketIntelligenceSignals: [],
            summary:                   text,
            formattedText:             text,
            swot:                      nil
        )
    }

    // MARK: Benchmark Apply Section

    private var cityBenchmark: CityMetrics? {
        if !deal.locationCity.isEmpty,
           let bm = MarketBenchmarks.benchmark(for: deal.locationCity) { return bm }
        // Fallback: infer city from property name / address / notes URL
        let inferred = DealIngestionServer.inferCity(
            name:    deal.propertyName,
            address: deal.address,
            country: "",
            url:     deal.notes)
        return inferred.isEmpty ? nil : MarketBenchmarks.benchmark(for: inferred)
    }

    @ViewBuilder
    private var benchmarkApplySection: some View {
        if deal.locationCity.isEmpty {
            HStack(spacing: 6) {
                Text("// MARKET_BENCHMARKS")
                    .porteosMeta()
                    .foregroundStyle(DesignTokens.textDim)
                Spacer()
                Text("set city in deal to enable")
                    .porteosMeta()
                    .foregroundStyle(DesignTokens.textDim)
            }
            .padding(.horizontal, DesignTokens.blockGutter)
            .padding(.vertical, 10)
        } else if let bm = cityBenchmark {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("// MARKET_BENCHMARKS")
                            .porteosMeta()
                            .foregroundStyle(DesignTokens.textDim)
                        Text("\(bm.cityName), \(bm.country)")
                            .porteosRowValue()
                            .foregroundStyle(DesignTokens.textPrimary)
                            .lineLimit(1)
                    }
                    Spacer()
                    Button { applyAllBenchmarks(bm) } label: {
                        Text("[ APPLY ]")
                            .porteosButtonPrimary()
                            .foregroundStyle(DesignTokens.accentRust)
                    }
                    .buttonStyle(.plain)
                    .help("Fill empty deal fields with \(bm.cityName) market rates")
                }

                benchmarkPreviewGrid(bm)

                if let note = benchmarkApplied {
                    Text(note)
                        .porteosMeta()
                        .foregroundStyle(DesignTokens.statusGo)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, DesignTokens.blockGutter)
            .padding(.vertical, 10)
        }
    }

    private func benchmarkPreviewGrid(_ bm: CityMetrics) -> some View {
        VStack(spacing: 3) {
            benchmarkRow("Cap Rate",   String(format: "%.1f%%", bm.avgCapRate),
                         current: deal.vacancyRate > 0 ? nil : "—")
            benchmarkRow("Vacancy",    String(format: "%.1f%%", bm.avgVacancyRate),
                         current: deal.vacancyRate > 0 ? String(format: "%.1f%%", deal.vacancyRate) : "—")
            if deal.totalArea > 0 {
                let gpi = bm.avgGPIPerSqm * deal.totalArea
                benchmarkRow("GPI (est.)", "€\(Int(gpi))/yr",
                             current: deal.grossPotentialIncome > 0 ? nil : "—")
                let opex = bm.avgOpExPerSqm * deal.totalArea
                benchmarkRow("OpEx (est.)", "€\(Int(opex))/yr",
                             current: deal.operatingExpenses > 0 ? nil : "—")
            }
            benchmarkRow("Interest",   String(format: "%.1f%%", bm.avgInterestRate),
                         current: deal.interestRate > 0 ? String(format: "%.1f%%", deal.interestRate) : "—")
        }
    }

    private func benchmarkRow(_ label: String, _ market: String, current: String?) -> some View {
        HStack(spacing: 0) {
            Text(label)
                .porteosMeta()
                .foregroundStyle(DesignTokens.textDim)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(market)
                .porteosMeta()
                .foregroundStyle(DesignTokens.textSecondary)
                .frame(width: 90, alignment: .trailing)
            if let cur = current {
                Text(cur == "—" ? "missing" : cur)
                    .porteosMeta()
                    .foregroundStyle(cur == "—" ? DesignTokens.statusWarn : DesignTokens.textDim)
                    .frame(width: 60, alignment: .trailing)
            }
        }
    }

    private func applyAllBenchmarks(_ bm: CityMetrics) {
        DealHistoryManager.shared.push(deal: deal, label: "Apply \(bm.cityName) benchmarks")

        var applied: [String] = []

        if deal.vacancyRate == 0 {
            deal.vacancyRate = bm.avgVacancyRate
            applied.append("vacancy \(String(format: "%.1f", bm.avgVacancyRate))%")
        }
        if deal.interestRate == 0 {
            deal.interestRate = bm.avgInterestRate
            applied.append("interest \(String(format: "%.1f", bm.avgInterestRate))%")
        }
        if deal.totalArea > 0 {
            if deal.grossPotentialIncome == 0 {
                deal.grossPotentialIncome = bm.avgGPIPerSqm * deal.totalArea
                applied.append("GPI €\(Int(bm.avgGPIPerSqm * deal.totalArea))/yr")
            }
            if deal.operatingExpenses == 0 {
                deal.operatingExpenses = bm.avgOpExPerSqm * deal.totalArea
                applied.append("OpEx €\(Int(bm.avgOpExPerSqm * deal.totalArea))/yr")
            }
        }
        // Loan amount at 65% LTV (standard market assumption for value-add)
        if deal.loanAmount == 0, deal.purchasePrice > 0 {
            deal.loanAmount = deal.purchasePrice * 0.65
            applied.append("loan 65% LTV €\(Int(deal.purchasePrice * 0.65))")
        }
        if deal.hospitalityADR == 0, bm.avgADR > 0 {
            deal.hospitalityADR = bm.avgADR
            applied.append("ADR €\(Int(bm.avgADR))")
        }
        if deal.hospitalityOccupancyRate == 0, bm.avgOccupancyRate > 0 {
            deal.hospitalityOccupancyRate = bm.avgOccupancyRate
            applied.append("occupancy \(Int(bm.avgOccupancyRate))%")
        }

        // Re-compute and persist score so dashboard reflects the new assumptions immediately
        deal.porteosScore = PropertyDealViewModel(deal: deal).porteosScore.finalScore
        deal.updatedAt = Date()
        try? modelContext.save()

        if applied.isEmpty {
            benchmarkApplied = "// All fields already populated — no changes made."
        } else {
            benchmarkApplied = "// Applied: \(applied.joined(separator: " · "))\n// Score updated."
            // Reset prior result so next run reflects updated data
            result     = nil
            analyzedID = nil
        }
    }

    private func applyAction(_ action: AnalysisSignal.Action) {
        switch action {
        case .applyBenchmark(let value, let field):
            DealHistoryManager.shared.push(
                deal:  deal,
                label: "Benchmark: \(fieldLabel(field))"
            )
            switch field {
            case "interestRate":               deal.interestRate             = value
            case "vacancyRate":                deal.vacancyRate              = value
            case "hospitalityADR":             deal.hospitalityADR           = value
            case "hospitalityOccupancyRate":   deal.hospitalityOccupancyRate = value
            default: break
            }
            deal.updatedAt = Date()
            try? modelContext.save()
        }
    }

    private func fieldLabel(_ field: String) -> String {
        switch field {
        case "interestRate":             return "Interest Rate"
        case "vacancyRate":              return "Vacancy Rate"
        case "hospitalityADR":           return "ADR"
        case "hospitalityOccupancyRate": return "Occupancy"
        default:                          return field
        }
    }

    private func sentimentColor(_ sentiment: AnalysisSignal.Sentiment) -> Color {
        switch sentiment {
        case .positive: return DesignTokens.statusGo
        case .neutral:  return ProfileType.circular.accentColor
        case .warning:  return DesignTokens.statusWarn
        case .critical: return DesignTokens.statusCritical
        }
    }
}

// MARK: - SWOTAccordionView
// Isolated View struct so @State lives at the correct SwiftUI identity level.
// Functions inside @ViewBuilder chains lose state linkage on macOS — a struct fixes this.

private struct SWOTAccordionView: View {

    let swot: SWOTAnalysis
    @State private var expanded: String? = nil

    private var rowDivider: some View {
        Rectangle()
            .fill(DesignTokens.dividerStructural)
            .frame(height: DesignTokens.dividerWidth)
            .padding(.horizontal, DesignTokens.blockGutter)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            row("S", swot.strength,    color: DesignTokens.statusGo)
            rowDivider
            row("W", swot.weakness,    color: DesignTokens.statusCritical)
            rowDivider
            row("O", swot.opportunity, color: DesignTokens.statusWarn)
            rowDivider
            row("T", swot.threat,      color: DesignTokens.textSecondary)
        }
    }

    private func row(_ key: String, _ text: String, color: Color) -> some View {
        let isExpanded  = expanded == key
        let needsExpand = text.count > 30
        let preview     = needsExpand ? String(text.prefix(72)) + "…" : text

        return Button {
            withAnimation(.easeOut(duration: 0.15)) {
                expanded = isExpanded ? nil : key
            }
        } label: {
            HStack(alignment: .top, spacing: 10) {
                Text(key)
                    .porteosMeta()
                    .foregroundStyle(color)
                    .frame(width: 16)
                Text(isExpanded ? text : preview)
                    .porteosMeta()
                    .foregroundStyle(DesignTokens.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
                if needsExpand {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(DesignTokens.textDim)
                }
            }
            .padding(.horizontal, DesignTokens.blockGutter)
            .padding(.vertical, 8)
            .background(DesignTokens.surfacePanel)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - AISignalBarRow

private struct AISignalBarRow: View {

    let label: String
    let score: Int
    let detail: String
    let barColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text(label)
                    .porteosMetricLabel()
                    .foregroundStyle(DesignTokens.textDim)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(1)

                TerminalSegmentBar(
                    fillRatio: Double(score) / 100,
                    barColor: barColor,
                    height: 6
                )
                .frame(width: 72)

                Text("\(score)")
                    .porteosMetricValue()
                    .monospacedDigit()
                    .foregroundStyle(barColor)
                    .frame(width: 28, alignment: .trailing)
            }

            Text(detail)
                .porteosMeta()
                .foregroundStyle(DesignTokens.textDim)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, DesignTokens.blockGutter)
        .padding(.vertical, 10)
        .background(DesignTokens.surfacePanel)
    }
}

// MARK: - Preview

#Preview("Idle") {
    let config    = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: PropertyDeal.self, configurations: config)
    let deal      = PropertyDeal(propertyName: "Lisbon Office Block A")
    container.mainContext.insert(deal)
    return AIVibePanel(deal: deal, refreshID: UUID())
        .frame(width: DesignTokens.inspectorPaneWidth)
        .background(DesignTokens.surfacePanel)
        .modelContainer(container)
}

#Preview("Result") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: PropertyDeal.self, configurations: config)
    let deal = PropertyDeal(
        propertyName: "Lisbon Office Block A",
        purchasePrice: 2_000_000,
        porteosScore: 87
    )
    container.mainContext.insert(deal)
    return AIVibePanel(deal: deal, refreshID: UUID())
        .frame(width: DesignTokens.inspectorPaneWidth)
        .background(DesignTokens.surfacePanel)
        .modelContainer(container)
}
