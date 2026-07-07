import SwiftUI

// MARK: - MetricWithTrend
// Legacy wrapper — delegates layout to TerminalMetricCell.

struct MetricWithTrend: View {

    let label:      String
    let value:      String
    let trend:      [Double]
    let trendColor: Color
    var state:      MetricState = .neutral

    var body: some View {
        TerminalMetricCell(label: label, value: value, state: state,
                           trend: trend, trendColor: trendColor)
    }
}
