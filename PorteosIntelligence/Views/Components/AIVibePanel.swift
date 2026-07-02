import SwiftUI
import SwiftData

// MARK: - AIVibePanel
// Self-contained AI Vibe Check panel. Manages analysis state internally.
// Displayed inside InspectorPane under the [AI VIBE] tab.

struct AIVibePanel: View {

    @Bindable var deal: PropertyDeal
    /// Bumped by InspectorPane whenever deal data changes (edit commit or benchmark
    /// apply). AIVibePanel watches this and clears its stale in-memory result so the
    /// panel returns to idle and prompts a fresh run.
    let refreshID: UUID

    @Environment(\.modelContext) private var modelContext

    @State private var result:      AnalysisResult? = nil
    @State private var phase:       AnalysisPhase?  = nil   // nil = idle
    @State private var analyzedID:  UUID?           = nil

    private var isRunning: Bool { phase == .analyzingRules || phase == .generatingNarrative }

    // MARK: Tokens

    private let shellBg       = Color(hex: "#0F1115")
    private let shellSurface  = Color(hex: "#1A1D24")
    private let shellElevated = Color(hex: "#23262E")
    private let shellBorder   = Color(hex: "#2E333F")
    private let accentRust    = Color(hex: "#C25E30")
    private let textPrimary   = Color(hex: "#F8F9FA")
    private let textSecondary = Color(hex: "#94A3B8")
    private let textTertiary  = Color(hex: "#64748B")

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
        .onAppear {
            // Restore persisted analysis without re-running
            if let stored = deal.aiAnalysisText, !stored.isEmpty, result == nil {
                analyzedID = deal.id
                result = quickResult(from: stored)
            }
        }
        .onChange(of: deal.id) {
            // Deal switched in the inspector — clear stale result
            result     = nil
            analyzedID = nil
            if let stored = deal.aiAnalysisText, !stored.isEmpty {
                analyzedID = deal.id
                result = quickResult(from: stored)
            }
        }
        .onChange(of: refreshID) {
            // InspectorPane bumped refreshID because deal data was edited or a
            // benchmark was applied. Invalidate the in-memory result so the panel
            // returns to idle and the user is prompted to re-run the analysis.
            result     = nil
            analyzedID = nil
        }
    }

    // MARK: Idle State

    private var idleState: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("01 // AI_VIBE_CHECK")

            VStack(alignment: .leading, spacing: 8) {
                logLine(">", "no analysis run for this deal")
                logLine(">", "triggers on: commit, manual run")
                logLine(">", "reads: RE · hospitality · design · circular")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Rectangle().fill(shellBorder).frame(height: 1)

            runButton(label: "[ RUN ANALYSIS ]")
        }
    }

    // MARK: Running State

    private var runningState: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("01 // AI_VIBE_CHECK")

            VStack(alignment: .leading, spacing: 8) {
                if phase == .analyzingRules || phase == .generatingNarrative {
                    logLine(">", "scanning real estate metrics...")
                    logLine(">", "scanning hospitality metrics...")
                    logLine(">", "scanning design metrics...")
                    logLine(">", "scanning circular economy metrics...")
                }
                if phase == .generatingNarrative {
                    logLine(">", "[ ANALYZING_RULES... ] done")
                    logLine(">", "[ GENERATING_NARRATIVE... ] calling local LLM...")
                } else if phase == .analyzingRules {
                    logLine(">", "[ ANALYZING_RULES... ]")
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    // MARK: Result View

    @ViewBuilder
    private func resultView(_ r: AnalysisResult) -> some View {
        // Grade banner
        gradeBanner(r)
        Rectangle().fill(shellBorder).frame(height: 1)

        // Headline
        Text(r.headline)
            .font(.custom("JetBrains Mono", size: 12))
            .foregroundStyle(textSecondary)
            .lineSpacing(1.6)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

        Rectangle().fill(shellBorder).frame(height: 1)

        // LLM offline warning
        if case .done(let llmOffline) = phase, llmOffline {
            llmOfflineBanner
        }

        // Signal sections
        signalSection(title: "REAL ESTATE",         signals: r.realEstateSignals)
        signalSection(title: "HOSPITALITY",         signals: r.hospitalitySignals)
        signalSection(title: "DESIGN",              signals: r.designSignals)
        signalSection(title: "CIRCULAR ECONOMY",    signals: r.circularSignals)
        signalSection(title: "MARKET INTELLIGENCE", signals: r.marketIntelligenceSignals)

        // Assessment
        if !r.summary.isEmpty {
            sectionHeader("// ASSESSMENT")
            Text(r.summary)
                .font(.custom("JetBrains Mono", size: 12))
                .foregroundStyle(textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(1.6)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            Rectangle().fill(shellBorder).frame(height: 1)
        }

        // Stat summary row
        statRow(r)
        Rectangle().fill(shellBorder).frame(height: 1)

        // Regenerate button
        runButton(label: "[ REGENERATE ]")
    }

    // MARK: Grade Banner

    private func gradeBanner(_ r: AnalysisResult) -> some View {
        let gradeColor = Color(hex: r.grade.hexColor)
        return VStack(spacing: 6) {
            Text(r.grade.rawValue)
                .font(.custom("JetBrains Mono", size: 48).weight(.bold))
                .monospacedDigit()
                .foregroundStyle(gradeColor)

            Text(r.grade.label)
                .font(.custom("JetBrains Mono", size: 11).weight(.bold))
                .tracking(0.1)
                .foregroundStyle(gradeColor)

            if let score = deal.porteosScore {
                Text("\(Int(score.rounded())) / 100 PORTEOS SCORE")
                    .font(.custom("JetBrains Mono", size: 10))
                    .foregroundStyle(textTertiary)
                    .monospacedDigit()
            } else {
                Text("SCORE PENDING — COMMIT DEAL DATA")
                    .font(.custom("JetBrains Mono", size: 10))
                    .foregroundStyle(textTertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(shellElevated)
    }

    // MARK: Signal Section

    @ViewBuilder
    private func signalSection(title: String, signals: [AnalysisSignal]) -> some View {
        if !signals.isEmpty {
            sectionHeader("// \(title)")

            VStack(alignment: .leading, spacing: 8) {
                ForEach(signals.indices, id: \.self) { i in
                    signalRow(signals[i])
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Rectangle().fill(shellBorder).frame(height: 1)
        }
    }

    private func signalRow(_ signal: AnalysisSignal) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 8) {
                Text(signal.prefix)
                    .font(.custom("JetBrains Mono", size: 12).weight(.bold))
                    .foregroundStyle(sentimentColor(signal.sentiment))
                    .frame(width: 12, alignment: .leading)

                Text(signal.message)
                    .font(.custom("JetBrains Mono", size: 12))
                    .foregroundStyle(textSecondary)
                    .lineSpacing(1.6)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.leading, 2)
            }

            // Actionable suggestion — only rendered when the signal carries one
            if let action = signal.action {
                HStack(spacing: 8) {
                    // Indent to align with message text
                    Rectangle().fill(Color.clear).frame(width: 22)

                    Button { applyAction(action) } label: {
                        Text("[ APPLY ]")
                            .font(.custom("JetBrains Mono", size: 11).weight(.bold))
                            .foregroundStyle(Color(hex: "#0F1115"))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 8)
                            .background(Color(hex: "#C25E30"))
                            .clipShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    if case .applyBenchmark(let value, let field) = action {
                        Text("→ sets \(fieldLabel(field)) to \(formatActionValue(value, field: field))")
                            .font(.custom("JetBrains Mono", size: 11))
                            .foregroundStyle(Color(hex: "#64748B"))
                    }
                }
            }
        }
    }

    // MARK: Apply Benchmark

    private func applyAction(_ action: AnalysisSignal.Action) {
        switch action {
        case .applyBenchmark(let value, let field):
            // Snapshot BEFORE mutating so the user can undo this benchmark apply.
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

    private func formatActionValue(_ v: Double, field: String) -> String {
        switch field {
        case "interestRate", "vacancyRate", "hospitalityOccupancyRate":
            return String(format: "%.2f%%", v)
        case "hospitalityADR":
            return String(format: "€%.0f", v)
        default:
            return String(format: "%.2f", v)
        }
    }

    // MARK: Stat Summary Row

    private func statRow(_ r: AnalysisResult) -> some View {
        HStack(spacing: 0) {
            statCell(label: "PROFILES", value: "\(r.activeProfileCount)")
            divider
            statCell(label: "POSITIVE", value: "\(r.positiveCount)", color: Color(hex: "#10B981"))
            divider
            statCell(label: "CAUTION", value: "\(r.warningCount)",   color: Color(hex: "#F59E0B"))
            divider
            statCell(label: "CRITICAL", value: "\(r.criticalCount)", color: Color(hex: "#EF4444"))
        }
        .frame(height: 44)
        .background(shellElevated)
    }

    private func statCell(label: String, value: String, color: Color = Color(hex: "#94A3B8")) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.custom("JetBrains Mono", size: 17).weight(.bold))
                .monospacedDigit()
                .foregroundStyle(color)
            Text(label)
                .font(.custom("JetBrains Mono", size: 9).weight(.medium))
                .tracking(0.06)
                .foregroundStyle(Color(hex: "#64748B"))
        }
        .frame(maxWidth: .infinity)
    }

    private var divider: some View {
        Rectangle().fill(shellBorder).frame(width: 1, height: 28)
    }

    // MARK: Run Button

    // MARK: LLM Offline Banner

    private var llmOfflineBanner: some View {
        HStack(spacing: 6) {
            Text("~")
                .font(.custom("JetBrains Mono", size: 11).weight(.bold))
                .foregroundStyle(Color(hex: "#F59E0B"))
            Text("Local LLM offline. Using rule-based analysis only.")
                .font(.custom("JetBrains Mono", size: 11))
                .foregroundStyle(Color(hex: "#94A3B8"))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: "#1A1D24"))
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color(hex: "#2E333F")).frame(height: 1)
        }
    }

    private func runButton(label: String) -> some View {
        Button { runAnalysis() } label: {
            Text(label)
                .font(.custom("JetBrains Mono", size: 13).weight(.bold))
                .foregroundStyle(Color(hex: "#0F1115"))
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background(accentRust)
                .clipShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: Section Header

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.custom("JetBrains Mono", size: 11).weight(.bold))
            .tracking(0.08)
            .foregroundStyle(textTertiary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
    }

    private func logLine(_ prefix: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(prefix)
                .font(.custom("JetBrains Mono", size: 13))
                .foregroundStyle(accentRust)
            Text(text)
                .font(.custom("JetBrains Mono", size: 13))
                .foregroundStyle(textSecondary)
        }
    }

    // MARK: Analysis Runner

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
                result      = r
                analyzedID  = deal.id
                // Persist analysis text only — do NOT touch deal.updatedAt here.
                // Setting updatedAt would trigger InspectorPane's onChange which
                // immediately wipes the text we just stored.
                deal.aiAnalysisText = r.formattedText
                try? modelContext.save()
            }
        }
    }

    // MARK: Restore from stored text

    /// Builds a minimal AnalysisResult from the stored plain-text so the panel
    /// shows something without re-running the analysis on every appear.
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

    // MARK: Helpers

    private func sentimentColor(_ s: AnalysisSignal.Sentiment) -> Color {
        switch s {
        case .positive: return Color(hex: "#10B981")
        case .neutral:  return Color(hex: "#64748B")
        case .warning:  return Color(hex: "#F59E0B")
        case .critical: return Color(hex: "#EF4444")
        }
    }
}

// MARK: - Preview

#Preview {
    let config    = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: PropertyDeal.self, configurations: config)
    let deal      = PropertyDeal(propertyName: "Lisbon Office Block A", purchasePrice: 2_000_000,
                                 grossPotentialIncome: 180_000, vacancyRate: 5,
                                 operatingExpenses: 55_000, loanAmount: 1_500_000,
                                 interestRate: 4.5, porteosScore: 73)
    container.mainContext.insert(deal)
    return HStack(spacing: 0) {
        Spacer()
        AIVibePanel(deal: deal, refreshID: UUID())
            .frame(width: 320)
            .background(Color(hex: "#1A1D24"))
    }
    .frame(width: 600, height: 800)
    .background(Color(hex: "#0F1115"))
    .modelContainer(container)
}
