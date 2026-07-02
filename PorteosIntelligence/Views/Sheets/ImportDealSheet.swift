import SwiftUI
import SwiftData
import UniformTypeIdentifiers

// MARK: - ImportDealSheet

struct ImportDealSheet: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss)      private var dismiss

    @State private var showFilePicker = false
    @State private var selectedFile:  String              = ""
    @State private var headers:       [String]            = []
    @State private var parsedRows:    [[String: String]]  = []
    @State private var errorMessage:  String?             = nil

    private var hasFile: Bool { !parsedRows.isEmpty }

    var body: some View {
        TerminalSheetShell(command: "deal --import", width: 560) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    fileSection
                    if hasFile {
                        TerminalStructuralDivider()
                        previewSection
                    }
                    if let error = errorMessage {
                        TerminalStructuralDivider()
                        errorBanner(error)
                    }
                }
            }
        } footer: {
            TerminalSheetFooter(
                cancelAction: { dismiss() },
                primaryLabel: "[ IMPORT_DEALS ]",
                primaryAction: importDeals,
                primaryEnabled: hasFile,
                primaryColor: .rust
            )
        }
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [
                UTType(filenameExtension: "csv") ?? .plainText,
                .json
            ],
            allowsMultipleSelection: false,
            onCompletion: handleFileResult
        )
    }

    private var fileSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            TerminalSectionLabel(text: "01 // FILE_SELECTION")

            HStack(spacing: 12) {
                Button("[ SELECT_FILE ]") { showFilePicker = true }
                    .buttonStyle(TerminalButtonStyle(outlined: .green))

                Text(selectedFile.isEmpty ? "No file selected" : selectedFile)
                    .font(DesignTokens.mono(size: 11))
                    .foregroundStyle(selectedFile.isEmpty ? DesignTokens.textDim : DesignTokens.textSecondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
        .padding(DesignTokens.blockGutter)
    }

    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            TerminalSectionLabel(text: "02 // IMPORT_PREVIEW  [\(parsedRows.count) row\(parsedRows.count == 1 ? "" : "s") detected]")

            VStack(spacing: 0) {
                previewHeaderRow
                TerminalStructuralDivider()
                ForEach(Array(parsedRows.prefix(3).enumerated()), id: \.offset) { idx, row in
                    previewDataRow(row)
                    if idx < min(2, parsedRows.count - 1) {
                        TerminalStructuralDivider()
                    }
                }
                if parsedRows.count > 3 {
                    TerminalStructuralDivider()
                    HStack {
                        Text("+ \(parsedRows.count - 3) more row\(parsedRows.count - 3 == 1 ? "" : "s") not shown")
                            .font(DesignTokens.mono(size: 10))
                            .foregroundStyle(DesignTokens.textDim)
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .frame(height: DesignTokens.rowHeightData)
                    .background(DesignTokens.surfaceElevated)
                }
            }
            .background(DesignTokens.surfacePanel)
            .overlay(Rectangle().strokeBorder(DesignTokens.dividerStructural, lineWidth: 1))
            .clipShape(Rectangle())
        }
        .padding(DesignTokens.blockGutter)
    }

    private var previewHeaderRow: some View {
        HStack(spacing: 0) {
            previewCell("NAME", width: 160, isHeader: true)
            TerminalStructuralDivider().frame(width: 1, height: DesignTokens.rowHeightData)
            previewCell("PRICE", width: 100, isHeader: true)
            TerminalStructuralDivider().frame(width: 1, height: DesignTokens.rowHeightData)
            previewCell("LOCATION", width: 140, isHeader: true)
            TerminalStructuralDivider().frame(width: 1, height: DesignTokens.rowHeightData)
            previewCell("TYPE", width: nil, isHeader: true)
        }
        .frame(height: DesignTokens.rowHeightData)
        .background(DesignTokens.surfaceElevated)
    }

    private func previewDataRow(_ row: [String: String]) -> some View {
        HStack(spacing: 0) {
            previewCell(row["Name"] ?? "—", width: 160, isHeader: false)
            TerminalStructuralDivider().frame(width: 1, height: DesignTokens.rowHeightData)
            previewCell(row["Price"] ?? "—", width: 100, isHeader: false)
            TerminalStructuralDivider().frame(width: 1, height: DesignTokens.rowHeightData)
            previewCell(row["Location"] ?? "—", width: 140, isHeader: false)
            TerminalStructuralDivider().frame(width: 1, height: DesignTokens.rowHeightData)
            previewCell(row["Type"] ?? "—", width: nil, isHeader: false)
        }
        .frame(height: DesignTokens.rowHeightData)
    }

    private func previewCell(_ text: String, width: CGFloat?, isHeader: Bool) -> some View {
        Text(text)
            .font(DesignTokens.mono(size: isHeader ? 10 : 11))
            .foregroundStyle(isHeader ? DesignTokens.textDim : DesignTokens.textSecondary)
            .lineLimit(1)
            .padding(.horizontal, 8)
            .frame(width: width, alignment: .leading)
            .frame(maxWidth: width == nil ? .infinity : nil, alignment: .leading)
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 8) {
            Text("ERR >")
                .font(DesignTokens.mono(size: 11, weight: .bold))
                .foregroundStyle(DesignTokens.statusCritical)
            Text(message)
                .font(DesignTokens.mono(size: 11))
                .foregroundStyle(DesignTokens.textSecondary)
                .lineLimit(2)
            Spacer()
        }
        .padding(.horizontal, DesignTokens.blockGutter)
        .frame(minHeight: DesignTokens.rowHeightHeader)
        .padding(.vertical, 8)
        .background(DesignTokens.statusCritical.opacity(0.05))
    }

    private func handleFileResult(_ result: Result<[URL], Error>) {
        errorMessage = nil
        parsedRows   = []
        headers      = []

        switch result {
        case .failure(let error):
            errorMessage = error.localizedDescription
        case .success(let urls):
            guard let url = urls.first else { return }
            let secured = url.startAccessingSecurityScopedResource()
            defer { if secured { url.stopAccessingSecurityScopedResource() } }
            do {
                let raw = try String(contentsOf: url, encoding: .utf8)
                selectedFile = url.lastPathComponent
                parseCSV(raw)
            } catch {
                errorMessage = "Read failed: \(error.localizedDescription)"
            }
        }
    }

    private func parseCSV(_ content: String) {
        let lines = content
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        guard lines.count >= 2 else {
            errorMessage = "File contains no data rows."
            return
        }

        headers = lines[0]
            .components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }

        parsedRows = lines.dropFirst().map { line in
            let values = line
                .components(separatedBy: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
            var row: [String: String] = [:]
            for (i, header) in headers.enumerated() {
                row[header] = i < values.count ? values[i] : ""
            }
            return row
        }
    }

    private func importDeals() {
        for row in parsedRows {
            let price = Double((row["Price"] ?? "").filter { $0.isNumber || $0 == "." }) ?? 0
            let deal = PropertyDeal(
                propertyName:  row["Name"] ?? "",
                propertyType:  row["Type"] ?? "",
                locationCity:  row["Location"] ?? "",
                purchasePrice: price
            )
            modelContext.insert(deal)
        }
        dismiss()
    }
}

#Preview {
    ImportDealSheet()
        .background(DesignTokens.canvasBase)
}
