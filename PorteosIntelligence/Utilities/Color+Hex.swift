import SwiftUI

// MARK: - Color Hex Initializer
// Supports 3-char (#RGB), 6-char (#RRGGBB), and 8-char (#AARRGGBB) hex codes.
// Leading '#' is ignored if present.

extension Color {
    init(hex: String) {
        let raw = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)

        var int: UInt64 = 0
        Scanner(string: raw).scanHexInt64(&int)

        let r, g, b, a: Double
        switch raw.count {
        case 3:  // #RGB  → #RRGGBB
            r = Double((int >> 8) & 0xF) / 15
            g = Double((int >> 4) & 0xF) / 15
            b = Double( int       & 0xF) / 15
            a = 1
        case 6:  // #RRGGBB
            r = Double((int >> 16) & 0xFF) / 255
            g = Double((int >>  8) & 0xFF) / 255
            b = Double( int        & 0xFF) / 255
            a = 1
        case 8:  // #AARRGGBB
            a = Double((int >> 24) & 0xFF) / 255
            r = Double((int >> 16) & 0xFF) / 255
            g = Double((int >>  8) & 0xFF) / 255
            b = Double( int        & 0xFF) / 255
        default:
            r = 1; g = 1; b = 1; a = 1  // fallback: white
        }

        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}
