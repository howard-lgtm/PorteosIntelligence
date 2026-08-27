import SwiftUI

// MARK: - TerminalComboboxField
// Free-text field with filtered suggestion dropdown (property type, city, etc.).

struct TerminalComboboxField<FocusTag: Hashable>: View {

    let label: String
    let placeholder: String
    @Binding var text: String
    let suggestions: (String) -> [String]
    private var focusBinding: FocusState<FocusTag?>.Binding?
    private var focusTag: FocusTag?

    @FocusState private var isFocused: Bool
    @State private var highlightIndex: Int = 0

    init(label: String,
         placeholder: String,
         text: Binding<String>,
         suggestions: @escaping (String) -> [String]) where FocusTag == Never {
        self.label = label
        self.placeholder = placeholder
        self._text = text
        self.suggestions = suggestions
        self.focusBinding = nil
        self.focusTag = nil
    }

    init(label: String,
         placeholder: String,
         text: Binding<String>,
         suggestions: @escaping (String) -> [String],
         focus: FocusState<FocusTag?>.Binding,
         equals tag: FocusTag) {
        self.label = label
        self.placeholder = placeholder
        self._text = text
        self.suggestions = suggestions
        self.focusBinding = focus
        self.focusTag = tag
    }

    private let shellBg      = DesignTokens.canvasBase
    private let shellSurface = DesignTokens.surfacePanel
    private let shellBorder  = DesignTokens.dividerStructural
    private let textPrimary  = DesignTokens.textPrimary
    private let textTertiary = DesignTokens.textDim
    private let accentRust   = DesignTokens.accentRust

    private var filtered: [String] {
        suggestions(text)
    }

    private var showDropdown: Bool {
        fieldIsFocused && !filtered.isEmpty
    }

    private var fieldIsFocused: Bool {
        if let focusBinding, let focusTag {
            return focusBinding.wrappedValue == focusTag
        }
        return isFocused
    }

    @ViewBuilder
    private var textInput: some View {
        let field = TextField(placeholder, text: $text)
            .textFieldStyle(.plain)
            .porteosRowValue()
            .foregroundStyle(textPrimary)
            .padding(.horizontal, 8)
            .frame(height: DesignTokens.rowHeightHeader)

        if let focusBinding, let focusTag {
            field
                .focused(focusBinding, equals: focusTag)
                .onChange(of: focusBinding.wrappedValue) { _, newValue in
                    isFocused = newValue == focusTag
                }
        } else {
            field.focused($isFocused)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label.uppercased())
                .porteosMeta()
                .foregroundStyle(textTertiary)

            VStack(spacing: 0) {
                textInput
                    .onSubmit { commitHighlighted() }
                    .onChange(of: text) { _, _ in highlightIndex = 0 }
                    .onKeyPress(.upArrow) {
                        guard showDropdown else { return .ignored }
                        highlightIndex = max(0, highlightIndex - 1)
                        return .handled
                    }
                    .onKeyPress(.downArrow) {
                        guard showDropdown else { return .ignored }
                        highlightIndex = min(filtered.count - 1, highlightIndex + 1)
                        return .handled
                    }

                if showDropdown {
                    Rectangle()
                        .fill(shellBorder)
                        .frame(height: DesignTokens.dividerWidth)

                    VStack(spacing: 0) {
                        ForEach(Array(filtered.enumerated()), id: \.offset) { idx, item in
                            Button {
                                text = item
                                clearFocus()
                            } label: {
                                HStack {
                                    Text(item)
                                        .porteosRowValue()
                                        .foregroundStyle(idx == highlightIndex ? accentRust : textPrimary)
                                    Spacer()
                                }
                                .padding(.horizontal, 8)
                                .frame(height: DesignTokens.rowHeightHeader - 4)
                                .background(idx == highlightIndex ? shellSurface : shellBg)
                            }
                            .buttonStyle(.plain)

                            if idx < filtered.count - 1 {
                                Rectangle()
                                    .fill(shellBorder)
                                    .frame(height: DesignTokens.dividerWidth)
                                    .padding(.leading, 8)
                            }
                        }
                    }
                }
            }
            .background(shellBg)
            .overlay(Rectangle().strokeBorder(shellBorder, lineWidth: DesignTokens.dividerWidth))
            .clipShape(Rectangle())
        }
    }

    private func commitHighlighted() {
        guard showDropdown, highlightIndex < filtered.count else { return }
        text = filtered[highlightIndex]
        clearFocus()
    }

    private func clearFocus() {
        if let focusBinding {
            focusBinding.wrappedValue = nil
        }
        isFocused = false
    }
}
