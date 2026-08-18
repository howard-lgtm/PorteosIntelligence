import Foundation
import SwiftData

// MARK: - DealResearchImporter
//
// Greedy JSON field mapper for AI/external research exports (Gemini, GPT, etc.).
// Understands the Gemini research format produced for Porteos deals plus generic
// flat research JSON. Applies only zero/empty fields — never overwrites user data.
// GPS coordinates are applied directly (bypassing CLGeocoder).
//
// Usage:
//   let result = DealResearchImporter.apply(json: data, to: deal, context: ctx)

struct DealResearchImporter {

    struct ImportResult {
        let applied: [String]   // human-readable list of fields applied
        let notes: String       // research text appended to deal.notes
        let hadGPS: Bool
    }

    // MARK: Public API

    static func apply(json: Data, to deal: PropertyDeal, context: ModelContext) -> ImportResult {
        guard json.count < 10_000_000 else {   // P13-06: 10MB cap
            return ImportResult(applied: ["// File too large (>10MB)"], notes: "", hadGPS: false)
        }
        guard let raw = try? JSONSerialization.jsonObject(with: json) as? [String: Any] else {
            return ImportResult(applied: [], notes: "", hadGPS: false)
        }
        return applyDict(raw, to: deal, context: context)
    }

    // MARK: Private

    private static func applyDict(
        _ dict: [String: Any],
        to deal: PropertyDeal,
        context: ModelContext
    ) -> ImportResult {
        DealHistoryManager.shared.push(deal: deal, label: "Import Research JSON")

        var applied: [String] = []
        var noteLines: [String] = []
        var hadGPS = false

        // ── Flatten all nested dicts into a single lookup map ──────────────────
        let flat = flatten(dict)

        // ── GPS coordinates — always apply when present and valid ──────────────
        if let lat = double(flat, keys: ["latitude", "lat", "decimal_latitude"]),
           let lon = double(flat, keys: ["longitude", "lon", "lng", "decimal_longitude"]),
           lat != 0, lon != 0,
           lat  >= -90,  lat  <= 90,
           lon >= -180, lon <= 180 {
            deal.latitude  = lat
            deal.longitude = lon
            deal.geocodeStatus = .ok
            applied.append("GPS \(String(format: "%.5f", lat)), \(String(format: "%.5f", lon))")
            hadGPS = true
        }

        // ── Guard: 10MB cap ───────────────────────────────────────────────────
        // (P13-06: prevent memory spike on crafted large files)

        // ── Price ──────────────────────────────────────────────────────────────
        if deal.purchasePrice == 0,
           let price = double(flat, keys: [
               "listing_price_eur", "purchasePrice", "purchase_price",
               "price_eur", "price", "land_acquisition_eur",
               "acquisition_price_eur", "asking_price_eur"
           ]), price > 0 {
            deal.purchasePrice = price
            applied.append("price €\(Int(price))")
        }

        // ── Total capital outlay (development projects) → notes ───────────────
        if let outlay = double(flat, keys: [
            "total_initial_capital_outlay_eur", "total_investment_eur",
            "total_capex_eur", "total_project_cost_eur"
        ]), outlay > 0 {
            noteLines.append(String(format: "Total capital outlay: €%.0f", outlay))
        }

        // ── Built area ────────────────────────────────────────────────────────
        if deal.totalArea == 0,
           let area = double(flat, keys: [
               "gross_built_area_sqm", "totalArea", "total_area",
               "max_buildable_gba_sqm", "gba_sqm", "area_sqm",
               "floor_area_sqm", "built_area_sqm", "gfa_sqm"
           ]), area > 0 {
            deal.totalArea = area
            applied.append("area \(Int(area))m²")
        }

        // ── Land / rustic area ────────────────────────────────────────────────
        if deal.landArea == 0,
           let land = double(flat, keys: [
               "rustic_land_area_sqm", "landArea", "land_area",
               "plot_area_sqm", "site_area_sqm", "plot_area_hectares"
           ]), land > 0 {
            // Convert hectares → m² if value looks like hectares (< 500)
            let landM2 = land < 500 ? land * 10_000 : land
            deal.landArea = landM2
            applied.append("land \(Int(landM2))m²")
        }

        // ── Renovation / construction budget ──────────────────────────────────
        if deal.renovationBudget == 0,
           let reno = double(flat, keys: [
               "total_construction_capex_eur", "construction_cost_eur",
               "renovationBudget", "renovation_budget_eur",
               "hard_soft_costs_eur", "capex_eur"
           ]), reno > 0 {
            deal.renovationBudget = reno
            applied.append("reno €\(Int(reno))")
        }

        // ── Hospitality: room count ───────────────────────────────────────────
        if deal.hospitalityRoomCount == 0,
           let rooms = int(flat, keys: [
               "target_keys_count", "total_keys", "room_count", "rooms",
               "keys_count", "no_of_rooms", "key_count", "total_rooms"
           ]), rooms > 0 {
            deal.hospitalityRoomCount = rooms
            applied.append("rooms \(rooms)")
        }

        // ── Hospitality: ADR ──────────────────────────────────────────────────
        if deal.hospitalityADR == 0,
           let adr = double(flat, keys: [
               "adr_eur", "adr", "average_daily_rate",
               "average_daily_rate_eur", "avg_room_rate_eur"
           ]), adr > 0 {
            deal.hospitalityADR = adr
            applied.append("ADR €\(Int(adr))")
        }

        // ── Hospitality: occupancy rate ───────────────────────────────────────
        if deal.hospitalityOccupancyRate == 0,
           let occ = double(flat, keys: [
               "occupancy_rate_pct", "occupancy_pct", "occupancy_rate",
               "target_occupancy_pct", "stabilised_occupancy_pct"
           ]), occ > 0, occ <= 100 {
            deal.hospitalityOccupancyRate = occ
            applied.append("occupancy \(Int(occ))%")
        }

        // ── Gross potential income (total revenue) ────────────────────────────
        if deal.grossPotentialIncome == 0,
           let gpi = double(flat, keys: [
               "total_gross_revenue_eur", "gross_revenue_eur", "grossPotentialIncome",
               "gross_potential_income_eur", "total_revenue_eur", "annual_revenue_eur"
           ]), gpi > 0 {
            deal.grossPotentialIncome = gpi
            applied.append("GPI €\(Int(gpi))")
        }

        // ── Vacancy rate ──────────────────────────────────────────────────────
        if deal.vacancyRate == 0,
           let vacancy = double(flat, keys: [
               "vacancy_rate_pct", "vacancy_pct", "vacancyRate",
               "vacancy_rate", "vacancy_percentage"
           ]), vacancy > 0, vacancy <= 100 {
            deal.vacancyRate = vacancy
            applied.append("vacancy \(Int(vacancy))%")
        }

        // ── Closing costs ─────────────────────────────────────────────────────
        if deal.closingCosts == 0,
           let closing = double(flat, keys: [
               "closing_costs_eur", "closingCosts", "acquisition_costs_eur",
               "transaction_costs_eur", "closing_fees_eur"
           ]), closing > 0 {
            deal.closingCosts = closing
            applied.append("closing €\(Int(closing))")
        }

        // ── Operating expenses ────────────────────────────────────────────────
        if deal.operatingExpenses == 0,
           let opex = double(flat, keys: [
               "total_annual_opex_eur", "total_opex_eur", "operatingExpenses",
               "operating_expenses_eur", "annual_opex_eur", "opex_eur"
           ]), opex > 0 {
            deal.operatingExpenses = opex
            applied.append("OpEx €\(Int(opex))")
        }

        // ── OpEx Breakdown (6 fields) ─────────────────────────────────────────
        if deal.opexPropertyManagement == 0,
           let mgmt = double(flat, keys: [
               "opex_property_management_eur", "property_management_eur",
               "management_fees_eur", "property_mgmt_eur"
           ]), mgmt > 0 {
            deal.opexPropertyManagement = mgmt
            applied.append("OpEx mgmt €\(Int(mgmt))")
        }

        if deal.opexPropertyTax == 0,
           let tax = double(flat, keys: [
               "opex_property_tax_eur", "property_tax_eur",
               "annual_property_tax_eur", "real_estate_tax_eur"
           ]), tax > 0 {
            deal.opexPropertyTax = tax
            applied.append("OpEx tax €\(Int(tax))")
        }

        if deal.opexInsurance == 0,
           let ins = double(flat, keys: [
               "opex_insurance_eur", "insurance_eur",
               "annual_insurance_eur", "property_insurance_eur"
           ]), ins > 0 {
            deal.opexInsurance = ins
            applied.append("OpEx insurance €\(Int(ins))")
        }

        if deal.opexUtilities == 0,
           let util = double(flat, keys: [
               "opex_utilities_eur", "utilities_eur",
               "annual_utilities_eur", "utility_costs_eur"
           ]), util > 0 {
            deal.opexUtilities = util
            applied.append("OpEx utilities €\(Int(util))")
        }

        if deal.opexMaintenance == 0,
           let maint = double(flat, keys: [
               "opex_maintenance_eur", "maintenance_eur",
               "annual_maintenance_eur", "repairs_maintenance_eur"
           ]), maint > 0 {
            deal.opexMaintenance = maint
            applied.append("OpEx maintenance €\(Int(maint))")
        }

        if deal.opexCapitalReserves == 0,
           let reserves = double(flat, keys: [
               "opex_capital_reserves_eur", "capital_reserves_eur",
               "replacement_reserves_eur", "reserve_fund_eur"
           ]), reserves > 0 {
            deal.opexCapitalReserves = reserves
            applied.append("OpEx reserves €\(Int(reserves))")
        }

        // ── Hospitality OpEx ratio ────────────────────────────────────────────
        if deal.hospitalityOpExRatio == 0,
           let ratio = double(flat, keys: [
               "opex_ratio_pct", "opex_ratio", "hospitalityOpExRatio",
               "operating_cost_ratio_pct", "expense_ratio_pct"
           ]), ratio > 0, ratio <= 100 {
            deal.hospitalityOpExRatio = ratio
            applied.append("OpEx ratio \(Int(ratio))%")
        }

        // ── Ancillary / F&B revenue ───────────────────────────────────────────
        if deal.hospitalityFBRevenue == 0,
           let fnb = double(flat, keys: [
               "ancillary_revenue_eur", "fb_revenue_eur", "food_beverage_revenue_eur",
               "hospitalityFBRevenue", "fnb_revenue_eur"
           ]), fnb > 0 {
            deal.hospitalityFBRevenue = fnb
            applied.append("F&B €\(Int(fnb))")
        }

        // ── Loan / financing ──────────────────────────────────────────────────
        if deal.interestRate == 0,
           let rate = double(flat, keys: [
               "interest_rate_pct", "interestRate", "loan_rate_pct",
               "mortgage_rate_pct", "financing_rate_pct"
           ]), rate > 0, rate < 30 {
            deal.interestRate = rate
            applied.append("rate \(rate)%")
        }

        if deal.amortizationMonths == 0,
           let amYears = double(flat, keys: [
               "amortization_years", "loan_term_years", "mortgage_term_years",
               "repayment_period_years"
           ]), amYears > 0 {
            deal.amortizationMonths = Int(amYears * 12)
            applied.append("amort \(Int(amYears))yr")
        }

        // Compute loan amount from LTV if both LTV and purchase price are known
        if deal.loanAmount == 0,
           let ltv = double(flat, keys: [
               "ltv_pct", "ltv", "loan_to_value_pct", "loan_to_value"
           ]), ltv > 0, ltv <= 100, deal.purchasePrice > 0 {
            // Use total outlay if available, otherwise purchase price
            let basis = double(flat, keys: [
                "total_initial_capital_outlay_eur", "total_investment_eur"
            ]) ?? deal.purchasePrice
            let loan = basis * (ltv / 100)
            deal.loanAmount = loan
            applied.append("loan €\(Int(loan)) (\(Int(ltv))% LTV)")
        }

        // ── Exit cap rate ─────────────────────────────────────────────────────
        if deal.exitCapRate == 0,
           let exitCap = double(flat, keys: [
               "target_exit_cap_rate_pct", "exit_cap_rate_pct", "exitCapRate",
               "exit_yield_pct", "terminal_cap_rate_pct"
           ]), exitCap > 0, exitCap < 30 {
            deal.exitCapRate = exitCap
            applied.append("exit cap \(exitCap)%")
        }

        // ── Financial metrics → notes (informational) ─────────────────────────
        let financialNoteKeys: [(String, String, String)] = [
            ("unlevered_yield_on_cost_pct",  "Yield on cost",    "%.2f%%"),
            ("unlevered_10yr_irr_pct",       "Unlevered IRR",    "%.2f%%"),
            ("levered_10yr_irr_pct",         "Levered IRR",      "%.2f%%"),
            ("debt_service_coverage_ratio",  "DSCR",             "%.2fx"),
            ("equity_payback_period_years",  "Equity payback",   "%.1f yr"),
            ("terminal_asset_value_eur",     "Terminal value",   "€%.0f"),
            ("revpar_eur",                   "RevPAR",           "€%.0f"),
            ("trevpar_eur",                  "TRevPAR",          "€%.0f"),
            ("noi_margin_pct",               "NOI margin",       "%.1f%%"),
        ]
        for (key, label, fmt) in financialNoteKeys {
            if let val = double(flat, keys: [key]) {
                noteLines.append(String(format: "\(label): \(fmt)", val))
            }
        }

        // ── Property type ─────────────────────────────────────────────────────
        if deal.propertyType.isEmpty,
           let ptype = string(flat, keys: [
               "property_type", "propertyType", "asset_type", "asset_class",
               "building_type", "development_type", "typology"
           ]) {
            deal.propertyType = ptype
            applied.append("type \(ptype)")
        }

        // ── Bedrooms from typology string ─────────────────────────────────────
        if let bdr = int(flat, keys: ["bedrooms", "bedroom_count", "rooms"]), bdr > 0 {
            // direct integer field
        } else if let typology = string(flat, keys: ["typology", "property_type", "type"]) {
            // "T3 (Three-Bedroom Potential)" → 3
            if let m = typology.range(of: #"\bT(\d)\b"#, options: .regularExpression) {
                let tStr = String(typology[m]).dropFirst() // "T3" → "3"
                if let n = Int(tStr), n > 0, deal.hospitalityRoomCount == 0 {
                    // Store bedroom count in notes since PropertyDeal doesn't have a bedrooms field
                    // (it uses hospitalityRoomCount for hospitality only)
                    noteLines.append("Typology: \(typology)")
                    applied.append("typology \(typology)")
                }
            }
        }

        // ── Location ──────────────────────────────────────────────────────────
        if deal.locationCity.isEmpty {
            // Try most-specific first: parish → municipality → district → region
            let cityKeys = ["parish", "locality", "municipality", "district", "region", "city",
                            "locationCity", "location_city"]
            if let city = string(flat, keys: cityKeys), !city.isEmpty {
                deal.locationCity = city
                applied.append("city \(city)")
            }
        }

        // ── Regulatory Fields (7 fields) ──────────────────────────────────────
        if deal.zoningClass.isEmpty,
           let zoning = string(flat, keys: [
               "zoning_class", "zoning", "zoning_designation",
               "land_use_zoning", "zoning_code"
           ]) {
            deal.zoningClass = zoning
            applied.append("zoning \(zoning)")
        }

        if deal.floorAreaRatio == 0,
           let far = double(flat, keys: [
               "floor_area_ratio", "far", "building_ratio",
               "construction_index", "utilization_index"
           ]), far > 0, far <= 10 {
            deal.floorAreaRatio = far
            applied.append("FAR \(String(format: "%.2f", far))")
        }

        if deal.maxBuildingHeight == 0,
           let height = double(flat, keys: [
               "max_building_height_m", "max_height_m", "height_limit_m",
               "maximum_building_height", "max_height_meters"
           ]), height > 0 {
            deal.maxBuildingHeight = height
            applied.append("max height \(Int(height))m")
        }

        if deal.maxBedroomsOrUnits == 0,
           let units = int(flat, keys: [
               "max_bedrooms_or_units", "max_units", "max_dwelling_units",
               "maximum_bedrooms", "max_residential_units"
           ]), units > 0 {
            deal.maxBedroomsOrUnits = units
            applied.append("max units \(units)")
        }

        if deal.planningStatus == "unknown",
           let status = string(flat, keys: [
               "planning_status", "planning_permission_status",
               "development_status", "permit_status"
           ]) {
            // Normalize to: "none" | "applied" | "approved"
            let normalized = status.lowercased()
            if normalized.contains("none") || normalized.contains("not applied") {
                deal.planningStatus = "none"
            } else if normalized.contains("applied") || normalized.contains("pending") {
                deal.planningStatus = "applied"
            } else if normalized.contains("approved") || normalized.contains("granted") {
                deal.planningStatus = "approved"
            } else {
                deal.planningStatus = normalized
            }
            applied.append("planning \(deal.planningStatus)")
        }

        if !deal.heritageOrListed,
           let heritage = flat["heritage_or_listed"] as? Bool ?? flat["is_listed"] as? Bool ?? flat["heritage_status"] as? Bool {
            deal.heritageOrListed = heritage
            if heritage {
                applied.append("heritage: listed")
            }
        } else if !deal.heritageOrListed,
                  let heritageStr = string(flat, keys: ["heritage_or_listed", "listed_status", "heritage_status"]) {
            let normalized = heritageStr.lowercased()
            if normalized.contains("yes") || normalized.contains("listed") || normalized.contains("protected") {
                deal.heritageOrListed = true
                applied.append("heritage: listed")
            }
        }

        if deal.strLicenceStatus == "unknown",
           let strStatus = string(flat, keys: [
               "str_licence_status", "short_term_rental_license",
               "str_permit_status", "alojamento_local_status"
           ]) {
            // Normalize to: "none" | "applied" | "approved"
            let normalized = strStatus.lowercased()
            if normalized.contains("none") || normalized.contains("not required") {
                deal.strLicenceStatus = "none"
            } else if normalized.contains("applied") || normalized.contains("pending") {
                deal.strLicenceStatus = "applied"
            } else if normalized.contains("approved") || normalized.contains("granted") || normalized.contains("active") {
                deal.strLicenceStatus = "approved"
            } else {
                deal.strLicenceStatus = normalized
            }
            applied.append("STR \(deal.strLicenceStatus)")
        }

        // ── Address / access road ─────────────────────────────────────────────
        if deal.address.isEmpty,
           let road = string(flat, keys: ["access_road", "address", "street"]),
           !road.isEmpty {
            deal.address = road
            applied.append("address \(road)")
        }

        // ── Agency / agent (notes) ────────────────────────────────────────────
        if let agency = string(flat, keys: ["listing_agency", "agency", "agent_company"]) {
            noteLines.append("Agency: \(agency)")
        }
        if let agent = string(flat, keys: ["listing_agent", "agent", "agent_name"]) {
            noteLines.append("Agent: \(agent)")
        }
        if let ref = string(flat, keys: ["listing_reference", "reference", "ref", "listing_ref"]) {
            noteLines.append("Ref: \(ref)")
        }

        // ── Research narrative fields → notes ─────────────────────────────────
        let researchKeys: [(String, String)] = [
            ("soil_type",                   "Soil"),
            ("solar_exposure",              "Solar"),
            ("microclimate_benefits",       "Microclimate"),
            ("water_access",                "Water"),
            ("licensing_framework",         "Licensing"),
            ("zoning_restrictions",         "Zoning"),
            ("sustainable_architectural_potentials", "Sustainable potential"),
            ("north_boundary",              "N boundary"),
            ("south_boundary",              "S boundary"),
            ("west_boundary",               "W boundary"),
            ("east_boundary",               "E boundary"),
            ("archaeological_proximity",    "Archaeological"),
            ("structure",                   "Structure"),
            ("status",                      "Status"),
        ]
        for (key, label) in researchKeys {
            if let val = flat[key] as? String, !val.isEmpty {
                noteLines.append("\(label): \(val)")
            }
        }

        // ── Price per sqm (informational) ─────────────────────────────────────
        if let ppsqm = double(flat, keys: ["implied_unit_price_eur_sqm", "price_per_sqm",
                                            "subject_price_per_sqm"]), ppsqm > 0 {
            noteLines.append(String(format: "Price/m²: €%.0f", ppsqm))
        }

        // ── Append research notes ─────────────────────────────────────────────
        let researchBlock = noteLines.isEmpty ? "" : "\n\n--- RESEARCH IMPORT ---\n" + noteLines.joined(separator: "\n")
        if !researchBlock.isEmpty {
            deal.notes = deal.notes + researchBlock
        }

        // ── Country ───────────────────────────────────────────────────────────
        if deal.locationCountry.isEmpty,
           let country = string(flat, keys: ["country", "location_country", "locationCountry"]),
           !country.isEmpty {
            deal.locationCountry = country
            applied.append("country \(country)")
        }

        // ── Market resolution ─────────────────────────────────────────────────
        if deal.marketId.isEmpty, !deal.locationCity.isEmpty {
            if let resolved = MarketFeedRegistry.resolveMarketId(
                city: deal.locationCity,
                countryHint: string(flat, keys: ["country", "region"]) ?? "") {
                deal.marketId = resolved
                applied.append("market \(resolved)")
            }
        }

        deal.porteosScore = PropertyDealViewModel(deal: deal).porteosScore.finalScore
        deal.updatedAt = Date()
        try? context.save()

        return ImportResult(applied: applied, notes: researchBlock, hadGPS: hadGPS)
    }

    // MARK: - JSON flattening

    /// Recursively flattens nested dicts into a single [String: Any] map.
    private static func flatten(_ dict: [String: Any]) -> [String: Any] {
        var result: [String: Any] = [:]
        for (key, value) in dict {
            result[key] = value
            if let nested = value as? [String: Any] {
                let sub = flatten(nested)
                for (subKey, subVal) in sub {
                    result[subKey] = subVal
                }
            }
        }
        return result
    }

    // MARK: - Field extractors

    private static func double(_ flat: [String: Any], keys: [String]) -> Double? {
        for key in keys {
            if let n = flat[key] as? Double { return n }
            if let n = flat[key] as? Int    { return Double(n) }
            if let s = flat[key] as? String, let n = Double(s) { return n }
        }
        return nil
    }

    private static func int(_ flat: [String: Any], keys: [String]) -> Int? {
        for key in keys {
            if let n = flat[key] as? Int    { return n }
            if let n = flat[key] as? Double { return Int(n) }
        }
        return nil
    }

    private static func string(_ flat: [String: Any], keys: [String]) -> String? {
        for key in keys {
            if let s = flat[key] as? String, !s.trimmingCharacters(in: .whitespaces).isEmpty {
                return s.trimmingCharacters(in: .whitespaces)
            }
        }
        return nil
    }
}
