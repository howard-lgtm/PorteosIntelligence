import SwiftUI

// MARK: - ProfileType
// Shared enum used by AppShell, NavigationPane, TopHeaderBar, and InspectorPane.
// Accent colors reflect the V3.1 palette: Rust / Teal / Blue / Purple.

enum ProfileType: String, CaseIterable, Identifiable {
    case cmdCenter   = "cmd_center"
    case realEstate  = "real_estate"
    case hospitality = "hospitality"
    case design      = "design"
    case circular    = "circular"

    var id: String { rawValue }

    /// File-tree nav path shown in NavigationPane.
    var navPath: String { "/\(rawValue)" }

    /// Compact display name shown in TopHeaderBar center slot.
    var displayName: String {
        switch self {
        case .cmdCenter:   return "CMD_CENTER"
        case .realEstate:  return "REAL_ESTATE_PROFILE"
        case .hospitality: return "HOSPITALITY_PROFILE"
        case .design:      return "DESIGN_PROFILE"
        case .circular:    return "CIRCULAR_ECONOMY_PROFILE"
        }
    }

    /// Shell-style command shown in TopHeaderBar center slot.
    var commandLine: String {
        switch self {
        case .cmdCenter:   return "cmd --overview"
        case .realEstate:  return "real_estate --dashboard"
        case .hospitality: return "hospitality --dashboard"
        case .design:      return "design --dashboard"
        case .circular:    return "circular_economy --dashboard"
        }
    }

    /// V3.1 profile accent color (identity only – NOT for semantic states).
    var accentColor: Color {
        switch self {
        case .cmdCenter:   return Color(hex: "#94A3B8")   // text-secondary (neutral)
        case .realEstate:  return Color(hex: "#C25E30")   // Rust
        case .hospitality: return Color(hex: "#14B8A6")   // Teal
        case .design:      return Color(hex: "#A855F7")   // Purple
        case .circular:    return Color(hex: "#3B82F6")   // Blue
        }
    }
}
