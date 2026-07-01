import Foundation

// MARK: - CityMetrics

/// Static market benchmark for a single city.
/// All values are approximate averages sourced from institutional real estate
/// and hospitality research (2024–2026 estimates). Use as reference baselines
/// only — always validate against live data before investment decisions.
struct CityMetrics {
    let cityName:   String
    let country:    String
    let region:     String    // "Europe" | "MEA" | "Americas" | "APAC"

    // MARK: Real Estate
    let avgCapRate:        Double   // % (prime commercial/mixed-use)
    let avgVacancyRate:    Double   // % (office/retail)
    let avgOpExPerSqm:     Double   // €/m² per year
    let avgGPIPerSqm:      Double   // €/m² per year (gross potential rent)

    // MARK: Hospitality
    let avgADR:            Double   // € average daily rate
    let avgOccupancyRate:  Double   // %
    let avgRevPAR:         Double   // € revenue per available room

    // MARK: Design / Climate
    let typicalDaylighting:         Double  // % (annual average daylighting coverage)
    let typicalCoolingDegreeDays:   Double  // base 18 °C, annual CDD

    // MARK: Financing & Construction
    let avgInterestRate:             Double  // % (typical mortgage/commercial loan rate)
    let avgPropertyTaxRate:          Double  // % of assessed value per year
    let avgConstructionCostPerSqm:   Double  // €/m² (mid-spec commercial build)
    let avgInsuranceRatePerSqm:      Double  // €/m²/year (building insurance)
}

// MARK: - MarketBenchmarks

struct MarketBenchmarks {

    // MARK: Static Database

    static let benchmarks: [CityMetrics] = [

        // ── PORTUGAL ───────────────────────────────────────────────────────────

        CityMetrics(
            cityName: "Lisbon", country: "Portugal", region: "Europe",
            avgCapRate: 5.5, avgVacancyRate: 8.0,
            avgOpExPerSqm: 45.0, avgGPIPerSqm: 180.0,
            avgADR: 120.0, avgOccupancyRate: 75.0, avgRevPAR: 90.0,
            typicalDaylighting: 65.0, typicalCoolingDegreeDays: 450,
            avgInterestRate: 4.0, avgPropertyTaxRate: 0.4,
            avgConstructionCostPerSqm: 1600.0, avgInsuranceRatePerSqm: 10.0
        ),
        CityMetrics(
            cityName: "Porto", country: "Portugal", region: "Europe",
            avgCapRate: 6.0, avgVacancyRate: 10.0,
            avgOpExPerSqm: 40.0, avgGPIPerSqm: 150.0,
            avgADR: 95.0, avgOccupancyRate: 70.0, avgRevPAR: 66.5,
            typicalDaylighting: 60.0, typicalCoolingDegreeDays: 380,
            avgInterestRate: 4.0, avgPropertyTaxRate: 0.4,
            avgConstructionCostPerSqm: 1350.0, avgInsuranceRatePerSqm: 9.0
        ),
        CityMetrics(
            cityName: "Faro", country: "Portugal", region: "Europe",
            avgCapRate: 6.5, avgVacancyRate: 12.0,
            avgOpExPerSqm: 35.0, avgGPIPerSqm: 120.0,
            avgADR: 110.0, avgOccupancyRate: 68.0, avgRevPAR: 74.8,
            typicalDaylighting: 72.0, typicalCoolingDegreeDays: 620,
            avgInterestRate: 4.0, avgPropertyTaxRate: 0.35,
            avgConstructionCostPerSqm: 1200.0, avgInsuranceRatePerSqm: 8.5
        ),

        // ── SPAIN ──────────────────────────────────────────────────────────────

        CityMetrics(
            cityName: "Madrid", country: "Spain", region: "Europe",
            avgCapRate: 4.8, avgVacancyRate: 9.5,
            avgOpExPerSqm: 52.0, avgGPIPerSqm: 210.0,
            avgADR: 135.0, avgOccupancyRate: 76.0, avgRevPAR: 102.6,
            typicalDaylighting: 62.0, typicalCoolingDegreeDays: 720,
            avgInterestRate: 3.8, avgPropertyTaxRate: 0.7,
            avgConstructionCostPerSqm: 1700.0, avgInsuranceRatePerSqm: 11.0
        ),
        CityMetrics(
            cityName: "Barcelona", country: "Spain", region: "Europe",
            avgCapRate: 4.5, avgVacancyRate: 8.5,
            avgOpExPerSqm: 55.0, avgGPIPerSqm: 230.0,
            avgADR: 150.0, avgOccupancyRate: 78.0, avgRevPAR: 117.0,
            typicalDaylighting: 64.0, typicalCoolingDegreeDays: 510,
            avgInterestRate: 3.8, avgPropertyTaxRate: 0.65,
            avgConstructionCostPerSqm: 1900.0, avgInsuranceRatePerSqm: 12.0
        ),
        CityMetrics(
            cityName: "Seville", country: "Spain", region: "Europe",
            avgCapRate: 5.5, avgVacancyRate: 11.0,
            avgOpExPerSqm: 38.0, avgGPIPerSqm: 155.0,
            avgADR: 105.0, avgOccupancyRate: 72.0, avgRevPAR: 75.6,
            typicalDaylighting: 68.0, typicalCoolingDegreeDays: 850,
            avgInterestRate: 3.8, avgPropertyTaxRate: 0.7,
            avgConstructionCostPerSqm: 1400.0, avgInsuranceRatePerSqm: 10.0
        ),

        // ── FRANCE ─────────────────────────────────────────────────────────────

        CityMetrics(
            cityName: "Paris", country: "France", region: "Europe",
            avgCapRate: 3.8, avgVacancyRate: 7.0,
            avgOpExPerSqm: 80.0, avgGPIPerSqm: 650.0,
            avgADR: 280.0, avgOccupancyRate: 80.0, avgRevPAR: 224.0,
            typicalDaylighting: 48.0, typicalCoolingDegreeDays: 95,
            avgInterestRate: 3.5, avgPropertyTaxRate: 1.5,
            avgConstructionCostPerSqm: 4000.0, avgInsuranceRatePerSqm: 20.0
        ),
        CityMetrics(
            cityName: "Lyon", country: "France", region: "Europe",
            avgCapRate: 4.5, avgVacancyRate: 9.0,
            avgOpExPerSqm: 55.0, avgGPIPerSqm: 280.0,
            avgADR: 130.0, avgOccupancyRate: 70.0, avgRevPAR: 91.0,
            typicalDaylighting: 50.0, typicalCoolingDegreeDays: 210,
            avgInterestRate: 3.5, avgPropertyTaxRate: 1.4,
            avgConstructionCostPerSqm: 2200.0, avgInsuranceRatePerSqm: 16.0
        ),

        // ── UNITED KINGDOM ─────────────────────────────────────────────────────

        CityMetrics(
            cityName: "London", country: "United Kingdom", region: "Europe",
            avgCapRate: 4.2, avgVacancyRate: 8.5,
            avgOpExPerSqm: 90.0, avgGPIPerSqm: 700.0,
            avgADR: 250.0, avgOccupancyRate: 82.0, avgRevPAR: 205.0,
            typicalDaylighting: 38.0, typicalCoolingDegreeDays: 40,
            avgInterestRate: 5.2, avgPropertyTaxRate: 0.4,
            avgConstructionCostPerSqm: 4500.0, avgInsuranceRatePerSqm: 22.0
        ),
        CityMetrics(
            cityName: "Edinburgh", country: "United Kingdom", region: "Europe",
            avgCapRate: 5.0, avgVacancyRate: 9.0,
            avgOpExPerSqm: 60.0, avgGPIPerSqm: 320.0,
            avgADR: 160.0, avgOccupancyRate: 74.0, avgRevPAR: 118.4,
            typicalDaylighting: 36.0, typicalCoolingDegreeDays: 10,
            avgInterestRate: 5.2, avgPropertyTaxRate: 0.35,
            avgConstructionCostPerSqm: 2800.0, avgInsuranceRatePerSqm: 18.0
        ),
        CityMetrics(
            cityName: "Manchester", country: "United Kingdom", region: "Europe",
            avgCapRate: 5.0, avgVacancyRate: 10.0,
            avgOpExPerSqm: 55.0, avgGPIPerSqm: 270.0,
            avgADR: 140.0, avgOccupancyRate: 75.0, avgRevPAR: 105.0,
            typicalDaylighting: 35.0, typicalCoolingDegreeDays: 20,
            avgInterestRate: 5.2, avgPropertyTaxRate: 0.35,
            avgConstructionCostPerSqm: 2500.0, avgInsuranceRatePerSqm: 17.0
        ),

        // ── GERMANY ────────────────────────────────────────────────────────────

        CityMetrics(
            cityName: "Berlin", country: "Germany", region: "Europe",
            avgCapRate: 4.2, avgVacancyRate: 5.5,
            avgOpExPerSqm: 58.0, avgGPIPerSqm: 300.0,
            avgADR: 140.0, avgOccupancyRate: 75.0, avgRevPAR: 105.0,
            typicalDaylighting: 44.0, typicalCoolingDegreeDays: 75,
            avgInterestRate: 3.8, avgPropertyTaxRate: 0.5,
            avgConstructionCostPerSqm: 2800.0, avgInsuranceRatePerSqm: 13.0
        ),
        CityMetrics(
            cityName: "Munich", country: "Germany", region: "Europe",
            avgCapRate: 3.8, avgVacancyRate: 4.0,
            avgOpExPerSqm: 68.0, avgGPIPerSqm: 380.0,
            avgADR: 175.0, avgOccupancyRate: 78.0, avgRevPAR: 136.5,
            typicalDaylighting: 48.0, typicalCoolingDegreeDays: 130,
            avgInterestRate: 3.8, avgPropertyTaxRate: 0.5,
            avgConstructionCostPerSqm: 3500.0, avgInsuranceRatePerSqm: 15.0
        ),
        CityMetrics(
            cityName: "Frankfurt", country: "Germany", region: "Europe",
            avgCapRate: 4.0, avgVacancyRate: 10.0,
            avgOpExPerSqm: 70.0, avgGPIPerSqm: 400.0,
            avgADR: 165.0, avgOccupancyRate: 72.0, avgRevPAR: 118.8,
            typicalDaylighting: 42.0, typicalCoolingDegreeDays: 90,
            avgInterestRate: 3.8, avgPropertyTaxRate: 0.5,
            avgConstructionCostPerSqm: 3000.0, avgInsuranceRatePerSqm: 14.0
        ),
        CityMetrics(
            cityName: "Hamburg", country: "Germany", region: "Europe",
            avgCapRate: 4.0, avgVacancyRate: 7.0,
            avgOpExPerSqm: 62.0, avgGPIPerSqm: 320.0,
            avgADR: 145.0, avgOccupancyRate: 73.0, avgRevPAR: 105.9,
            typicalDaylighting: 40.0, typicalCoolingDegreeDays: 55,
            avgInterestRate: 3.8, avgPropertyTaxRate: 0.5,
            avgConstructionCostPerSqm: 2900.0, avgInsuranceRatePerSqm: 13.5
        ),

        // ── NETHERLANDS ────────────────────────────────────────────────────────

        CityMetrics(
            cityName: "Amsterdam", country: "Netherlands", region: "Europe",
            avgCapRate: 4.5, avgVacancyRate: 6.0,
            avgOpExPerSqm: 72.0, avgGPIPerSqm: 420.0,
            avgADR: 190.0, avgOccupancyRate: 80.0, avgRevPAR: 152.0,
            typicalDaylighting: 40.0, typicalCoolingDegreeDays: 50,
            avgInterestRate: 3.7, avgPropertyTaxRate: 0.35,
            avgConstructionCostPerSqm: 3200.0, avgInsuranceRatePerSqm: 14.0
        ),

        // ── ITALY ──────────────────────────────────────────────────────────────

        CityMetrics(
            cityName: "Milan", country: "Italy", region: "Europe",
            avgCapRate: 4.5, avgVacancyRate: 8.0,
            avgOpExPerSqm: 65.0, avgGPIPerSqm: 380.0,
            avgADR: 195.0, avgOccupancyRate: 76.0, avgRevPAR: 148.2,
            typicalDaylighting: 52.0, typicalCoolingDegreeDays: 340,
            avgInterestRate: 4.2, avgPropertyTaxRate: 0.76,
            avgConstructionCostPerSqm: 3000.0, avgInsuranceRatePerSqm: 13.0
        ),
        CityMetrics(
            cityName: "Rome", country: "Italy", region: "Europe",
            avgCapRate: 5.0, avgVacancyRate: 10.0,
            avgOpExPerSqm: 55.0, avgGPIPerSqm: 280.0,
            avgADR: 185.0, avgOccupancyRate: 75.0, avgRevPAR: 138.75,
            typicalDaylighting: 60.0, typicalCoolingDegreeDays: 480,
            avgInterestRate: 4.2, avgPropertyTaxRate: 0.76,
            avgConstructionCostPerSqm: 2400.0, avgInsuranceRatePerSqm: 12.0
        ),
        CityMetrics(
            cityName: "Venice", country: "Italy", region: "Europe",
            avgCapRate: 4.8, avgVacancyRate: 6.5,
            avgOpExPerSqm: 60.0, avgGPIPerSqm: 310.0,
            avgADR: 210.0, avgOccupancyRate: 72.0, avgRevPAR: 151.2,
            typicalDaylighting: 54.0, typicalCoolingDegreeDays: 310,
            avgInterestRate: 4.2, avgPropertyTaxRate: 0.76,
            avgConstructionCostPerSqm: 2600.0, avgInsuranceRatePerSqm: 13.0
        ),

        // ── IRELAND ────────────────────────────────────────────────────────────

        CityMetrics(
            cityName: "Dublin", country: "Ireland", region: "Europe",
            avgCapRate: 5.0, avgVacancyRate: 8.0,
            avgOpExPerSqm: 65.0, avgGPIPerSqm: 360.0,
            avgADR: 185.0, avgOccupancyRate: 79.0, avgRevPAR: 146.15,
            typicalDaylighting: 36.0, typicalCoolingDegreeDays: 10,
            avgInterestRate: 4.0, avgPropertyTaxRate: 0.3,
            avgConstructionCostPerSqm: 3500.0, avgInsuranceRatePerSqm: 18.0
        ),

        // ── AUSTRIA ────────────────────────────────────────────────────────────

        CityMetrics(
            cityName: "Vienna", country: "Austria", region: "Europe",
            avgCapRate: 4.5, avgVacancyRate: 5.5,
            avgOpExPerSqm: 60.0, avgGPIPerSqm: 290.0,
            avgADR: 155.0, avgOccupancyRate: 74.0, avgRevPAR: 114.7,
            typicalDaylighting: 48.0, typicalCoolingDegreeDays: 210,
            avgInterestRate: 3.8, avgPropertyTaxRate: 0.3,
            avgConstructionCostPerSqm: 2800.0, avgInsuranceRatePerSqm: 13.0
        ),

        // ── SWITZERLAND ────────────────────────────────────────────────────────

        CityMetrics(
            cityName: "Zurich", country: "Switzerland", region: "Europe",
            avgCapRate: 3.5, avgVacancyRate: 4.5,
            avgOpExPerSqm: 95.0, avgGPIPerSqm: 550.0,
            avgADR: 280.0, avgOccupancyRate: 72.0, avgRevPAR: 201.6,
            typicalDaylighting: 50.0, typicalCoolingDegreeDays: 140,
            avgInterestRate: 1.5, avgPropertyTaxRate: 0.2,
            avgConstructionCostPerSqm: 5500.0, avgInsuranceRatePerSqm: 28.0
        ),
        CityMetrics(
            cityName: "Geneva", country: "Switzerland", region: "Europe",
            avgCapRate: 3.5, avgVacancyRate: 5.0,
            avgOpExPerSqm: 95.0, avgGPIPerSqm: 520.0,
            avgADR: 270.0, avgOccupancyRate: 70.0, avgRevPAR: 189.0,
            typicalDaylighting: 50.0, typicalCoolingDegreeDays: 155,
            avgInterestRate: 1.5, avgPropertyTaxRate: 0.2,
            avgConstructionCostPerSqm: 5200.0, avgInsuranceRatePerSqm: 27.0
        ),

        // ── BELGIUM ────────────────────────────────────────────────────────────

        CityMetrics(
            cityName: "Brussels", country: "Belgium", region: "Europe",
            avgCapRate: 5.0, avgVacancyRate: 10.5,
            avgOpExPerSqm: 60.0, avgGPIPerSqm: 280.0,
            avgADR: 145.0, avgOccupancyRate: 70.0, avgRevPAR: 101.5,
            typicalDaylighting: 38.0, typicalCoolingDegreeDays: 55,
            avgInterestRate: 3.9, avgPropertyTaxRate: 1.25,
            avgConstructionCostPerSqm: 2400.0, avgInsuranceRatePerSqm: 13.0
        ),

        // ── NORDICS ────────────────────────────────────────────────────────────

        CityMetrics(
            cityName: "Stockholm", country: "Sweden", region: "Europe",
            avgCapRate: 4.2, avgVacancyRate: 8.0,
            avgOpExPerSqm: 70.0, avgGPIPerSqm: 380.0,
            avgADR: 175.0, avgOccupancyRate: 72.0, avgRevPAR: 126.0,
            typicalDaylighting: 42.0, typicalCoolingDegreeDays: 30,
            avgInterestRate: 3.5, avgPropertyTaxRate: 0.75,
            avgConstructionCostPerSqm: 3800.0, avgInsuranceRatePerSqm: 16.0
        ),
        CityMetrics(
            cityName: "Copenhagen", country: "Denmark", region: "Europe",
            avgCapRate: 4.0, avgVacancyRate: 7.0,
            avgOpExPerSqm: 72.0, avgGPIPerSqm: 350.0,
            avgADR: 170.0, avgOccupancyRate: 74.0, avgRevPAR: 125.8,
            typicalDaylighting: 40.0, typicalCoolingDegreeDays: 35,
            avgInterestRate: 3.6, avgPropertyTaxRate: 0.6,
            avgConstructionCostPerSqm: 3600.0, avgInsuranceRatePerSqm: 15.0
        ),
        CityMetrics(
            cityName: "Oslo", country: "Norway", region: "Europe",
            avgCapRate: 4.2, avgVacancyRate: 7.5,
            avgOpExPerSqm: 80.0, avgGPIPerSqm: 400.0,
            avgADR: 185.0, avgOccupancyRate: 70.0, avgRevPAR: 129.5,
            typicalDaylighting: 38.0, typicalCoolingDegreeDays: 20,
            avgInterestRate: 4.5, avgPropertyTaxRate: 0.2,
            avgConstructionCostPerSqm: 4500.0, avgInsuranceRatePerSqm: 18.0
        ),
        CityMetrics(
            cityName: "Helsinki", country: "Finland", region: "Europe",
            avgCapRate: 4.5, avgVacancyRate: 9.0,
            avgOpExPerSqm: 65.0, avgGPIPerSqm: 310.0,
            avgADR: 155.0, avgOccupancyRate: 68.0, avgRevPAR: 105.4,
            typicalDaylighting: 36.0, typicalCoolingDegreeDays: 20,
            avgInterestRate: 3.7, avgPropertyTaxRate: 0.35,
            avgConstructionCostPerSqm: 3200.0, avgInsuranceRatePerSqm: 14.0
        ),

        // ── CENTRAL & EASTERN EUROPE ───────────────────────────────────────────

        CityMetrics(
            cityName: "Warsaw", country: "Poland", region: "Europe",
            avgCapRate: 5.5, avgVacancyRate: 12.0,
            avgOpExPerSqm: 42.0, avgGPIPerSqm: 210.0,
            avgADR: 100.0, avgOccupancyRate: 68.0, avgRevPAR: 68.0,
            typicalDaylighting: 42.0, typicalCoolingDegreeDays: 130,
            avgInterestRate: 5.75, avgPropertyTaxRate: 0.4,
            avgConstructionCostPerSqm: 1600.0, avgInsuranceRatePerSqm: 8.0
        ),
        CityMetrics(
            cityName: "Prague", country: "Czech Republic", region: "Europe",
            avgCapRate: 5.2, avgVacancyRate: 10.0,
            avgOpExPerSqm: 40.0, avgGPIPerSqm: 200.0,
            avgADR: 115.0, avgOccupancyRate: 72.0, avgRevPAR: 82.8,
            typicalDaylighting: 44.0, typicalCoolingDegreeDays: 160,
            avgInterestRate: 5.5, avgPropertyTaxRate: 0.2,
            avgConstructionCostPerSqm: 1700.0, avgInsuranceRatePerSqm: 7.0
        ),
        CityMetrics(
            cityName: "Budapest", country: "Hungary", region: "Europe",
            avgCapRate: 5.8, avgVacancyRate: 11.0,
            avgOpExPerSqm: 35.0, avgGPIPerSqm: 170.0,
            avgADR: 100.0, avgOccupancyRate: 70.0, avgRevPAR: 70.0,
            typicalDaylighting: 48.0, typicalCoolingDegreeDays: 280,
            avgInterestRate: 6.5, avgPropertyTaxRate: 0.15,
            avgConstructionCostPerSqm: 1300.0, avgInsuranceRatePerSqm: 6.0
        ),
        CityMetrics(
            cityName: "Bucharest", country: "Romania", region: "Europe",
            avgCapRate: 7.0, avgVacancyRate: 14.0,
            avgOpExPerSqm: 28.0, avgGPIPerSqm: 140.0,
            avgADR: 75.0, avgOccupancyRate: 65.0, avgRevPAR: 48.75,
            typicalDaylighting: 50.0, typicalCoolingDegreeDays: 360,
            avgInterestRate: 7.0, avgPropertyTaxRate: 0.1,
            avgConstructionCostPerSqm: 1100.0, avgInsuranceRatePerSqm: 5.0
        ),

        // ── GREECE ─────────────────────────────────────────────────────────────

        CityMetrics(
            cityName: "Athens", country: "Greece", region: "Europe",
            avgCapRate: 6.0, avgVacancyRate: 11.0,
            avgOpExPerSqm: 38.0, avgGPIPerSqm: 175.0,
            avgADR: 130.0, avgOccupancyRate: 72.0, avgRevPAR: 93.6,
            typicalDaylighting: 70.0, typicalCoolingDegreeDays: 790,
            avgInterestRate: 4.5, avgPropertyTaxRate: 0.35,
            avgConstructionCostPerSqm: 1600.0, avgInsuranceRatePerSqm: 9.0
        ),

        // ── MIDDLE EAST & AFRICA ───────────────────────────────────────────────

        CityMetrics(
            cityName: "Dubai", country: "UAE", region: "MEA",
            avgCapRate: 6.5, avgVacancyRate: 12.0,
            avgOpExPerSqm: 55.0, avgGPIPerSqm: 340.0,
            avgADR: 210.0, avgOccupancyRate: 74.0, avgRevPAR: 155.4,
            typicalDaylighting: 85.0, typicalCoolingDegreeDays: 3100,
            avgInterestRate: 5.5, avgPropertyTaxRate: 0.0,
            avgConstructionCostPerSqm: 1800.0, avgInsuranceRatePerSqm: 11.0
        ),
        CityMetrics(
            cityName: "Abu Dhabi", country: "UAE", region: "MEA",
            avgCapRate: 6.8, avgVacancyRate: 13.0,
            avgOpExPerSqm: 50.0, avgGPIPerSqm: 290.0,
            avgADR: 175.0, avgOccupancyRate: 68.0, avgRevPAR: 119.0,
            typicalDaylighting: 85.0, typicalCoolingDegreeDays: 3200,
            avgInterestRate: 5.5, avgPropertyTaxRate: 0.0,
            avgConstructionCostPerSqm: 1700.0, avgInsuranceRatePerSqm: 10.5
        ),
        CityMetrics(
            cityName: "Riyadh", country: "Saudi Arabia", region: "MEA",
            avgCapRate: 7.0, avgVacancyRate: 14.0,
            avgOpExPerSqm: 45.0, avgGPIPerSqm: 250.0,
            avgADR: 150.0, avgOccupancyRate: 62.0, avgRevPAR: 93.0,
            typicalDaylighting: 90.0, typicalCoolingDegreeDays: 3600,
            avgInterestRate: 5.5, avgPropertyTaxRate: 0.0,
            avgConstructionCostPerSqm: 1400.0, avgInsuranceRatePerSqm: 9.0
        ),
        CityMetrics(
            cityName: "Casablanca", country: "Morocco", region: "MEA",
            avgCapRate: 7.5, avgVacancyRate: 15.0,
            avgOpExPerSqm: 30.0, avgGPIPerSqm: 180.0,
            avgADR: 90.0, avgOccupancyRate: 62.0, avgRevPAR: 55.8,
            typicalDaylighting: 72.0, typicalCoolingDegreeDays: 680,
            avgInterestRate: 5.0, avgPropertyTaxRate: 0.5,
            avgConstructionCostPerSqm: 900.0, avgInsuranceRatePerSqm: 6.5
        ),

        // ── AMERICAS ───────────────────────────────────────────────────────────

        CityMetrics(
            cityName: "New York", country: "United States", region: "Americas",
            avgCapRate: 4.5, avgVacancyRate: 13.0,
            avgOpExPerSqm: 120.0, avgGPIPerSqm: 900.0,
            avgADR: 320.0, avgOccupancyRate: 83.0, avgRevPAR: 265.6,
            typicalDaylighting: 52.0, typicalCoolingDegreeDays: 680,
            avgInterestRate: 7.0, avgPropertyTaxRate: 1.1,
            avgConstructionCostPerSqm: 5500.0, avgInsuranceRatePerSqm: 32.0
        ),
        CityMetrics(
            cityName: "Miami", country: "United States", region: "Americas",
            avgCapRate: 5.0, avgVacancyRate: 9.0,
            avgOpExPerSqm: 85.0, avgGPIPerSqm: 540.0,
            avgADR: 240.0, avgOccupancyRate: 78.0, avgRevPAR: 187.2,
            typicalDaylighting: 72.0, typicalCoolingDegreeDays: 2200,
            avgInterestRate: 7.0, avgPropertyTaxRate: 1.3,
            avgConstructionCostPerSqm: 3000.0, avgInsuranceRatePerSqm: 38.0
        ),
        CityMetrics(
            cityName: "São Paulo", country: "Brazil", region: "Americas",
            avgCapRate: 8.0, avgVacancyRate: 18.0,
            avgOpExPerSqm: 35.0, avgGPIPerSqm: 200.0,
            avgADR: 110.0, avgOccupancyRate: 65.0, avgRevPAR: 71.5,
            typicalDaylighting: 65.0, typicalCoolingDegreeDays: 1400,
            avgInterestRate: 12.0, avgPropertyTaxRate: 1.0,
            avgConstructionCostPerSqm: 1200.0, avgInsuranceRatePerSqm: 9.0
        ),

        // ── ASIA-PACIFIC ───────────────────────────────────────────────────────

        CityMetrics(
            cityName: "Singapore", country: "Singapore", region: "APAC",
            avgCapRate: 4.0, avgVacancyRate: 8.0,
            avgOpExPerSqm: 90.0, avgGPIPerSqm: 600.0,
            avgADR: 260.0, avgOccupancyRate: 83.0, avgRevPAR: 215.8,
            typicalDaylighting: 65.0, typicalCoolingDegreeDays: 3800,
            avgInterestRate: 4.0, avgPropertyTaxRate: 0.4,
            avgConstructionCostPerSqm: 3800.0, avgInsuranceRatePerSqm: 18.0
        ),
        CityMetrics(
            cityName: "Tokyo", country: "Japan", region: "APAC",
            avgCapRate: 3.5, avgVacancyRate: 4.0,
            avgOpExPerSqm: 85.0, avgGPIPerSqm: 480.0,
            avgADR: 200.0, avgOccupancyRate: 80.0, avgRevPAR: 160.0,
            typicalDaylighting: 52.0, typicalCoolingDegreeDays: 1200,
            avgInterestRate: 1.0, avgPropertyTaxRate: 0.3,
            avgConstructionCostPerSqm: 3500.0, avgInsuranceRatePerSqm: 14.0
        ),
        CityMetrics(
            cityName: "Sydney", country: "Australia", region: "APAC",
            avgCapRate: 5.0, avgVacancyRate: 10.0,
            avgOpExPerSqm: 80.0, avgGPIPerSqm: 450.0,
            avgADR: 220.0, avgOccupancyRate: 78.0, avgRevPAR: 171.6,
            typicalDaylighting: 65.0, typicalCoolingDegreeDays: 800,
            avgInterestRate: 6.2, avgPropertyTaxRate: 0.35,
            avgConstructionCostPerSqm: 3200.0, avgInsuranceRatePerSqm: 15.0
        ),
        CityMetrics(
            cityName: "Hong Kong", country: "China SAR", region: "APAC",
            avgCapRate: 3.2, avgVacancyRate: 14.0,
            avgOpExPerSqm: 110.0, avgGPIPerSqm: 750.0,
            avgADR: 245.0, avgOccupancyRate: 80.0, avgRevPAR: 196.0,
            typicalDaylighting: 55.0, typicalCoolingDegreeDays: 1800,
            avgInterestRate: 4.5, avgPropertyTaxRate: 0.0,
            avgConstructionCostPerSqm: 5000.0, avgInsuranceRatePerSqm: 25.0
        ),
    ]

    // MARK: - Lookup API

    /// Returns the benchmark for `city`, case-insensitively matching on either
    /// `cityName` or common aliases (e.g. "Lisboa" → "Lisbon").
    /// Falls back to a national average if no city match is found.
    static func benchmark(for city: String) -> CityMetrics? {
        let query = city.trimmingCharacters(in: .whitespaces).lowercased()
        if query.isEmpty { return nil }

        // Direct match
        if let exact = benchmarks.first(where: { $0.cityName.lowercased() == query }) {
            return exact
        }

        // Alias map: alternate spellings → canonical city name
        let aliases: [String: String] = [
            "lisboa":        "Lisbon",
            "lisbonne":      "Lisbon",
            "lissabon":      "Lisbon",
            "porto":         "Porto",
            "oporto":        "Porto",
            "nueva york":    "New York",
            "nyc":           "New York",
            "ny":            "New York",
            "rome":          "Rome",
            "roma":          "Rome",
            "munich":        "Munich",
            "münchen":       "Munich",
            "muenchen":      "Munich",
            "cologne":       "Frankfurt",
            "köln":          "Frankfurt",
            "wien":          "Vienna",
            "vienne":        "Vienna",
            "zuerich":       "Zurich",
            "zürich":        "Zurich",
            "genève":        "Geneva",
            "genf":          "Geneva",
            "bruxelles":     "Brussels",
            "brüssel":       "Brussels",
            "venecia":       "Venice",
            "venezia":       "Venice",
            "atenas":        "Athens",
            "athènes":       "Athens",
            "athína":        "Athens",
            "dubai city":    "Dubai",
            "hong-kong":     "Hong Kong",
            "singapour":     "Singapore",
            "tokio":         "Tokyo",
            "sao paulo":     "São Paulo",
        ]

        if let canonical = aliases[query],
           let aliased = benchmarks.first(where: { $0.cityName == canonical }) {
            return aliased
        }

        // Prefix / contains fallback (city-level)
        if let partial = benchmarks.first(where: { $0.cityName.lowercased().hasPrefix(query) })
                      ?? benchmarks.first(where: { $0.cityName.lowercased().contains(query) }) {
            return partial
        }

        // ── National average fallback ──────────────────────────────────────────
        // If the query matches a country name, return a computed national average.
        return nationalAverage(for: query)
    }

    /// Returns a `CityMetrics` representing the numeric average of all cities
    /// in `country`. Returns `nil` if no cities for that country are found.
    static func nationalAverage(for country: String) -> CityMetrics? {
        let q     = country.lowercased()
        let cities = benchmarks.filter { $0.country.lowercased() == q
                                      || $0.country.lowercased().hasPrefix(q) }
        guard !cities.isEmpty else { return nil }

        let n = Double(cities.count)
        func avg(_ kp: KeyPath<CityMetrics, Double>) -> Double {
            cities.reduce(0) { $0 + $1[keyPath: kp] } / n
        }

        return CityMetrics(
            cityName: "\(cities[0].country) (National Avg)",
            country:   cities[0].country,
            region:    cities[0].region,
            avgCapRate:        avg(\.avgCapRate),
            avgVacancyRate:    avg(\.avgVacancyRate),
            avgOpExPerSqm:     avg(\.avgOpExPerSqm),
            avgGPIPerSqm:      avg(\.avgGPIPerSqm),
            avgADR:            avg(\.avgADR),
            avgOccupancyRate:  avg(\.avgOccupancyRate),
            avgRevPAR:         avg(\.avgRevPAR),
            typicalDaylighting:       avg(\.typicalDaylighting),
            typicalCoolingDegreeDays: avg(\.typicalCoolingDegreeDays),
            avgInterestRate:             avg(\.avgInterestRate),
            avgPropertyTaxRate:          avg(\.avgPropertyTaxRate),
            avgConstructionCostPerSqm:   avg(\.avgConstructionCostPerSqm),
            avgInsuranceRatePerSqm:      avg(\.avgInsuranceRatePerSqm)
        )
    }

    /// Returns up to `limit` cities whose names start with `prefix` (case-insensitive).
    static func suggestions(matching prefix: String, limit: Int = 6) -> [CityMetrics] {
        let q = prefix.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return [] }
        let starts   = benchmarks.filter { $0.cityName.lowercased().hasPrefix(q) }
        let contains = benchmarks.filter { !$0.cityName.lowercased().hasPrefix(q) && $0.cityName.lowercased().contains(q) }
        return Array((starts + contains).prefix(limit))
    }

    static var regions: [String] { Array(Set(benchmarks.map(\.region))).sorted() }
    static func cities(in region: String) -> [CityMetrics] {
        benchmarks.filter { $0.region == region }
    }
}
