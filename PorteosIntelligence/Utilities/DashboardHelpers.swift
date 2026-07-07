import SwiftUI

// MARK: - Dashboard Sparkline Helpers
// Free functions shared across all four dashboard views.
// Extracted here to avoid duplication; call sites require no change
// because Swift resolves free functions and shadowing private methods
// identically at the call site.

/// Generates a deterministic 12-point pseudo-random walk that ends at
/// `current`.  The waveform is seeded from the absolute value so the
/// shape is stable across re-renders but varies per metric.
func mockTrend(from current: Double, months: Int = 12) -> [Double] {
    guard current != 0 else { return Array(repeating: 0.0, count: months) }
    let base  = abs(current)
    let sign  = current >= 0 ? 1.0 : -1.0
    let phase = base.truncatingRemainder(dividingBy: 97) / 97.0 * .pi * 2
    return (0..<months).map { i in
        let t    = Double(i) / Double(months - 1)
        let grow = 0.87 + 0.13 * t          // 87 % → 100 % of current
        let wave = sin(phase + Double(i) * 0.78) * 0.035
        return sign * base * (grow + wave)
    }
}

/// Returns the appropriate sparkline color based on trend direction.
/// - `higherIsBetter: true`  → green when trend is rising,  red when falling.
/// - `higherIsBetter: false` → green when trend is falling, red when rising.
func sparkColor(_ trend: [Double], higherIsBetter: Bool = true) -> Color {
    let up = (trend.last ?? 0) >= (trend.first ?? 0)
    return (up == higherIsBetter) ? DesignTokens.statusGo : DesignTokens.statusCritical
}
