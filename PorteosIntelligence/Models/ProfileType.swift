import SwiftUI

// MARK: - ProfileType
// Shared enum used by AppShell, NavigationPane, TopHeaderBar, and InspectorPane.
// Accent colors reflect the V3.1 palette: Rust / Teal / Blue / Purple.

enum ProfileType: String, CaseIterable, Identifiable {
    case cmdCenter   = "cmd_center"
    case realEstate  = "real_estate"
    case hospitality = "hospitality"
    case design      = "design"
    case circular           = "circular"
    case globalIntelligence = "global_intelligence"

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
        case .circular:           return "CIRCULAR_ECONOMY_PROFILE"
        case .globalIntelligence: return "GLOBAL_INTELLIGENCE_PROFILE"
        }
    }

    /// Short module label for V2.06 workspace header: `[ PROFILE // MODULE ]`.
    var moduleHeaderLabel: String {
        switch self {
        case .cmdCenter:   return "CMD_CENTER"
        case .realEstate:  return "REAL_ESTATE"
        case .hospitality: return "HOSPITALITY"
        case .design:      return "DESIGN"
        case .circular:           return "CIRCULAR_ECONOMY"
        case .globalIntelligence: return "GLOBAL_INTELLIGENCE"
        }
    }

    var moduleSubLabel: String {
        switch self {
        case .cmdCenter:   return "OVERVIEW"
        default:           return "DASHBOARD"
        }
    }

    /// V2.06 bracketed workspace header string.
    var workspaceHeaderTitle: String {
        "[ \(moduleHeaderLabel) // \(moduleSubLabel) ]"
    }

    /// Shell-style command shown in TopHeaderBar center slot.
    var commandLine: String {
        switch self {
        case .cmdCenter:   return "cmd --overview"
        case .realEstate:  return "real_estate --dashboard"
        case .hospitality: return "hospitality --dashboard"
        case .design:      return "design --dashboard"
        case .circular:           return "circular_economy --dashboard"
        case .globalIntelligence: return "intel --map --market=PT"
        }
    }

    /// V3.1 profile accent color (identity only – NOT for semantic states).
    var accentColor: Color {
        switch self {
        case .cmdCenter:   return Color(hex: "#94A3B8")   // text-secondary (neutral)
        case .realEstate:  return Color(hex: "#C25E30")   // Rust
        case .hospitality: return Color(hex: "#14B8A6")   // Teal
        case .design:      return Color(hex: "#A855F7")   // Purple
        case .circular:           return Color(hex: "#3B82F6")   // Blue
        case .globalIntelligence: return Color(hex: "#06B6D4")   // Cyan
        }
    }

    /// CLI host segment for dashboard headers: `porteos@{host} ~ %`.
    var cliHost: String {
        switch self {
        case .cmdCenter:   return "system"
        case .realEstate:  return "real-estate"
        case .hospitality: return "hospitality"
        case .design:      return "design"
        case .circular:           return "circular"
        case .globalIntelligence: return "geo"
        }
    }

    /// Uppercase tag beside deal name on hero score strip.
    var heroProfileTag: String {
        switch self {
        case .cmdCenter:   return "CMD CENTER"
        case .realEstate:  return "REAL ESTATE"
        case .hospitality: return "HOSPITALITY"
        case .design:      return "DESIGN"
        case .circular:           return "CIRCULAR"
        case .globalIntelligence: return "GLOBAL INTELLIGENCE"
        }
    }

    /// Left nav pane label (Figma img_00_21 — uppercase, spaced).
    var shellNavLabel: String { heroProfileTag }

    /// Market trend grid profile key for `MarketTrendGridBuilder`.
    var marketTrendProfileKey: String {
        switch self {
        case .realEstate:  return "realEstate"
        case .hospitality: return "hospitality"
        case .design:      return "design"
        case .circular:           return "circular"
        case .globalIntelligence: return "globalIntelligence"
        case .cmdCenter:          return "cmdCenter"
        }
    }

    func dashboardCLI(assetName: String) -> String {
        let name = assetName.isEmpty ? "Untitled Deal" : assetName
        switch self {
        case .globalIntelligence:
            return "./intel --map --portfolio=geo"
        case .cmdCenter:
            return "./dashboard --portfolio=overview --profiles=6"
        default:
            return "./dashboard --asset=\"\(name)\""
        }
    }

    /// Global Intelligence header — reflects active market filter chip.
    static func geoCommandLine(marketId: String?) -> String {
        guard let marketId, !marketId.isEmpty else { return "intel --map" }
        return "intel --map --market=\(marketId)"
    }
}
