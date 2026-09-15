import AppKit
import SwiftUI

// MARK: - WindowStateManager
// Persists and restores the main window's size, position, and full-screen state
// across launches. Uses NSWindow.setFrameAutosaveName for frame (size + position)
// and UserDefaults for full-screen state.

final class WindowStateManager: NSObject, NSWindowDelegate {

    static let shared = WindowStateManager()
    private override init() {}

    private let autosaveName    = "PorteosMainWindow"
    private let fullScreenKey   = "porteos.windowWasFullScreen"
    private let defaultWidth:  CGFloat = 1440
    private let defaultHeight: CGFloat = 900

    // MARK: - Setup

    /// Call once when the main window becomes available.
    func configure(window: NSWindow) {
        window.delegate = self

        // Let macOS auto-save/restore frame (position + size).
        // If no saved frame exists yet, center the window at the default size.
        window.setFrameAutosaveName(autosaveName)

        if !hasSavedFrame {
            let screen = window.screen ?? NSScreen.main ?? NSScreen.screens.first!
            let origin = CGPoint(
                x: (screen.visibleFrame.width  - defaultWidth)  / 2 + screen.visibleFrame.minX,
                y: (screen.visibleFrame.height - defaultHeight) / 2 + screen.visibleFrame.minY
            )
            window.setFrame(NSRect(origin: origin, size: CGSize(width: defaultWidth, height: defaultHeight)),
                            display: false)
        }

        // Set a sensible minimum size so the layout never collapses.
        window.minSize = CGSize(width: 960, height: 640)

        // Full-screen logic:
        // - First ever launch (key absent) → go full screen for maximum impact
        // - Subsequent launches → restore whatever the user last set
        let hasSavedFullScreenPref = UserDefaults.standard.object(forKey: fullScreenKey) != nil
        let shouldGoFullScreen = hasSavedFullScreenPref
            ? UserDefaults.standard.bool(forKey: fullScreenKey)
            : true   // default to full screen on first launch

        if shouldGoFullScreen {
            // Small delay — the window must be fully on screen before toggling.
            // Guard: configure() can be invoked again if SwiftUI re-creates the
            // WindowAccessor (e.g. when a sheet is presented on the window). An
            // unguarded toggle would send an already-full-screen window out, or a
            // windowed window into a dedicated Space, making the app appear to
            // "crash or close". Only toggle if the state actually differs.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                guard !window.styleMask.contains(.fullScreen) else { return }
                window.toggleFullScreen(nil)
            }
        }
    }

    // MARK: - NSWindowDelegate

    func windowDidEnterFullScreen(_ notification: Notification) {
        UserDefaults.standard.set(true, forKey: fullScreenKey)
    }

    func windowDidExitFullScreen(_ notification: Notification) {
        UserDefaults.standard.set(false, forKey: fullScreenKey)
    }

    // MARK: - Private

    private var hasSavedFrame: Bool {
        UserDefaults.standard.string(forKey: "NSWindow Frame \(autosaveName)") != nil
    }
}

// MARK: - WindowAccessor
// Invisible SwiftUI view that surfaces the underlying NSWindow on first appear.

struct WindowAccessor: NSViewRepresentable {

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                WindowStateManager.shared.configure(window: window)
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
