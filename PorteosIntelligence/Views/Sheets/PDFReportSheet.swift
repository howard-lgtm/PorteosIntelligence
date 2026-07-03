import SwiftUI
import SwiftData
import AppKit
import UniformTypeIdentifiers

// MARK: - PDFReportSheet
// Figma img_00_16 — PDF report configuration sheet.

struct PDFReportSheet: View {

    let deal: PropertyDeal

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss)      private var dismiss

    @State private var options      = ReportOptions()
    @State private var scenarios:   [DealScenario] = []
    @State private var isGenerating = false
    @State private var errorMessage: String?

    private var estimatedPages: Int {
        var n = 3
        if options.includeAIAnalysis { n += 1 }
        if options.includeValidation { n += 1 }
        if options.includeScenarios && !scenarios.isEmpty { n += 1 }
        return n
    }

    private var hasAIAnalysis: Bool {
        deal.aiAnalysisText != nil && !(deal.aiAnalysisText?.isEmpty ?? true)
    }

    private var hasScenarios: Bool { !scenarios.isEmpty }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            sheetHeader
            TerminalStructuralDivider()
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    dealInfoSection
                    sectionDivider
                    sectionsSection
                    sectionDivider
                    outputDetailsSection
                    if let err = errorMessage {
                        sectionDivider
                        errorBanner(err)
                    }
                    generateButton
                }
            }
        }
        .frame(width: 480)
        .background(DesignTokens.canvasBase)
        .clipShape(Rectangle())
        .onAppear { loadScenarios() }
    }

    // MARK: Header

    private var sheetHeader: some View {
        HStack(spacing: 0) {
            Text("porteos@system ~ % ")
                .font(DesignTokens.cliPromptFont())
                .foregroundStyle(DesignTokens.textDim)
            Text("pdf_report_generator")
                .font(DesignTokens.mono(size: DesignTokens.TypeScale.cliPrompt, weight: .bold))
                .foregroundStyle(DesignTokens.accentRust)
            Spacer()
            Button { dismiss() } label: {
                Text("[ × ]")
                    .font(DesignTokens.mono(size: DesignTokens.TypeScale.cliPrompt, weight: .bold))
                    .foregroundStyle(DesignTokens.textSecondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, DesignTokens.blockGutter)
        .frame(height: DesignTokens.rowHeightPaneBar)
        .background(DesignTokens.surfacePanel)
    }

    // MARK: Deal Info

    private var dealInfoSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionLabel("DEAL INFORMATION")
            infoRow("PROPERTY", deal.propertyName.isEmpty ? "Untitled" : deal.propertyName)
            insetDivider
            infoRow("LOCATION", deal.locationCity.isEmpty ? "—" : deal.locationCity)
            insetDivider
            infoRow("STATUS", deal.status.rawValue.uppercased())
            insetDivider
            infoRow("PORTEOS SCORE", deal.porteosScore.map { "\(Int($0.rounded())) / 100" } ?? "—")
        }
    }

    // MARK: Sections

    private var sectionsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionLabel("ALWAYS INCLUDED")
            staticRow("01 // COVER PAGE", "deal identity, score, profile weights")
            insetDivider
            staticRow("02 // REAL ESTATE FINANCIALS", "revenue, OpEx, profitability, leverage, returns")
            insetDivider
            staticRow("03 // HOSPITALITY + DESIGN + CIRCULAR", "performance metrics across all profiles")

            sectionLabel("OPTIONAL SECTIONS")
            optionRow(
                "04 // AI VIBE ASSESSMENT",
                hasAIAnalysis ? "// includes grade, signals & summary" : "// no analysis cached — run in Inspector first",
                binding: $options.includeAIAnalysis,
                available: hasAIAnalysis
            )
            insetDivider
            optionRow(
                "05 // DATA VALIDATION LOG",
                "// includes all critical errors and warnings",
                binding: $options.includeValidation,
                available: true
            )
            insetDivider
            optionRow(
                "06 // SAVED SCENARIOS",
                hasScenarios ? "// includes \(scenarios.count) scenario(s)" : "// no scenarios saved for this deal",
                binding: $options.includeScenarios,
                available: hasScenarios
            )
        }
    }

    // MARK: Output Details

    private var outputDetailsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionLabel("OUTPUT DETAILS")
            infoRow("FORMAT", "PDF  //  A4  (595 × 842 pt)")
            insetDivider
            infoRow("MARGINS", "40 pt  //  CONTENT WIDTH: 515 pt")
            insetDivider
            infoRow("FONT", "JETBRAINS MONO")
            insetDivider
            infoRow("ESTIMATED PAGES", "\(estimatedPages)")
            insetDivider

            Button { options.blackAndWhite.toggle() } label: {
                HStack(spacing: 10) {
                    selectionSquare(isActive: options.blackAndWhite, useRustFill: true)
                    Text("BLACK_AND_WHITE_MODE")
                        .font(DesignTokens.rowLabelFont())
                        .foregroundStyle(DesignTokens.textPrimary)
                    Spacer()
                }
            }
            .buttonStyle(.plain)
            .padding(.horizontal, DesignTokens.blockGutter)
            .padding(.vertical, 10)
            .background(DesignTokens.surfacePanel)

            if options.blackAndWhite {
                Text("[ INFO ] PDF will be optimised for black & white printing.")
                    .font(DesignTokens.metaFont())
                    .foregroundStyle(DesignTokens.textDim)
                    .padding(.horizontal, DesignTokens.blockGutter)
                    .padding(.bottom, 10)
            }
        }
    }

    // MARK: Generate

    private var generateButton: some View {
        Button { generateAndSave() } label: {
            Text(isGenerating ? "[ GENERATING… ]" : "[ GENERATE & SAVE ]")
                .font(DesignTokens.mono(size: DesignTokens.TypeScale.rowLabel, weight: .bold))
                .foregroundStyle(isGenerating ? DesignTokens.textDim : DesignTokens.canvasBase)
                .frame(maxWidth: .infinity)
                .frame(height: DesignTokens.rowHeightButton + 4)
                .background(isGenerating ? DesignTokens.dividerStructural : DesignTokens.accentRust)
                .clipShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, DesignTokens.blockGutter)
        .padding(.vertical, 14)
        .disabled(isGenerating)
    }

    // MARK: Rows

    private func sectionLabel(_ label: String) -> some View {
        Text("// \(label)")
            .font(DesignTokens.mono(size: DesignTokens.TypeScale.meta, weight: .bold))
            .tracking(0.06)
            .foregroundStyle(DesignTokens.textDim)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, DesignTokens.blockGutter)
            .padding(.top, 14)
            .padding(.bottom, 6)
    }

    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(label)
                .font(DesignTokens.rowLabelFont())
                .foregroundStyle(DesignTokens.textSecondary)
            Spacer()
            Text(value)
                .font(DesignTokens.rowValueFont())
                .foregroundStyle(DesignTokens.textPrimary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, DesignTokens.blockGutter)
        .padding(.vertical, 9)
        .background(DesignTokens.surfacePanel)
    }

    private func staticRow(_ label: String, _ note: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text("[ ─ ]")
                .font(DesignTokens.rowLabelFont())
                .foregroundStyle(DesignTokens.textDim)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(DesignTokens.rowLabelFont())
                    .foregroundStyle(DesignTokens.textSecondary)
                Text(note)
                    .font(DesignTokens.metaFont())
                    .foregroundStyle(DesignTokens.textDim)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, DesignTokens.blockGutter)
        .padding(.vertical, 10)
        .background(DesignTokens.surfacePanel)
    }

    private func optionRow(
        _ label: String,
        _ note: String,
        binding: Binding<Bool>,
        available: Bool
    ) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Button {
                guard available else { return }
                binding.wrappedValue.toggle()
            } label: {
                Text(binding.wrappedValue && available ? "[ ✓ ]" : "[   ]")
                    .font(DesignTokens.mono(size: DesignTokens.TypeScale.rowLabel, weight: .bold))
                    .foregroundStyle(binding.wrappedValue && available
                                     ? DesignTokens.accentRust
                                     : DesignTokens.textDim)
            }
            .buttonStyle(.plain)
            .disabled(!available)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(DesignTokens.rowLabelFont())
                    .foregroundStyle(available ? DesignTokens.textPrimary : DesignTokens.textDim)
                Text(note)
                    .font(DesignTokens.metaFont())
                    .foregroundStyle(available ? DesignTokens.textDim : DesignTokens.textDim.opacity(0.55))
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, DesignTokens.blockGutter)
        .padding(.vertical, 10)
        .background(DesignTokens.surfacePanel)
    }

    private func selectionSquare(isActive: Bool, useRustFill: Bool = false) -> some View {
        Rectangle()
            .fill(isActive && useRustFill ? DesignTokens.accentRust : Color.clear)
            .frame(width: 14, height: 14)
            .overlay {
                Rectangle().strokeBorder(
                    isActive && useRustFill ? DesignTokens.accentRust : DesignTokens.dividerStructural,
                    lineWidth: DesignTokens.dividerWidth
                )
            }
    }

    private func errorBanner(_ msg: String) -> some View {
        HStack {
            Text("[ ERR ]  \(msg)")
                .font(DesignTokens.metaFont())
                .foregroundStyle(DesignTokens.statusWarn)
        }
        .padding(.horizontal, DesignTokens.blockGutter)
        .padding(.vertical, 8)
        .background(DesignTokens.statusWarn.opacity(0.08))
    }

    private var sectionDivider: some View {
        Rectangle()
            .fill(DesignTokens.dividerStructural)
            .frame(height: DesignTokens.dividerWidth)
    }

    private var insetDivider: some View {
        Rectangle()
            .fill(DesignTokens.dividerStructural.opacity(0.55))
            .frame(height: DesignTokens.dividerWidth)
            .padding(.horizontal, DesignTokens.blockGutter)
    }

    // MARK: Data

    private func loadScenarios() {
        let id   = deal.id
        let desc = FetchDescriptor<DealScenario>(
            predicate: #Predicate { $0.dealID == id },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        scenarios = (try? modelContext.fetch(desc)) ?? []
        if scenarios.isEmpty { options.includeScenarios = false }
        if !hasAIAnalysis { options.includeAIAnalysis = false }
    }

    private func generateAndSave() {
        isGenerating = true
        errorMessage = nil

        let reportScenarios = options.includeScenarios ? scenarios : []
        let generator = PDFReportGenerator()
        let data = generator.generateReport(deal: deal, options: options, scenarios: reportScenarios)

        guard !data.isEmpty else {
            errorMessage = "PDF generation failed. Please try again."
            isGenerating = false
            return
        }

        let safeName = (deal.propertyName.isEmpty ? "deal" : deal.propertyName)
            .lowercased()
            .replacingOccurrences(of: " ", with: "_")
            .filter { $0.isLetter || $0.isNumber || $0 == "_" || $0 == "-" }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmm"
        let timestamp = dateFormatter.string(from: Date())

        let panel = NSSavePanel()
        panel.title                = "Save PDF Report"
        panel.message              = "Choose where to save the deal analysis report."
        panel.nameFieldStringValue = "\(safeName)_porteos_report_\(timestamp).pdf"
        panel.allowedContentTypes  = [.pdf]
        panel.canCreateDirectories = true

        panel.begin { response in
            if response == .OK, let url = panel.url {
                do {
                    try data.write(to: url)
                } catch {
                    DispatchQueue.main.async {
                        self.errorMessage = "Failed to write file: \(error.localizedDescription)"
                        self.isGenerating = false
                    }
                    return
                }
            }
            DispatchQueue.main.async {
                self.isGenerating = false
                self.dismiss()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let config    = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: PropertyDeal.self, DealScenario.self, configurations: config)
    let deal      = PropertyDeal(propertyName: "Lisbon Office Block A", locationCity: "Lisbon")
    deal.porteosScore = 78
    deal.aiAnalysisText = "Sample analysis"
    container.mainContext.insert(deal)

    return PDFReportSheet(deal: deal)
        .modelContainer(container)
}
