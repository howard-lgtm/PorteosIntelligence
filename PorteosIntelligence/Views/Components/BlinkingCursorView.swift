import SwiftUI

// MARK: - BlinkingCursorView
// V2.06 footer cursor — dim block, not bright white.

struct BlinkingCursorView: View {

    @State private var visible = true

    var body: some View {
        Text("█")
            .porteosButtonPrimary()
            .foregroundStyle(DesignTokens.textDim)
            .opacity(visible ? 1 : 0.15)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.55).repeatForever(autoreverses: true)) {
                    visible.toggle()
                }
            }
    }
}
