import SwiftUI

// MARK: - TerminalSheetShell
// Canonical modal/sheet chrome — all dialogs use this wrapper.

struct TerminalSheetShell<Content: View, Footer: View>: View {

    let command: String
    var accentColor: Color = DesignTokens.accentRust
    var trailingBadge: String? = nil
    var width: CGFloat = 560
    var height: CGFloat? = nil
    var showClose: Bool = true
    @ViewBuilder let content: () -> Content
    @ViewBuilder let footer: () -> Footer

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            sheetHeader
            TerminalStructuralDivider()
            content()
            TerminalStructuralDivider()
            footer()
        }
        .frame(width: width, height: height)
        .background(DesignTokens.canvasBase)
        .clipShape(Rectangle())
    }

    private var sheetHeader: some View {
        HStack(spacing: 0) {
            Text("porteos@system ~ % ")
                .font(DesignTokens.mono(size: 11))
                .foregroundStyle(DesignTokens.textDim)
            Text(command)
                .font(DesignTokens.mono(size: 11, weight: .bold))
                .foregroundStyle(accentColor)
                .lineLimit(1)
            Spacer()
            if let trailingBadge {
                Text(trailingBadge)
                    .font(DesignTokens.mono(size: 10))
                    .foregroundStyle(DesignTokens.textDim)
                    .padding(.trailing, 12)
            }
            if showClose {
                Button { dismiss() } label: {
                    Text("[ × ]")
                        .font(DesignTokens.mono(size: 11, weight: .bold))
                        .foregroundStyle(DesignTokens.textSecondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, DesignTokens.blockGutter)
        .frame(height: DesignTokens.rowHeightPaneBar)
        .background(DesignTokens.surfacePanel)
    }
}

// MARK: - TerminalSheetFooter

struct TerminalSheetFooter: View {

    var statusText: String? = nil
    let cancelAction: () -> Void
    let primaryLabel: String
    let primaryAction: () -> Void
    var primaryEnabled: Bool = true
    var primaryColor: TerminalButtonStyle.Palette = .rust

    var body: some View {
        HStack(spacing: 12) {
            Button("[ CANCEL ]", action: cancelAction)
                .font(DesignTokens.mono(size: 11))
                .foregroundStyle(DesignTokens.textSecondary)
                .buttonStyle(.plain)

            if let statusText {
                Text(statusText)
                    .font(DesignTokens.mono(size: 10))
                    .foregroundStyle(DesignTokens.textDim)
            }

            Spacer()

            Button(primaryLabel, action: primaryAction)
                .buttonStyle(TerminalButtonStyle(color: primaryEnabled ? primaryColor : .muted))
                .disabled(!primaryEnabled)
        }
        .padding(.horizontal, DesignTokens.blockGutter)
        .frame(height: DesignTokens.rowHeightPaneBar + 16)
        .background(DesignTokens.surfacePanel)
    }
}

// MARK: - TerminalCategoryTabBar

struct TerminalCategoryTabBar: View {

    let categories: [(id: String, label: String, color: Color)]
    @Binding var selectedID: String

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(categories, id: \.id) { cat in
                    categoryTab(id: cat.id, label: cat.label, color: cat.color)
                }
            }
            .padding(.horizontal, DesignTokens.blockGutter)
        }
        .frame(height: DesignTokens.rowHeightHeader + 2)
        .background(DesignTokens.surfacePanel)
    }

    private func categoryTab(id: String, label: String, color: Color) -> some View {
        let isActive = selectedID == id
        return Button { selectedID = id } label: {
            VStack(spacing: 0) {
                Spacer()
                Text(label)
                    .font(DesignTokens.mono(size: 11, weight: isActive ? .bold : .regular))
                    .foregroundStyle(isActive ? color : DesignTokens.textDim)
                    .padding(.horizontal, 10)
                Spacer()
                Rectangle()
                    .fill(isActive ? color : Color.clear)
                    .frame(height: 2)
            }
        }
        .buttonStyle(.plain)
    }
}
