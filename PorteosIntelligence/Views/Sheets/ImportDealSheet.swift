import SwiftUI
import SwiftData
import UniformTypeIdentifiers

// MARK: - ImportDealSheet

struct ImportDealSheet: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss)      private var dismiss

    // MARK: Tokens

    private let shellBg       = Color(hex: "#0F1115")
    private let shellSurface  = Color(hex: "#1A1D24")
    private let shellElevated = Color(hex: "#23262E")
    private let shellBorder   = Color(hex: "#2E333F")
    private let accentRust    = Color(hex: "#C25E30")
    private let accentGreen   = Color(hex: "#10B981")
    private let textPrimary   = Color(hex: "#F8F9FA")
    private let textSecondary = Color(hex: "#94A3B8")
    private let textTertiary  = Color(hex: "#64748B")

    // MARK: State

    @State private var showFilePicker = false
    @State private var selectedFile:  String              = ""
    @State private var headers:       [String]            = []
    @State private var parsedRows:    [[String: String]]  = []
    @State private var errorMessage:  String?             = nil

    private var hasFile: Bool { !parsedRows.isEmpty }

    // MARK: Body

    var body: some View {
        VStack(spacing: 0) {
            sheetHeader
            Rectangle().fill(shellBorder).frame(height: 1)

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    fileSection
                    if hasFile {
                        Rectangle().fill(shellBorder).frame(height: 1)
                        previewSection
                    }
                    if let error = errorMessage {
                        Rectangle().fill(shellBorder).frame(height: 1)
                        errorBanner(error)
                    }
                }
            }

            Rectangle().fill(shellBorder).frame(height: 1)
            footer
        }
        .background(shellBg)
        .clipShape(Rectangle())
        .frame(width: 560)
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

    // MARK: Header

    private var sheetHeader: some View {
        HStack(spacing: 0) {
            Text("porteos@system ~ % ")
                .font(.custom("JetBrains Mono", size: 11))
                .foregroundStyle(textTertiary)
            Text("deal --import")
                .font(.custom("JetBrains Mono", size: 11).weight(.bold))
                .foregroundStyle(accentRust)
            Spacer()
            Button { dismiss() } label: {
                Text("✕")
                    .font(.custom("JetBrains Mono", size: 14).weight(.bold))
                    .foregroundStyle(textTertiary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .frame(height: 40)
        .background(shellSurface)
    }

    // MARK: Section 1 — File Selection

    private var fileSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("01 // FILE_SELECTION")

            HStack(spacing: 12) {
                Button { showFilePicker = true } label: {
                    Text("[ SELECT_FILE ]")
                        .font(.custom("JetBrains Mono", size: 11))
                        .foregroundStyle(accentGreen)
                        .padding(.horizontal, 12)
                        .frame(height: 28)
                        .overlay(Rectangle().strokeBorder(accentGreen, lineWidth: 1))
                        .clipShape(Rectangle())
                }
                .buttonStyle(.plain)

                Text(selectedFile.isEmpty ? "No file selected" : selectedFile)
                    .font(.custom("JetBrains Mono", size: 11))
                    .foregroundStyle(selectedFile.isEmpty ? textTertiary : textSecondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
        .padding(16)
    }

    // MARK: Section 2 — Preview

    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("02 // IMPORT_PREVIEW  [\(parsedRows.count) row\(parsedRows.count == 1 ? "" : "s") detected]")

            VStack(spacing: 0) {
                previewHeaderRow
                Rectangle().fill(shellBorder).frame(height: 1)
                ForEach(Array(parsedRows.prefix(3).enumerated()), id: \.offset) { idx, row in
                    previewDataRow(row)
                    if idx < min(2, parsedRows.count - 1) {
                        Rectangle().fill(shellBorder).frame(height: 1)
                    }
                }
                if parsedRows.count > 3 {
                    Rectangle().fill(shellBorder).frame(height: 1)
                    HStack {
                        Text("+ \(parsedRows.count - 3) more row\(parsedRows.count - 3 == 1 ? "" : "s") not shown")
                            .font(.custom("JetBrains Mono", size: 10))
                            .foregroundStyle(textTertiary)
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .frame(height: 28)
                    .background(shellElevated)
                }
            }
            .background(shellSurface)
            .overlay(Rectangle().strokeBorder(shellBorder, lineWidth: 1))
            .clipShape(Rectangle())
        }
        .padding(16)
    }

    private var previewHeaderRow: some View {
        HStack(spacing: 0) {
            previewCell("NAME",     width: 160, isHeader: true)
            Rectangle().fill(shellBorder).frame(width: 1)
            previewCell("PRICE",    width: 100, isHeader: true)
            Rectangle().fill(shellBorder).frame(width: 1)
            previewCell("LOCATION", width: 140, isHeader: true)
            Rectangle().fill(shellBorder).frame(width: 1)
            previewCell("TYPE",     width: nil,  isHeader: true)
        }
        .frame(height: 28)
        .background(shellElevated)
    }

    private func previewDataRow(_ row: [String: String]) -> some View {
        HStack(spacing: 0) {
            previewCell(row["Name"]     ?? "—", width: 160, isHeader: false)
            Rectangle().fill(shellBorder).frame(width: 1)
            previewCell(row["Price"]    ?? "—", width: 100, isHeader: false)
            Rectangle().fill(shellBorder).frame(width: 1)
            previewCell(row["Location"] ?? "—", width: 140, isHeader: false)
            Rectangle().fill(shellBorder).frame(width: 1)
            previewCell(row["Type"]     ?? "—", width: nil,  isHeader: false)
        }
        .frame(height: 28)
    }

    private func previewCell(_ text: String, width: CGFloat?, isHeader: Bool) -> some View {
        Text(text)
            .font(.custom("JetBrains Mono", size: isHeader ? 10 : 11))
            .foregroundStyle(isHeader ? textTertiary : textSecondary)
            .lineLimit(1)
            .padding(.horizontal, 8)
            .frame(width: width, alignment: .leading)
            .frame(maxWidth: width == nil ? .infinity : nil, alignment: .leading)
    }

    // MARK: Error Banner

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 8) {
            Text("ERR >")
                .font(.custom("JetBrains Mono", size: 11).weight(.bold))
                .foregroundStyle(Color(hex: "#EF4444"))
            Text(message)
                .font(.custom("JetBrains Mono", size: 11))
                .foregroundStyle(textSecondary)
                .lineLimit(2)
            Spacer()
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 36)
        .padding(.vertical, 8)
        .background(Color(hex: "#EF4444").opacity(0.05))
    }

    // MARK: Footer

    private var footer: some View {
        HStack(spacing: 12) {
            Button { dismiss() } label: {
                Text("[ CANCEL ]")
                    .font(.custom("JetBrains Mono", size: 11))
                    .foregroundStyle(textSecondary)
                    .frame(height: 28)
            }
            .buttonStyle(.plain)

            Spacer()

            Button { importDeals() } label: {
                Text("[ IMPORT_DEALS ]")
                    .font(.custom("JetBrains Mono", size: 11).weight(.bold))
                    .foregroundStyle(Color(hex: "#0F1115"))
                    .padding(.horizontal, 16)
                    .frame(height: 28)
                    .background(hasFile ? accentRust : shellBorder)
                    .clipShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(!hasFile)
        }
        .padding(.horizontal, 16)
        .frame(height: 56)
        .background(shellSurface)
    }

    // MARK: Shared

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.custom("JetBrains Mono", size: 10).weight(.bold))
            .foregroundStyle(textTertiary)
    }

    // MARK: File Handling

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

    // MARK: CSV Parsing

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

    // MARK: Import

    private func importDeals() {
        for row in parsedRows {
            let price = Double(
                (row["Price"] ?? "").filter { $0.isNumber || $0 == "." }
            ) ?? 0
            let deal = PropertyDeal(
                propertyName:  row["Name"]     ?? "",
                propertyType:  row["Type"]     ?? "",
                locationCity:  row["Location"] ?? "",
                purchasePrice: price
            )
            modelContext.insert(deal)
        }
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    ImportDealSheet()
        .background(Color(hex: "#0F1115"))
}
