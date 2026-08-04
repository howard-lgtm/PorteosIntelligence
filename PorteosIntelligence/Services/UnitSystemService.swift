import Foundation
import SwiftUI

// MARK: - UnitSystem

enum UnitSystem: String, CaseIterable {
    case metric   = "metric"
    case imperial = "imperial"

    var areaUnit:     String { self == .imperial ? "ft²" : "m²" }
    var heightUnit:   String { self == .imperial ? "ft"  : "m"  }
    var areaFactor:   Double { self == .imperial ? 10.7639 : 1.0 }
    var heightFactor: Double { self == .imperial ? 3.28084 : 1.0 }

    /// Countries that use imperial units for real estate (US, Liberia, Myanmar + territories)
    static let imperialCountries: Set<String> = [
        "united states", "us", "usa", "liberia", "myanmar", "burma",
        "cayman islands", "belize", "united states virgin islands",
        "american samoa", "puerto rico", "guam", "bahamas",
    ]

    static func from(country: String) -> UnitSystem {
        let lower = country.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        return imperialCountries.contains(lower) ? .imperial : .metric
    }
}

// MARK: - UnitSystemService

/// Central unit formatting service. Uses deal country for auto-detection,
/// respecting the user's manual override in Settings.
final class UnitSystemService {

    static let shared = UnitSystemService()
    private init() {}

    // User override stored in UserDefaults. "auto" = detect from deal country.
    private let overrideKey = "porteos.unitSystemOverride"

    var manualOverride: String {
        get { UserDefaults.standard.string(forKey: overrideKey) ?? "auto" }
        set { UserDefaults.standard.set(newValue, forKey: overrideKey) }
    }

    /// Resolve the unit system for a given deal country.
    func system(for country: String) -> UnitSystem {
        switch manualOverride {
        case "metric":   return .metric
        case "imperial": return .imperial
        default:         return UnitSystem.from(country: country)
        }
    }

    // MARK: Formatting helpers

    /// Format an area value stored in m².
    func formatArea(_ m2: Double, country: String, decimals: Int = 0) -> String {
        guard m2 > 0 else { return "—" }
        let sys = system(for: country)
        let converted = m2 * sys.areaFactor
        let formatted = converted.formatted(.number.precision(.fractionLength(decimals)))
        return "\(formatted) \(sys.areaUnit)"
    }

    /// Format a height/distance value stored in metres.
    func formatHeight(_ metres: Double, country: String, decimals: Int = 1) -> String {
        guard metres > 0 else { return "—" }
        let sys = system(for: country)
        let converted = metres * sys.heightFactor
        let formatted = converted.formatted(.number.precision(.fractionLength(decimals)))
        return "\(formatted) \(sys.heightUnit)"
    }

    /// Format a price-per-area metric (e.g. purchase price / m²).
    /// Returns e.g. "€ 1,250 / ft²"
    func formatPricePerArea(_ pricePerM2: Double, currency: String, country: String) -> String {
        guard pricePerM2 > 0 else { return "—" }
        let sys = system(for: country)
        // If imperial, price per ft² = price per m² / 10.7639
        let converted = sys == .imperial ? pricePerM2 / 10.7639 : pricePerM2
        let symbol = currencySymbol(for: currency)
        let formatted = converted.formatted(.number.precision(.fractionLength(0)))
        return "\(symbol) \(formatted) / \(sys.areaUnit)"
    }

    /// Format a currency value with the appropriate symbol.
    func formatCurrency(_ amount: Double, currency: String, decimals: Int = 0) -> String {
        guard amount > 0 else { return "—" }
        let symbol = currencySymbol(for: currency)
        let formatted = amount.formatted(.number.precision(.fractionLength(decimals)))
        return "\(symbol) \(formatted)"
    }

    func currencySymbol(for currency: String) -> String {
        switch currency.uppercased() {
        case "USD", "US$": return "$"
        case "GBP":        return "£"
        case "SEK":        return "kr"
        case "CHF":        return "Fr"
        case "JPY":        return "¥"
        case "AUD":        return "A$"
        case "CAD":        return "C$"
        case "NOK":        return "kr"
        case "DKK":        return "kr"
        case "PLN":        return "zł"
        case "CZK":        return "Kč"
        case "HUF":        return "Ft"
        case "BRL":        return "R$"
        default:           return "€"   // EUR and unknown
        }
    }

    /// The area unit label for a given country (for field suffixes in forms).
    func areaUnitLabel(for country: String) -> String {
        system(for: country).areaUnit
    }

    /// The height unit label for a given country.
    func heightUnitLabel(for country: String) -> String {
        system(for: country).heightUnit
    }
}
