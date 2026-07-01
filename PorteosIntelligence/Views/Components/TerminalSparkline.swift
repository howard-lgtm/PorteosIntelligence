import SwiftUI

// MARK: - TerminalSparkline
// Compact terminal-aesthetic trend line rendered via Canvas.
// Uses linear interpolation (sharp angles, no bezier curves).

struct TerminalSparkline: View {

    let data: [Double]
    let color: Color
    var height: CGFloat = 24

    private let borderColor = Color(hex: "#2E333F")

    var body: some View {
        Canvas { ctx, size in
            guard data.count >= 2 else { return }

            let minVal = data.min() ?? 0
            let maxVal = data.max() ?? 1
            let range  = maxVal == minVal ? 1.0 : maxVal - minVal

            let stepX = size.width / CGFloat(data.count - 1)

            // Normalize data → pixel coords (y-flipped: higher value = lower y)
            let points: [CGPoint] = data.enumerated().map { i, v in
                CGPoint(
                    x: CGFloat(i) * stepX,
                    y: (1.0 - CGFloat((v - minVal) / range)) * size.height
                )
            }

            // ── Gradient fill beneath the line ──────────────────────────────
            var fillPath = Path()
            fillPath.move(to: CGPoint(x: points[0].x, y: size.height))
            fillPath.addLine(to: points[0])
            for pt in points.dropFirst() { fillPath.addLine(to: pt) }
            fillPath.addLine(to: CGPoint(x: points[points.count - 1].x, y: size.height))
            fillPath.closeSubpath()

            ctx.fill(
                fillPath,
                with: .linearGradient(
                    Gradient(colors: [color.opacity(0.28), color.opacity(0.0)]),
                    startPoint: CGPoint(x: size.width / 2, y: 0),
                    endPoint:   CGPoint(x: size.width / 2, y: size.height)
                )
            )

            // ── 1px stroke line (linear, no bezier) ─────────────────────────
            var linePath = Path()
            linePath.move(to: points[0])
            for pt in points.dropFirst() { linePath.addLine(to: pt) }
            ctx.stroke(linePath, with: .color(color), lineWidth: 1)

            // ── 3×3pt square marker at final data point ──────────────────────
            if let last = points.last {
                let dot = CGRect(x: last.x - 1.5, y: last.y - 1.5, width: 3, height: 3)
                ctx.fill(Path(dot), with: .color(color))
            }

            // ── 1px border (inset by 0.5 to stay within canvas bounds) ───────
            let border = Path(CGRect(x: 0.5, y: 0.5,
                                     width:  size.width  - 1,
                                     height: size.height - 1))
            ctx.stroke(border, with: .color(borderColor), lineWidth: 1)
        }
        .frame(height: height)
        .clipShape(Rectangle())
    }
}

// MARK: - Preview

#Preview {
    let up:   [Double] = [88, 90, 87, 93, 96, 91, 98, 100, 97, 103, 108, 112]
    let down: [Double] = [115, 110, 108, 112, 106, 102, 99,  96,  98,  93,  89,  85]
    let flat: [Double] = [100, 102, 98, 101, 99, 103, 100, 98, 102, 100, 101, 99]

    return VStack(spacing: 12) {
        TerminalSparkline(data: up,   color: Color(hex: "#10B981"), height: 24).frame(width: 80)
        TerminalSparkline(data: down, color: Color(hex: "#EF4444"), height: 24).frame(width: 80)
        TerminalSparkline(data: flat, color: Color(hex: "#F59E0B"), height: 24).frame(width: 80)
        TerminalSparkline(data: up,   color: Color(hex: "#14B8A6"), height: 32).frame(width: 120)
    }
    .padding(16)
    .background(Color(hex: "#0F1115"))
}
