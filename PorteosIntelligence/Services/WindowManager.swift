import AppKit
import SwiftUI
import SwiftData
import Observation

// MARK: - WindowManager

/// Singleton that manages the tear-away lifecycle for the three main panes.
/// Observable properties drive conditional rendering in AppShell; NSWindow
/// instances handle the actual OS-level window creation and positioning.
@Observable
final class WindowManager {

    static let shared = WindowManager()
    private init() {}

    // MARK: Observable State (drives AppShell UI)

    var detachedPanes:  Set<PaneType> = []
    var selectedDealID: UUID?         = nil
    var activeProfile:  ProfileType   = .cmdCenter

    // MARK: Non-Observable Storage

    /// Injected on first appearance of AppShell so detached windows inherit the store.
    @ObservationIgnored var modelContainer: ModelContainer?

    @ObservationIgnored private var openWindows:       [PaneType: NSWindow]           = [:]
    @ObservationIgnored private var windowDelegates:   [PaneType: PaneWindowDelegate] = [:]
    /// Guards against double-cleanup when reattach() closes a window programmatically.
    @ObservationIgnored private var closingByReattach: Set<PaneType>                  = []

    // MARK: - PaneType

    enum PaneType: String, Hashable, CaseIterable {
        case navigation
        case center
        case inspector

        var windowTitle: String {
            switch self {
            case .navigation: "PORTEOS // NAVIGATION"
            case .center:     "PORTEOS // ANALYSIS"
            case .inspector:  "PORTEOS // INSPECTOR"
            }
        }

        var defaultSize: NSSize {
            switch self {
            case .navigation: NSSize(width: 320,  height: 760)
            case .center:     NSSize(width: 1000, height: 820)
            case .inspector:  NSSize(width: 360,  height: 760)
            }
        }

        var minSize: NSSize {
            switch self {
            case .navigation: NSSize(width: 240, height: 420)
            case .center:     NSSize(width: 600, height: 500)
            case .inspector:  NSSize(width: 280, height: 420)
            }
        }
    }

    // MARK: Public API

    func detach(_ pane: PaneType) {
        guard !detachedPanes.contains(pane) else { return }
        createWindow(for: pane)
        detachedPanes.insert(pane)
    }

    func reattach(_ pane: PaneType) {
        guard detachedPanes.contains(pane) else { return }
        detachedPanes.remove(pane)
        closeWindow(for: pane)
    }

    func reattachAll() {
        PaneType.allCases.forEach { reattach($0) }
    }

    /// Called by `PaneWindowDelegate` when the user manually closes the window
    /// via the red X button. Keeps `detachedPanes` in sync without re-closing.
    func didCloseWindowFromUser(for pane: PaneType) {
        guard !closingByReattach.contains(pane) else { return }
        openWindows.removeValue(forKey: pane)
        windowDelegates.removeValue(forKey: pane)
        detachedPanes.remove(pane)
    }

    // MARK: Window Lifecycle

    private func createWindow(for pane: PaneType) {
        guard let container = modelContainer else {
            print("[WindowManager] modelContainer not set — cannot detach \(pane.rawValue)")
            return
        }

        let contentView: NSView
        let windowSize: NSSize
        switch pane {
        case .navigation:
            contentView = NSHostingView(rootView: DetachedNavigationView().modelContainer(container))
            windowSize  = pane.defaultSize
        case .center:
            contentView = NSHostingView(rootView: DetachedCenterView().modelContainer(container))
            windowSize  = pane.defaultSize
        case .inspector:
            contentView = NSHostingView(rootView: DetachedInspectorView().modelContainer(container))
            windowSize  = pane.defaultSize
        }

        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: windowSize),
            styleMask:   [.titled, .closable, .miniaturizable, .resizable],
            backing:     .buffered,
            defer:       false
        )
        window.contentView          = contentView
        window.title                = "Porteos — \(pane.rawValue.capitalized)"
        window.backgroundColor      = NSColor(hex: "#0F1115")
        window.isReleasedWhenClosed = false   // keep alive so delegate can safely call back
        window.minSize              = pane.minSize

        // Cascade so multiple detached windows don't perfectly overlap
        let idx = CGFloat(PaneType.allCases.firstIndex(of: pane) ?? 0)
        if let main = NSApp.mainWindow {
            window.setFrameOrigin(
                NSPoint(x: main.frame.minX + 60 + idx * 36,
                        y: main.frame.minY + 60)
            )
        } else {
            window.center()
        }

        let delegate          = PaneWindowDelegate(pane: pane)
        window.delegate       = delegate
        windowDelegates[pane] = delegate
        openWindows[pane]     = window
        window.orderFront(nil)   // bring forward without stealing key focus
    }

    private func closeWindow(for pane: PaneType) {
        closingByReattach.insert(pane)
        openWindows[pane]?.close()
        openWindows.removeValue(forKey: pane)
        windowDelegates.removeValue(forKey: pane)
        closingByReattach.remove(pane)
    }
}

// MARK: - NSColor hex convenience

private extension NSColor {
    convenience init(hex: String) {
        let clean = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: clean).scanHexInt64(&value)
        self.init(
            red:   CGFloat((value >> 16) & 0xFF) / 255.0,
            green: CGFloat((value >> 8)  & 0xFF) / 255.0,
            blue:  CGFloat( value        & 0xFF) / 255.0,
            alpha: 1.0
        )
    }
}

// MARK: - PaneWindowDelegate

/// Routes manual user-close (red X) back into WindowManager.
final class PaneWindowDelegate: NSObject, NSWindowDelegate {
    let pane: WindowManager.PaneType
    init(pane: WindowManager.PaneType) { self.pane = pane }

    func windowWillClose(_ notification: Notification) {
        WindowManager.shared.didCloseWindowFromUser(for: pane)
    }
}
