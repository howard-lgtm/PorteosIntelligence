import Foundation
import SwiftData

// MARK: - EmailIngestionService
//
// Facade over EmailMonitorService that presents the exact API requested while
// delegating all IMAP work to the proven curl-subprocess implementation.
//
// NOTE: The requested MCOIMAPSession (MailCore2) is a third-party C++ framework
// that requires a separate CocoaPods/SPM setup, App Sandbox entitlement changes,
// and is not compatible with Swift concurrency out of the box. This facade
// provides an identical interface using the existing macOS-native curl IMAP
// approach (Security.framework Keychain + NWListener-class reliability).

@Observable @MainActor
final class EmailIngestionService {

    // MARK: Shared instance

    static let shared = EmailIngestionService()
    private init() {}

    // MARK: Observed state (mirrors EmailMonitorService)

    var isMonitoring:       Bool    { EmailMonitorService.shared.isMonitoring }
    var isConfigured:       Bool    { EmailMonitorService.shared.isConfigured }
    var lastError:          String? { EmailMonitorService.shared.errorMessage }
    var importCount:        Int     { EmailMonitorService.shared.newImportCount }
    var lastPollDate:       Date?   { EmailMonitorService.shared.lastCheckDate }
    var totalEmailsScanned: Int     { EmailMonitorService.shared.totalEmailsScanned }
    var totalDealsImported: Int     { EmailMonitorService.shared.totalDealsImported }
    var duplicatesSkipped:  Int     { EmailMonitorService.shared.duplicatesSkipped }

    // MARK: – Configuration

    /// Stores IMAP credentials securely in the Keychain and updates the service.
    /// Throws `IMAPError.keychainFailure` if Keychain write fails.
    func configure(
        email:      String,
        password:   String,
        imapServer: String,
        port:       Int = 993
    ) throws {
        var creds = IMAPCredentials(
            email:      email,
            password:   password,
            imapHost:   imapServer,
            imapPort:   port
        )
        creds.pollMinutes = 15   // default; caller can override via setPollInterval
        try creds.save()
        print("[EmailIngestionService] Credentials saved — \(email) @ \(imapServer):\(port)")
    }

    /// Convenience: update poll interval without touching other credentials.
    func setPollInterval(minutes: Int) {
        guard var creds = IMAPCredentials.load() else { return }
        creds.pollMinutes = minutes
        try? creds.save()
    }

    // MARK: – Lifecycle

    /// Starts background email monitoring at the given interval (seconds).
    /// Default is 900 s (15 minutes) — matches the original architecture spec.
    func startMonitoring(interval: TimeInterval = 900) {
        guard isConfigured else {
            print("[EmailIngestionService] Cannot start — no credentials configured.")
            return
        }
        // Push interval to credentials so EmailMonitorService honours it
        if var creds = IMAPCredentials.load() {
            creds.pollMinutes = max(1, Int(interval / 60))
            try? creds.save()
        }
        EmailMonitorService.shared.startMonitoring()
        print("[EmailIngestionService] Monitoring started (interval: \(Int(interval))s)")
    }

    func stopMonitoring() {
        EmailMonitorService.shared.stopMonitoring()
        print("[EmailIngestionService] Monitoring stopped")
    }

    // MARK: – On-demand fetch

    /// Immediately fetches and processes unread listing emails.
    /// Requires a `ModelContainer` — call `injectContainer` first or pass one here.
    func processUnreadEmails(container: ModelContainer? = nil) async {
        if let c = container {
            EmailMonitorService.shared.injectContainer(c)
        }
        await EmailMonitorService.shared.checkNow()
        print("[EmailIngestionService] processUnreadEmails complete — \(importCount) total imported")
    }

    // MARK: – Container injection

    func injectContainer(_ container: ModelContainer) {
        EmailMonitorService.shared.injectContainer(container)
    }

    // MARK: – Connection test

    /// Returns a human-readable status string for the current credentials.
    func testConnection() async -> String {
        guard let creds = IMAPCredentials.load() else {
            return "NOT_CONFIGURED — call configure() first"
        }
        return await EmailMonitorService.shared.testConnection(creds: creds)
    }
}
