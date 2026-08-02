import Foundation
import CoreLocation

// MARK: - MarketFeedRegistry
// Static news + geography registry for Global Intelligence (Profile 6).
//
// ID convention: `{COUNTRY}-{METRO}` — e.g. UK-LON, US-NYC, US-LA, PT-ALG
// Country nodes use ISO-style 2-letter ids (PT, UK, US). Metros inherit parent RSS.
//
// Investment focus: below-market / value-add — quintas (PT), €1 houses (IT),
// akiya (JP), distressed US metros, Mediterranean conversion, Nordic yield.

// MARK: - Models

struct MarketDefinition: Identifiable, Sendable {
    let id: String
    let displayName: String
    let countryCode: String     // ISO 3166-1 alpha-2
    let parentId: String?
    let mapCenter: CLLocationCoordinate2D
    let mapSpanDelta: Double
    let investmentThesis: String
    let rssFeeds: [String]
    let cityAliases: [String]
}

enum IntelSector: String, CaseIterable, Identifiable, Sendable {
    case realEstate = "REAL_ESTATE"
    case hospitality = "HOSPITALITY"
    case research    = "RESEARCH"
    case community   = "COMMUNITY"
    case tech        = "TECH"
    case travel      = "TRAVEL"
    case trends      = "TRENDS"
    case energy      = "ENERGY"
    case capMarkets  = "CAP_MARKETS"
    case adjacent    = "ADJACENT"

    var id: String { rawValue }

    /// Compact chip label in the news feed filter bar.
    var chipLabel: String {
        switch self {
        case .realEstate: return "RE"
        case .hospitality: return "HOSP"
        case .research:    return "R&D"
        case .community:   return "COMM"
        case .tech:        return "TECH"
        case .travel:      return "TRAVEL"
        case .trends:      return "TRENDS"
        case .energy:      return "ENERGY"
        case .capMarkets:  return "CAP"
        case .adjacent:    return "ADJ"
        }
    }

    /// Expanded label shown on article rows.
    var displayName: String {
        switch self {
        case .realEstate: return "REAL ESTATE"
        case .hospitality: return "HOSPITALITY"
        case .research:    return "RESEARCH"
        case .community:   return "COMMUNITY"
        case .tech:        return "TECH"
        case .travel:      return "TRAVEL"
        case .trends:      return "TRENDS"
        case .energy:      return "ENERGY"
        case .capMarkets:  return "CAP MARKETS"
        case .adjacent:    return "ADJACENT"
        }
    }

    var keywords: [String] {
        switch self {
        case .realEstate:
            return [
                "real estate", "property", "housing", "commercial property", "residential",
                "office", "retail", "industrial", "warehouse", "logistics", "cre",
                "landlord", "tenant", "lease", "leasing", "rental", "rent", "apartment",
                "multifamily", "development", "zoning", "planning permission", "planning",
                "imobiliário", "imobiliario", "habitação", "habitacao", "condominio",
                "build-to-rent", "btr", "pbsa", "student housing", "senior living",
                "life sciences", "data center", "affordable housing", "social housing",
            ]
        case .hospitality:
            return [
                "hospitality", "hotel", "resort", "lodging", "boutique hotel", "hostel",
                "adr", "revpar", "occupancy", "food and beverage", "f&b", "restaurant",
                "spa", "wellness", "conference", "banquet", "minpaku", "agriturismo",
                "ecotourism", "boutique stay", "short-term rental", "airbnb",
            ]
        case .research:
            return [
                "research", "report", "study", "survey", "analysis", "white paper",
                "market report", "outlook report", "sector note", "insight",
                "cbre", "jll", "knight frank", "savills", "cushman", "colliers",
                "msci", "green street", "data release", "benchmark",
            ]
        case .community:
            return [
                "community", "neighbourhood", "neighborhood", "local", "residents",
                "civic", "co-living", "cohousing", "cooperative", "tenant union",
                "nimby", "public consultation", "urban regeneration", "placemaking",
                "social impact", "affordable", "mixed-income",
            ]
        case .tech:
            return [
                "proptech", "property technology", "technology", "artificial intelligence",
                " ai ", "machine learning", "startup", "smart building", "smart city",
                "iot", "software", "platform", "digital twin", "automation",
                "construction tech", "contech", "fintech", "blockchain",
            ]
        case .travel:
            return [
                "travel", "tourism", "tourist", "destination", "visitor", "visa",
                "schengen", "airline", "aviation", "cruise", "border", "arrivals",
                "turismo", "ecotourism", "heritage tourism", "city break",
            ]
        case .trends:
            return [
                "trend", "trends", "outlook", "forecast", "projection", "emerging",
                "shift", "transformation", "macro", "sentiment", "inflection",
                "structural", "secular", "headwind", "tailwind", "cycle",
            ]
        case .energy:
            return [
                "energy", "solar", "renewable", "renewables", "grid", "electricity",
                "gas", "power", "esg", "net zero", "net-zero", "carbon", "decarbon",
                "heat pump", "hvac", "green building", "leed", "breeam", "operational carbon",
                "embodied carbon", "ppa", "battery storage",
            ]
        case .capMarkets:
            return [
                "capital markets", "cap markets", "bond", "bonds", "equity", "reit",
                "ipo", "spread", "liquidity", "financing", "debt", "sovereign",
                "yield curve", "ecb", "fed", "federal reserve", "mortgage", "interest rate",
                "base rate", "bps", "credit", "lending", "refinance", "refinancing",
                "cmb", "cmbs", "syndicated loan", "prime yield", "cap rate",
            ]
        case .adjacent:
            return [
                "construction", "infrastructure", "supply chain", "urban", "mobility",
                "coworking", "flex office", "logistics hub", "port", "rail",
                "demographics", "migration", "population", "inflation", "gdp",
                "insurance", "reinsurance", "climate risk", "flood risk",
                "materials cost", "labour", "labor shortage", "permitting",
            ]
        }
    }

    /// Match order — more specific sectors before broad catch-alls.
    static let classificationOrder: [IntelSector] = [
        .capMarkets, .hospitality, .realEstate, .energy, .tech, .travel,
        .research, .community, .trends, .adjacent,
    ]
}

// Legacy alias — topics are now portfolio intelligence sectors.
typealias IntelTopic = IntelSector

// MARK: - Registry

struct MarketFeedRegistry {

    // MARK: Countries — national scope only (metros hold city aliases)

    static let countries: [MarketDefinition] = [
        .init(id: "PT", displayName: "Portugal", countryCode: "PT", parentId: nil,
              mapCenter: .init(latitude: 39.4, longitude: -8.2), mapSpanDelta: 6.0,
              investmentThesis: "Quintas, relic farmhouses, ecotourism conversions, below-market rural stock.",
              rssFeeds: [
                  // PT-specific business/economy — market-relevant, not global noise
                  "https://www.jornaldenegocios.pt/rss",
                  "https://www.publico.pt/rss/economia",
                  // ECB press for EU monetary policy (interest rate signals)
                  "https://www.ecb.europa.eu/rss/press.html",
                  // Euronews removed — too global, contaminates PT market with
                  // unrelated content (OPEC, Tesla, global politics) tagged as PT
              ],
              cityAliases: ["portugal"]),
        .init(id: "ES", displayName: "Spain", countryCode: "ES", parentId: nil,
              mapCenter: .init(latitude: 40.0, longitude: -3.5), mapSpanDelta: 6.0,
              investmentThesis: "Coastal value-add, pueblo renovation, tourism conversion.",
              rssFeeds: ["https://feeds.elpais.com/mrss-s/pages/ep/site/elpais.com/section/economia/portada"],
              cityAliases: ["spain", "españa"]),
        .init(id: "IT", displayName: "Italy", countryCode: "IT", parentId: nil,
              mapCenter: .init(latitude: 42.5, longitude: 12.5), mapSpanDelta: 6.0,
              investmentThesis: "€1-house towns, cheap rural casali, agriturismo conversions.",
              rssFeeds: ["https://www.repubblica.it/rss/economia/rss2.0.xml"],
              cityAliases: ["italy", "italia"]),
        .init(id: "FR", displayName: "France", countryCode: "FR", parentId: nil,
              mapCenter: .init(latitude: 46.5, longitude: 2.5), mapSpanDelta: 6.0,
              investmentThesis: "Maison de village, chambres d'hôtes, renovation outside Paris.",
              rssFeeds: ["https://www.lemonde.fr/economie/rss_full.xml"],
              cityAliases: ["france"]),
        .init(id: "UK", displayName: "United Kingdom", countryCode: "GB", parentId: nil,
              mapCenter: .init(latitude: 54.0, longitude: -2.5), mapSpanDelta: 5.0,
              investmentThesis: "Distressed commercial, regional residential yield, conversions.",
              rssFeeds: ["https://feeds.bbci.co.uk/news/business/rss.xml"],
              cityAliases: ["uk", "united kingdom", "england", "scotland", "wales", "britain"]),
        .init(id: "HR", displayName: "Croatia", countryCode: "HR", parentId: nil,
              mapCenter: .init(latitude: 45.1, longitude: 15.2), mapSpanDelta: 3.5,
              investmentThesis: "Adriatic coast value-add, stone houses, tourism rental conversion.",
              rssFeeds: [],
              cityAliases: ["croatia", "hrvatska"]),
        .init(id: "GR", displayName: "Greece", countryCode: "GR", parentId: nil,
              mapCenter: .init(latitude: 39.0, longitude: 22.0), mapSpanDelta: 4.5,
              investmentThesis: "Island and mainland rural stock, golden-visa renovation plays.",
              rssFeeds: [],
              cityAliases: ["greece", "ellada"]),
        .init(id: "SE", displayName: "Sweden", countryCode: "SE", parentId: nil,
              mapCenter: .init(latitude: 62.0, longitude: 15.0), mapSpanDelta: 8.0,
              investmentThesis: "Stockholm yield spread, secondary-city residential, conversion stock.",
              rssFeeds: ["https://www.di.se/rss"],
              cityAliases: ["sweden", "sverige"]),
        .init(id: "DK", displayName: "Denmark", countryCode: "DK", parentId: nil,
              mapCenter: .init(latitude: 56.0, longitude: 10.0), mapSpanDelta: 3.5,
              investmentThesis: "Copenhagen metro yield, regional renovation, coast tourism.",
              rssFeeds: [],
              cityAliases: ["denmark", "danmark"]),
        .init(id: "NO", displayName: "Norway", countryCode: "NO", parentId: nil,
              mapCenter: .init(latitude: 64.0, longitude: 12.0), mapSpanDelta: 8.0,
              investmentThesis: "Oslo commercial, fjord tourism conversion.",
              rssFeeds: [],
              cityAliases: ["norway", "norge"]),
        .init(id: "FI", displayName: "Finland", countryCode: "FI", parentId: nil,
              mapCenter: .init(latitude: 64.0, longitude: 26.0), mapSpanDelta: 7.0,
              investmentThesis: "Helsinki residential yield, lake cabin renovation.",
              rssFeeds: [],
              cityAliases: ["finland", "suomi"]),
        .init(id: "US", displayName: "United States", countryCode: "US", parentId: nil,
              mapCenter: .init(latitude: 39.0, longitude: -98.0), mapSpanDelta: 25.0,
              investmentThesis: "National macro — rates, distressed supply, Sun Belt migration.",
              rssFeeds: ["https://feeds.a.dj.com/rss/RSSMarketsMain.xml"],
              cityAliases: ["usa", "united states", "america"]),
        .init(id: "JP", displayName: "Japan", countryCode: "JP", parentId: nil,
              mapCenter: .init(latitude: 36.2, longitude: 138.25), mapSpanDelta: 8.0,
              investmentThesis: "Akiya vacant homes, rural minpaku, cheap stock outside Tokyo.",
              rssFeeds: ["https://www.japantimes.co.jp/feed/topstories.rss"],
              cityAliases: ["japan", "nihon"]),
    ]

    // MARK: Metros — `{CC}-{CODE}` pattern

    static let metros: [MarketDefinition] = [
        // Portugal
        .init(id: "PT-LIS", displayName: "Lisbon", countryCode: "PT", parentId: "PT",
              mapCenter: .init(latitude: 38.72, longitude: -9.14), mapSpanDelta: 0.8,
              investmentThesis: "Urban rehab, short-term rental conversion, office-to-resi.",
              rssFeeds: [], cityAliases: ["lisbon", "lisboa", "cascais", "sintra"]),
        .init(id: "PT-OPO", displayName: "Porto", countryCode: "PT", parentId: "PT",
              mapCenter: .init(latitude: 41.15, longitude: -8.61), mapSpanDelta: 0.7,
              investmentThesis: "Historic centre renovation, tourism rental, Douro adjacency.",
              rssFeeds: [], cityAliases: ["porto", "oporto", "gaia"]),
        .init(id: "PT-ALG", displayName: "Algarve", countryCode: "PT", parentId: "PT",
              mapCenter: .init(latitude: 37.1, longitude: -8.0), mapSpanDelta: 1.2,
              investmentThesis: "Quinta ecotourism, villa conversion, below-market rural stock.",
              rssFeeds: [], cityAliases: ["faro", "luz", "lagos", "albufeira", "algarve", "tavira"]),

        // Spain
        .init(id: "ES-MAD", displayName: "Madrid", countryCode: "ES", parentId: "ES",
              mapCenter: .init(latitude: 40.42, longitude: -3.70), mapSpanDelta: 0.9,
              investmentThesis: "Value-add residential, commercial repositioning.",
              rssFeeds: [], cityAliases: ["madrid"]),
        .init(id: "ES-BCN", displayName: "Barcelona", countryCode: "ES", parentId: "ES",
              mapCenter: .init(latitude: 41.39, longitude: 2.17), mapSpanDelta: 0.8,
              investmentThesis: "Tourism rental regulation plays, Eixample rehab.",
              rssFeeds: [], cityAliases: ["barcelona", "catalonia", "cataluña"]),
        .init(id: "ES-VAL", displayName: "Valencia", countryCode: "ES", parentId: "ES",
              mapCenter: .init(latitude: 39.47, longitude: -0.38), mapSpanDelta: 0.9,
              investmentThesis: "Coastal pueblo stock, secondary-city yield.",
              rssFeeds: [], cityAliases: ["valencia", "malaga", "seville", "sevilla"]),

        // Italy
        .init(id: "IT-ROM", displayName: "Rome", countryCode: "IT", parentId: "IT",
              mapCenter: .init(latitude: 41.90, longitude: 12.50), mapSpanDelta: 0.9,
              investmentThesis: "Peripheral rehab, commercial conversion.",
              rssFeeds: [], cityAliases: ["rome", "roma"]),
        .init(id: "IT-MIL", displayName: "Milan", countryCode: "IT", parentId: "IT",
              mapCenter: .init(latitude: 45.46, longitude: 9.19), mapSpanDelta: 0.8,
              investmentThesis: "Office-resi conversion, northern yield.",
              rssFeeds: [], cityAliases: ["milan", "milano"]),
        .init(id: "IT-RUR", displayName: "Rural Italy", countryCode: "IT", parentId: "IT",
              mapCenter: .init(latitude: 43.0, longitude: 12.0), mapSpanDelta: 3.0,
              investmentThesis: "€1-house municipalities, casali, agriturismo.",
              rssFeeds: [], cityAliases: ["sicily", "sicilia", "tuscany", "toscana", "umbria", "puglia", "abruzzo"]),

        // France
        .init(id: "FR-PAR", displayName: "Paris", countryCode: "FR", parentId: "FR",
              mapCenter: .init(latitude: 48.86, longitude: 2.35), mapSpanDelta: 0.7,
              investmentThesis: "Peripheral arrondissement value-add, commercial conversion.",
              rssFeeds: [], cityAliases: ["paris", "île-de-france", "ile-de-france"]),
        .init(id: "FR-RUR", displayName: "Rural France", countryCode: "FR", parentId: "FR",
              mapCenter: .init(latitude: 46.0, longitude: 2.0), mapSpanDelta: 4.0,
              investmentThesis: "Maison de village, gîte and chambres d'hôtes conversion.",
              rssFeeds: [], cityAliases: ["lyon", "marseille", "bordeaux", "nice", "dordogne", "provence"]),

        // United Kingdom
        .init(id: "UK-LON", displayName: "London", countryCode: "GB", parentId: "UK",
              mapCenter: .init(latitude: 51.51, longitude: -0.13), mapSpanDelta: 0.8,
              investmentThesis: "Distressed commercial, outer-borough residential value-add.",
              rssFeeds: [], cityAliases: ["london", "greater london", "croydon", "hackney"]),
        .init(id: "UK-MAN", displayName: "Manchester", countryCode: "GB", parentId: "UK",
              mapCenter: .init(latitude: 53.48, longitude: -2.24), mapSpanDelta: 0.9,
              investmentThesis: "Northern powerhouse residential yield, industrial conversion.",
              rssFeeds: [], cityAliases: ["manchester", "salford", "liverpool", "leeds"]),
        .init(id: "UK-BIR", displayName: "Birmingham", countryCode: "GB", parentId: "UK",
              mapCenter: .init(latitude: 52.49, longitude: -1.90), mapSpanDelta: 0.9,
              investmentThesis: "Midlands value-add, HS2-adjacent repositioning.",
              rssFeeds: [], cityAliases: ["birmingham", "west midlands", "coventry"]),
        .init(id: "UK-EDI", displayName: "Edinburgh", countryCode: "GB", parentId: "UK",
              mapCenter: .init(latitude: 55.95, longitude: -3.19), mapSpanDelta: 0.8,
              investmentThesis: "Scottish residential yield, heritage conversion.",
              rssFeeds: [], cityAliases: ["edinburgh", "glasgow", "scotland"]),

        // Croatia & Greece
        .init(id: "HR-SPU", displayName: "Split / Dalmatia", countryCode: "HR", parentId: "HR",
              mapCenter: .init(latitude: 43.51, longitude: 16.44), mapSpanDelta: 1.0,
              investmentThesis: "Adriatic stone houses, tourism rental conversion.",
              rssFeeds: [], cityAliases: ["split", "zadar", "dubrovnik", "dalmatia"]),
        .init(id: "HR-ZAG", displayName: "Zagreb", countryCode: "HR", parentId: "HR",
              mapCenter: .init(latitude: 45.81, longitude: 15.98), mapSpanDelta: 0.8,
              investmentThesis: "Capital residential yield, inland value-add.",
              rssFeeds: [], cityAliases: ["zagreb"]),
        .init(id: "GR-ATH", displayName: "Athens", countryCode: "GR", parentId: "GR",
              mapCenter: .init(latitude: 37.98, longitude: 23.73), mapSpanDelta: 0.9,
              investmentThesis: "Distressed urban stock, golden-visa adjacent rehab.",
              rssFeeds: [], cityAliases: ["athens", "athina", "piraeus"]),
        .init(id: "GR-ISL", displayName: "Greek Islands", countryCode: "GR", parentId: "GR",
              mapCenter: .init(latitude: 37.0, longitude: 25.0), mapSpanDelta: 2.5,
              investmentThesis: "Island rural stock, tourism conversion.",
              rssFeeds: [], cityAliases: ["crete", "santorini", "mykonos", "rhodes", "corfu"]),

        // Nordics
        .init(id: "SE-STO", displayName: "Stockholm", countryCode: "SE", parentId: "SE",
              mapCenter: .init(latitude: 59.33, longitude: 18.07), mapSpanDelta: 0.9,
              investmentThesis: "Capital yield spread, conversion stock.",
              rssFeeds: [], cityAliases: ["stockholm"]),
        .init(id: "SE-GOT", displayName: "Gothenburg", countryCode: "SE", parentId: "SE",
              mapCenter: .init(latitude: 57.71, longitude: 11.97), mapSpanDelta: 0.9,
              investmentThesis: "West coast industrial-residential conversion.",
              rssFeeds: [], cityAliases: ["gothenburg", "göteborg", "malmö", "malmo"]),
        .init(id: "DK-CPH", displayName: "Copenhagen", countryCode: "DK", parentId: "DK",
              mapCenter: .init(latitude: 55.68, longitude: 12.57), mapSpanDelta: 0.8,
              investmentThesis: "Metro residential yield, harbour conversion.",
              rssFeeds: [], cityAliases: ["copenhagen", "københavn", "aarhus"]),
        .init(id: "NO-OSL", displayName: "Oslo", countryCode: "NO", parentId: "NO",
              mapCenter: .init(latitude: 59.91, longitude: 10.75), mapSpanDelta: 0.9,
              investmentThesis: "Capital commercial, fjord tourism adjacency.",
              rssFeeds: [], cityAliases: ["oslo", "bergen"]),
        .init(id: "FI-HEL", displayName: "Helsinki", countryCode: "FI", parentId: "FI",
              mapCenter: .init(latitude: 60.17, longitude: 24.94), mapSpanDelta: 0.9,
              investmentThesis: "Capital residential, lake cabin renovation plays.",
              rssFeeds: [], cityAliases: ["helsinki", "tampere", "turku"]),

        // United States
        .init(id: "US-NYC", displayName: "New York Metro", countryCode: "US", parentId: "US",
              mapCenter: .init(latitude: 40.75, longitude: -73.98), mapSpanDelta: 1.2,
              investmentThesis: "Distressed multifamily, outer-borough value-add.",
              rssFeeds: ["https://www.crainsnewyork.com/section/real-estate/feed"],
              cityAliases: ["new york", "nyc", "manhattan", "brooklyn", "queens", "bronx"]),
        .init(id: "US-LA", displayName: "Los Angeles Metro", countryCode: "US", parentId: "US",
              mapCenter: .init(latitude: 34.05, longitude: -118.25), mapSpanDelta: 1.8,
              investmentThesis: "Multifamily value-add, ADU conversion, commercial strips.",
              rssFeeds: [], cityAliases: ["los angeles", "la", "santa monica", "pasadena", "long beach"]),
        .init(id: "US-CHI", displayName: "Chicago Metro", countryCode: "US", parentId: "US",
              mapCenter: .init(latitude: 41.88, longitude: -87.63), mapSpanDelta: 1.5,
              investmentThesis: "Midwest industrial conversion, residential value-add.",
              rssFeeds: [], cityAliases: ["chicago"]),
        .init(id: "US-MIA", displayName: "Miami Metro", countryCode: "US", parentId: "US",
              mapCenter: .init(latitude: 25.76, longitude: -80.19), mapSpanDelta: 1.2,
              investmentThesis: "Condo repositioning, STR conversion, Sun Belt migration.",
              rssFeeds: [], cityAliases: ["miami", "fort lauderdale", "miami beach"]),
        .init(id: "US-FLA", displayName: "Florida (state)", countryCode: "US", parentId: "US",
              mapCenter: .init(latitude: 27.5, longitude: -81.5), mapSpanDelta: 4.0,
              investmentThesis: "Statewide Sun Belt stock, hospitality conversion.",
              rssFeeds: [], cityAliases: ["orlando", "tampa", "jacksonville", "florida", "fl"]),
        .init(id: "US-TX", displayName: "Texas (state)", countryCode: "US", parentId: "US",
              mapCenter: .init(latitude: 31.0, longitude: -99.0), mapSpanDelta: 6.0,
              investmentThesis: "Houston/Dallas/Austin growth corridors, industrial value-add.",
              rssFeeds: [], cityAliases: ["houston", "dallas", "austin", "san antonio", "texas", "tx"]),
        .init(id: "US-DET", displayName: "Detroit Metro", countryCode: "US", parentId: "US",
              mapCenter: .init(latitude: 42.33, longitude: -83.05), mapSpanDelta: 1.5,
              investmentThesis: "Classic distressed residential — rehab-to-rent.",
              rssFeeds: [], cityAliases: ["detroit", "wayne county"]),
        .init(id: "US-ATL", displayName: "Atlanta Metro", countryCode: "US", parentId: "US",
              mapCenter: .init(latitude: 33.75, longitude: -84.39), mapSpanDelta: 1.5,
              investmentThesis: "Sun Belt sprawl value-add, industrial conversion.",
              rssFeeds: [], cityAliases: ["atlanta", "georgia", "ga"]),
        .init(id: "US-BOS", displayName: "Boston Metro", countryCode: "US", parentId: "US",
              mapCenter: .init(latitude: 42.36, longitude: -71.06), mapSpanDelta: 1.3,
              investmentThesis: "Triple-decker rehab, student housing adjacency.",
              rssFeeds: [], cityAliases: ["boston", "cambridge", "massachusetts", "ma"]),

        // Japan
        .init(id: "JP-TYO", displayName: "Tokyo", countryCode: "JP", parentId: "JP",
              mapCenter: .init(latitude: 35.68, longitude: 139.69), mapSpanDelta: 1.0,
              investmentThesis: "Peripheral ward value-add, commercial conversion.",
              rssFeeds: [], cityAliases: ["tokyo", "yokohama", "chiba"]),
        .init(id: "JP-RUR", displayName: "Rural Japan", countryCode: "JP", parentId: "JP",
              mapCenter: .init(latitude: 36.0, longitude: 137.0), mapSpanDelta: 5.0,
              investmentThesis: "Akiya vacant homes, minpaku conversion, cheap regional stock.",
              rssFeeds: [], cityAliases: ["akiya", "osaka", "kyoto", "hokkaido", "okinawa", "nagano"]),
    ]

    static let all: [MarketDefinition] = countries + metros

    static var metroIds: [String] { metros.map(\.id) }
    static var countryIds: [String] { countries.map(\.id) }

    static func market(id: String) -> MarketDefinition? {
        all.first { $0.id == id }
    }

    /// Resolve most specific market from deal city + country (import / geocode).
    static func resolveMarketId(city: String, countryHint: String = "") -> String? {
        let haystack = "\(city) \(countryHint)".lowercased()
        let ranked = metros.sorted { $0.cityAliases.count < $1.cityAliases.count }
        for m in ranked {
            if m.cityAliases.contains(where: { haystack.contains($0) }) { return m.id }
        }
        for c in countries {
            if c.cityAliases.contains(where: { haystack.contains($0) }) { return c.id }
        }
        return nil
    }

    /// Country node for a market id (metro → parent, country → self).
    static func countryId(for marketId: String) -> String? {
        guard let m = market(id: marketId) else { return nil }
        return m.parentId ?? m.id
    }

    static func feedURLs(for marketId: String) -> [String] {
        guard let m = market(id: marketId) else { return [] }
        var urls = m.rssFeeds
        if let parent = m.parentId, let p = market(id: parent) {
            urls.append(contentsOf: p.rssFeeds)
        }
        return Array(Set(urls)).filter { !$0.isEmpty }
    }

    /// Classify headline/body text into portfolio intelligence sectors.
    static func sectors(in text: String) -> [IntelSector] {
        let lower = text.lowercased()
        return IntelSector.classificationOrder.filter { sector in
            sector.keywords.contains { lower.contains($0) }
        }
    }

    /// Legacy name — sectors replaced value-add topic tags.
    static func topics(in text: String) -> [IntelTopic] {
        sectors(in: text)
    }
}
