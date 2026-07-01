import SwiftUI
import SwiftData

// MARK: - QuickAddSheet
// Ultra-fast single-field deal entry: paste a URL or type "Lisbon T2 €350k 90m²"

struct QuickAddSheet: View {

    @Environment(\.dismiss)      private var dismiss
    @Environment(\.modelContext) private var modelContext

    var onSaved: ((UUID) -> Void)? = nil

    // MARK: State

    @State private var input:      String = ""
    @State private var isSaving    = false
    @State private var savedID:    UUID?
    @FocusState private var focused: Bool

    // MARK: Derived — live parse (recomputes on every keystroke, parser is CPU-cheap)

    private var parsed: QuickEntryResult? {
        QuickEntryParser.parse(input)
    }

    private var isURL: Bool { QuickEntryParser.isURL(input.trimmingCharacters(in: .whitespaces)) }

    private var canSave: Bool {
        guard let p = parsed else { return false }
        // URL-only entries are valid even with price = 0
        return p.purchasePrice > 0 || p.sourceURL != nil
    }

    // MARK: Design tokens

    private let shellBg       = Color(hex: "#0F1115")
    private let shellSurface  = Color(hex: "#1A1D24")
    private let shellBorder   = Color(hex: "#2E333F")
    private let textPrimary   = Color(hex: "#E2E8F0")
    private let textSecondary = Color(hex: "#94A3B8")
    private let textTertiary  = Color(hex: "#64748B")
    private let accentRust    = Color(hex: "#C25E30")
    private let accentGreen   = Color(hex: "#10B981")
    private let accentAmber   = Color(hex: "#F59E0B")
    private let accentRed     = Color(hex: "#EF4444")

    // MARK: Body

    var body: some View {
        VStack(spacing: 0) {
            titleBar
            inputSection
            Rectangle().fill(shellBorder).frame(height: 1)
            previewSection
            Rectangle().fill(shellBorder).frame(height: 1)
            actionBar
        }
        .background(shellBg)
        .clipShape(Rectangle())
        .frame(width: 560)
        .fixedSize(horizontal: false, vertical: true)
        .onAppear { focused = true }
    }

    // MARK: - Title bar

    private var titleBar: some View {
        HStack(spacing: 0) {
            Text("QUICK_ADD")
                .font(.custom("JetBrains Mono", size: 11))
                .foregroundColor(textTertiary)
            Text("  //  ⌘⇧Q")
                .font(.custom("JetBrains Mono", size: 10))
                .foregroundColor(Color(hex: "#3D4455"))
            Spacer()
            confidencePill
        }
        .padding(.horizontal, 12)
        .frame(height: 32)
        .background(shellSurface)
        .overlay(alignment: .bottom) {
            Rectangle().fill(shellBorder).frame(height: 1)
        }
    }

    @ViewBuilder
    private var confidencePill: some View {
        if let p = parsed {
            let (label, color): (String, Color) = switch p.confidence {
            case .high:   ("HIGH",   accentGreen)
            case .medium: ("MEDIUM", accentAmber)
            case .low:    ("LOW",    accentRed)
            }
            Text("CONFIDENCE: \(label)")
                .font(.custom("JetBrains Mono", size: 9))
                .foregroundColor(color)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(color.opacity(0.12))
                .clipShape(Rectangle())
        }
    }

    // MARK: - Input section

    private var inputSection: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                // Cursor prompt
                Text(isURL ? "url>" : ">")
                    .font(.custom("JetBrains Mono", size: 13).weight(.medium))
                    .foregroundColor(accentRust)
                    .frame(width: isURL ? 28 : 12, alignment: .leading)

                TextField(
                    "",
                    text: $input,
                    prompt: Text("\"Lisbon T2 €350k 90m²\"  or paste a listing URL")
                        .font(.custom("JetBrains Mono", size: 12))
                        .foregroundColor(textTertiary)
                )
                .textFieldStyle(.plain)
                .font(.custom("JetBrains Mono", size: 13))
                .foregroundColor(textPrimary)
                .focused($focused)
                .onSubmit { if canSave { save() } }

                // Clear button
                if !input.isEmpty {
                    Button { input = "" } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 10))
                            .foregroundColor(textTertiary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .frame(height: 44)

            // Syntax hint strip
            HStack(spacing: 12) {
                hintTag("PRICE", "€350k  €1.2M  $450,000")
                hintTag("AREA",  "90m²  90sqm  1200sqft")
                hintTag("TYPE",  "T2  3BR  villa")
                hintTag("LOC",   "Lisbon  Madrid")
            }
            .padding(.horizontal, 12)
            .frame(height: 22)
            .background(shellBg.opacity(0.6))
        }
    }

    // MARK: - Parsed preview

    @ViewBuilder
    private var previewSection: some View {
        if let p = parsed {
            VStack(spacing: 0) {
                previewHeader
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 1),
                    GridItem(.flexible(), spacing: 1),
                ], spacing: 1) {
                    previewCell("PROPERTY_NAME", p.propertyName,     isKnown: !p.propertyName.isEmpty)
                    previewCell("LOCATION",      p.location,         isKnown: p.location != "Unknown")
                    previewCell("PURCHASE_PRICE",
                                p.purchasePrice > 0 ? p.priceLabel : "—",
                                isKnown: p.purchasePrice > 0)
                    previewCell("CURRENCY",      p.currency,         isKnown: true)
                    previewCell("AREA",
                                p.totalArea > 0 ? "\(Int(p.totalArea)) m²" : "—",
                                isKnown: p.totalArea > 0)
                    previewCell("PROPERTY_TYPE", p.propertyType,     isKnown: true)
                    previewCell("BEDROOMS",
                                p.bedrooms.map { String($0) } ?? "—",
                                isKnown: p.bedrooms != nil)
                    previewCell("STATUS",        "PIPELINE",         isKnown: true)
                }

                if p.estimatedGPI > 0 {
                    Rectangle().fill(shellBorder).frame(height: 1)
                    derivedMetricsRow(p)
                }

                if let url = p.sourceURL {
                    Rectangle().fill(shellBorder).frame(height: 1)
                    urlRow(url)
                }
            }
        } else {
            // Empty state
            HStack {
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 11))
                Text("Start typing — fields parse automatically")
                    .font(.custom("JetBrains Mono", size: 10))
            }
            .foregroundColor(textTertiary)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
        }
    }

    private var previewHeader: some View {
        HStack {
            Text("porteos@system ~ % parse --result")
                .font(.custom("JetBrains Mono", size: 10))
                .foregroundColor(textTertiary)
            Spacer()
        }
        .padding(.horizontal, 12)
        .frame(height: 24)
        .background(shellSurface)
    }

    private func previewCell(_ key: String, _ value: String, isKnown: Bool) -> some View {
        HStack(spacing: 0) {
            Text(key)
                .font(.custom("JetBrains Mono", size: 9))
                .foregroundColor(textTertiary)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(value)
                .font(.custom("JetBrains Mono", size: 11).weight(.medium))
                .foregroundColor(isKnown ? textPrimary : textTertiary)
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .frame(height: 28)
        .background(shellSurface)
    }

    private func derivedMetricsRow(_ p: QuickEntryResult) -> some View {
        HStack(spacing: 0) {
            Text("AUTO_CALC")
                .font(.custom("JetBrains Mono", size: 9))
                .foregroundColor(textTertiary)
                .frame(width: 80, alignment: .leading)
            Spacer()
            derivedChip("EST_GPI",  formatCurrency(p.estimatedGPI, p.currency))
            derivedChip("VAC",      "5%")
            derivedChip("EST_OPEX", formatCurrency(p.opex, p.currency))
            if p.totalArea > 0 && p.purchasePrice > 0 {
                derivedChip("€/M²", String(format: "%.0f", p.purchasePrice / p.totalArea))
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 28)
        .background(shellBg)
    }

    private func urlRow(_ url: String) -> some View {
        HStack(spacing: 6) {
            Text("URL")
                .font(.custom("JetBrains Mono", size: 9))
                .foregroundColor(textTertiary)
            Text(url)
                .font(.custom("JetBrains Mono", size: 9))
                .foregroundColor(accentAmber)
                .lineLimit(1)
                .truncationMode(.middle)
            Spacer()
        }
        .padding(.horizontal, 12)
        .frame(height: 24)
        .background(shellBg)
    }

    // MARK: - Action bar

    private var actionBar: some View {
        HStack(spacing: 8) {
            // Parse mode label
            Text(isURL ? "MODE: URL" : "MODE: TEXT")
                .font(.custom("JetBrains Mono", size: 9))
                .foregroundColor(textTertiary)

            Spacer()

            Button { dismiss() } label: {
                Text("[ ESC ]")
                    .font(.custom("JetBrains Mono", size: 11))
                    .foregroundColor(textTertiary)
                    .frame(height: 32)
                    .padding(.horizontal, 12)
                    .background(shellSurface)
                    .overlay(Rectangle().stroke(shellBorder, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.escape, modifiers: [])

            Button {
                save()
            } label: {
                Group {
                    if isSaving {
                        Text("[ SAVING… ]")
                    } else if savedID != nil {
                        Text("[ SAVED ✓ ]")
                    } else {
                        Text("[ SAVE_TO_PIPELINE ]")
                    }
                }
                .font(.custom("JetBrains Mono", size: 11))
                .foregroundColor(canSave ? textPrimary : textTertiary)
                .frame(height: 32)
                .padding(.horizontal, 14)
                .background(canSave ? accentRust : shellSurface)
                .clipShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(!canSave || isSaving)
            .keyboardShortcut(.return, modifiers: .command)
        }
        .padding(.horizontal, 12)
        .frame(height: 48)
        .background(shellSurface)
    }

    // MARK: - Save

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

    // MARK: - Small helpers

    private func hintTag(_ key: String, _ example: String) -> some View {
        HStack(spacing: 4) {
            Text(key)
                .font(.custom("JetBrains Mono", size: 8))
                .foregroundColor(accentRust)
            Text(example)
                .font(.custom("JetBrains Mono", size: 8))
                .foregroundColor(textTertiary)
        }
    }

    private func derivedChip(_ key: String, _ value: String) -> some View {
        HStack(spacing: 3) {
            Text(key)
                .font(.custom("JetBrains Mono", size: 8))
                .foregroundColor(textTertiary)
            Text(value)
                .font(.custom("JetBrains Mono", size: 9))
                .foregroundColor(accentGreen)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(accentGreen.opacity(0.08))
        .clipShape(Rectangle())
        .padding(.leading, 4)
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
