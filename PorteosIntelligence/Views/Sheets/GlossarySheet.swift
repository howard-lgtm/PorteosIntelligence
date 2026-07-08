import SwiftUI

// MARK: - GlossarySheet
// Actions → Glossary — searchable terminology reference.

struct GlossarySheet: View {

    var onDismiss: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss

    @State private var query: String = ""

    private let shellBg       = DesignTokens.canvasBase
    private let shellSurface  = DesignTokens.surfacePanel
    private let shellBorder   = DesignTokens.dividerStructural
    private let textPrimary   = DesignTokens.textPrimary
    private let textSecondary = DesignTokens.textSecondary
    private let textTertiary  = DesignTokens.textDim
    private let accentRust    = DesignTokens.accentRust

    private var filteredSections: [GlossarySection] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return PorteosGlossary.sections }

        return PorteosGlossary.sections.compactMap { section in
            let hits = section.entries.filter {
                $0.term.lowercased().contains(q) || $0.definition.lowercased().contains(q)
            }
            guard !hits.isEmpty else { return nil }
            return GlossarySection(title: section.title, entries: hits)
        }
    }

    private var visibleCount: Int {
        filteredSections.reduce(0) { $0 + $1.entries.count }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            divider

            searchBar
            divider

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if filteredSections.isEmpty {
                        Text("// no matches for \"\(query)\"")
                            .porteosRowValue()
                            .foregroundStyle(textSecondary)
                            .padding(DesignTokens.blockGutter)
                    } else {
                        ForEach(Array(filteredSections.enumerated()), id: \.element.id) { idx, section in
                            sectionBlock(section)
                            if idx < filteredSections.count - 1 { divider }
                        }
                    }
                }
            }
            .frame(maxHeight: 420)

            divider
            footerBar
        }
        .frame(width: 560)
        .background(shellSurface)
        .overlay {
            Rectangle().strokeBorder(shellBorder, lineWidth: DesignTokens.dividerWidth)
        }
        .clipShape(Rectangle())
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: 0) {
            Text("porteos@system ~ % ")
                .porteosCliPrompt()
                .foregroundStyle(textTertiary)
            Text("./glossary --all")
                .porteosButtonPrimary()
                .foregroundStyle(accentRust)
            Spacer()
            Text("\(visibleCount) terms")
                .porteosMeta()
                .foregroundStyle(textTertiary)
        }
        .padding(.horizontal, DesignTokens.blockGutter)
        .frame(height: DesignTokens.rowHeightHeader)
        .background(shellBg)
    }

    // MARK: Search

    private var searchBar: some View {
        HStack(spacing: 8) {
            Text("grep")
                .porteosMeta()
                .foregroundStyle(textTertiary)
            TextField("filter terms…", text: $query)
                .textFieldStyle(.plain)
                .porteosRowValue()
                .foregroundStyle(textPrimary)
        }
        .padding(.horizontal, DesignTokens.blockGutter)
        .frame(height: DesignTokens.rowHeightHeader)
        .background(shellBg)
    }

    // MARK: Sections

    private func sectionBlock(_ section: GlossarySection) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("// \(section.title)")
                .porteosMeta()
                .foregroundStyle(accentRust)
                .padding(.horizontal, DesignTokens.blockGutter)
                .padding(.top, 12)
                .padding(.bottom, 6)

            ForEach(Array(section.entries.enumerated()), id: \.element.id) { idx, entry in
                entryRow(entry)
                if idx < section.entries.count - 1 { insetDivider }
            }
            .padding(.bottom, 8)
        }
    }

    private func entryRow(_ entry: GlossaryEntry) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(entry.term.uppercased())
                .porteosRowLabel()
                .foregroundStyle(textPrimary)
            Text(entry.definition)
                .porteosRowValue()
                .foregroundStyle(textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, DesignTokens.blockGutter)
        .padding(.vertical, 8)
    }

    // MARK: Footer

    private var footerBar: some View {
        HStack {
            Spacer()
            Button { close() } label: {
                Text("[ CLOSE ]")
                    .porteosButtonPrimary()
                    .foregroundStyle(textSecondary)
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.escape, modifiers: [])
            Spacer()
        }
        .frame(height: DesignTokens.rowHeightPaneBar)
        .background(shellBg)
    }

    // MARK: Helpers

    private var divider: some View {
        Rectangle()
            .fill(shellBorder)
            .frame(height: DesignTokens.dividerWidth)
    }

    private var insetDivider: some View {
        Rectangle()
            .fill(shellBorder)
            .frame(height: DesignTokens.dividerWidth)
            .padding(.leading, DesignTokens.blockGutter)
    }

    private func close() {
        if let onDismiss { onDismiss() } else { dismiss() }
    }
}

#Preview {
    ZStack {
        DesignTokens.canvasBase.ignoresSafeArea()
        GlossarySheet()
    }
}
