import SwiftUI

// MARK: - DesignTokens
// V2.06_STABLE — single source of truth. Phase A type scale locked here.

enum DesignTokens {

    // MARK: Shell (V2.06)

    static let canvasBase         = Color(hex: "#0A0A0A")
    static let surfacePanel       = Color(hex: "#111111")
    static let surfaceElevated    = Color(hex: "#1A1A1A")
    static let dividerStructural  = Color(hex: "#333333")

    static let shellBg            = canvasBase
    static let shellSurface       = surfacePanel
    static let shellElevated      = surfaceElevated
    static let shellBorder        = dividerStructural

    // MARK: Text

    static let textPrimary        = Color(hex: "#F8F9FA")
    static let textSecondary      = Color(hex: "#94A3B8")
    static let textDim            = Color(hex: "#666666")
    static let textTertiary       = textDim

    // MARK: Semantic (Figma: semantic/*)

    static let statusGo           = Color(hex: "#27C93F")
    static let statusWarn         = Color(hex: "#FFBD2E")
    static let statusCritical     = Color(hex: "#FF5F56")
    static let statusInfo         = Color(hex: "#3B82F6")

    static let colorOptimal       = statusGo
    static let colorWarning       = statusWarn
    static let colorDanger        = statusCritical

    // MARK: Deal status (Figma: status/*)

    static let statusPipeline     = Color(hex: "#64748B")
    static let statusReview       = Color(hex: "#F59E0B")
    static let statusViable       = Color(hex: "#27C93F")
    static let statusRejected     = Color(hex: "#FF5F56")
    static let statusAcquired     = Color(hex: "#3B82F6")

    // MARK: Profile accents (Figma: profile/*) — identity only, not threshold state

    static let accentCmdCenter    = Color(hex: "#94A3B8")
    static let accentRust         = Color(hex: "#C25E30")
    static let accentHospitality  = Color(hex: "#14B8A6")
    static let accentDesign       = Color(hex: "#A855F7")
    static let accentCircular     = Color(hex: "#3B82F6")
    static let accentPipeline     = Color(hex: "#F59E0B")

    // MARK: Layout — shell (Figma: layout/*)

    static let navPaneWidth:       CGFloat = 260
    static let inspectorPaneWidth: CGFloat = 280
    static let windowMinWidth:     CGFloat = 1200
    static let windowMinHeight:    CGFloat = 800

    // MARK: Layout — rows

    static let rowHeightData:     CGFloat = 28
    static let rowHeightNavLink:  CGFloat = 24
    static let rowHeightButton:   CGFloat = 32
    static let rowHeightHeader:   CGFloat = 36
    static let rowHeightPaneBar:  CGFloat = 40
    static let rowHeightCommandBar: CGFloat = 32
    static let dividerWidth:      CGFloat = 1
    static let navSelectionBorder: CGFloat = 2

    // MARK: Layout — shell & grid (Phase A+B)

    static let blockGutter:          CGFloat = 12
    static let blockSpacing:         CGFloat = 6
    static let gridRowSpacing:       CGFloat = 6
    static let gridColumnSpacing:    CGFloat = 6
    static let metricCellPadding:    CGFloat = 8
    static let metricCellMinHeight:  CGFloat = 52
    static let heroCellMinHeight:    CGFloat = 88
    static let heroCellPadding:      CGFloat = 12
    static let profileCellMinHeight: CGFloat = 72
    static let profileBarHeight:     CGFloat = 4
    static let crmRowHeight:         CGFloat = 36
    static let sparklineHeight:      CGFloat = 22
    static let sparklineWidth:       CGFloat = 56
    static let gridColumnCount:      Int = 4
    static let gridWideThreshold:    CGFloat = 900

    /// @deprecated
    static let cellInternalPadding  = metricCellPadding
    static let metricCellPaddingY   = metricCellPadding
    static let metricCellHeight     = metricCellMinHeight
    static let gridNarrowThreshold  = gridWideThreshold

    static var metricGridColumns4: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: gridColumnSpacing, alignment: .leading),
              count: gridColumnCount)
    }

    /// 2 columns below 900pt center width; 4 columns at 900pt+.
    static func metricGridColumns(forWidth width: CGFloat) -> [GridItem] {
        let count = width >= gridWideThreshold ? gridColumnCount : 2
        return Array(repeating: GridItem(.flexible(), spacing: gridColumnSpacing, alignment: .leading),
                     count: count)
    }

    // MARK: Phase A — Type scale (pt). No hardcoded sizes in views.

    enum TypeScale {
        static let meta:        CGFloat = 10   // timestamps, LN:120, hints only
        static let rowLabel:    CGFloat = 11
        static let rowValue:    CGFloat = 12
        static let metricLabel: CGFloat = 11
        static let metricValue: CGFloat = 16
        static let moduleCmd:   CGFloat = 11
        static let cliPrompt:   CGFloat = 11
        static let heroScore:   CGFloat = 36
        static let heroGrade:   CGFloat = 20
    }

    // MARK: Typography helpers

    static func mono(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom("JetBrains Mono", size: size).weight(weight)
    }

    static func metaFont() -> Font {
        mono(size: TypeScale.meta)
    }

    static func rowLabelFont() -> Font {
        mono(size: TypeScale.rowLabel)
    }

    static func rowValueFont() -> Font {
        mono(size: TypeScale.rowValue, weight: .medium)
    }

    static func metricLabelFont() -> Font {
        mono(size: TypeScale.metricLabel, weight: .medium)
    }

    static func metricValueFont() -> Font {
        mono(size: TypeScale.metricValue, weight: .semibold)
    }

    static func primaryMetricFont() -> Font { metricValueFont() }

    static func sectionLabelFont() -> Font {
        mono(size: TypeScale.moduleCmd, weight: .medium)
    }

    static func moduleCommandFont() -> Font { sectionLabelFont() }

    static func cliPromptFont() -> Font {
        mono(size: TypeScale.cliPrompt)
    }

    static func heroScoreFont() -> Font {
        mono(size: TypeScale.heroScore, weight: .bold)
    }

    static func heroGradeFont() -> Font {
        mono(size: TypeScale.heroGrade, weight: .bold)
    }
}

// MARK: - MetricState

extension MetricState {
    var semanticColor: Color {
        switch self {
        case .neutral:           return DesignTokens.textPrimary
        case .optimal:           return DesignTokens.statusGo
        case .warning:           return DesignTokens.statusWarn
        case .danger, .critical: return DesignTokens.statusCritical
        }
    }

    /// 2px left accent — list rows and metric inset cells. No background fill in grids.
    var highlightBorderColor: Color? {
        switch self {
        case .warning:           return DesignTokens.statusWarn
        case .danger, .critical: return DesignTokens.statusCritical
        default:                 return nil
        }
    }

    /// Background tint for list rows only — not used in TerminalMetricCell.
    var highlightBackgroundOpacity: Double {
        switch self {
        case .warning:           return 0.05
        case .danger, .critical: return 0.05
        default:                 return 0
        }
    }
}

// MARK: - Terminal semantic button actions

enum TerminalSemanticAction {
    case approve
    case watchlist
    case reject

    var label: String {
        switch self {
        case .approve:   return "[ APPROVE ]"
        case .watchlist: return "[ WATCHLIST ]"
        case .reject:    return "[ REJECT ]"
        }
    }

    var accentColor: Color {
        switch self {
        case .approve:   return DesignTokens.statusGo
        case .watchlist: return DesignTokens.statusWarn
        case .reject:    return DesignTokens.statusCritical
        }
    }

    var fillOpacity: Double {
        switch self {
        case .approve:   return 0.15
        case .watchlist: return 0
        case .reject:    return 0
        }
    }
}

// MARK: - DealStatus colors (Figma status/* tokens)

extension DealStatus {
    var tokenColor: Color {
        switch self {
        case .pipeline: return DesignTokens.statusPipeline
        case .review:   return DesignTokens.statusReview
        case .viable:   return DesignTokens.statusViable
        case .rejected: return DesignTokens.statusRejected
        case .acquired: return DesignTokens.statusAcquired
        }
    }
}
