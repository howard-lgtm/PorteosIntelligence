import SwiftUI

// MARK: - BlinkingCursorView
// V2.06 footer: absolute white block cursor (█).

struct BlinkingCursorView: View {

    @State private var visible = true

    var body: some View {
        Text("█")
            .font(DesignTokens.mono(size: 11, weight: .bold))
            .foregroundStyle(DesignTokens.textPrimary)
            .opacity(visible ? 1 : 0)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.55).repeatForever(autoreverses: true)) {
                    visible.toggle()
                }
            }
    }
}
