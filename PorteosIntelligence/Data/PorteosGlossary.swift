import Foundation

// MARK: - PorteosGlossary
// Canonical terminology reference for dashboard metrics, profiles, and validation logs.

struct GlossaryEntry: Identifiable {
    let id = UUID()
    let term: String
    let definition: String
}

struct GlossarySection: Identifiable {
    let id = UUID()
    let title: String
    let entries: [GlossaryEntry]
}

struct PorteosGlossary {

    static let sections: [GlossarySection] = [
        .init(title: "CORE SCORING", entries: [
            .init(term: "Porteos Score", definition: "Composite 0–100 deal grade blending Real Estate, Hospitality, Design, and Circular profile weights."),
            .init(term: "Investor Score", definition: "Risk-adjusted return signal derived from NOI, leverage, and market spread."),
            .init(term: "Grade", definition: "Letter band mapped from Porteos Score (A ≥ 80, B ≥ 65, C ≥ 50, D < 50)."),
        ]),
        .init(title: "REAL ESTATE", entries: [
            .init(term: "GPI", definition: "Gross Potential Income — total rent if fully occupied before vacancy and expenses."),
            .init(term: "EGI", definition: "Effective Gross Income — GPI minus vacancy loss plus other income."),
            .init(term: "NOI", definition: "Net Operating Income — EGI minus operating expenses (before debt service)."),
            .init(term: "Cap Rate", definition: "NOI ÷ property value, expressed as a percentage yield."),
            .init(term: "DSCR", definition: "Debt Service Coverage Ratio — NOI divided by annual mortgage payments."),
            .init(term: "Cash-on-Cash", definition: "Annual pre-tax cash flow divided by total equity invested."),
            .init(term: "LTV", definition: "Loan-to-Value — loan amount as a percentage of purchase price."),
            .init(term: "Exit Cap Rate", definition: "Assumed cap rate at disposition for terminal value / IRR modelling."),
            .init(term: "OpEx", definition: "Operating expenses — recurring costs to run the asset (tax, insurance, utilities, etc.)."),
        ]),
        .init(title: "HOSPITALITY", entries: [
            .init(term: "ADR", definition: "Average Daily Rate — average room revenue per occupied room-night."),
            .init(term: "Occupancy", definition: "Percentage of available room-nights sold in a period."),
            .init(term: "RevPAR", definition: "Revenue Per Available Room — ADR × occupancy rate."),
            .init(term: "TRevPAR", definition: "Total RevPAR — room revenue plus ancillary (F&B, spa, meetings) per available room."),
            .init(term: "OpEx Ratio", definition: "Operating expenses as a percentage of total hospitality revenue."),
            .init(term: "OTA", definition: "Online Travel Agency channel (Booking.com, Expedia, etc.) and its booking share."),
        ]),
        .init(title: "DESIGN", entries: [
            .init(term: "GFA", definition: "Gross Floor Area — total built floor area including walls and circulation (m²)."),
            .init(term: "NIA", definition: "Net Internal Area — usable floor area excluding structure and circulation (m²)."),
            .init(term: "NTG Ratio", definition: "Net-to-Gross — NIA ÷ GFA; higher values indicate efficient space planning."),
            .init(term: "ACH", definition: "Air Changes Per Hour — ventilation rate in occupied spaces."),
            .init(term: "Biophilic Score", definition: "Count and coverage of nature-connected design elements."),
            .init(term: "Adaptability Score", definition: "0–100 rating of spatial flexibility (partitions, multi-use, future retrofit)."),
        ]),
        .init(title: "CIRCULAR ECONOMY", entries: [
            .init(term: "Embodied Carbon", definition: "CO₂e locked in materials and construction (kg CO₂e)."),
            .init(term: "Operational Carbon", definition: "Annual in-use emissions (tCO₂e/yr) from energy, water, and operations."),
            .init(term: "Carbon Intensity", definition: "Embodied carbon per m² of building area (tCO₂e/m²)."),
            .init(term: "Recycled Content", definition: "Percentage of materials by mass that are post-consumer recycled."),
            .init(term: "Renewable Content", definition: "Percentage of materials from rapidly renewable or bio-based sources."),
            .init(term: "Material Recovery", definition: "Share of construction materials returned, reused, or recycled vs disposed."),
        ]),
        .init(title: "MARKET & VALIDATION", entries: [
            .init(term: "Prime Yield", definition: "Benchmark cap rate for top-tier assets in the local market."),
            .init(term: "Yield Spread", definition: "Difference between deal cap rate and market prime yield (basis points)."),
            .init(term: "CPI", definition: "Consumer Price Index — inflation reference for rent escalation."),
            .init(term: "Validation Log", definition: "System warnings when inputs produce non-physical or uneconomic results."),
            .init(term: "bps", definition: "Basis points — 1/100 of a percentage point (100 bps = 1%)."),
        ]),
    ]

    static var entryCount: Int {
        sections.reduce(0) { $0 + $1.entries.count }
    }
}
