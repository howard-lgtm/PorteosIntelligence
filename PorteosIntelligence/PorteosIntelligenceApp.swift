import SwiftUI
import SwiftData

@main
struct PorteosIntelligenceApp: App {

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            PropertyDeal.self,
            DealScenario.self,
            EmailImportRecord.self,
            MarketTrend.self,
        ])
        
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // Schema migration failed - delete the old store and recreate
            print("[PorteosApp] ModelContainer failed - resetting store. Error: \(error)")
            
            // Get the store URL directly (it's non-optional)
            let storeURL = modelConfiguration.url
            let dir = storeURL.deletingLastPathComponent()
            let name = storeURL.deletingPathExtension().lastPathComponent
            
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

    var body: some Scene {
        WindowGroup {
            AppShell()
                .modelContainer(sharedModelContainer)
                // Stop ingestion server cleanly when the app quits
                .onReceive(NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification)) { _ in
                    DealIngestionServer.shared.stop()
                    EmailMonitorService.shared.stopMonitoring()
                }
        }
        .commands {
            AppCommandsProvider()
        }
    }
}
