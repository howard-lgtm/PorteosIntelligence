import SwiftUI
import SwiftData

@main
struct PorteosIntelligenceApp: App {

    init() {
        PorteosFontLoader.registerBundledFonts()
    }

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            PropertyDeal.self,
            DealScenario.self,
            EmailImportRecord.self,
            MarketTrend.self,
            DealImage.self,
            ResearchMessage.self,  // Chat history for research tab
        ])

        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // Schema migration failed — back up all store files before wiping.
            print("[PorteosApp] ModelContainer failed — attempting backup before reset. Error: \(error)")

            let storeURL = modelConfiguration.url
            let dir      = storeURL.deletingLastPathComponent()
            let name     = storeURL.deletingPathExtension().lastPathComponent

            // ── Dated backup in ~/Documents/PorteosBackups/ ───────────────────
            let docs    = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let backups = docs.appendingPathComponent("PorteosBackups", isDirectory: true)
            try? FileManager.default.createDirectory(at: backups, withIntermediateDirectories: true)

            let stamp = ISO8601DateFormatter().string(from: Date())
                .replacingOccurrences(of: ":", with: "-")

            for suffix in ["store", "store-shm", "store-wal"] {
                let src = dir.appendingPathComponent("\(name).\(suffix)")
                guard FileManager.default.fileExists(atPath: src.path) else { continue }
                let dst = backups.appendingPathComponent("deals-\(stamp).\(suffix)")
                do {
                    try FileManager.default.copyItem(at: src, to: dst)
                    print("[PorteosApp] Backed up \(suffix) → \(dst.lastPathComponent)")
                } catch {
                    print("[PorteosApp] Backup failed for \(suffix): \(error.localizedDescription)")
                }
            }

            // ── Post a user-visible alert via NSAlert before continuing ───────
            DispatchQueue.main.async {
                let alert             = NSAlert()
                alert.messageText     = "Porteos — Data Store Reset"
                alert.informativeText = """
A schema migration was needed and the deal database was reset.

Your data has been backed up to:
~/Documents/PorteosBackups/

Files are named deals-\(stamp).store — contact support to recover them.
"""
                alert.alertStyle      = .warning
                alert.addButton(withTitle: "Continue")
                alert.runModal()
            }

            // ── Delete old store files ────────────────────────────────────────
            print("[PorteosApp] Removing store files at: \(dir.path)")
            for suffix in ["store", "store-shm", "store-wal"] {
                let file = dir.appendingPathComponent("\(name).\(suffix)")
                let existed = FileManager.default.fileExists(atPath: file.path)
                print("[PorteosApp] Removing \(file.lastPathComponent): \(existed)")
                try? FileManager.default.removeItem(at: file)
            }

            do {
                let freshContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
                print("[PorteosApp] Fresh ModelContainer created successfully.")
                return freshContainer
            } catch {
                print("[PorteosApp] FATAL even after reset: \(error)")
                fatalError("Could not create ModelContainer even after store reset: \(error)")
            }
        }
    }()

    @State private var showSplash = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                AppShell()
                    .modelContainer(sharedModelContainer)
                    .onAppear { backfillMissingScores() }
                    .onReceive(NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification)) { _ in
                        DealIngestionServer.shared.stop()
                        EmailMonitorService.shared.stopMonitoring()
                    }
                    // Surfaces the NSWindow so WindowStateManager can configure it.
                    .background(WindowAccessor())

                if showSplash {
                    BootSplashView { showSplash = false }
                        .zIndex(100)
                        .transition(.opacity)
                }
            }
        }
        .defaultSize(width: 1440, height: 900)
        .commands {
            AppCommandsProvider()
        }

        // Independent profile windows — opened via [ ↗ ] buttons in NavigationPane.
        // Each window is fully self-contained with its own deal selection.
        WindowGroup("Profile", id: "profile", for: ProfileWindowValue.self) { $value in
            ProfileWindowView(windowValue: $value)
                .modelContainer(sharedModelContainer)
                .frame(minWidth: 900, minHeight: 600)
        }
        .defaultSize(width: 1200, height: 800)
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
    }

    /// Background pass: score any deal that still has nil porteosScore.
    /// Runs once on launch — non-blocking, detached, no UI impact.
    private func backfillMissingScores() {
        // Run on MainActor — SwiftData models and @Observable ViewModels require it.
        // Async so it yields to the UI and doesn't block launch.
        Task { @MainActor in
            let ctx = ModelContext(sharedModelContainer)
            guard let deals = try? ctx.fetch(
                FetchDescriptor<PropertyDeal>(
                    predicate: #Predicate { $0.porteosScore == nil }
                )
            ), !deals.isEmpty else { return }
            for deal in deals {
                deal.porteosScore = PropertyDealViewModel(deal: deal).porteosScore.finalScore
            }
            try? ctx.save()
            print("[PorteosApp] Backfilled score for \(deals.count) deal(s)")
        }
    }
}
