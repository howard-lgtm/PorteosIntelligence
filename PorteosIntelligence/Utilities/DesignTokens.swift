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

    // MARK: Semantic

    static let statusGo           = Color(hex: "#27C93F")
    static let statusWarn         = Color(hex: "#FFBD2E")
    static let statusCritical     = Color(hex: "#FF5F56")

    static let colorOptimal       = statusGo
    static let colorWarning       = statusWarn
    static let colorDanger        = statusCritical

    static let accentRust         = Color(hex: "#A34121")

    // MARK: Layout — rows

    static let rowHeightData:     CGFloat = 28
    static let rowHeightButton:   CGFloat = 32
    static let rowHeightHeader:   CGFloat = 36
    static let rowHeightPaneBar:  CGFloat = 40
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
