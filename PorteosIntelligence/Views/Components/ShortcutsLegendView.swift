import SwiftUI

// MARK: - ShortcutsLegendView
// Figma img_00_9 — Keyboard Shortcuts overlay.

struct ShortcutsLegendView: View {

    var onDismiss: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss

    private struct ShortcutEntry: Identifiable {
        let id = UUID()
        let keys: [String]
        let description: String
    }

    private struct ShortcutSection: Identifiable {
        let id = UUID()
        let title: String
        let entries: [ShortcutEntry]
    }

    private let sections: [ShortcutSection] = [
        .init(title: "FILE", entries: [
            .init(keys: ["⌘", "N"],       description: "New Deal"),
            .init(keys: ["⌘", "I"],       description: "Import Deals"),
        ]),
        .init(title: "NAVIGATION", entries: [
            .init(keys: ["⌘", "0"],       description: "Command Center"),
            .init(keys: ["⌘", "1"],       description: "Real Estate Profile"),
            .init(keys: ["⌘", "2"],       description: "Hospitality Profile"),
            .init(keys: ["⌘", "3"],       description: "Design Profile"),
            .init(keys: ["⌘", "4"],       description: "Circular Economy Profile"),
        ]),
        .init(title: "ACTIONS", entries: [
            .init(keys: ["⌘", "K"],        description: "Command Palette"),
            .init(keys: ["⌘", "E"],        description: "Edit Deal Data"),
            .init(keys: ["⌘", "⇧", "O"], description: "Export Data"),
            .init(keys: ["⌘", "⏎"],       description: "Save / Commit Changes"),
            .init(keys: ["Esc"],           description: "Cancel / Close Sheet"),
            .init(keys: ["⌘", "/"],       description: "Show This Legend"),
        ]),
    ]

    private var totalCount: Int {
        sections.reduce(0) { $0 + $1.entries.count }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            divider

            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(sections.enumerated()), id: \.element.id) { idx, section in
                    sectionBlock(section)
                    if idx < sections.count - 1 { divider }
                }
            }

            divider
            footerBar
        }
        .frame(width: 520)
        .background(DesignTokens.surfacePanel)
        .overlay {
            Rectangle().strokeBorder(DesignTokens.dividerStructural, lineWidth: DesignTokens.dividerWidth)
        }
        .clipShape(Rectangle())
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: 0) {
            Text("porteos@system ~ % ")
                .font(DesignTokens.cliPromptFont())
                .foregroundStyle(DesignTokens.textDim)
            Text("./shortcuts --list")
                .font(DesignTokens.mono(size: DesignTokens.TypeScale.rowValue, weight: .bold))
                .foregroundStyle(DesignTokens.accentRust)
            Spacer()
            Text("\(totalCount) shortcuts")
                .font(DesignTokens.metaFont())
                .foregroundStyle(DesignTokens.textDim)
        }
        .padding(.horizontal, DesignTokens.blockGutter)
        .frame(height: DesignTokens.rowHeightHeader)
        .background(DesignTokens.canvasBase)
    }

    // MARK: Sections

    private func sectionBlock(_ section: ShortcutSection) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(section.title)
                .font(DesignTokens.mono(size: DesignTokens.TypeScale.meta, weight: .bold))
                .tracking(0.08)
                .foregroundStyle(DesignTokens.textDim)
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

    private func entryRow(_ entry: ShortcutEntry) -> some View {
        HStack(spacing: 16) {
            HStack(spacing: 4) {
                ForEach(entry.keys, id: \.self) { key in
                    keyBadge(key)
                }
            }
            .frame(minWidth: 96, alignment: .leading)

            Text(entry.description)
                .font(DesignTokens.rowValueFont())
                .foregroundStyle(DesignTokens.textPrimary)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, DesignTokens.blockGutter)
        .frame(height: DesignTokens.rowHeightHeader)
    }

    private func keyBadge(_ key: String) -> some View {
        Text(key)
            .font(DesignTokens.mono(size: DesignTokens.TypeScale.rowLabel, weight: .bold))
            .foregroundStyle(DesignTokens.textPrimary)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(DesignTokens.surfaceElevated)
            .overlay {
                Rectangle().strokeBorder(DesignTokens.dividerStructural, lineWidth: DesignTokens.dividerWidth)
            }
            .clipShape(Rectangle())
    }

    // MARK: Footer

    private var footerBar: some View {
        HStack {
            Spacer()
            Button { close() } label: {
                Text("[ CLOSE ]")
                    .font(DesignTokens.mono(size: DesignTokens.TypeScale.rowValue, weight: .bold))
                    .foregroundStyle(DesignTokens.textSecondary)
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.escape, modifiers: [])
            Spacer()
        }
        .frame(height: DesignTokens.rowHeightPaneBar)
        .background(DesignTokens.canvasBase)
    }

    // MARK: Helpers

    private var divider: some View {
        Rectangle()
            .fill(DesignTokens.dividerStructural)
            .frame(height: DesignTokens.dividerWidth)
    }

    private var insetDivider: some View {
        Rectangle()
            .fill(DesignTokens.dividerStructural)
            .frame(height: DesignTokens.dividerWidth)
            .padding(.leading, DesignTokens.blockGutter)
    }

    private func close() {
        if let onDismiss { onDismiss() } else { dismiss() }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        DesignTokens.canvasBase.ignoresSafeArea()
        ShortcutsLegendView()
    }
}
