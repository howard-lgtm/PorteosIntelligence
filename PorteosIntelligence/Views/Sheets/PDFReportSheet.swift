import SwiftUI
import SwiftData
import AppKit
import UniformTypeIdentifiers

// MARK: - PDFReportSheet
//
// A terminal-style configuration sheet for generating a PDF deal analysis
// report. The user selects which optional sections to include, then taps
// [ GENERATE & SAVE ] which invokes NSSavePanel and writes the PDF to disk.

struct PDFReportSheet: View {

    let deal: PropertyDeal

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss)      private var dismiss

    // ── State ─────────────────────────────────────────────────────────────────
    @State private var options     = ReportOptions()
    @State private var scenarios:  [DealScenario] = []
    @State private var isGenerating = false
    @State private var errorMessage: String?

    // ── Design tokens ─────────────────────────────────────────────────────────
    private let shellBg      = Color(hex: "#0F1115")
    private let shellSurface = Color(hex: "#1A1D24")
    private let shellBorder  = Color(hex: "#2E333F")
    private let textPrimary  = Color(hex: "#F8F9FA")
    private let textSecondary = Color(hex: "#94A3B8")
    private let textTertiary  = Color(hex: "#64748B")
    private let accentRust   = Color(hex: "#C25E30")
    private let colorGreen   = Color(hex: "#10B981")
    private let colorAmber   = Color(hex: "#F59E0B")

    // ── Computed ──────────────────────────────────────────────────────────────
    private var estimatedPages: Int {
        var n = 3   // cover + real estate + multi-profile always included
        if options.includeAIAnalysis { n += 1 }
        if options.includeValidation { n += 1 }
        if options.includeScenarios && !scenarios.isEmpty { n += 1 }
        return n
    }

    private var hasAIAnalysis: Bool { deal.aiAnalysisText != nil && !(deal.aiAnalysisText?.isEmpty ?? true) }
    private var hasScenarios:  Bool { !scenarios.isEmpty }

    // MARK: Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            sheetHeader
            Rectangle().fill(shellBorder).frame(height: 1)
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    dealInfoSection
                    divider
                    sectionsSection
                    divider
                    outputDetailsSection
                    divider
                    if let err = errorMessage {
                        errorBanner(err)
                    }
                    generateButton
                }
            }
        }
        .frame(width: 460)
        .background(shellBg)
        .clipShape(Rectangle())
        .onAppear { loadScenarios() }
    }

    // MARK: – Header

    private var sheetHeader: some View {
        HStack(spacing: 0) {
            Text("porteos@system ~ % pdf_report_generator")
                .font(.custom("JetBrains Mono", size: 12))
                .foregroundStyle(textTertiary)
            Spacer()
            Button { dismiss() } label: {
                Text("[ × ]")
                    .font(.custom("JetBrains Mono", size: 13).weight(.bold))
                    .foregroundStyle(textSecondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .frame(height: 36)
        .background(shellSurface)
    }

    // MARK: – Deal Info Section

    private var dealInfoSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionLabel("DEAL INFORMATION")
            infoRow("PROPERTY", deal.propertyName.isEmpty ? "Untitled" : deal.propertyName)
            thinDivider
            infoRow("LOCATION", deal.locationCity.isEmpty ? "—" : deal.locationCity)
            thinDivider
            infoRow("STATUS",   deal.status.rawValue.uppercased())
            thinDivider
            infoRow("PORTEOS SCORE", deal.porteosScore.map { "\(Int($0.rounded())) / 100" } ?? "—")
        }
    }

    // MARK: – Sections Section

    private var sectionsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionLabel("ALWAYS INCLUDED")
            staticRow("01 // COVER PAGE",                "deal identity, score, profile weights")
            thinDivider
            staticRow("02 // REAL ESTATE FINANCIALS",    "revenue, OpEx, profitability, leverage, returns")
            thinDivider
            staticRow("03 // HOSPITALITY + DESIGN + CIRCULAR", "performance metrics across all profiles")

            sectionLabel("OPTIONAL SECTIONS")
            optionRow(
                "04 // AI VIBE ASSESSMENT",
                hasAIAnalysis ? "// includes grade, signals & summary" : "// no analysis cached — run in Inspector first",
                binding:   $options.includeAIAnalysis,
                available: hasAIAnalysis
            )
            thinDivider
            optionRow(
                "05 // DATA VALIDATION LOG",
                "// includes all critical errors and warnings",
                binding:   $options.includeValidation,
                available: true
            )
            thinDivider
            optionRow(
                "06 // SAVED SCENARIOS",
                hasScenarios ? "// includes \(scenarios.count) scenario(s)" : "// no scenarios saved for this deal",
                binding:   $options.includeScenarios,
                available: hasScenarios
            )
        }
    }

    // MARK: – Output Details Section

    private var outputDetailsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionLabel("OUTPUT DETAILS")
            infoRow("FORMAT",          "PDF  //  A4  (595 × 842 pt)")
            thinDivider
            infoRow("MARGINS",         "40 pt  //  CONTENT WIDTH: 515 pt")
            thinDivider
            infoRow("FONT",            "JETBRAINS MONO")
            thinDivider
            infoRow("ESTIMATED PAGES", "\(estimatedPages)")
            thinDivider
            HStack {
                Button(action: { options.blackAndWhite.toggle() }) {
                    HStack(spacing: 8) {
                        Rectangle()
                            .fill(options.blackAndWhite ? shellBorder : Color.clear)
                            .frame(width: 16, height: 16)
                            .overlay(
                                Rectangle()
                                    .stroke(shellBorder, lineWidth: 1)
                            )
                            .overlay(
                                Text(options.blackAndWhite ? "✓" : "")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(textPrimary)
                            )
                        Text("BLACK_AND_WHITE_MODE")
                            .font(.custom("JetBrains Mono", size: 11))
                            .foregroundColor(textSecondary)
                    }
                }
                .buttonStyle(.plain)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 8)

            if options.blackAndWhite {
                Text("[ INFO ] PDF will be optimized for black & white printing")
                    .font(.custom("JetBrains Mono", size: 10))
                    .foregroundColor(textTertiary)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
            }
        }
    }

    // MARK: – Generate Button

    private var generateButton: some View {
        Button { generateAndSave() } label: {
            ZStack {
                Rectangle()
                    .fill(isGenerating ? Color(hex: "#2E333F") : accentRust)
                Text(isGenerating ? "// GENERATING…" : "[ GENERATE & SAVE ]")
                    .font(.custom("JetBrains Mono", size: 13).weight(.bold))
                    .foregroundStyle(isGenerating ? textTertiary : Color(hex: "#0F1115"))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 38)
            .clipShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .disabled(isGenerating)
    }

    // MARK: – Reusable Row Views

    private func sectionLabel(_ label: String) -> some View {
        HStack {
            Text("// \(label)")
                .font(.custom("JetBrains Mono", size: 9.5))
                .foregroundStyle(textTertiary)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 6)
    }

    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top, spacing: 0) {
            Text(label)
                .font(.custom("JetBrains Mono", size: 11))
                .foregroundStyle(textSecondary)
            Spacer()
            Text(value)
                .font(.custom("JetBrains Mono", size: 11).weight(.medium))
                .foregroundStyle(textPrimary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 9)
        .background(shellSurface)
    }

    private func staticRow(_ label: String, _ note: String) -> some View {
        HStack(spacing: 10) {
            Text("[ ─ ]")
                .font(.custom("JetBrains Mono", size: 11))
                .foregroundStyle(textTertiary)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.custom("JetBrains Mono", size: 11).weight(.medium))
                    .foregroundStyle(textSecondary)
                Text(note)
                    .font(.custom("JetBrains Mono", size: 9))
                    .foregroundStyle(textTertiary)
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(shellSurface)
    }

    private func optionRow(
        _ label:    String,
        _ note:     String,
        binding:    Binding<Bool>,
        available:  Bool
    ) -> some View {
        HStack(spacing: 10) {
            Button {
                guard available else { return }
                binding.wrappedValue.toggle()
            } label: {
                Text(binding.wrappedValue && available ? "[ ✓ ]" : "[   ]")
                    .font(.custom("JetBrains Mono", size: 11).weight(.bold))
                    .foregroundStyle(binding.wrappedValue && available ? accentRust : textTertiary)
            }
            .buttonStyle(.plain)
            .disabled(!available)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.custom("JetBrains Mono", size: 11).weight(.medium))
                    .foregroundStyle(available ? textPrimary : textTertiary)
                Text(note)
                    .font(.custom("JetBrains Mono", size: 9))
                    .foregroundStyle(available ? textTertiary : textTertiary.opacity(0.5))
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(shellSurface)
    }

    private func errorBanner(_ msg: String) -> some View {
        HStack {
            Text("[ERR]  \(msg)")
                .font(.custom("JetBrains Mono", size: 10))
                .foregroundStyle(colorAmber)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(colorAmber.opacity(0.08))
    }

    private var divider: some View {
        Rectangle().fill(shellBorder).frame(height: 1)
    }

    private var thinDivider: some View {
        Rectangle()
            .fill(shellBorder.opacity(0.5))
            .frame(height: 1)
            .padding(.horizontal, 20)
    }

    // MARK: – Data Operations

    private func loadScenarios() {
        let id   = deal.id
        let desc = FetchDescriptor<DealScenario>(
            predicate: #Predicate { $0.dealID == id },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        scenarios = (try? modelContext.fetch(desc)) ?? []
        // Auto-disable scenarios option if none exist
        if scenarios.isEmpty { options.includeScenarios = false }
        // Auto-disable AI if no analysis text
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
        panel.title                  = "Save PDF Report"
        panel.message                = "Choose where to save the deal analysis report."
        panel.nameFieldStringValue   = "\(safeName)_porteos_report_\(timestamp).pdf"
        panel.allowedContentTypes    = [.pdf]
        panel.canCreateDirectories   = true

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
    container.mainContext.insert(deal)

    return PDFReportSheet(deal: deal)
        .modelContainer(container)
}
