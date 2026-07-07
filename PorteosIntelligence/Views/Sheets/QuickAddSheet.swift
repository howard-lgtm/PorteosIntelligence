import SwiftUI
import SwiftData

// MARK: - QuickAddSheet
// Figma img_00_17 — NL input, parse preview, confidence pill, pipeline save.

struct QuickAddSheet: View {

    @Environment(\.dismiss)      private var dismiss
    @Environment(\.modelContext) private var modelContext

    var onSaved: ((UUID) -> Void)? = nil

    @State private var input:   String = ""
    @State private var isSaving = false
    @State private var savedID: UUID?
    @FocusState private var focused: Bool

    private var parsed: QuickEntryResult? {
        QuickEntryParser.parse(input)
    }

    private var isURL: Bool {
        QuickEntryParser.isURL(input.trimmingCharacters(in: .whitespaces))
    }

    private var canSave: Bool {
        guard let p = parsed else { return false }
        return p.purchasePrice > 0 || p.sourceURL != nil
    }

    // MARK: Body

    var body: some View {
        VStack(spacing: 0) {
            titleBar
            inputSection
            TerminalStructuralDivider()
            previewSection
            TerminalStructuralDivider()
            actionBar
        }
        .background(DesignTokens.canvasBase)
        .clipShape(Rectangle())
        .frame(width: 480)
        .fixedSize(horizontal: false, vertical: true)
        .onAppear { focused = true }
    }

    // MARK: Header

    private var titleBar: some View {
        HStack(spacing: 0) {
            Text("QUICK_ADD")
                .porteosRowLabel()
                .foregroundStyle(DesignTokens.textDim)
            Text("  //  CMD+SHIFT+Q")
                .porteosMeta()
                .foregroundStyle(DesignTokens.textDim)
            Spacer()
            confidencePill
        }
        .padding(.horizontal, DesignTokens.blockGutter)
        .frame(height: DesignTokens.rowHeightHeader)
        .background(DesignTokens.surfacePanel)
    }

    @ViewBuilder
    private var confidencePill: some View {
        if let p = parsed {
            let (label, color): (String, Color) = switch p.confidence {
            case .high:   ("HIGH",   DesignTokens.statusGo)
            case .medium: ("MEDIUM", DesignTokens.statusWarn)
            case .low:    ("LOW",    DesignTokens.statusCritical)
            }
            Text("CONFIDENCE: \(label)")
                .porteosMeta()
                .foregroundStyle(color)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(color.opacity(0.12))
                .overlay {
                    Rectangle().strokeBorder(color.opacity(0.35), lineWidth: DesignTokens.dividerWidth)
                }
                .clipShape(Rectangle())
        }
    }

    // MARK: Input

    private var inputSection: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Rectangle()
                    .fill(DesignTokens.accentRust)
                    .frame(width: 2)

                HStack(spacing: 8) {
                    Text(isURL ? "url>" : ">")
                        .porteosRowValue()
                        .foregroundStyle(DesignTokens.accentRust)
                        .frame(width: isURL ? 28 : 14, alignment: .leading)

                    TextField(
                        "",
                        text: $input,
                        prompt: Text("Lisbon T2 €350k 90m²")
                            .porteosStyle(.rowValue)
                            .foregroundStyle(DesignTokens.textDim)
                    )
                    .textFieldStyle(.plain)
                    .porteosRowValue()
                    .foregroundStyle(DesignTokens.textPrimary)
                    .focused($focused)
                    .onSubmit { if canSave { save() } }
                }
                .padding(.horizontal, DesignTokens.blockGutter)
                .frame(height: DesignTokens.rowHeightPaneBar)
            }

            if let p = parsed, !isURL {
                parsedSummaryBar(p)
            }
        }
    }

    private func parsedSummaryBar(_ p: QuickEntryResult) -> some View {
        let segments = summarySegments(for: p)
        return HStack(spacing: 0) {
            ForEach(Array(segments.enumerated()), id: \.offset) { idx, segment in
                if idx > 0 {
                    Text("|")
                        .porteosMeta()
                        .foregroundStyle(DesignTokens.dividerStructural)
                        .padding(.horizontal, 8)
                }
                HStack(spacing: 4) {
                    Text(segment.label)
                        .porteosMeta()
                        .foregroundStyle(DesignTokens.textDim)
                    Text(segment.value)
                        .porteosMeta()
                        .foregroundStyle(DesignTokens.textSecondary)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, DesignTokens.blockGutter)
        .frame(height: DesignTokens.rowHeightHeader)
        .background(DesignTokens.canvasBase)
    }

    private struct SummarySegment {
        let label: String
        let value: String
    }

    private func summarySegments(for p: QuickEntryResult) -> [SummarySegment] {
        var result: [SummarySegment] = []
        if p.purchasePrice > 0 {
            result.append(.init(label: "PRICE", value: compactPrice(p)))
        }
        if p.totalArea > 0 {
            result.append(.init(label: "AREA", value: "\(Int(p.totalArea))m²"))
        }
        if let beds = p.bedrooms {
            result.append(.init(label: "TYPE", value: "T\(beds)"))
        } else if p.propertyType != "Apartment" {
            result.append(.init(label: "TYPE", value: p.propertyType))
        }
        if p.location != "Unknown" {
            result.append(.init(label: "LOC", value: p.location))
        }
        return result
    }

    // MARK: Preview

    @ViewBuilder
    private var previewSection: some View {
        if let p = parsed {
            VStack(spacing: 0) {
                previewHeader

                previewRow("PROPERTY_NAME", p.propertyName, isKnown: !p.propertyName.isEmpty)
                previewDivider
                previewRow("LOCATION", p.location, isKnown: p.location != "Unknown")
                previewDivider
                previewRow(
                    "PURCHASE_PRICE",
                    p.purchasePrice > 0 ? formattedPurchasePrice(p) : "—",
                    isKnown: p.purchasePrice > 0
                )
                previewDivider
                previewRow("CURRENCY", p.currency, isKnown: true)
                previewDivider
                previewRow(
                    "AREA",
                    p.totalArea > 0 ? "\(Int(p.totalArea)) m²" : "—",
                    isKnown: p.totalArea > 0
                )
                previewDivider
                previewRow("PROPERTY_TYPE", p.propertyType, isKnown: true)
                previewDivider
                previewRow("BEDROOMS", p.bedrooms.map { String($0) } ?? "—", isKnown: p.bedrooms != nil)
                previewDivider
                previewRow("STATUS", "PIPELINE", isKnown: true)

                if p.estimatedGPI > 0 {
                    TerminalStructuralDivider()
                    derivedMetricsRow(p)
                }

                if let url = p.sourceURL {
                    TerminalStructuralDivider()
                    urlRow(url)
                }
            }
        } else {
            Text("Start typing — fields parse automatically")
                .porteosMeta()
                .foregroundStyle(DesignTokens.textDim)
                .frame(maxWidth: .infinity)
                .frame(height: DesignTokens.rowHeightPaneBar)
        }
    }

    private var previewHeader: some View {
        HStack {
            Text("porteos@system ~ % ")
                .porteosMeta()
                .foregroundStyle(DesignTokens.textDim)
            Text("parse --result")
                .porteosMeta()
                .foregroundStyle(DesignTokens.textDim)
            Spacer()
        }
        .padding(.horizontal, DesignTokens.blockGutter)
        .frame(height: DesignTokens.rowHeightHeader)
        .background(DesignTokens.surfacePanel)
    }

    private var previewDivider: some View {
        Rectangle()
            .fill(DesignTokens.dividerStructural)
            .frame(height: DesignTokens.dividerWidth)
    }

    private func previewRow(_ key: String, _ value: String, isKnown: Bool) -> some View {
        HStack(spacing: 12) {
            Text(key)
                .porteosMeta()
                .foregroundStyle(DesignTokens.textDim)
                .frame(width: 120, alignment: .leading)

            Text(value)
                .porteosRowValue()
                .foregroundStyle(isKnown ? DesignTokens.textPrimary : DesignTokens.textDim)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, DesignTokens.blockGutter)
        .frame(height: DesignTokens.rowHeightHeader)
        .background(DesignTokens.surfacePanel)
    }

    private func derivedMetricsRow(_ p: QuickEntryResult) -> some View {
        HStack(spacing: 8) {
            derivedChip("EST_GPI", formatCurrency(p.estimatedGPI, p.currency))
            derivedChip("VAC", "5%")
            derivedChip("EST_OPEX", formatCurrency(p.opex, p.currency))
            if p.totalArea > 0 && p.purchasePrice > 0 {
                derivedChip("€/M²", String(format: "%.0f", p.purchasePrice / p.totalArea))
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, DesignTokens.blockGutter)
        .frame(height: DesignTokens.rowHeightHeader + 4)
        .background(DesignTokens.canvasBase)
    }

    private func urlRow(_ url: String) -> some View {
        HStack(spacing: 8) {
            Text("URL")
                .porteosMeta()
                .foregroundStyle(DesignTokens.textDim)
            Text(url)
                .porteosMeta()
                .foregroundStyle(DesignTokens.statusWarn)
                .lineLimit(1)
                .truncationMode(.middle)
            Spacer()
        }
        .padding(.horizontal, DesignTokens.blockGutter)
        .frame(height: DesignTokens.rowHeightHeader)
        .background(DesignTokens.canvasBase)
    }

    // MARK: Footer

    private var actionBar: some View {
        HStack(spacing: 12) {
            Text(isURL ? "MODE: URL" : "MODE: TEXT")
                .porteosMeta()
                .foregroundStyle(DesignTokens.textDim)

            Spacer()

            Button { dismiss() } label: {
                Text("[ ESC ]")
                    .porteosRowLabel()
                    .foregroundStyle(DesignTokens.textDim)
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.escape, modifiers: [])

            Button { save() } label: {
                Group {
                    if isSaving {
                        Text("[ SAVING… ]")
                    } else if savedID != nil {
                        Text("[ SAVED ]")
                    } else {
                        Text("[ SAVE_TO_PIPELINE ]")
                    }
                }
            }
            .buttonStyle(TerminalButtonStyle(color: canSave && !isSaving ? .rust : .muted))
            .disabled(!canSave || isSaving)
            .keyboardShortcut(.return, modifiers: .command)
        }
        .padding(.horizontal, DesignTokens.blockGutter)
        .frame(height: DesignTokens.rowHeightPaneBar + 8)
        .background(DesignTokens.surfacePanel)
    }

    // MARK: Save

    private func save() {
        guard let p = parsed, canSave else { return }
        isSaving = true

        let deal = PropertyDeal(
            propertyName:         p.propertyName,
            propertyType:         p.propertyType,
            totalArea:            p.totalArea,
            locationCity:         p.location != "Unknown" ? p.location : "",
            purchasePrice:        p.purchasePrice,
            grossPotentialIncome: p.estimatedGPI,
            vacancyRate:          p.vacancyRate,
            operatingExpenses:    p.opex,
            notes:                buildNotes(p),
            tags:                 buildTags(p),
            status:               .pipeline
        )
        modelContext.insert(deal)

        do {
            try modelContext.save()
            savedID = deal.id
            isSaving = false
            onSaved?(deal.id)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { dismiss() }
        } catch {
            isSaving = false
        }
    }

    private func buildNotes(_ p: QuickEntryResult) -> String {
        var lines: [String] = [p.notes]
        if let url = p.sourceURL { lines.append("URL: \(url)") }
        if p.currency != "EUR" { lines.append("Price currency: \(p.currency) — update purchase price in EUR.") }
        if p.estimatedGPI > 0 { lines.append("GPI/OPEX auto-estimated — review in dashboard.") }
        return lines.joined(separator: "\n")
    }

    private func buildTags(_ p: QuickEntryResult) -> [String] {
        var tags = ["quick_add"]
        if p.sourceURL != nil { tags.append("has_url") }
        if p.confidence == .low { tags.append("needs_review") }
        return tags
    }

    // MARK: Formatting

    private func compactPrice(_ p: QuickEntryResult) -> String {
        let sym = p.currency == "USD" ? "$" : "€"
        if p.purchasePrice >= 1_000_000 {
            return "\(sym)\(String(format: "%.1f", p.purchasePrice / 1_000_000))M"
        }
        if p.purchasePrice >= 1_000 {
            return "\(sym)\(Int(p.purchasePrice / 1_000))k"
        }
        return "\(sym)\(Int(p.purchasePrice))"
    }

    private func formattedPurchasePrice(_ p: QuickEntryResult) -> String {
        let sym = p.currency == "USD" ? "$" : "€"
        let formatted = Int(p.purchasePrice).formatted(.number.grouping(.automatic))
        return "\(sym) \(formatted)"
    }

    private func derivedChip(_ key: String, _ value: String) -> some View {
        HStack(spacing: 4) {
            Text(key)
                .porteosMeta()
                .foregroundStyle(DesignTokens.statusGo.opacity(0.8))
            Text(value)
                .porteosMeta()
                .foregroundStyle(DesignTokens.statusGo)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(DesignTokens.statusGo.opacity(0.10))
        .overlay {
            Rectangle().strokeBorder(DesignTokens.statusGo.opacity(0.30), lineWidth: DesignTokens.dividerWidth)
        }
        .clipShape(Rectangle())
    }

    private func formatCurrency(_ value: Double, _ currency: String) -> String {
        let sym = currency == "USD" ? "$" : (currency == "SEK" ? "" : "€")
        let suf = currency == "SEK" ? " kr" : ""
        if value >= 1_000_000 {
            return "\(sym)\(String(format: "%.1f", value / 1_000_000))M\(suf)"
        }
        if value >= 1_000 {
            return "\(sym)\(Int(value / 1_000))k\(suf)"
        }
        return "\(sym)\(Int(value))\(suf)"
    }
}

// MARK: - Preview

#Preview {
    QuickAddSheet()
        .modelContainer(for: PropertyDeal.self, inMemory: true)
}
