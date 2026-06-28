import SwiftUI

// MARK: - TerminalInputField
// Shared by all edit sheets.
//
// Double-backed path (value:formatter:) uses an internal @State string so the
// user's keystrokes are never discarded by a parent-view re-render.  The
// formatter is retained only to infer decimal-place count for initial display;
// it is NOT used as a TextField formatter (which is the source of the "revert
// to 0" bug on macOS SwiftUI).

struct TerminalInputField: View {

    let label: String
    let placeholder: String
    let prefix: String?
    let suffix: String?

    // Exactly one of these is populated, depending on which init was called.
    private var stringBinding: Binding<String>?
    private var doubleBinding: Binding<Double>?
    private var formatter: NumberFormatter?

    // Local edit text for the double-backed path.
    // @State survives parent re-renders; the binding is only used on appear /
    // when the external model value changes out-of-band.
    @State private var localText: String = ""

    // MARK: Inits

    /// String-backed field — fully backward-compatible.
    init(label: String,
         placeholder: String,
         prefix: String? = nil,
         suffix: String? = nil,
         text: Binding<String>) {
        self.label         = label
        self.placeholder   = placeholder
        self.prefix        = prefix
        self.suffix        = suffix
        self.stringBinding = text
    }

    /// Double-backed field.  The formatter is used only to determine decimal
    /// places for display; the TextField itself is string-based for reliability.
    init(label: String,
         placeholder: String,
         prefix: String? = nil,
         suffix: String? = nil,
         value: Binding<Double>,
         formatter: NumberFormatter) {
        self.label         = label
        self.placeholder   = placeholder
        self.prefix        = prefix
        self.suffix        = suffix
        self.doubleBinding = value
        self.formatter     = formatter
    }

    // MARK: Tokens

    private let shellBg      = Color(hex: "#0F1115")
    private let shellBorder  = Color(hex: "#2E333F")
    private let textPrimary  = Color(hex: "#F8F9FA")
    private let textTertiary = Color(hex: "#64748B")

    // MARK: Body

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label.uppercased())
                .font(.custom("JetBrains Mono", size: 10).weight(.bold))
                .tracking(0.05)
                .foregroundStyle(textTertiary)

            HStack(spacing: 0) {
                if let prefix {
                    Text(prefix)
                        .font(.custom("JetBrains Mono", size: 14))
                        .foregroundStyle(textTertiary)
                        .frame(width: 24, height: 28)
                        .background(shellBg)
                        .overlay(alignment: .trailing) {
                            Rectangle().fill(shellBorder).frame(width: 1)
                        }
                }

                inputCore

                if let suffix {
                    Text(suffix)
                        .font(.custom("JetBrains Mono", size: 14))
                        .foregroundStyle(textTertiary)
                        .frame(width: 24, height: 28)
                        .background(shellBg)
                        .overlay(alignment: .leading) {
                            Rectangle().fill(shellBorder).frame(width: 1)
                        }
                }
            }
            .background(shellBg)
            .overlay(Rectangle().strokeBorder(shellBorder, lineWidth: 1))
            .clipShape(Rectangle())
        }
    }

    // MARK: Input Core

    @ViewBuilder
    private var inputCore: some View {
        if let doubleBinding {
            TextField(placeholder, text: $localText)
                .textFieldStyle(.plain)
                .font(.custom("JetBrains Mono", size: 14))
                .foregroundStyle(textPrimary)
                .monospacedDigit()
                .padding(.horizontal, 8)
                .frame(height: 28)
                // Seed localText from the model on first appearance.
                .onAppear {
                    localText = displayString(for: doubleBinding.wrappedValue)
                }
                // Live-update the model on every keystroke.
                .onChange(of: localText) { _, newText in
                    doubleBinding.wrappedValue = parse(newText)
                }
                // Sync when the model value is changed externally (e.g. a
                // different deal is selected while the sheet is open).
                .onChange(of: doubleBinding.wrappedValue) { _, newValue in
                    // Only overwrite localText when it no longer matches the
                    // new model value — prevents a feedback loop.
                    guard abs(parse(localText) - newValue) > 0.001 else { return }
                    localText = displayString(for: newValue)
                }

        } else if let stringBinding {
            TextField(placeholder, text: stringBinding)
                .textFieldStyle(.plain)
                .font(.custom("JetBrains Mono", size: 14))
                .foregroundStyle(textPrimary)
                .monospacedDigit()
                .padding(.horizontal, 8)
                .frame(height: 28)
        }
    }

    // MARK: Helpers

    /// Strip everything except digits and the decimal point, then parse.
    private func parse(_ text: String) -> Double {
        let cleaned = text.filter { $0.isNumber || $0 == "." }
        return Double(cleaned) ?? 0
    }

    /// Format `value` as a plain decimal string using the formatter's configured
    /// decimal-place count (no currency symbol, no grouping separators).
    private func displayString(for value: Double) -> String {
        guard value > 0 else { return "" }
        let dp = formatter?.maximumFractionDigits ?? 0
        return dp > 0 ? String(format: "%.\(dp)f", value) : "\(Int(value))"
    }
}
