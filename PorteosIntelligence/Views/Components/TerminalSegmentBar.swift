import SwiftUI

// MARK: - TerminalSegmentBar
// Figma img_00_1 — horizontal fill bar for leverage + sensitivity modules.

struct TerminalSegmentBar: View {

    let fillRatio: Double
    var barColor: Color
    var trackColor: Color = DesignTokens.dividerStructural
    var height: CGFloat = 8

    private var clamped: Double { min(1, max(0, fillRatio)) }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(trackColor)
                    .frame(height: height)

                Rectangle()
                    .fill(barColor)
                    .frame(width: geo.size.width * clamped, height: height)
            }
            .frame(maxHeight: .infinity, alignment: .center)
        }
        .frame(height: height)
    }
}

// MARK: - SensitivityImpactRow
// Figma 06 // SENSITIVITY_ANALYSIS — label | bar | impact value.

struct SensitivityImpactRow: View {

    let label: String
    let fillRatio: Double
    let impactText: String
    let accent: Color
    var impactColor: Color = DesignTokens.statusWarn

    var body: some View {
        HStack(spacing: 10) {
            Text(label.uppercased())
                .font(DesignTokens.metricLabelFont())
                .tracking(0.02)
                .foregroundStyle(DesignTokens.textDim)
                .frame(width: 128, alignment: .leading)
                .lineLimit(2)

            TerminalSegmentBar(fillRatio: fillRatio, barColor: accent)

            Text(impactText)
                .font(DesignTokens.metricValueFont())
                .monospacedDigit()
                .foregroundStyle(impactColor)
                .frame(minWidth: 88, alignment: .trailing)
                .lineLimit(1)
        }
        .padding(DesignTokens.metricCellPadding)
        .frame(minHeight: DesignTokens.metricCellMinHeight)
        .background(DesignTokens.surfaceElevated)
        .overlay {
            Rectangle().strokeBorder(DesignTokens.dividerStructural,
                                     lineWidth: DesignTokens.dividerWidth)
        }
        .clipShape(Rectangle())
    }
}

#Preview {
    VStack(spacing: DesignTokens.gridRowSpacing) {
        SensitivityImpactRow(
            label: "Cap Rate ±0.5%",
            fillRatio: 0.85,
            impactText: "−€32K NOI",
            accent: DesignTokens.accentRust
        )
        SensitivityImpactRow(
            label: "Vacancy +5%",
            fillRatio: 0.62,
            impactText: "−€21K NOI",
            accent: DesignTokens.accentRust
        )
        SensitivityImpactRow(
            label: "Int Rate +100BPS",
            fillRatio: 0.48,
            impactText: "−€18K CF",
            accent: DesignTokens.accentRust
        )
    }
    .padding(DesignTokens.blockGutter)
    .frame(width: 660)
    .background(DesignTokens.canvasBase)
}
