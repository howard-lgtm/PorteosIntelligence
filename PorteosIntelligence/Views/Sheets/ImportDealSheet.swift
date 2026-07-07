import SwiftUI
import SwiftData
import UniformTypeIdentifiers

// MARK: - ImportDealSheet
// Figma img_00_14 — drop zone, CSV preview, column mapping.

struct ImportDealSheet: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss)      private var dismiss

    @State private var showFilePicker   = false
    @State private var selectedFile     = ""
    @State private var headers:          [String]            = []
    @State private var parsedRows:       [[String: String]]  = []
    @State private var errorMessage:   String?             = nil

    @State private var mapPropertyName  = ""
    @State private var mapPurchasePrice = ""
    @State private var mapLocation      = ""
    @State private var mapPropertyType  = ""

    private var hasFile: Bool { !parsedRows.isEmpty }

    private var mappedFieldCount: Int {
        [mapPropertyName, mapPurchasePrice, mapLocation, mapPropertyType]
            .filter { !$0.isEmpty }.count
    }

    private var canImport: Bool {
        hasFile && !mapPropertyName.isEmpty && !mapPurchasePrice.isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            TerminalCLIHeader(command: "deal --import --csv")
            TerminalStructuralDivider()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    dropZone
                    if hasFile {
                        TerminalStructuralDivider()
                        previewSection
                        TerminalStructuralDivider()
                        mappingSection
                    }
                    if let error = errorMessage {
                        TerminalStructuralDivider()
                        errorBanner(error)
                    }
                }
            }

            TerminalStructuralDivider()
            footerBar
        }
        .frame(width: 460)
        .background(DesignTokens.canvasBase)
        .clipShape(Rectangle())
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

    // MARK: Drop Zone

    private var dropZone: some View {
        Button { showFilePicker = true } label: {
            VStack(spacing: 10) {
                Text("CSV")
                    .porteosMeta()
                    .foregroundStyle(DesignTokens.textDim)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(DesignTokens.surfaceElevated)
                    .overlay {
                        Rectangle().strokeBorder(DesignTokens.dividerStructural, lineWidth: DesignTokens.dividerWidth)
                    }

                Text("DROP CSV FILE OR CLICK TO BROWSE")
                    .porteosButtonPrimary()
                    .foregroundStyle(DesignTokens.textSecondary)

                Text(selectedFile.isEmpty
                     ? "Supports .csv and .json • Maximum 10 MB"
                     : selectedFile)
                    .porteosMeta()
                    .foregroundStyle(DesignTokens.textDim)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 28)
            .background(DesignTokens.surfacePanel)
            .overlay {
                Rectangle()
                    .strokeBorder(
                        DesignTokens.dividerStructural,
                        style: StrokeStyle(lineWidth: DesignTokens.dividerWidth, dash: [6, 4])
                    )
            }
        }
        .buttonStyle(.plain)
        .padding(DesignTokens.blockGutter)
    }

    // MARK: Preview

    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("CSV PREVIEW")
                    .porteosModuleCmd()
                    .foregroundStyle(DesignTokens.textDim)
                Spacer()
                Text("\(selectedFile) • \(parsedRows.count) rows")
                    .porteosMeta()
                    .foregroundStyle(DesignTokens.textDim)
                    .lineLimit(1)
            }

            VStack(spacing: 0) {
                previewHeaderRow
                previewDivider
                ForEach(Array(previewRows.enumerated()), id: \.offset) { idx, row in
                    previewDataRow(row)
                    if idx < previewRows.count - 1 { previewDivider }
                }
            }
            .overlay {
                Rectangle().strokeBorder(DesignTokens.dividerStructural, lineWidth: DesignTokens.dividerWidth)
            }
            .clipShape(Rectangle())
        }
        .padding(DesignTokens.blockGutter)
    }

    private var previewRows: [[String: String]] {
        Array(parsedRows.prefix(3))
    }

    private var previewHeaderRow: some View {
        HStack(spacing: 0) {
            previewCell(previewHeader(for: mapPropertyName, fallback: "NAME"), isHeader: true)
            previewDividerVertical
            previewCell(previewHeader(for: mapPurchasePrice, fallback: "PRICE"), isHeader: true)
            previewDividerVertical
            previewCell(previewHeader(for: mapLocation, fallback: "CITY"), isHeader: true)
        }
        .frame(height: DesignTokens.rowHeightHeader)
        .background(DesignTokens.surfaceElevated)
    }

    private func previewDataRow(_ row: [String: String]) -> some View {
        HStack(spacing: 0) {
            previewCell(rowValue(row, mapPropertyName), isHeader: false)
            previewDividerVertical
            previewCell(rowValue(row, mapPurchasePrice), isHeader: false)
            previewDividerVertical
            previewCell(rowValue(row, mapLocation), isHeader: false)
        }
        .frame(height: DesignTokens.rowHeightHeader)
        .background(DesignTokens.surfacePanel)
    }

    private func previewHeader(for mapped: String, fallback: String) -> String {
        mapped.isEmpty ? fallback : mapped.uppercased()
    }

    private func rowValue(_ row: [String: String], _ key: String) -> String {
        guard !key.isEmpty else { return "—" }
        let value = row[key] ?? ""
        return value.isEmpty ? "—" : value
    }

    private func previewCell(_ text: String, isHeader: Bool) -> some View {
        Text(text)
            .porteosMeta()
            .foregroundStyle(isHeader ? DesignTokens.textDim : DesignTokens.textSecondary)
            .lineLimit(1)
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
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

    // MARK: Mapping

    private var mappingSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("COLUMN MAPPING")
                    .porteosModuleCmd()
                    .foregroundStyle(DesignTokens.textDim)
                Spacer()
                Text("PORTEOS FIELD → CSV COLUMN")
                    .porteosMeta()
                    .foregroundStyle(DesignTokens.textDim)
            }

            mappingRow(label: "PROPERTY NAME",  selection: $mapPropertyName)
            mappingRow(label: "PURCHASE PRICE", selection: $mapPurchasePrice)
            mappingRow(label: "LOCATION",       selection: $mapLocation)
            mappingRow(label: "PROPERTY TYPE",  selection: $mapPropertyType, allowUnmapped: true)

            mappingStatusLine
        }
        .padding(DesignTokens.blockGutter)
    }

    private func mappingRow(label: String, selection: Binding<String>, allowUnmapped: Bool = false) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .porteosMeta()
                .foregroundStyle(DesignTokens.textDim)
                .frame(width: 112, alignment: .leading)

            Text("→")
                .porteosMeta()
                .foregroundStyle(DesignTokens.textDim)

            Picker("", selection: selection) {
                if allowUnmapped {
                    Text("NOT MAPPED").tag("")
                }
                ForEach(headers, id: \.self) { header in
                    Text(header.uppercased()).tag(header)
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .porteosRowValue()
            .foregroundStyle(selection.wrappedValue.isEmpty && allowUnmapped
                             ? DesignTokens.accentRust
                             : DesignTokens.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 8)
            .frame(height: DesignTokens.rowHeightHeader)
            .background(DesignTokens.surfacePanel)
            .overlay {
                Rectangle().strokeBorder(DesignTokens.dividerStructural, lineWidth: DesignTokens.dividerWidth)
            }
        }
    }

    @ViewBuilder
    private var mappingStatusLine: some View {
        if hasFile {
            let missingType = mapPropertyType.isEmpty
            Text("\(mappedFieldCount) / 4 columns mapped\(missingType ? " • PROPERTY TYPE requires manual selection" : "")")
                .porteosMeta()
                .foregroundStyle(missingType ? DesignTokens.accentRust : DesignTokens.textDim)
        }
    }

    // MARK: Footer

    private var footerBar: some View {
        HStack(spacing: 12) {
            Button { dismiss() } label: {
                Text("[ CANCEL ]")
                    .porteosRowLabel()
                    .foregroundStyle(DesignTokens.textSecondary)
            }
            .buttonStyle(.plain)

            Spacer()

            Button { importDeals() } label: {
                Text("[ IMPORT ]")
            }
            .buttonStyle(TerminalButtonStyle(color: canImport ? .rust : .muted))
            .disabled(!canImport)
        }
        .padding(.horizontal, DesignTokens.blockGutter)
        .frame(height: DesignTokens.rowHeightPaneBar + 16)
        .background(DesignTokens.surfacePanel)
    }

    // MARK: Errors

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 8) {
            Text("ERR >")
                .porteosButtonPrimary()
                .foregroundStyle(DesignTokens.statusCritical)
            Text(message)
                .porteosRowLabel()
                .foregroundStyle(DesignTokens.textSecondary)
                .lineLimit(2)
            Spacer()
        }
        .padding(.horizontal, DesignTokens.blockGutter)
        .padding(.vertical, 10)
        .background(DesignTokens.statusCritical.opacity(0.05))
    }

    // MARK: File Handling

    private func handleFileResult(_ result: Result<[URL], Error>) {
        errorMessage = nil
        parsedRows   = []
        headers      = []
        resetMappings()

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

        autoMapColumns()
    }

    private func autoMapColumns() {
        mapPropertyName  = matchHeader(["name", "property name", "property_name", "deal name"])
        mapPurchasePrice = matchHeader(["price", "purchase price", "purchase_price", "amount"])
        mapLocation      = matchHeader(["city", "location", "location_city", "market"])
        mapPropertyType  = matchHeader(["type", "property type", "property_type", "asset type"])
    }

    private func matchHeader(_ candidates: [String]) -> String {
        for candidate in candidates {
            if let match = headers.first(where: { $0.lowercased() == candidate }) {
                return match
            }
        }
        return ""
    }

    private func resetMappings() {
        mapPropertyName  = ""
        mapPurchasePrice = ""
        mapLocation      = ""
        mapPropertyType  = ""
    }

    private func importDeals() {
        for row in parsedRows {
            let price = Double((row[mapPurchasePrice] ?? "").filter { $0.isNumber || $0 == "." }) ?? 0
            let deal = PropertyDeal(
                propertyName:  row[mapPropertyName] ?? "",
                propertyType:  mapPropertyType.isEmpty ? "" : (row[mapPropertyType] ?? ""),
                locationCity:  mapLocation.isEmpty ? "" : (row[mapLocation] ?? ""),
                purchasePrice: price
            )
            modelContext.insert(deal)
        }
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    ImportDealSheet()
        .background(DesignTokens.canvasBase)
}
