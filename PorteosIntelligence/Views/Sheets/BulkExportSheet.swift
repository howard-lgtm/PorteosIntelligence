import SwiftUI
import AppKit
import UniformTypeIdentifiers

// MARK: - BulkExportSheet

struct BulkExportSheet: View {

    /// All deals in the store (unfiltered).
    let allDeals: [PropertyDeal]
    /// Deals currently visible in the NavigationPane status filter.
    let filteredDeals: [PropertyDeal]

    @Environment(\.dismiss) private var dismiss

    // MARK: State

    @State private var format: ExportFormat   = .csv
    @State private var depth: ExportDepth     = .financials
    @State private var scope: ScopeOption     = .all
    @State private var exportMessage: String  = ""

    enum ScopeOption: String, CaseIterable {
        case all      = "ALL DEALS"
        case pipeline = "PIPELINE ONLY"
        case viable   = "VIABLE ONLY"
        case acquired = "ACQUIRED ONLY"
    }

    private var dealsToExport: [PropertyDeal] {
        switch scope {
        case .all:      return allDeals
        case .pipeline: return allDeals.filter { $0.status == .pipeline }
        case .viable:   return allDeals.filter { $0.status == .viable }
        case .acquired: return allDeals.filter { $0.status == .acquired }
        }
    }

    // MARK: Tokens

    private let shellBg       = Color(hex: "#0F1115")
    private let shellSurface  = Color(hex: "#1A1D24")
    private let shellElevated = Color(hex: "#23262E")
    private let shellBorder   = Color(hex: "#2E333F")
    private let accentRust    = Color(hex: "#C25E30")
    private let accentGreen   = Color(hex: "#10B981")
    private let textPrimary   = Color(hex: "#F8FAFC")
    private let textSecondary = Color(hex: "#94A3B8")
    private let textTertiary  = Color(hex: "#64748B")

    // MARK: Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            cliHeader
            Rectangle().fill(shellBorder).frame(height: 1)

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    formatRow
                    Rectangle().fill(shellBorder).frame(height: 1)
                    depthRow
                    Rectangle().fill(shellBorder).frame(height: 1)
                    scopeSection
                    Rectangle().fill(shellBorder).frame(height: 1)
                    previewSection
                }
            }

            Rectangle().fill(shellBorder).frame(height: 1)
            footerRow
        }
        .frame(width: 640, height: 560)
        .background(shellBg)
        .clipShape(Rectangle())
    }

    // MARK: CLI Header

    private var cliHeader: some View {
        HStack(spacing: 0) {
            Text("porteos@system ~ % ")
                .font(.custom("JetBrains Mono", size: 13))
                .foregroundStyle(textTertiary)
            Text("deal --export --format=\(format.rawValue.lowercased())")
                .font(.custom("JetBrains Mono", size: 13).weight(.bold))
                .foregroundStyle(accentRust)
                .lineLimit(1)
            Spacer()
        }
        .padding(.horizontal, 16)
        .frame(height: 36)
        .background(shellSurface)
    }

    // MARK: Format Row

    private var formatRow: some View {
        HStack(spacing: 0) {
            sectionLabel("FORMAT")
            Spacer()
            HStack(spacing: 8) {
                ForEach(ExportFormat.allCases, id: \.self) { f in
                    formatButton(label: f.rawValue, isActive: format == f) { format = f }
                }
            }
            .padding(.trailing, 16)
        }
        .padding(.leading, 16)
        .frame(height: 44)
    }

    // MARK: Depth Row

    private var depthRow: some View {
        HStack(spacing: 0) {
            sectionLabel("FIELD DEPTH")
            Spacer()
            HStack(spacing: 8) {
                ForEach(ExportDepth.allCases, id: \.self) { d in
                    formatButton(label: d.rawValue, isActive: depth == d) { depth = d }
                }
            }
            .padding(.trailing, 16)
        }
        .padding(.leading, 16)
        .frame(height: 44)
    }

    // MARK: Scope Section

    private var scopeSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionLabel("SCOPE")
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 10)

            VStack(alignment: .leading, spacing: 0) {
                ForEach(ScopeOption.allCases, id: \.self) { option in
                    scopeRow(option)
                    if option != ScopeOption.allCases.last {
                        Rectangle().fill(shellBorder).frame(height: 1).padding(.leading, 16)
                    }
                }
            }
            .padding(.bottom, 12)
        }
    }

    private func scopeRow(_ option: ScopeOption) -> some View {
        let count = countFor(option)
        let isActive = scope == option

        return Button { scope = option } label: {
            HStack(spacing: 8) {
                Rectangle()
                    .fill(isActive ? accentGreen : Color.clear)
                    .frame(width: 2, height: 14)

                Text("[ \(option.rawValue) ]")
                    .font(.custom("JetBrains Mono", size: 13).weight(isActive ? .bold : .regular))
                    .foregroundStyle(isActive ? accentGreen : textTertiary)

                Spacer()

                Text("\(count) deal\(count == 1 ? "" : "s")")
                    .font(.custom("JetBrains Mono", size: 13))
                    .foregroundStyle(isActive ? accentGreen : textTertiary)
                    .padding(.trailing, 16)
            }
            .frame(height: 32)
            .background(isActive ? shellElevated : Color.clear)
            .clipShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func countFor(_ option: ScopeOption) -> Int {
        switch option {
        case .all:      return allDeals.count
        case .pipeline: return allDeals.filter { $0.status == .pipeline }.count
        case .viable:   return allDeals.filter { $0.status == .viable }.count
        case .acquired: return allDeals.filter { $0.status == .acquired }.count
        }
    }

    // MARK: Preview Section

    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Text("PREVIEW")
                    .font(.custom("JetBrains Mono", size: 11).weight(.bold))
                    .tracking(0.08)
                    .foregroundStyle(textTertiary)
                Text("// first 3 rows · \(dealsToExport.count) deal\(dealsToExport.count == 1 ? "" : "s") selected")
                    .font(.custom("JetBrains Mono", size: 11))
                    .foregroundStyle(textTertiary)
                Spacer()
            }
            .padding(.horizontal, 16)
            .frame(height: 32)

            Rectangle().fill(shellBorder).frame(height: 1)

            if dealsToExport.isEmpty {
                Text("no deals match the current scope")
                    .font(.custom("JetBrains Mono", size: 13))
                    .foregroundStyle(textSecondary)
                    .padding(16)
            } else {
                ScrollView([.horizontal, .vertical]) {
                    Text(previewText)
                        .font(.custom("JetBrains Mono", size: 11))
                        .foregroundStyle(textSecondary)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(height: 180)
                .background(shellElevated)
            }
        }
    }

    private var previewText: String {
        guard !dealsToExport.isEmpty else { return "" }
        return DealExporter.previewLines(
            deals: dealsToExport,
            depth: depth,
            format: format,
            maxRows: 3
        )
    }

    // MARK: Footer

    private var footerRow: some View {
        HStack(spacing: 12) {
            // Status / error message
            if exportMessage.isEmpty {
                Text("\(dealsToExport.count) deal\(dealsToExport.count == 1 ? "" : "s") · \(depth.rawValue) · \(format.rawValue)")
                    .font(.custom("JetBrains Mono", size: 13))
                    .foregroundStyle(textTertiary)
            } else {
                Text(exportMessage)
                    .font(.custom("JetBrains Mono", size: 13))
                    .foregroundStyle(exportMessage.hasPrefix("✓") ? accentGreen : Color(hex: "#EF4444"))
                    .lineLimit(1)
            }

            Spacer()

            // Cancel
            Button { dismiss() } label: {
                Text("[ CANCEL ]")
                    .font(.custom("JetBrains Mono", size: 13))
                    .foregroundStyle(textSecondary)
                    .frame(height: 32)
            }
            .buttonStyle(.plain)

            // Export
            Button { triggerExport() } label: {
                Text("[ EXPORT_FILE ]")
                    .font(.custom("JetBrains Mono", size: 13).weight(.bold))
                    .foregroundStyle(dealsToExport.isEmpty ? textTertiary : Color(hex: "#0F1115"))
                    .padding(.horizontal, 16)
                    .frame(height: 32)
                    .background(dealsToExport.isEmpty ? shellElevated : accentRust)
                    .clipShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(dealsToExport.isEmpty)
        }
        .padding(.horizontal, 16)
        .frame(height: 56)
        .background(shellSurface)
    }

    // MARK: Export Action

    private func triggerExport() {
        let data: Data
        switch format {
        case .csv:  data = DealExporter.exportToCSV(deals: dealsToExport, depth: depth)
        case .json: data = DealExporter.exportToJSON(deals: dealsToExport, depth: depth)
        }

        let stamp = dateStamp()
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "porteos_export_\(stamp).\(format.fileExtension)"
        panel.allowedContentTypes  = [format.utType]
        panel.canCreateDirectories = true
        panel.title                = "Export Porteos Deals"

        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            do {
                try data.write(to: url)
                exportMessage = "✓ EXPORTED \(dealsToExport.count) DEAL\(dealsToExport.count == 1 ? "" : "S") → \(url.lastPathComponent)"
            } catch {
                exportMessage = "✗ ERROR: \(error.localizedDescription)"
            }
        }
    }

    private func dateStamp() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyyMMdd_HHmm"
        return f.string(from: Date())
    }

    // MARK: Shared Sub-views

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.custom("JetBrains Mono", size: 13).weight(.bold))
            .tracking(0.08)
            .foregroundStyle(textTertiary)
    }

    private func formatButton(label: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text("[ \(label) ]")
                .font(.custom("JetBrains Mono", size: 13).weight(isActive ? .bold : .regular))
                .foregroundStyle(isActive ? Color(hex: "#0F1115") : textTertiary)
                .padding(.horizontal, 12)
                .frame(height: 28)
                .background(isActive ? accentRust : shellElevated)
                .clipShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    let deals: [PropertyDeal] = [
        PropertyDeal(
            propertyName:         "Lisbon Office Block A",
            address:              "Av. da Liberdade, Lisboa",
            propertyType:         "Commercial",
            locationCity:         "Lisboa",
            purchasePrice:        2_400_000,
            grossPotentialIncome: 210_000,
            vacancyRate:          5,
            operatingExpenses:    72_000,
            loanAmount:           1_680_000,
            interestRate:         4.25,
            amortizationMonths:   360,
            porteosScore:         78,
            status:               .viable
        ),
        PropertyDeal(
            propertyName:  "Porto Hotel",
            address:       "Rua de Santa Catarina, Porto",
            propertyType:  "Hospitality",
            locationCity:  "Porto",
            purchasePrice: 4_800_000,
            status:        .pipeline
        )
    ]
    BulkExportSheet(allDeals: deals, filteredDeals: deals)
}
