import SwiftUI

// MARK: - ShortcutsLegendView
//
// Terminal-style keyboard shortcut reference panel.
// Triggered via ⌘/ from anywhere in the app.

struct ShortcutsLegendView: View {

    @Environment(\.dismiss) private var dismiss

    // MARK: Tokens

    private let shellBg       = Color(hex: "#0F1115")
    private let shellSurface  = Color(hex: "#1A1D24")
    private let shellElevated = Color(hex: "#23262E")
    private let shellBorder   = Color(hex: "#2E333F")
    private let accentRust    = Color(hex: "#C25E30")
    private let textPrimary   = Color(hex: "#F8F9FA")
    private let textSecondary = Color(hex: "#94A3B8")
    private let textTertiary  = Color(hex: "#64748B")
    private let accentGreen   = Color(hex: "#10B981")

    // MARK: Data

    private struct ShortcutEntry {
        let keys: [String]   // each element is one key token, e.g. "⌘", "N"
        let description: String
    }

    private struct ShortcutSection {
        let title: String
        let entries: [ShortcutEntry]
    }

    private let sections: [ShortcutSection] = [
        .init(title: "FILE", entries: [
            .init(keys: ["⌘", "N"],        description: "New Deal"),
            .init(keys: ["⌘", "I"],        description: "Import Deals"),
        ]),
        .init(title: "NAVIGATION", entries: [
            .init(keys: ["⌘", "0"],        description: "Command Center"),
            .init(keys: ["⌘", "1"],        description: "Real Estate Profile"),
            .init(keys: ["⌘", "2"],        description: "Hospitality Profile"),
            .init(keys: ["⌘", "3"],        description: "Design Profile"),
            .init(keys: ["⌘", "4"],        description: "Circular Economy Profile"),
        ]),
        .init(title: "ACTIONS", entries: [
            .init(keys: ["⌘", "K"],        description: "Command Palette"),
            .init(keys: ["⌘", "E"],        description: "Edit Deal Data"),
            .init(keys: ["⌘", "⇧", "O"],  description: "Export Data"),
            .init(keys: ["⌘", "↩"],        description: "Save / Commit Changes"),
            .init(keys: ["Esc"],            description: "Cancel / Close Sheet"),
            .init(keys: ["⌘", "/"],        description: "Show This Legend"),
        ]),
    ]

    // MARK: Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Rectangle().fill(shellBorder).frame(height: 1)

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(sections.indices, id: \.self) { i in
                        sectionBlock(sections[i])
                        if i < sections.count - 1 {
                            Rectangle().fill(shellBorder).frame(height: 1)
                        }
                    }
                }
            }

            Rectangle().fill(shellBorder).frame(height: 1)
            footerBar
        }
        .frame(width: 560)
        .background(shellBg)
        .clipShape(Rectangle())
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: 0) {
            Text("porteos@system ~ % ")
                .font(.custom("JetBrains Mono", size: 13))
                .foregroundStyle(textTertiary)
            Text("./shortcuts --list")
                .font(.custom("JetBrains Mono", size: 13).weight(.bold))
                .foregroundStyle(accentRust)
            Spacer()
            Text("\(totalCount) shortcuts")
                .font(.custom("JetBrains Mono", size: 11))
                .foregroundStyle(textTertiary)
                .padding(.trailing, 16)
        }
        .padding(.leading, 16)
        .frame(height: 36)
        .background(shellSurface)
    }

    private var totalCount: Int {
        sections.reduce(0) { $0 + $1.entries.count }
    }

    // MARK: Section Block

    private func sectionBlock(_ section: ShortcutSection) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section label
            Text(section.title)
                .font(.custom("JetBrains Mono", size: 11).weight(.bold))
                .tracking(0.08)
                .foregroundStyle(textTertiary)
                .padding(.leading, 16)
                .padding(.top, 12)
                .padding(.bottom, 6)

            VStack(alignment: .leading, spacing: 0) {
                ForEach(section.entries.indices, id: \.self) { i in
                    entryRow(section.entries[i])
                    if i < section.entries.count - 1 {
                        Rectangle()
                            .fill(shellBorder.opacity(0.5))
                            .frame(height: 1)
                            .padding(.leading, 16)
                    }
                }
            }
            .padding(.bottom, 10)
        }
    }

    // MARK: Entry Row

    private func entryRow(_ entry: ShortcutEntry) -> some View {
        HStack(spacing: 12) {
            // Key badge cluster — right-aligned in a fixed-width slot
            HStack(spacing: 4) {
                ForEach(entry.keys.indices, id: \.self) { i in
                    keyBadge(entry.keys[i])
                    if i < entry.keys.count - 1 {
                        Text("+")
                            .font(.custom("JetBrains Mono", size: 11))
                            .foregroundStyle(textTertiary)
                    }
                }
            }
            .frame(width: 140, alignment: .trailing)

            // Description
            Text(entry.description)
                .font(.custom("JetBrains Mono", size: 13))
                .foregroundStyle(textPrimary)

            Spacer()
        }
        .padding(.horizontal, 16)
        .frame(height: 36)
    }

    private func keyBadge(_ key: String) -> some View {
        Text(key)
            .font(.custom("JetBrains Mono", size: 12).weight(.bold))
            .foregroundStyle(textPrimary)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(shellElevated)
            .overlay {
                Rectangle()
                    .strokeBorder(shellBorder, lineWidth: 1)
            }
            .clipShape(Rectangle())
    }

    // MARK: Footer

    private var footerBar: some View {
        HStack {
            Text("press Esc or ⌘/ to close")
                .font(.custom("JetBrains Mono", size: 11))
                .foregroundStyle(textTertiary)
                .padding(.leading, 16)

            Spacer()

            Button {
                dismiss()
            } label: {
                Text("[ CLOSE ]")
                    .font(.custom("JetBrains Mono", size: 13).weight(.bold))
                    .foregroundStyle(Color(hex: "#0F1115"))
                    .padding(.horizontal, 16)
                    .frame(height: 28)
                    .background(accentRust)
                    .clipShape(Rectangle())
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.escape, modifiers: [])
            .padding(.trailing, 16)
        }
        .frame(height: 48)
        .background(shellSurface)
    }
}

// MARK: - Preview

#Preview {
    ShortcutsLegendView()
        .background(Color(hex: "#0F1115"))
}
