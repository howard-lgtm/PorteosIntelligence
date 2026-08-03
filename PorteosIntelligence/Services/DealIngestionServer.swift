import Foundation
import Network
import SwiftData

// MARK: - HTTP primitives

private struct HTTPRequest {
    let method:  String
    let path:    String
    let headers: [String: String]
    let body:    Data

    /// Number of bytes the sender declared it will send.
    var declaredBodyLength: Int { Int(headers["content-length"] ?? "0") ?? 0 }

    /// True once we have accumulated all body bytes.
    var isComplete: Bool { body.count >= declaredBodyLength }

    /// Parse raw TCP bytes into an `HTTPRequest`.  Returns `nil` if headers are
    /// incomplete; partial body is accepted (caller checks `isComplete`).
    static func parse(_ data: Data) -> HTTPRequest? {
        let sep = Data([0x0D, 0x0A, 0x0D, 0x0A]) // \r\n\r\n
        guard let sepRange = data.range(of: sep) else { return nil }

        let headerData = data[..<sepRange.lowerBound]
        let bodyData   = data[sepRange.upperBound...]

        guard let headerString = String(data: headerData, encoding: .utf8) else { return nil }

        let lines = headerString.components(separatedBy: "\r\n")
        guard let requestLine = lines.first else { return nil }

        let parts = requestLine.components(separatedBy: " ")
        guard parts.count >= 2 else { return nil }

        var headers: [String: String] = [:]
        for line in lines.dropFirst() {
            guard let idx = line.firstIndex(of: ":") else { continue }
            let key = String(line[..<idx]).trimmingCharacters(in: .whitespaces).lowercased()
            let val = String(line[line.index(after: idx)...]).trimmingCharacters(in: .whitespaces)
            headers[key] = val
        }

        return HTTPRequest(method: parts[0], path: parts[1],
                           headers: headers, body: Data(bodyData))
    }
}

private struct HTTPResponse {
    let status:  Int
    let headers: [String: String]
    let body:    Data

    private static func statusText(_ code: Int) -> String {
        switch code {
        case 200: return "OK"
        case 204: return "No Content"
        case 400: return "Bad Request"
        case 404: return "Not Found"
        case 503: return "Service Unavailable"
        default:  return "Error"
        }
    }

    var wireData: Data {
        var head = "HTTP/1.1 \(status) \(Self.statusText(status))\r\n"
        for (k, v) in headers { head += "\(k): \(v)\r\n" }
        head += "Content-Length: \(body.count)\r\n"
        head += "Connection: close\r\n"
        head += "\r\n"
        var d = head.data(using: .utf8)!
        d.append(body)
        return d
    }

    // MARK: Factory helpers

    static let corsHeaders: [String: String] = [
        "Access-Control-Allow-Origin":  "*",
        "Access-Control-Allow-Methods": "POST, GET, OPTIONS",
        "Access-Control-Allow-Headers": "Content-Type, X-Source",
        "Access-Control-Max-Age":       "86400",
    ]

    static func json(_ dict: [String: Any], status: Int = 200) -> HTTPResponse {
        let body = (try? JSONSerialization.data(withJSONObject: dict)) ?? Data()
        var h = corsHeaders
        h["Content-Type"] = "application/json"
        return HTTPResponse(status: status, headers: h, body: body)
    }

    static var corsPreflight: HTTPResponse {
        HTTPResponse(status: 204, headers: corsHeaders, body: Data())
    }

    static func error(_ msg: String, status: Int = 400) -> HTTPResponse {
        json(["success": false, "error": msg], status: status)
    }

    static func notFound(_ path: String) -> HTTPResponse {
        error("Endpoint not found: \(path)", status: 404)
    }
}

// MARK: - Ingestion payload

struct DealIngestionPayload: Decodable {
    var source:             String?
    var url:                String?
    var propertyName:       String?
    var locationCity:       String?
    var locationCountry:    String?
    var purchasePrice:      Double?
    var totalArea:          Double?
    var landArea:           Double?
    var propertyType:       String?
    var bedrooms:           Int?
    var bathrooms:          Int?
    var listingDescription: String?
    var images:             [String]?
    var listingDate:        String?

    enum CodingKeys: String, CodingKey {
        case source, url, propertyName, locationCity, locationCountry,
             purchasePrice, totalArea, landArea, propertyType,
             bedrooms, bathrooms,
             listingDescription = "description",
             images, listingDate
    }
}

// MARK: - IngestLog

struct IngestLog: Identifiable {
    let id          = UUID()
    let timestamp:  Date
    let method:     String
    let path:       String
    let statusCode: Int
    let source:     String
    let dealName:   String
    let dealID:     UUID?
}

// MARK: - DealIngestionServer

@Observable @MainActor
final class DealIngestionServer {

    static let shared = DealIngestionServer()
    private init() {}

    // MARK: Observed state

    var isRunning      = false
    var port: UInt16   = 9000
    var requestCount   = 0
    var lastRequest:   Date?
    var errorMessage:  String?
    var recentLogs:    [IngestLog] = []   // capped at 50

    // MARK: Private

    private var listener:       NWListener?
    private var serverQueue =   DispatchQueue(label: "com.porteos.ingestion", qos: .userInitiated)
    private var modelContainer: ModelContainer?

    // MARK: Container injection

    func injectContainer(_ container: ModelContainer) {
        modelContainer = container
    }

    // MARK: Lifecycle

    func start(on port: UInt16? = nil) {
        if let p = port { self.port = p }
        stop()

        do {
            let params       = NWParameters.tcp
            params.allowLocalEndpointReuse = true
            let nwPort       = NWEndpoint.Port(rawValue: self.port)!
            listener         = try NWListener(using: params, on: nwPort)
        } catch {
            errorMessage = "Failed to create listener: \(error.localizedDescription)"
            return
        }

        listener?.stateUpdateHandler = { [weak self] state in
            Task { @MainActor [weak self] in
                switch state {
                case .ready:
                    self?.isRunning     = true
                    self?.errorMessage  = nil
                case .failed(let err):
                    self?.isRunning     = false
                    self?.errorMessage  = err.localizedDescription
                case .cancelled:
                    self?.isRunning     = false
                default:
                    break
                }
            }
        }

        listener?.newConnectionHandler = { [weak self] conn in
            // Security: reject any connection not originating from loopback
            let remoteHost: String
            switch conn.endpoint {
            case .hostPort(let host, _):
                remoteHost = "\(host)"
            default:
                remoteHost = ""
            }
            guard remoteHost == "127.0.0.1" || remoteHost == "::1"
                  || remoteHost.isEmpty       // unix domain / unknown = allow
            else {
                conn.cancel()
                return
            }
            Task { @MainActor [weak self] in
                self?.handleNewConnection(conn)
            }
        }

        listener?.start(queue: serverQueue)
    }

    func stop() {
        listener?.cancel()
        listener   = nil
        isRunning  = false
    }

    func restart() {
        stop()
        // Brief yield so NWListener releases the port before re-binding
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 150_000_000)   // 150 ms
            start()
        }
    }

    // MARK: Connection handling

    private func handleNewConnection(_ conn: NWConnection) {
        conn.start(queue: serverQueue)
        receiveRequest(conn: conn, buffer: Data())
    }

    /// Accumulates TCP bytes until we have a complete HTTP request, then dispatches.
    private func receiveRequest(conn: NWConnection, buffer: Data) {
        conn.receive(minimumIncompleteLength: 1, maximumLength: 65_536) { [weak self] data, _, isDone, error in
            guard let self else { return }

            var accumulated = buffer
            if let data { accumulated.append(data) }

            // Try to parse; if headers are incomplete keep accumulating
            guard let request = HTTPRequest.parse(accumulated) else {
                if !isDone && error == nil {
                    let nextBuffer = accumulated
                    Task { @MainActor [weak self] in
                        self?.receiveRequest(conn: conn, buffer: nextBuffer)
                    }
                } else {
                    conn.cancel()
                }
                return
            }

            // If body is still arriving, accumulate more
            if !request.isComplete && !isDone && error == nil {
                let nextBuffer = accumulated
                Task { @MainActor [weak self] in
                    self?.receiveRequest(conn: conn, buffer: nextBuffer)
                }
                return
            }

            Task { @MainActor [weak self] in
                self?.processRequest(request, conn: conn)
            }
        }
    }

    // MARK: UserDefaults preferences

    var autoStartEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "serverAutoStartEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "serverAutoStartEnabled") }
    }

    private var configuredAPIKey: String {
        UserDefaults.standard.string(forKey: "serverAPIKey") ?? ""
    }

    // MARK: Request routing

    private func processRequest(_ req: HTTPRequest, conn: NWConnection) {

        consoleLog(req)

        // CORS pre-flight — always allowed, no auth check
        if req.method == "OPTIONS" {
            send(.corsPreflight, to: conn)
            appendLog(method: req.method, path: req.path, status: 204,
                      source: "cors", name: "preflight", dealID: nil)
            return
        }

        // Health endpoint — always allowed, no auth check
        if req.method == "GET" && (req.path == "/api/health" || req.path == "/health") {
            let body: [String: Any] = [
                "status":       "ok",
                "version":      "1.0",
                "app":          "Porteos Intelligence",
                "port":         Int(port),
                "requestCount": requestCount,
            ]
            send(.json(body), to: conn)
            appendLog(method: req.method, path: req.path, status: 200,
                      source: "system", name: "health", dealID: nil)
            return
        }

        // Optional API-key check for authenticated endpoints
        let key = configuredAPIKey
        if !key.isEmpty {
            let provided = req.headers["x-porteos-key"] ?? ""
            if provided != key {
                send(.error("Unauthorized — invalid or missing X-Porteos-Key header", status: 401), to: conn)
                consoleLog(req, status: 401, note: "auth_failed")
                appendLog(method: req.method, path: req.path, status: 401,
                          source: "auth", name: "rejected", dealID: nil)
                return
            }
        }

        // Deal ingestion
        if req.method == "POST" && req.path == "/api/deals" {
            handleDealIngestion(req, conn: conn)
            return
        }

        // Unknown endpoint
        send(.notFound(req.path), to: conn)
        consoleLog(req, status: 404, note: "not_found")
        appendLog(method: req.method, path: req.path, status: 404,
                  source: "unknown", name: req.path, dealID: nil)
    }

    // MARK: Deal ingestion

    /// Dedup fallback for imports with no URL — matches on normalised name+city.
    /// Only triggers when both name and city are non-empty (avoids false positives).
    private func findExistingDeal(byName name: String, city: String, context: ModelContext) -> PropertyDeal? {
        let trimName = name.trimmingCharacters(in: .whitespaces).lowercased()
        let trimCity = city.trimmingCharacters(in: .whitespaces).lowercased()
        guard trimName.count > 3, trimCity.count > 1 else { return nil }
        guard let deals = try? context.fetch(FetchDescriptor<PropertyDeal>()) else { return nil }
        return deals.first { deal in
            deal.propertyName.lowercased() == trimName &&
            deal.locationCity.lowercased() == trimCity
        }
    }

    private func findExistingDeal(forURL url: String, context: ModelContext) -> PropertyDeal? {
        let normalized = ListingURLHelpers.normalize(url)

        if let records = try? context.fetch(
            FetchDescriptor<EmailImportRecord>(
                predicate: #Predicate { $0.listingURL == normalized }
            )
        ), let record = records.first, let dealID = record.dealID {
            let deals = try? context.fetch(
                FetchDescriptor<PropertyDeal>(
                    predicate: #Predicate { $0.id == dealID }
                )
            )
            if let deal = deals?.first { return deal }
        }

        let urlCopy = url
        if let dupes = try? context.fetch(
            FetchDescriptor<PropertyDeal>(
                predicate: #Predicate { $0.notes.contains(urlCopy) }
            )
        ), let first = dupes.first {
            return first
        }

        return nil
    }

    private func handleDealIngestion(_ req: HTTPRequest, conn: NWConnection) {
        guard let container = modelContainer else {
            send(.error("Server not ready — data container unavailable", status: 503), to: conn)
            consoleLog(req, status: 503, note: "no_container")
            appendLog(method: "POST", path: "/api/deals", status: 503,
                      source: "error", name: "no container", dealID: nil)
            return
        }

        guard !req.body.isEmpty,
              let payload = try? JSONDecoder().decode(DealIngestionPayload.self, from: req.body) else {
            send(.error("Invalid or missing JSON payload"), to: conn)
            consoleLog(req, status: 400, note: "bad_json")
            appendLog(method: "POST", path: "/api/deals", status: 400,
                      source: "error", name: "parse error", dealID: nil)
            return
        }

        let ctx  = ModelContext(container)
        // Infer city from available text if the scraper didn't capture it
        let city = (payload.locationCity ?? "").trimmingCharacters(in: .whitespaces).isEmpty
            ? DealIngestionServer.inferCity(
                name:    payload.propertyName    ?? "",
                address: "",
                country: payload.locationCountry ?? "",
                url:     payload.url             ?? "")
            : payload.locationCity ?? ""

        // ── Dedup: URL match (primary) or name+city hash (fallback for no-URL imports) ─
        let duplicateByURL: PropertyDeal? = {
            guard let url = payload.url, !url.isEmpty else { return nil }
            return findExistingDeal(forURL: url, context: ctx)
        }()
        let duplicateByNameCity: PropertyDeal? = duplicateByURL == nil
            ? findExistingDeal(
                byName: payload.propertyName ?? "",
                city:   city,
                context: ctx)
            : nil
        let duplicateExisting = duplicateByURL ?? duplicateByNameCity

        if let existing = duplicateExisting {
            let reply: [String: Any] = [
                "success":   true,
                "dealID":    existing.id.uuidString,
                "message":   "Deal already exists (deduplicated)",
                "duplicate": true,
            ]
            send(.json(reply), to: conn)
            consoleLog(req, status: 200, note: "duplicate")
            appendLog(method: "POST", path: "/api/deals", status: 200,
                      source: payload.source ?? "unknown",
                      name: payload.propertyName ?? "duplicate",
                      dealID: existing.id)
            ToastManager.shared.show(IngestionToastData(
                dealID:       existing.id,
                propertyName: payload.propertyName ?? "Duplicate Deal",
                location:     city,
                price:        payload.purchasePrice ?? 0,
                source:       payload.source ?? "browser_extension",
                isDuplicate:  true
            ))
            return
        }

        // ── Market benchmarks (reuse Data/MarketBenchmarks.swift) ────────────
        let bm           = city.isEmpty ? nil : MarketBenchmarks.benchmark(for: city)
        let area         = payload.totalArea     ?? 0
        let price        = payload.purchasePrice ?? 0

        let gpi: Double = {
            if let b = bm, area > 0  { return area  * b.avgGPIPerSqm }
            if let b = bm, price > 0 { return price * (b.avgCapRate / 100.0) }
            if area  > 0             { return area  * 12.0 * 12.0 }   // €12/m²/month fallback
            return price * 0.04
        }()
        let vacancyRate  = bm?.avgVacancyRate ?? 5.0
        let opex: Double = {
            if let b = bm, area > 0  { return area * b.avgOpExPerSqm }
            return gpi * 0.30
        }()

        // ── Notes ─────────────────────────────────────────────────────────────
        var noteLines: [String] = []
        noteLines.append("Source: BROWSER_EXTENSION")
        if let src = payload.source     { noteLines.append("Platform: \(src.uppercased())") }
        if let url = payload.url        { noteLines.append("URL: \(url)") }
        if let country = payload.locationCountry { noteLines.append("Country: \(country)") }
        if let baths = payload.bathrooms { noteLines.append("Bathrooms: \(baths)") }
        if let date  = payload.listingDate { noteLines.append("Listed: \(date)") }
        if let b = bm {
            noteLines.append("\nMarket: \(b.cityName) avg cap rate \(b.avgCapRate)% · vacancy \(b.avgVacancyRate)%")
        }
        if let desc = payload.listingDescription, !desc.isEmpty { noteLines.append("\n\(desc)") }
        if let imgs = payload.images, !imgs.isEmpty {
            noteLines.append("Images: \(imgs.prefix(3).joined(separator: " | "))")
        }

        // ── Tags ──────────────────────────────────────────────────────────────
        var tags: [String] = ["browser_import", "source:browser_extension"]
        if let src = payload.source { tags.append("source:\(src)") }
        if payload.url != nil       { tags.append("has_url") }
        if bm != nil                { tags.append("benchmarked") }

        // ── Create PropertyDeal ────────────────────────────────────────────────
        let deal = PropertyDeal(
            propertyName:         payload.propertyName  ?? "Browser Import",
            propertyType:         payload.propertyType  ?? "Apartment",
            totalArea:            area,
            landArea:             payload.landArea       ?? 0,
            locationCity:         city,
            locationCountry:      payload.locationCountry ?? "",
            purchasePrice:        price,
            grossPotentialIncome: gpi,
            vacancyRate:          vacancyRate,
            operatingExpenses:    opex,
            notes:                noteLines.joined(separator: "\n"),
            tags:                 tags,
            status:               .pipeline
        )
        ctx.insert(deal)

        // Auto-fill remaining zero fields from benchmark + compute initial score
        DealPreloader.applyToNewDeal(deal)

        if let url = payload.url, !url.isEmpty {
            let record = EmailImportRecord(
                listingURL: ListingURLHelpers.normalize(url),
                source:     payload.source ?? "browser_extension",
                rawSubject: payload.propertyName ?? deal.propertyName,
                dealID:     deal.id
            )
            ctx.insert(record)
        }

        do {
            try ctx.save()
        } catch {
            send(.error("Failed to save deal: \(error.localizedDescription)", status: 503), to: conn)
            consoleLog(req, status: 503, note: "save_failed")
            return
        }

        Task { @MainActor in
            await GeocodingService.shared.geocode(deal: deal, context: ctx)
        }

        // Record metrics into the trend time-series for this city
        TrendRecorder.record(deal, context: ctx, source: "import")

        // ── Response ──────────────────────────────────────────────────────────
        let benchmarkNote = bm.map { " (\($0.cityName) benchmark applied)" } ?? ""
        let reply: [String: Any] = [
            "success": true,
            "dealID":  deal.id.uuidString,
            "message": "Deal imported successfully\(benchmarkNote)",
        ]
        send(.json(reply), to: conn)

        requestCount += 1
        lastRequest   = Date()
        consoleLog(req, status: 200, note: "deal:\(deal.id.uuidString.prefix(8))")
        appendLog(method: "POST", path: "/api/deals", status: 200,
                  source: payload.source ?? "browser_extension",
                  name: deal.propertyName,
                  dealID: deal.id)

        // ── Toast notification ────────────────────────────────────────────────
        ToastManager.shared.show(IngestionToastData(
            dealID:       deal.id,
            propertyName: deal.propertyName,
            location:     city,
            price:        price,
            source:       payload.source ?? "browser_extension",
            isDuplicate:  false
        ))

        // ── Navigate to deal + trigger AI analysis ────────────────────────────
        NotificationCenter.default.post(
            name: .serverDidIngestDeal,
            object: nil,
            userInfo: ["dealID": deal.id]
        )
    }

    // MARK: Console logging

    private let isoFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    private func consoleLog(_ req: HTTPRequest, status: Int = 0, note: String = "") {
        let ts    = isoFormatter.string(from: Date())
        let stat  = status > 0 ? " \(status)" : ""
        let extra = note.isEmpty ? "" : " [\(note)]"
        print("[PORTEOS_SERVER] \(ts) \(req.method) \(req.path)\(stat)\(extra)")
    }

    // MARK: Send response

    private func send(_ response: HTTPResponse, to conn: NWConnection) {
        let data = response.wireData
        conn.send(content: data, completion: .contentProcessed { _ in
            conn.cancel()
        })
    }

    // MARK: Log helper

    private func appendLog(method: String, path: String, status: Int,
                           source: String, name: String, dealID: UUID?) {
        let entry = IngestLog(timestamp: Date(), method: method, path: path,
                              statusCode: status, source: source, dealName: name,
                              dealID: dealID)
        recentLogs.insert(entry, at: 0)
        if recentLogs.count > 50 { recentLogs = Array(recentLogs.prefix(50)) }
    }
}

// MARK: - City inference

extension DealIngestionServer {

    /// Tries to extract a city name from available import metadata.
    /// Returns empty string if inference fails — callers should treat "" as "unknown".
    static func inferCity(name: String, address: String, country: String, url: String) -> String {
        let candidates = [name, address, url]

        // 1. "in Porto", "em Lisboa", "en Madrid" pattern in property name or address
        let locPatterns = [
            #"\bin\s+([A-ZÀ-Ú][a-zA-ZÀ-ú\-]{2,}(?:\s[A-ZÀ-Ú][a-zA-ZÀ-ú\-]+)?)"#,
            #"\bem\s+([A-ZÀ-Ú][a-zA-ZÀ-ú\-]{2,}(?:\s[A-ZÀ-Ú][a-zA-ZÀ-ú\-]+)?)"#,
            #"\ben\s+([A-ZÀ-Ú][a-zA-ZÀ-ú\-]{2,}(?:\s[A-ZÀ-Ú][a-zA-ZÀ-ú\-]+)?)"#,
        ]
        for source in [name, address] {
            for pattern in locPatterns {
                if let re = try? NSRegularExpression(pattern: pattern),
                   let m  = re.firstMatch(in: source, range: NSRange(source.startIndex..., in: source)),
                   let r  = Range(m.range(at: 1), in: source) {
                    let city = String(source[r]).trimmingCharacters(in: .whitespaces)
                    // Accept if city is in benchmark database OR in registry aliases
                    if MarketBenchmarks.benchmark(for: city) != nil { return city }
                    if MarketFeedRegistry.resolveMarketId(city: city) != nil { return city }
                }
            }
        }

        // 2. URL slug: "venda-predio-t10-porto-bonfim" → segment after T-type
        if !url.isEmpty {
            let parts = url.components(separatedBy: "/")
            if let slug = parts.first(where: { $0.hasPrefix("venda-") || $0.hasPrefix("arrendar-") }) {
                let segs = slug.components(separatedBy: "-")
                if let txIdx = segs.firstIndex(where: { $0.range(of: #"^t\d+$"#, options: .regularExpression) != nil }),
                   txIdx + 1 < segs.count {
                    let raw = segs[txIdx + 1].prefix(1).uppercased() + segs[txIdx + 1].dropFirst()
                    if MarketBenchmarks.benchmark(for: String(raw)) != nil { return String(raw) }
                }
            }
        }

        // 3. Last comma-separated segment of address ("Rua X, Porto" → "Porto")
        if !address.isEmpty {
            let segments = address.components(separatedBy: ",")
            if let last = segments.last?.trimmingCharacters(in: .whitespaces), last.count > 2 {
                if MarketBenchmarks.benchmark(for: last) != nil { return last }
            }
        }

        // 4. Country fallback — returns the national capital so benchmarks degrade gracefully
        switch country.lowercased() {
        case "portugal":       return "Lisbon"
        case "spain":          return "Madrid"
        case "italy":          return "Rome"
        case "france":         return "Paris"
        case "united kingdom": return "London"
        case "usa", "united states": return "New York"
        case "sweden":         return "Stockholm"
        case "japan":          return "Tokyo"
        default:               return ""
        }
    }
}

// MARK: - Notification name

extension Notification.Name {
    static let serverDidIngestDeal = Notification.Name("porteos.serverDidIngestDeal")
    static let autoTriggerAI       = Notification.Name("porteos.autoTriggerAI")
}
