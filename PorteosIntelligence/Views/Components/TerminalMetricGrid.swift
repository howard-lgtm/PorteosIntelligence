import SwiftUI

// MARK: - TerminalMetricGrid
// Responsive metric grid — 4 columns when wide, 2 when center pane is narrow.

private struct GridWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 800
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct TerminalMetricGrid<Content: View>: View {

    @State private var gridWidth: CGFloat = 800
    @ViewBuilder let content: () -> Content

    private var columns: [GridItem] {
        DesignTokens.metricGridColumns(forWidth: gridWidth)
    }

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: DesignTokens.gridRowSpacing) {
            content()
        }
        .background {
            GeometryReader { geo in
                Color.clear.preference(key: GridWidthKey.self, value: geo.size.width)
            }
        }
        .onPreferenceChange(GridWidthKey.self) { gridWidth = $0 }
    }
}

#Preview {
    TerminalMetricGrid {
        TerminalMetricCell(label: "Net Operating Income", value: "€125,000")
        TerminalMetricCell(label: "Cap Rate", value: "6.20%", state: .optimal)
        TerminalMetricCell(label: "Vacancy Rate", value: "9.50%", state: .warning)
        TerminalMetricCell(label: "DSCR", value: "0.98x", state: .danger)
    }
    .padding(DesignTokens.blockGutter)
    .frame(width: 680)
    .background(DesignTokens.canvasBase)
}
