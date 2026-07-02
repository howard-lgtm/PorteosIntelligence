import SwiftUI
import AppKit
import UniformTypeIdentifiers

// MARK: - BulkExportSheet

struct BulkExportSheet: View {

    let allDeals: [PropertyDeal]
    let filteredDeals: [PropertyDeal]

    @Environment(\.dismiss) private var dismiss

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

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            TerminalCLIHeader(
                command: "deal --export --format=\(format.rawValue.lowercased())",
                accentColor: DesignTokens.accentRust
            )
            TerminalStructuralDivider()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    formatRow
                    TerminalStructuralDivider()
                    depthRow
                    TerminalStructuralDivider()
                    scopeSection
                    TerminalStructuralDivider()
                    previewSection
                }
            }

            TerminalStructuralDivider()
            footerRow
        }
        .frame(width: 640, height: 560)
        .background(DesignTokens.canvasBase)
        .clipShape(Rectangle())
    }

    private var formatRow: some View {
        HStack(spacing: 0) {
            TerminalSectionLabel(text: "FORMAT")
            Spacer()
            HStack(spacing: 8) {
                ForEach(ExportFormat.allCases, id: \.self) { f in
                    toggleButton(label: f.rawValue, isActive: format == f) { format = f }
                }
            }
            .padding(.trailing, DesignTokens.blockGutter)
        }
        .padding(.leading, DesignTokens.blockGutter)
        .frame(height: 44)
    }

    private var depthRow: some View {
        HStack(spacing: 0) {
            TerminalSectionLabel(text: "FIELD DEPTH")
            Spacer()
            HStack(spacing: 8) {
                ForEach(ExportDepth.allCases, id: \.self) { d in
                    toggleButton(label: d.rawValue, isActive: depth == d) { depth = d }
                }
            }
            .padding(.trailing, DesignTokens.blockGutter)
        }
        .padding(.leading, DesignTokens.blockGutter)
        .frame(height: 44)
    }

    private var scopeSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            TerminalSectionLabel(text: "SCOPE")
                .padding(.horizontal, DesignTokens.blockGutter)
                .padding(.top, 12)
                .padding(.bottom, 10)

            VStack(alignment: .leading, spacing: 0) {
                ForEach(ScopeOption.allCases, id: \.self) { option in
                    scopeRow(option)
                    if option != ScopeOption.allCases.last {
                        TerminalStructuralDivider().padding(.leading, DesignTokens.blockGutter)
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
                    .fill(isActive ? DesignTokens.statusGo : Color.clear)
                    .frame(width: 2, height: 14)

                Text("[ \(option.rawValue) ]")
                    .font(DesignTokens.mono(size: 11, weight: isActive ? .bold : .regular))
                    .foregroundStyle(isActive ? DesignTokens.statusGo : DesignTokens.textDim)

                Spacer()

                Text("\(count) deal\(count == 1 ? "" : "s")")
                    .font(DesignTokens.mono(size: 11))
                    .foregroundStyle(isActive ? DesignTokens.statusGo : DesignTokens.textDim)
                    .padding(.trailing, DesignTokens.blockGutter)
            }
            .frame(height: DesignTokens.rowHeightData)
            .background(isActive ? DesignTokens.surfaceElevated : Color.clear)
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

    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                TerminalSectionLabel(text: "PREVIEW")
                Text("// first 3 rows · \(dealsToExport.count) deal\(dealsToExport.count == 1 ? "" : "s") selected")
                    .font(DesignTokens.mono(size: 10))
                    .foregroundStyle(DesignTokens.textDim)
                Spacer()
            }
            .padding(.horizontal, DesignTokens.blockGutter)
            .frame(height: DesignTokens.rowHeightData)

            TerminalStructuralDivider()

            if dealsToExport.isEmpty {
                Text("no deals match the current scope")
                    .font(DesignTokens.mono(size: 11))
                    .foregroundStyle(DesignTokens.textSecondary)
                    .padding(DesignTokens.blockGutter)
            } else {
                ScrollView([.horizontal, .vertical]) {
                    Text(previewText)
                        .font(DesignTokens.mono(size: 10))
                        .foregroundStyle(DesignTokens.textSecondary)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(height: 180)
                .background(DesignTokens.surfaceElevated)
            }
        }
    }

    private var previewText: String {
        guard !dealsToExport.isEmpty else { return "" }
        return DealExporter.previewLines(deals: dealsToExport, depth: depth, format: format, maxRows: 3)
    }

    private var footerRow: some View {
        HStack(spacing: 12) {
            if exportMessage.isEmpty {
                Text("\(dealsToExport.count) deal\(dealsToExport.count == 1 ? "" : "s") · \(depth.rawValue) · \(format.rawValue)")
                    .font(DesignTokens.mono(size: 10))
                    .foregroundStyle(DesignTokens.textDim)
            } else {
                Text(exportMessage)
                    .font(DesignTokens.mono(size: 10))
                    .foregroundStyle(exportMessage.hasPrefix("✓") ? DesignTokens.statusGo : DesignTokens.statusCritical)
                    .lineLimit(1)
            }

            Spacer()

            Button("[ CANCEL ]") { dismiss() }
                .font(DesignTokens.mono(size: 11))
                .foregroundStyle(DesignTokens.textSecondary)
                .buttonStyle(.plain)

            Button("[ EXPORT_FILE ]") { triggerExport() }
                .buttonStyle(TerminalButtonStyle(color: dealsToExport.isEmpty ? .muted : .rust))
                .disabled(dealsToExport.isEmpty)
        }
        .padding(.horizontal, DesignTokens.blockGutter)
        .frame(height: DesignTokens.rowHeightPaneBar + 16)
        .background(DesignTokens.surfacePanel)
    }

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

    private func toggleButton(label: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text("[ \(label) ]")
                .font(DesignTokens.mono(size: 11, weight: isActive ? .bold : .regular))
                .foregroundStyle(isActive ? DesignTokens.canvasBase : DesignTokens.textDim)
                .padding(.horizontal, 12)
                .frame(height: DesignTokens.rowHeightData)
                .background(isActive ? DesignTokens.accentRust : DesignTokens.surfaceElevated)
                .clipShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    let deals: [PropertyDeal] = [
        PropertyDeal(propertyName: "Lisbon Office Block A", purchasePrice: 2_400_000, status: .viable),
        PropertyDeal(propertyName: "Porto Hotel", purchasePrice: 4_800_000, status: .pipeline)
    ]
    BulkExportSheet(allDeals: deals, filteredDeals: deals)
        .background(DesignTokens.canvasBase)
}
