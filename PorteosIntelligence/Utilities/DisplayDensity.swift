import SwiftUI

// MARK: - DisplayDensity
// Two-step UI scale: Standard (1×) for laptop, Large (2×) for external monitors.
// Scales typography and row heights together — see Design-system/Figma/DISPLAY_DENSITY.md

enum DisplayDensity: String, CaseIterable, Identifiable {
    case standard = "standard"
    case large    = "large"

    var id: String { rawValue }

    /// Multiplier applied to base token sizes (font, row height, spacing rhythm).
    var multiplier: CGFloat {
        switch self {
        case .standard: return 1.0
        case .large:    return 2.0
        }
    }

    var settingsLabel: String {
        switch self {
        case .standard: return "STANDARD"
        case .large:    return "LARGE"
        }
    }

    var settingsHint: String {
        switch self {
        case .standard: return "1× — laptop / compact"
        case .large:    return "2× — external display"
        }
    }
}

// MARK: - DisplayDensityStore

@Observable
final class DisplayDensityStore {

    static let shared = DisplayDensityStore()

    private static let storageKey = "porteos.displayDensity"

    var mode: DisplayDensity {
        didSet {
            guard oldValue != mode else { return }
            UserDefaults.standard.set(mode.rawValue, forKey: Self.storageKey)
        }
    }

    private init() {
        let raw = UserDefaults.standard.string(forKey: Self.storageKey)
        mode = DisplayDensity(rawValue: raw ?? "") ?? .standard
    }

    // MARK: Scaling helpers — use these when wiring views to density

    func scale(_ base: CGFloat) -> CGFloat {
        (base * mode.multiplier).rounded()
    }

    func fontSize(_ base: CGFloat) -> CGFloat { scale(base) }

    func rowHeight(_ base: CGFloat = 28) -> CGFloat { scale(base) }

    func spacing(_ base: CGFloat) -> CGFloat { scale(base) }

    func monoFont(size base: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom("JetBrains Mono", size: fontSize(base)).weight(weight)
    }
}

// MARK: - Environment

private struct DisplayDensityStoreKey: EnvironmentKey {
    static let defaultValue = DisplayDensityStore.shared
}

extension EnvironmentValues {
    var displayDensity: DisplayDensityStore {
        get { self[DisplayDensityStoreKey.self] }
        set { self[DisplayDensityStoreKey.self] = newValue }
    }
}
