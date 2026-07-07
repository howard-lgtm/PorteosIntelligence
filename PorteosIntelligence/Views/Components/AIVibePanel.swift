import SwiftUI
import SwiftData

// MARK: - AIVibePanel
// Figma img_00_6 — AI Vibe idle + result states inside InspectorPane.

struct AIVibePanel: View {

    @Bindable var deal: PropertyDeal
    let refreshID: UUID

    @Environment(\.modelContext) private var modelContext

    @State private var result:     AnalysisResult? = nil
    @State private var phase:      AnalysisPhase?  = nil
    @State private var analyzedID: UUID?           = nil
    @State private var expandedSignalIndex: Int?   = nil

    private var isRunning: Bool {
        phase == .analyzingRules || phase == .generatingNarrative
    }

    private static let modelName = "porteos-score-v2.1"
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
            expandedSignalIndex = nil
            restoreStoredAnalysis()
        }
        .onChange(of: refreshID) { _, _ in
            result = nil
            analyzedID = nil
            expandedSignalIndex = nil
        }
    }

    // MARK: Idle

    private var idleState: some View {
        VStack(alignment: .leading, spacing: 0) {
            statusBox(
                title: "PORTEOS AI",
                lines: [
                    "NO ANALYSIS FOUND.",
                    "Run to generate AI signals, risk flags and suggestions."
                ]
            )

            fullWidthDivider

            runButton(label: "[ RUN ANALYSIS ]")

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

        if case .done(let llmOffline) = phase, llmOffline {
            llmOfflineBanner
            fullWidthDivider
        }

        let barSignals = topBarSignals(from: r)
        if !barSignals.isEmpty {
            sectionHeader("AI SIGNALS")
            VStack(spacing: 0) {
                ForEach(Array(barSignals.enumerated()), id: \.offset) { idx, item in
                    AISignalBarRow(
                        label: item.label,
                        score: item.score,
                        detail: item.detail,
                        barColor: sentimentColor(item.sentiment),
                        isExpanded: expandedSignalIndex == idx,
                        onToggle: {
                            expandedSignalIndex = expandedSignalIndex == idx ? nil : idx
                        }
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

        runButton(label: "[ REGENERATE ]")
        metadataBlock(lastRun: lastRunLabel)
        footerHint
    }

    // MARK: Hero

    private func resultHero(_ r: AnalysisResult) -> some View {
        let gradeColor = Color(hex: r.grade.hexColor)
        let scoreText  = deal.porteosScore.map { "\(Int($0.rounded()))" } ?? "—"

        return HStack(alignment: .center, spacing: 12) {
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
        .background(DesignTokens.surfaceElevated)
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
            metadataLine("MODEL", Self.modelName)
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
        phase = .analyzingRules
        Task {
            let r = await AIAnalysisService.shared.analyze(
                deal,
                context: modelContext,
                onPhaseChange: { [self] newPhase in
                    self.phase = newPhase
                }
            )
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
            headline:                  "\(name) — previously analysed. Tap regenerate to refresh.",
            realEstateSignals:         [],
            hospitalitySignals:        [],
            designSignals:             [],
            circularSignals:           [],
            marketIntelligenceSignals: [],
            summary:                   text,
            formattedText:             text
        )
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

// MARK: - AISignalBarRow

private struct AISignalBarRow: View {

    let label: String
    let score: Int
    let detail: String
    let barColor: Color
    let isExpanded: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
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

                    Text(isExpanded ? "[ − ]" : "[ + ]")
                        .porteosMeta()
                        .foregroundStyle(isExpanded ? DesignTokens.accentRust : DesignTokens.textDim)
                        .frame(width: 34, alignment: .trailing)
                }

                Text(detail)
                    .porteosMeta()
                    .foregroundStyle(DesignTokens.textDim)
                    .multilineTextAlignment(.leading)
                    .lineLimit(isExpanded ? nil : 1)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, DesignTokens.blockGutter)
            .padding(.vertical, 10)
            .background(isExpanded ? DesignTokens.surfaceElevated : DesignTokens.surfacePanel)
        }
        .buttonStyle(.plain)
        .animation(.easeOut(duration: 0.15), value: isExpanded)
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
