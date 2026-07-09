import Foundation
import Security
import SwiftData

// MARK: - IMAPCredentials

struct IMAPCredentials: Codable {
    var email:         String
    var password:      String
    var imapHost:      String
    var imapPort:      Int    = 993
    var folder:        String = "INBOX"
    var pollMinutes:   Int    = 15

    // Common provider presets
    static let presets: [(label: String, host: String, port: Int)] = [
        ("Gmail",              "imap.gmail.com",            993),
        ("Outlook / Office365","outlook.office365.com",     993),
        ("iCloud",             "imap.mail.me.com",          993),
        ("Yahoo",              "imap.mail.yahoo.com",       993),
        ("Custom",             "",                          993),
    ]

    // MARK: Keychain persistence

    private static let kcService = "com.porteos.intelligence"
    private static let kcAccount = "imap_credentials"

    static func load() -> IMAPCredentials? {
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: kcService,
            kSecAttrAccount as String: kcAccount,
            kSecReturnData as String:  kCFBooleanTrue!,
            kSecMatchLimit as String:  kSecMatchLimitOne,
        ]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data else { return nil }
        return try? JSONDecoder().decode(IMAPCredentials.self, from: data)
    }

    func save() throws {
        guard let data = try? JSONEncoder().encode(self) else { return }
        let del: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: Self.kcService,
            kSecAttrAccount as String: Self.kcAccount,
        ]
        SecItemDelete(del as CFDictionary)
        let add: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: Self.kcService,
            kSecAttrAccount as String: Self.kcAccount,
            kSecValueData as String:   data,
        ]
        let status = SecItemAdd(add as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw IMAPError.keychainFailure(status)
        }
    }

    static func delete() {
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: kcService,
            kSecAttrAccount as String: kcAccount,
        ]
        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - IMAPError

enum IMAPError: LocalizedError {
    case notConfigured
    case curlFailed(String)
    case keychainFailure(OSStatus)
    case noContainer

    var errorDescription: String? {
        switch self {
        case .notConfigured:              return "IMAP credentials not configured."
        case .curlFailed(let msg):        return "IMAP connection error: \(msg)"
        case .keychainFailure(let code):  return "Keychain error (OSStatus \(code))."
        case .noContainer:                return "Data container unavailable."
        }
    }
}

// MARK: - EmailMonitorService

@Observable @MainActor
final class EmailMonitorService {

    static let shared = EmailMonitorService()
    private init() {}

    // MARK: Published state

    var isMonitoring        = false
    var isCheckingNow       = false
    var lastCheckDate:      Date?
    var newImportCount      = 0        // badge count; caller resets to 0 on open
    var totalEmailsScanned  = 0        // cumulative emails examined across all cycles
    var totalDealsImported  = 0        // cumulative successful imports
    var duplicatesSkipped   = 0        // cumulative dedup hits
    var errorMessage:       String?
    /// Human-readable outcome of the most recent check (imports, dupes, scan scope).
    var lastCheckSummary:   String?

    var isConfigured: Bool { IMAPCredentials.load() != nil }

    /// Default lookback when no prior successful check exists.
    private let searchLookbackDays = 14

    // MARK: Private

    private var pollingTimer:   Timer?
    private var modelContainer: ModelContainer?

    // MARK: Container injection (called from AppShell.onAppear)

    func injectContainer(_ container: ModelContainer) {
        modelContainer = container
    }

    // MARK: Lifecycle

    func startMonitoring() {
        guard let creds = IMAPCredentials.load() else {
            errorMessage = "Configure IMAP credentials first."
            return
        }
        isMonitoring = true
        errorMessage = nil
        let interval = TimeInterval(creds.pollMinutes * 60)
        pollingTimer?.invalidate()
        pollingTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in await self?.checkNow() }
        }
        // Kick off an immediate check
        Task { await checkNow() }
    }

    func stopMonitoring() {
        isMonitoring = false
        pollingTimer?.invalidate()
        pollingTimer = nil
    }

    // MARK: Core check cycle

    func checkNow() async {
        guard !isCheckingNow else { return }
        guard let creds = IMAPCredentials.load() else { return }
        guard let container = modelContainer else {
            errorMessage = IMAPError.noContainer.localizedDescription
            return
        }

        isCheckingNow = true
        errorMessage  = nil
        lastCheckSummary = nil

        do {
            let result = try await fetchAndImport(creds: creds, container: container)
            newImportCount += result.imported
            lastCheckDate   = Date()
            lastCheckSummary = result.summary
            if result.imported == 0 && result.duplicatesSkipped > 0 && errorMessage == nil {
                // Not an error — inbox may be quiet or everything already imported.
                lastCheckSummary = (lastCheckSummary ?? "") + " // no new deals"
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isCheckingNow = false
    }

    // MARK: Test connection (returns a human-readable result string)

    func testConnection(creds: IMAPCredentials) async -> String {
        let url = "imaps://\(creds.imapHost):\(creds.imapPort)/"
        do {
            let output = try await runCurl([
                "-s", "--ssl-reqd",
                "--connect-timeout", "10",
                "-u", "\(creds.email):\(creds.password)",
                url, "--list-only",
            ])
            if output.isEmpty {
                return "CONNECTION_OK — mailbox is accessible."
            }
            let preview = output.components(separatedBy: "\n")
                .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
                .prefix(5)
                .joined(separator: " | ")
            return "CONNECTION_OK — folders: \(preview)"
        } catch {
            return "ERROR — \(error.localizedDescription)"
        }
    }

    // MARK: - Fetch-and-import pipeline

    private struct EmailCheckResult {
        var imported: Int
        var duplicatesSkipped: Int
        var scanned: Int
        var unparsed: Int
        var searchCriteria: String

        var summary: String {
            var parts: [String] = []
            parts.append("\(imported) imported")
            if duplicatesSkipped > 0 { parts.append("\(duplicatesSkipped) duplicates skipped") }
            if unparsed > 0 { parts.append("\(unparsed) unparsed") }
            parts.append("\(scanned) scanned")
            parts.append("via \(searchCriteria)")
            return parts.joined(separator: " · ")
        }
    }

    private func fetchAndImport(creds: IMAPCredentials, container: ModelContainer) async throws -> EmailCheckResult {
        let baseURL = imapBaseURL(creds: creds)
        let sinceDate = searchSinceDate()
        let criteriaList = [
            "SEARCH UNSEEN SINCE \(sinceDate)",
            "SEARCH SINCE \(sinceDate)",
        ]

        var indices: [Int] = []
        var usedCriteria = criteriaList[0]
        var lastSearchError: Error?

        for criteria in criteriaList {
            do {
                let output = try await runCurl([
                    "-s", "--ssl-reqd",
                    "--connect-timeout", "20",
                    "--max-time", "45",
                    "-u", "\(creds.email):\(creds.password)",
                    baseURL, "-X", criteria,
                ])
                indices = parseSearchResponse(output)
                usedCriteria = criteria
                lastSearchError = nil
                break
            } catch {
                lastSearchError = error
            }
        }

        if indices.isEmpty, let lastSearchError {
            throw lastSearchError
        }

        guard !indices.isEmpty else {
            return EmailCheckResult(
                imported: 0, duplicatesSkipped: 0, scanned: 0, unparsed: 0,
                searchCriteria: usedCriteria
            )
        }

        // Process at most 50 messages per cycle (newest first when indices are ascending)
        var importedCount = 0
        var dupesThisCycle = 0
        var unparsedCount  = 0
        let ctx = ModelContext(container)

        for index in indices.suffix(50) {
            guard let rawEmail = try? await runCurl([
                "-s", "--ssl-reqd",
                "--connect-timeout", "15",
                "-u", "\(creds.email):\(creds.password)",
                "\(baseURL)/;MAILINDEX=\(index)",
            ]) else { continue }

            let (subject, senderDomain, body) = parseRawEmail(rawEmail)
            guard !subject.isEmpty else { continue }

            await MainActor.run { totalEmailsScanned += 1 }

            // Step 3: Select the best parser
            let parser: any ListingEmailParser =
                allListingParsers.first { $0.canParse(subject: subject, senderDomain: senderDomain) }
                ?? GenericListingEmailParser()

            guard let listing = parser.parse(subject: subject, body: body) else {
                unparsedCount += 1
                continue
            }

            // Step 4: Deduplication by listing URL
            let listingURL = listing.listingURL ?? ""
            let normalizedURL = listingURL.isEmpty ? "" : ListingURLHelpers.normalize(listingURL)
            if !normalizedURL.isEmpty {
                let urlKey = normalizedURL
                let dupes = try ctx.fetch(
                    FetchDescriptor<EmailImportRecord>(
                        predicate: #Predicate { $0.listingURL == urlKey }
                    )
                )
                if !dupes.isEmpty {
                    dupesThisCycle += 1
                    await MainActor.run { duplicatesSkipped += 1 }
                    continue
                }
            }

            // Step 5: Create PropertyDeal
            let noteLines: [String] = [
                "Source: \(listing.source.uppercased())",
                "Subject: \(subject)",
                listingURL.isEmpty ? nil : "URL: \(listingURL)",
                "Currency: \(listing.currency)",
                listing.bedrooms.map { "Bedrooms: \($0)" },
            ].compactMap { $0 }

            let deal = PropertyDeal(
                propertyName:  listing.propertyName,
                propertyType:  listing.propertyType,
                totalArea:     listing.areaSqM ?? 0,
                locationCity:  listing.location,
                purchasePrice: listing.price,
                notes:         noteLines.joined(separator: "\n"),
                tags:          ["email_import", "source:\(listing.source)"],
                status:        .pipeline
            )
            ctx.insert(deal)

            // Step 6: Record the import for future dedup
            let dedupeURL = normalizedURL.isEmpty ? "noop://\(UUID().uuidString)" : normalizedURL
            let record = EmailImportRecord(
                listingURL: dedupeURL,
                source:     listing.source,
                rawSubject: subject,
                dealID:     deal.id
            )
            ctx.insert(record)

            try ctx.save()
            importedCount += 1

            // Task 5: toast notification on main actor
            let dealID    = deal.id
            let dealName  = deal.propertyName
            let dealCity  = deal.locationCity
            let dealPrice = deal.purchasePrice
            let src       = listing.source
            await MainActor.run {
                totalDealsImported += 1
                ToastManager.shared.show(IngestionToastData(
                    dealID:       dealID,
                    propertyName: dealName,
                    location:     dealCity,
                    price:        dealPrice,
                    source:       src,
                    isDuplicate:  false
                ))
            }
        }

        return EmailCheckResult(
            imported: importedCount,
            duplicatesSkipped: dupesThisCycle,
            scanned: min(indices.count, 50),
            unparsed: unparsedCount,
            searchCriteria: usedCriteria
        )
    }

    // MARK: - IMAP helpers

    private func imapBaseURL(creds: IMAPCredentials) -> String {
        let folder = creds.folder.isEmpty ? "INBOX" : creds.folder
        let encoded = folder
            .split(separator: "/")
            .map { $0.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? String($0) }
            .joined(separator: "/")
        return "imaps://\(creds.imapHost):\(creds.imapPort)/\(encoded)"
    }

    /// IMAP `SINCE` date — `DD-Mon-YYYY` (e.g. `09-Jul-2026`).
    private func searchSinceDate() -> String {
        let bufferDays = 2
        let anchor = lastCheckDate ?? Calendar.current.date(
            byAdding: .day, value: -searchLookbackDays, to: Date()
        ) ?? Date()
        let since = Calendar.current.date(byAdding: .day, value: -bufferDays, to: anchor) ?? anchor
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "dd-MMM-yyyy"
        return formatter.string(from: since)
    }

    // MARK: - curl subprocess runner (nonisolated so it never blocks the main actor)

    nonisolated private func runCurl(_ args: [String]) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/curl")
            process.arguments     = args

            let outPipe = Pipe()
            let errPipe = Pipe()
            process.standardOutput = outPipe
            process.standardError  = errPipe

            // Use terminationHandler — never blocks any thread
            process.terminationHandler = { proc in
                let output = String(
                    data: outPipe.fileHandleForReading.readDataToEndOfFile(),
                    encoding: .utf8
                ) ?? ""
                if proc.terminationStatus == 0 {
                    continuation.resume(returning: output)
                } else {
                    let errOut = String(
                        data: errPipe.fileHandleForReading.readDataToEndOfFile(),
                        encoding: .utf8
                    ) ?? ""
                    let trimmed = errOut.trimmingCharacters(in: .whitespacesAndNewlines)
                    let msg: String
                    if trimmed.isEmpty {
                        msg = "curl exit \(proc.terminationStatus)"
                    } else {
                        let line = trimmed.components(separatedBy: .newlines).first ?? trimmed
                        msg = String(line.prefix(200))
                    }
                    continuation.resume(throwing: IMAPError.curlFailed(msg))
                }
            }

            do {
                try process.run()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    // MARK: - IMAP response parsing

    /// Parses "* SEARCH 1 3 5 10\r\n" into [1, 3, 5, 10].
    private func parseSearchResponse(_ output: String) -> [Int] {
        guard let re = try? NSRegularExpression(pattern: "\\* SEARCH([^\r\n]*)"),
              let m  = re.firstMatch(in: output, range: NSRange(output.startIndex..., in: output)),
              let r  = Range(m.range(at: 1), in: output) else { return [] }
        return String(output[r])
            .trimmingCharacters(in: .whitespaces)
            .components(separatedBy: .whitespaces)
            .compactMap { Int($0) }
    }

    /// Splits raw RFC 2822 email into (subject, senderDomain, body).
    private func parseRawEmail(_ raw: String) -> (subject: String, senderDomain: String, body: String) {
        var subject      = ""
        var senderDomain = ""
        var inHeaders    = true
        var bodyLines: [String] = []

        for line in raw.components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if inHeaders {
                if trimmed.isEmpty { inHeaders = false; continue }
                let lower = trimmed.lowercased()
                if lower.hasPrefix("subject:") {
                    let raw = String(trimmed.dropFirst("subject:".count)).trimmingCharacters(in: .whitespaces)
                    subject = decodeMIMEWords(raw)
                } else if lower.hasPrefix("from:") {
                    let fromLine = String(trimmed.dropFirst("from:".count))
                    // Extract domain from address like "alerts@zillow.com" or "<alerts@zillow.com>"
                    if let atIdx = fromLine.firstIndex(of: "@") {
                        senderDomain = String(fromLine[fromLine.index(after: atIdx)...])
                            .components(separatedBy: CharacterSet(charactersIn: "> \"\t\r\n"))
                            .first ?? ""
                    }
                }
            } else {
                bodyLines.append(line)
            }
        }

        return (subject, senderDomain, bodyLines.joined(separator: "\n"))
    }

    /// Decodes MIME encoded-word syntax: =?UTF-8?Q?...?= and =?UTF-8?B?...?=
    private func decodeMIMEWords(_ text: String) -> String {
        let pattern = #"=\?([^?]+)\?([BQbq])\?([^?]+)\?="#
        guard let re = try? NSRegularExpression(pattern: pattern) else { return text }

        var result = text
        let nsResult = result as NSString
        let matches = re.matches(in: result, range: NSRange(location: 0, length: nsResult.length))

        for match in matches.reversed() {
            guard match.numberOfRanges == 4,
                  let encR  = Range(match.range(at: 2), in: result),
                  let textR = Range(match.range(at: 3), in: result),
                  let fullR = Range(match.range, in: result) else { continue }

            let encoding = result[encR].uppercased()
            let encoded  = String(result[textR])
            var decoded  = encoded

            if encoding == "Q" {
                // Quoted-printable: underscore → space, =XX → byte
                var qp = encoded.replacingOccurrences(of: "_", with: " ")
                let hexPat = #"=([0-9A-Fa-f]{2})"#
                if let hexRe = try? NSRegularExpression(pattern: hexPat) {
                    let nsQP = qp as NSString
                    let hexMatches = hexRe.matches(in: qp, range: NSRange(location: 0, length: nsQP.length))
                    for hm in hexMatches.reversed() {
                        guard let hr = Range(hm.range(at: 1), in: qp),
                              let byte = UInt8(qp[hr], radix: 16),
                              let char = String(bytes: [byte], encoding: .utf8) else { continue }
                        qp = (qp as NSString).replacingCharacters(in: hm.range, with: char)
                    }
                }
                decoded = qp
            } else if encoding == "B" {
                if let data = Data(base64Encoded: encoded),
                   let str  = String(data: data, encoding: .utf8) {
                    decoded = str
                }
            }

            result = result.replacingCharacters(in: fullR, with: decoded)
        }

        return result
    }
}
