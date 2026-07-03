import SwiftUI
import AppKit
import UniformTypeIdentifiers

// MARK: - BulkExportSheet
// Figma img_00_15 — format, export depth, field scope, preview table.

struct BulkExportSheet: View {

    let allDeals: [PropertyDeal]
    let filteredDeals: [PropertyDeal]

    @Environment(\.dismiss) private var dismiss

    @State private var format: ExportFormat = .csv
    @State private var depthOption: ExportDepthOption = .standard
    @State private var includeBase            = true
    @State private var includeFinancial         = true
    @State private var includeProfileWeights  = true
    @State private var includeAIScores        = false
    @State private var exportMessage          = ""

    private var dealsToExport: [PropertyDeal] { allDeals }

    private var effectiveDepth: ExportDepth {
        if depthOption == .full || includeAIScores { return .allMetrics }
        if depthOption == .standard || includeFinancial { return .financials }
        return .base
    }

    private var previewFieldCount: Int {
        switch effectiveDepth {
        case .base:       return 4
        case .financials: return 8
        case .allMetrics: return 12
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
                    formatSection
                    TerminalStructuralDivider()
                    depthSection
                    TerminalStructuralDivider()
                    scopeSection
                    TerminalStructuralDivider()
                    previewSection
                }
            }

            TerminalStructuralDivider()
            footerRow
        }
        .frame(width: 460)
        .background(DesignTokens.canvasBase)
        .clipShape(Rectangle())
    }

    // MARK: Format

    private var formatSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionLabel("FORMAT")
            HStack(spacing: 0) {
                ForEach(ExportFormat.allCases, id: \.self) { item in
                    formatTab(item)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, DesignTokens.blockGutter)
        }
        .padding(.bottom, 8)
    }

    private func formatTab(_ item: ExportFormat) -> some View {
        let isActive = format == item
        return Button { format = item } label: {
            VStack(spacing: 0) {
                Spacer()
                Text(item.rawValue)
                    .font(DesignTokens.mono(size: DesignTokens.TypeScale.rowLabel, weight: isActive ? .bold : .regular))
                    .foregroundStyle(isActive ? DesignTokens.textPrimary : DesignTokens.textDim)
                    .padding(.horizontal, 12)
                Spacer()
                Rectangle()
                    .fill(isActive ? DesignTokens.textPrimary : Color.clear)
                    .frame(height: 2)
            }
            .frame(height: DesignTokens.rowHeightHeader + 2)
        }
        .buttonStyle(.plain)
    }

    // MARK: Export Depth

    private var depthSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionLabel("EXPORT DEPTH")
                .padding(.bottom, 6)

            ForEach(ExportDepthOption.allCases, id: \.self) { option in
                depthRow(option)
            }
        }
        .padding(.bottom, 8)
    }

    private func depthRow(_ option: ExportDepthOption) -> some View {
        let isActive = depthOption == option
        return Button {
            depthOption = option
            syncScopeWithDepth(option)
        } label: {
            HStack(alignment: .top, spacing: 10) {
                selectionSquare(isActive: isActive)
                VStack(alignment: .leading, spacing: 2) {
                    Text(option.rawValue)
                        .font(DesignTokens.mono(size: DesignTokens.TypeScale.rowLabel, weight: .bold))
                        .foregroundStyle(isActive ? DesignTokens.textPrimary : DesignTokens.textDim)
                    Text(option.subtitle)
                        .font(DesignTokens.metaFont())
                        .foregroundStyle(DesignTokens.textDim)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, DesignTokens.blockGutter)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }

    // MARK: Scope

    private var scopeSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionLabel("SCOPE")
                .padding(.bottom, 6)

            scopeToggle("BASE FIELDS",        isOn: $includeBase)
            scopeToggle("FINANCIAL DATA",     isOn: $includeFinancial)
            scopeToggle("PROFILE WEIGHTS",    isOn: $includeProfileWeights)
            scopeToggle("AI SCORES",         isOn: $includeAIScores)
        }
        .padding(.bottom, 8)
    }

    private func scopeToggle(_ label: String, isOn: Binding<Bool>) -> some View {
        Button { isOn.wrappedValue.toggle() } label: {
            HStack(spacing: 10) {
                selectionSquare(isActive: isOn.wrappedValue)
                Text(label)
                    .font(DesignTokens.mono(size: DesignTokens.TypeScale.rowLabel, weight: .bold))
                    .foregroundStyle(isOn.wrappedValue ? DesignTokens.textPrimary : DesignTokens.textDim)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, DesignTokens.blockGutter)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }

    private func selectionSquare(isActive: Bool) -> some View {
        ZStack {
            Rectangle()
                .fill(isActive ? ProfileType.circular.accentColor : Color.clear)
                .frame(width: 12, height: 12)
            Rectangle()
                .strokeBorder(DesignTokens.dividerStructural, lineWidth: DesignTokens.dividerWidth)
                .frame(width: 12, height: 12)
        }
    }

    // MARK: Preview

    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("PREVIEW")
                    .font(DesignTokens.sectionLabelFont())
                    .foregroundStyle(DesignTokens.textDim)
                Spacer()
                Text("\(format.rawValue) • \(dealsToExport.count) rows • \(previewFieldCount) fields")
                    .font(DesignTokens.metaFont())
                    .foregroundStyle(DesignTokens.textDim)
            }
            .padding(.horizontal, DesignTokens.blockGutter)

            if dealsToExport.isEmpty {
                Text("No deals available for export")
                    .font(DesignTokens.rowLabelFont())
                    .foregroundStyle(DesignTokens.textSecondary)
                    .padding(DesignTokens.blockGutter)
            } else {
                VStack(spacing: 0) {
                    previewHeaderRow
                    previewDivider
                    ForEach(Array(dealsToExport.prefix(3).enumerated()), id: \.element.id) { idx, deal in
                        previewDataRow(deal, index: idx + 1)
                        if idx < min(2, dealsToExport.count - 1) { previewDivider }
                    }
                }
                .overlay {
                    Rectangle().strokeBorder(DesignTokens.dividerStructural, lineWidth: DesignTokens.dividerWidth)
                }
                .clipShape(Rectangle())
                .padding(.horizontal, DesignTokens.blockGutter)
            }
        }
        .padding(.bottom, DesignTokens.blockGutter)
    }

    private var previewHeaderRow: some View {
        HStack(spacing: 0) {
            previewCell("ID", isHeader: true, width: 36)
            previewDividerVertical
            previewCell("DEAL NAME", isHeader: true, width: nil)
            previewDividerVertical
            previewCell("PRICE", isHeader: true, width: 72)
            previewDividerVertical
            previewCell("SCORE", isHeader: true, width: 44)
        }
        .frame(height: DesignTokens.rowHeightHeader)
        .background(DesignTokens.surfaceElevated)
    }

    private func previewDataRow(_ deal: PropertyDeal, index: Int) -> some View {
        HStack(spacing: 0) {
            previewCell(String(format: "%03d", index), isHeader: false, width: 36)
            previewDividerVertical
            previewCell(deal.propertyName.isEmpty ? "Untitled" : deal.propertyName, isHeader: false, width: nil)
            previewDividerVertical
            previewCell(String(format: "%.0f", deal.purchasePrice), isHeader: false, width: 72)
            previewDividerVertical
            previewCell(deal.porteosScore.map { String(format: "%.0f", $0) } ?? "—", isHeader: false, width: 44)
        }
        .frame(height: DesignTokens.rowHeightHeader)
        .background(DesignTokens.surfacePanel)
    }

    private func previewCell(_ text: String, isHeader: Bool, width: CGFloat?) -> some View {
        Text(text)
            .font(DesignTokens.mono(size: DesignTokens.TypeScale.meta, weight: isHeader ? .bold : .regular))
            .foregroundStyle(isHeader ? DesignTokens.textDim : DesignTokens.textSecondary)
            .lineLimit(1)
            .padding(.horizontal, 8)
            .frame(width: width, alignment: .leading)
            .frame(maxWidth: width == nil ? .infinity : nil, alignment: .leading)
    }

    private var previewDivider: some View {
        Rectangle()
            .fill(DesignTokens.dividerStructural)
            .frame(height: DesignTokens.dividerWidth)
    }

    private var previewDividerVertical: some View {
        Rectangle()
            .fill(DesignTokens.dividerStructural)
            .frame(width: DesignTokens.dividerWidth)
    }

    // MARK: Footer

    private var footerRow: some View {
        HStack(spacing: 12) {
            if !exportMessage.isEmpty {
                Text(exportMessage)
                    .font(DesignTokens.metaFont())
                    .foregroundStyle(exportMessage.hasPrefix("✓") ? DesignTokens.statusGo : DesignTokens.statusCritical)
                    .lineLimit(1)
            }

            Spacer()

            Button { dismiss() } label: {
                Text("[ CANCEL ]")
                    .font(DesignTokens.rowLabelFont())
                    .foregroundStyle(DesignTokens.textSecondary)
            }
            .buttonStyle(.plain)

            Button { triggerExport() } label: {
                Text("[ EXPORT ]")
            }
            .buttonStyle(TerminalButtonStyle(color: dealsToExport.isEmpty ? .muted : .rust))
            .disabled(dealsToExport.isEmpty)
        }
        .padding(.horizontal, DesignTokens.blockGutter)
        .frame(height: DesignTokens.rowHeightPaneBar + 16)
        .background(DesignTokens.surfacePanel)
    }

    // MARK: Export

    private func triggerExport() {
        let depth = effectiveDepth
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

    private func syncScopeWithDepth(_ option: ExportDepthOption) {
        switch option {
        case .summary:
            includeBase = true
            includeFinancial = false
            includeProfileWeights = false
            includeAIScores = false
        case .standard:
            includeBase = true
            includeFinancial = true
            includeProfileWeights = true
            includeAIScores = false
        case .full:
            includeBase = true
            includeFinancial = true
            includeProfileWeights = true
            includeAIScores = true
        }
    }

    private func dateStamp() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyyMMdd_HHmm"
        return f.string(from: Date())
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(DesignTokens.sectionLabelFont())
            .foregroundStyle(DesignTokens.textDim)
            .padding(.horizontal, DesignTokens.blockGutter)
            .padding(.top, 12)
    }
}

// MARK: - ExportDepthOption

private enum ExportDepthOption: String, CaseIterable {
    case summary  = "SUMMARY"
    case standard = "STANDARD"
    case full     = "FULL"

    var subtitle: String {
        switch self {
        case .summary:  return "Core fields only"
        case .standard: return "Base + all profile fields"
        case .full:     return "Everything incl. AI scores + audit"
        }
    }
}

#Preview {
    let deals: [PropertyDeal] = [
        PropertyDeal(propertyName: "Lisbon Office Block A", purchasePrice: 45_200_000, porteosScore: 87, status: .viable),
        PropertyDeal(propertyName: "Porto Waterfront Dev", purchasePrice: 38_000_000, porteosScore: 74, status: .pipeline),
        PropertyDeal(propertyName: "Madrid Logistics Park", purchasePrice: 29_500_000, porteosScore: 68, status: .pipeline)
    ]
    BulkExportSheet(allDeals: deals, filteredDeals: deals)
        .background(DesignTokens.canvasBase)
}
