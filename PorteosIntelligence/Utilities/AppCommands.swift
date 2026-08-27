import SwiftUI

// MARK: - Notification Names
// Commands post these; panes subscribe with .onReceive — zero direct coupling.

extension Notification.Name {
    static let showNewDeal          = Notification.Name("porteos.showNewDeal")
    static let showImportDeals      = Notification.Name("porteos.showImportDeals")
    static let showExportSheet      = Notification.Name("porteos.showExportSheet")
    static let showEditDeal         = Notification.Name("porteos.showEditDeal")
    static let navigateProfile      = Notification.Name("porteos.navigateProfile")
    static let showShortcutsLegend  = Notification.Name("porteos.showShortcutsLegend")
    static let showCommandPalette   = Notification.Name("porteos.showCommandPalette")
    static let undoDealEdit         = Notification.Name("porteos.undoDealEdit")
    static let redoDealEdit         = Notification.Name("porteos.redoDealEdit")
    static let showPDFReport        = Notification.Name("porteos.showPDFReport")
    static let showEmailSetup       = Notification.Name("porteos.showEmailSetup")
    static let showQuickAdd         = Notification.Name("porteos.showQuickAdd")
    static let showServerConfig     = Notification.Name("porteos.showServerConfig")
    static let showSettings         = Notification.Name("porteos.showSettings")
    static let showGlossary         = Notification.Name("porteos.showGlossary")
    static let deleteSelectedDeal   = Notification.Name("porteos.deleteSelectedDeal")
    static let preloadMarketAssumptions = Notification.Name("porteos.preloadMarketAssumptions")
}

// MARK: - FocusedValue: hasDealSelected
// AppShell publishes this; Commands reads it to disable context-sensitive items.

private struct HasDealSelectedKey: FocusedValueKey {
    typealias Value = Bool
}

extension FocusedValues {
    var hasDealSelected: Bool? {
        get { self[HasDealSelectedKey.self] }
        set { self[HasDealSelectedKey.self] = newValue }
    }
}

// MARK: - AppCommandsProvider

struct AppCommandsProvider: Commands {

    @FocusedValue(\.hasDealSelected) private var hasDealSelected: Bool?

    var body: some Commands {

        // ── Help menu — replaces the system "Help isn't available" alert ─────────
        CommandGroup(replacing: .help) {
            Button("Porteos Keyboard Shortcuts") {
                post(.showShortcutsLegend)
            }
            Button("Command Palette") {
                post(.showCommandPalette)
            }
            Divider()
            Button("Glossary…") {
                post(.showGlossary)
            }
        }

        // ── Edit menu: Undo / Redo ─────────────────────────────────────────────
        // Replaces the system undo slot so ⌘Z / ⌘⇧Z route through our stack.
        // ── Edit menu: Delete selected deal ───────────────────────────────────
        CommandGroup(after: .undoRedo) {
            Divider()
            Button("Preload Market Assumptions…") {
                post(.preloadMarketAssumptions)
            }
            .keyboardShortcut("p", modifiers: [.command, .shift])
            .disabled(!(hasDealSelected ?? false))
            
            Button("Delete Deal…") {
                post(.deleteSelectedDeal)
            }
            .keyboardShortcut(.delete, modifiers: .command)
            .disabled(!(hasDealSelected ?? false))
        }

        CommandGroup(replacing: .undoRedo) {
            Button("Undo \(DealHistoryManager.shared.undoLabel)") {
                post(.undoDealEdit)
            }
            .keyboardShortcut("z", modifiers: .command)
            .disabled(!DealHistoryManager.shared.canUndo)

            Button("Redo \(DealHistoryManager.shared.redoLabel)") {
                post(.redoDealEdit)
            }
            .keyboardShortcut("z", modifiers: [.command, .shift])
            .disabled(!DealHistoryManager.shared.canRedo)
        }

        // ── File menu ─────────────────────────────────────────────────────────
        CommandGroup(replacing: .newItem) {
            Button("New Deal") {
                post(.showNewDeal)
            }
            .keyboardShortcut("n", modifiers: .command)

            Button("Quick Add…") {
                post(.showQuickAdd)
            }
            .keyboardShortcut("q", modifiers: [.command, .shift])

            Divider()

            Button("Import Deals…") {
                post(.showImportDeals)
            }
            .keyboardShortcut("i", modifiers: .command)
        }

        // ── Navigation menu ───────────────────────────────────────────────────
        CommandMenu("Navigation") {
            Button("Command Center") { navigate(.cmdCenter)   }.keyboardShortcut("0", modifiers: .command)
            Button("Real Estate")    { navigate(.realEstate)  }.keyboardShortcut("1", modifiers: .command)
            Button("Hospitality")    { navigate(.hospitality) }.keyboardShortcut("2", modifiers: .command)
            Button("Design")         { navigate(.design)      }.keyboardShortcut("3", modifiers: .command)
            Button("Circular Economy") { navigate(.circular)  }.keyboardShortcut("4", modifiers: .command)
            Button("Global Intelligence") { navigate(.globalIntelligence) }.keyboardShortcut("5", modifiers: .command)
        }

        // ── Actions menu ──────────────────────────────────────────────────────
        CommandMenu("Actions") {
            Button("Edit Deal Data") {
                post(.showEditDeal)
            }
            .keyboardShortcut("e", modifiers: .command)
            .disabled(!(hasDealSelected ?? false))

            Button("Export Data…") {
                post(.showExportSheet)
            }
            .keyboardShortcut("o", modifiers: [.command, .shift])

            Button("Export PDF Report…") {
                post(.showPDFReport)
            }
            .keyboardShortcut("p", modifiers: [.command, .shift])
            .disabled(!(hasDealSelected ?? false))

            Divider()

            Button("Email Alert Monitor…") {
                post(.showEmailSetup)
            }
            .keyboardShortcut("m", modifiers: [.command, .shift])

            Button("Ingestion Server…") {
                post(.showServerConfig)
            }
            .keyboardShortcut("h", modifiers: [.command, .shift])

            Button("Settings…") {
                post(.showSettings)
            }
            .keyboardShortcut(",", modifiers: .command)

            Divider()

            Button("Show Keyboard Shortcuts") {
                post(.showShortcutsLegend)
            }
            .keyboardShortcut("/", modifiers: .command)

            Button("Command Palette") {
                post(.showCommandPalette)
            }
            .keyboardShortcut("k", modifiers: .command)

            Divider()

            Button("Glossary…") {
                post(.showGlossary)
            }
            .keyboardShortcut("g", modifiers: [.command, .shift])
        }
    }

    // MARK: Helpers

    private func post(_ name: Notification.Name) {
        NotificationCenter.default.post(name: name, object: nil)
    }

    private func navigate(_ profile: ProfileType) {
        NotificationCenter.default.post(
            name:     .navigateProfile,
            object:   nil,
            userInfo: ["profile": profile.rawValue]
        )
    }
}
