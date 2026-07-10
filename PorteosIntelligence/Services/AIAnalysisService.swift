import Foundation
import SwiftData

// MARK: - VibeGrade

enum VibeGrade: String {
    case a = "A"
    case b = "B"
    case c = "C"
    case d = "D"
    case f = "F"

    var label: String {
        switch self {
        case .a: return "EXCEPTIONAL"
        case .b: return "STRONG"
        case .c: return "MODERATE"
        case .d: return "WEAK"
        case .f: return "CRITICAL"
        }
    }

    var hexColor: String {
        switch self {
        case .a: return "#10B981"
        case .b: return "#3B82F6"
        case .c: return "#F59E0B"
        case .d: return "#F97316"
        case .f: return "#EF4444"
        }
    }

    static func from(score: Double?) -> VibeGrade {
        guard let s = score else { return .f }
        if s >= 80 { return .a }
        if s >= 65 { return .b }
        if s >= 50 { return .c }
        if s >= 35 { return .d }
        return .f
    }
}

// MARK: - AnalysisSignal

struct AnalysisSignal {

    enum Sentiment { case positive, neutral, warning, critical }

    /// Actionable suggestion attached to a signal.
    /// `applyBenchmark` carries the benchmark value and the `PropertyDeal`
    /// key-path string so `AIVibePanel` can apply it with a single tap.
    enum Action {
        case applyBenchmark(value: Double, field: String)
    }

    let sentiment: Sentiment
    let message:   String
    let action:    Action?

    init(_ message: String, sentiment: Sentiment, action: Action? = nil) {
        self.message   = message
        self.sentiment = sentiment
        self.action    = action
    }

    var prefix: String {
        switch sentiment {
        case .positive: return "+"
        case .neutral:  return "·"
        case .warning:  return "~"
        case .critical: return "!"
        }
    }
}

// MARK: - DealVerdict

enum DealVerdict {
    case go       // Grade A or B  (score ≥ 65)
    case review   // Grade C       (score 50–64)
    case noGo     // Grade D or F  (score < 50)

    static func from(grade: VibeGrade) -> DealVerdict {
        switch grade {
        case .a, .b: return .go
        case .c:     return .review
        case .d, .f: return .noGo
        }
    }

    var label: String {
        switch self {
        case .go:     return "GO"
        case .review: return "REVIEW"
        case .noGo:   return "NO GO"
        }
    }

    var hexColor: String {
        switch self {
        case .go:     return "#27C93F"
        case .review: return "#FFBD2E"
        case .noGo:   return "#FF5F56"
        }
    }
}

// MARK: - AnalysisResult

struct AnalysisResult {
    let grade:                      VibeGrade
    let verdict:                    DealVerdict
    let headline:                   String
    let realEstateSignals:          [AnalysisSignal]
    let hospitalitySignals:         [AnalysisSignal]
    let designSignals:              [AnalysisSignal]
    let circularSignals:            [AnalysisSignal]
    let marketIntelligenceSignals:  [AnalysisSignal]
    let summary:                    String
    let formattedText:              String
    /// Parsed SWOT sections from LLM output. Nil when LLM was offline.
    let swot:                       SWOTAnalysis?

    var allSignals: [AnalysisSignal] {
        realEstateSignals + hospitalitySignals + designSignals + circularSignals + marketIntelligenceSignals
    }
    var positiveCount: Int { allSignals.filter { $0.sentiment == .positive }.count }
    var warningCount:  Int { allSignals.filter { $0.sentiment == .warning  }.count }
    var criticalCount: Int { allSignals.filter { $0.sentiment == .critical }.count }
    var activeProfileCount: Int {
        [!realEstateSignals.isEmpty, !hospitalitySignals.isEmpty,
         !designSignals.isEmpty,     !circularSignals.isEmpty].filter { $0 }.count
    }
}

struct SWOTAnalysis {
    let strength:    String
    let weakness:    String
    let opportunity: String
    let threat:      String
    let verdict:     DealVerdict   // as parsed from LLM; may differ from rule-based
}

// MARK: - AnalysisPhase

enum AnalysisPhase: Equatable {
    case analyzingRules
    case generatingNarrative
    case done(llmOffline: Bool)
}

// MARK: - AIAnalysisService

final class AIAnalysisService {

    static let shared = AIAnalysisService()
    private init() {}

    // MARK: Public API

    /// Runs rule-based signal analysis then attempts an LLM narrative via Ollama.
    /// `llmStatus` is set on `MainActor` so the UI can reflect loading phases.
    /// If Ollama is offline or times out, falls back to rule-based summary only.
    func analyze(
        _ deal: PropertyDeal,
        context: ModelContext? = nil,
        onPhaseChange: (@MainActor (AnalysisPhase) -> Void)? = nil
    ) async -> AnalysisResult {

        // ── Phase 1: rule-based signals ───────────────────────────────────────
        await notifyPhase(.analyzingRules, handler: onPhaseChange)

        let re   = analyzeRealEstate(deal)
        let hosp = analyzeHospitality(deal)
        let des  = analyzeDesign(deal)
        let circ = analyzeCircular(deal)
        let mkt  = context.map { analyzeMarketIntelligence(deal, context: $0) } ?? []
        let grade    = VibeGrade.from(score: deal.porteosScore)
        let headline = buildHeadline(deal: deal, grade: grade)
        let ruleSummary = buildSummary(re: re, hosp: hosp, des: des, circ: circ, mkt: mkt, grade: grade)

        // ── Phase 2: LLM SWOT (optional, non-blocking) ────────────────────────
        await notifyPhase(.generatingNarrative, handler: onPhaseChange)

        let allSignalMessages = (re + hosp + des + circ + mkt).map(\.message)
        var finalSummary = ruleSummary
        var llmOffline   = false
        var swot: SWOTAnalysis? = nil

        // Resolve city benchmark — used to ground the LLM in local market norms
        let cityBenchmark = MarketBenchmarks.benchmark(for: deal.locationCity)

        do {
            let raw = try await LLMAnalysisService.shared.generateSWOT(
                dealName:  deal.propertyName.isEmpty ? "Untitled Deal" : deal.propertyName,
                grade:     "\(grade.rawValue) — \(grade.label)",
                score:     deal.porteosScore,
                signals:   allSignalMessages,
                benchmark: cityBenchmark
            )
            swot = parseSWOT(from: raw, fallbackGrade: grade)
            if let s = swot {
                finalSummary = formatSWOTSummary(s) + "\n\n" + ruleSummary
            } else {
                finalSummary = raw + "\n\n" + ruleSummary
            }
        } catch {
            llmOffline = true
        }

        await notifyPhase(.done(llmOffline: llmOffline), handler: onPhaseChange)

        let text = formatText(deal: deal, grade: grade,
                              re: re, hosp: hosp, des: des, circ: circ, mkt: mkt,
                              summary: finalSummary)
        return AnalysisResult(
            grade:                     grade,
            verdict:                   DealVerdict.from(grade: grade),
            headline:                  headline,
            realEstateSignals:         re,
            hospitalitySignals:        hosp,
            designSignals:             des,
            circularSignals:           circ,
            marketIntelligenceSignals: mkt,
            summary:                   finalSummary,
            formattedText:             text,
            swot:                      swot
        )
    }

    private func notifyPhase(
        _ phase: AnalysisPhase,
        handler: (@MainActor (AnalysisPhase) -> Void)?
    ) async {
        guard let handler else { return }
        await MainActor.run { handler(phase) }
    }

    // MARK: Market Intelligence Analysis

    private func analyzeMarketIntelligence(_ d: PropertyDeal, context: ModelContext) -> [AnalysisSignal] {
        var s: [AnalysisSignal] = []

        // ── Cap rate trend ─────────────────────────────────────────────────────
        let capRateTrend = TrendAnalyzer.calculateTrend(
            for: d.locationCity, profile: "realEstate", metric: "capRate", context: context
        )
        if capRateTrend.confidence > 0 {
            if capRateTrend.direction == .down && capRateTrend.strength > 10 {
                s.append(.init(
                    "Cap rates in \(d.locationCity) falling \(f1(abs(capRateTrend.strength)))% over 6 months — market cooling",
                    sentiment: .warning
                ))
            } else if capRateTrend.direction == .down && capRateTrend.strength > 5 {
                s.append(.init(
                    "Cap rates in \(d.locationCity) trending down \(f1(abs(capRateTrend.strength)))% — monitor yield compression",
                    sentiment: .neutral
                ))
            } else if capRateTrend.direction == .up && capRateTrend.strength > 5 {
                s.append(.init(
                    "Cap rates in \(d.locationCity) expanding \(f1(capRateTrend.strength))% — improving yield environment",
                    sentiment: .positive
                ))
            }
            if capRateTrend.volatility > capRateTrend.current * 0.15 {
                s.append(.init(
                    "\(d.locationCity) cap rate volatility is high — \(f1(capRateTrend.volatility))pp std dev; underwriting risk elevated",
                    sentiment: .warning
                ))
            }
        }

        // ── ADR trend (hospitality) ────────────────────────────────────────────
        if d.hospitalityRoomCount > 0 || d.hospitalityADR > 0 {
            let adrTrend = TrendAnalyzer.calculateTrend(
                for: d.locationCity, profile: "hospitality", metric: "adr", context: context
            )
            if adrTrend.confidence > 0 {
                if adrTrend.direction == .up && adrTrend.strength > 5 {
                    s.append(.init(
                        "ADR in \(d.locationCity) rising \(f1(adrTrend.strength))% over 6 months — rate uplift potential",
                        sentiment: .positive
                    ))
                } else if adrTrend.direction == .down && adrTrend.strength > 5 {
                    s.append(.init(
                        "ADR in \(d.locationCity) declining \(f1(abs(adrTrend.strength)))% — hospitality pricing headwind",
                        sentiment: .warning
                    ))
                }
            }
        }

        // ── Market heat ────────────────────────────────────────────────────────
        let marketHeat = TrendAnalyzer.calculateMarketHeat(for: d.locationCity, context: context)
        switch marketHeat.level {
        case "HOT":
            s.append(.init(
                "\(d.locationCity) market is HOT — \(f1(marketHeat.importVelocity)) deals/week, prices \(marketHeat.priceVelocity >= 0 ? "+" : "")\(f1(marketHeat.priceVelocity))%/month",
                sentiment: .warning   // hot market = potential overpay risk
            ))
        case "WARM":
            s.append(.init(
                "\(d.locationCity) market is WARM — active deal flow at \(f1(marketHeat.importVelocity)) deals/week",
                sentiment: .neutral
            ))
        case "COLD":
            s.append(.init(
                "\(d.locationCity) market is COLD — low deal velocity, potential buying opportunity",
                sentiment: .neutral
            ))
        default: break   // COOL = no signal needed
        }
        if marketHeat.acquisitionRate > 0.3 {
            s.append(.init(
                "High acquisition rate in \(d.locationCity) (\(Int(marketHeat.acquisitionRate * 100))% of imports converted) — proven market for your strategy",
                sentiment: .positive
            ))
        }

        // ── Portfolio fit ──────────────────────────────────────────────────────
        let userFit = PortfolioLearningEngine.calculateDealFitScore(deal: d, context: context)
        if userFit >= 80 {
            s.append(.init(
                "Strong fit for your portfolio strategy — fit score \(Int(userFit)) / 100",
                sentiment: .positive
            ))
        } else if userFit >= 60 {
            s.append(.init(
                "Moderate fit for your typical strategy — fit score \(Int(userFit)) / 100",
                sentiment: .neutral
            ))
        } else if userFit < 40 {
            s.append(.init(
                "Low fit for your typical strategy — fit score \(Int(userFit)) / 100; review against acquisition criteria",
                sentiment: .warning
            ))
        }

        return s
    }

    // MARK: Real Estate Analysis

    private func analyzeRealEstate(_ d: PropertyDeal) -> [AnalysisSignal] {
        guard d.grossPotentialIncome > 0 || d.purchasePrice > 0 else { return [] }

        let m = RealEstateCalculator.calculateFull(inputs: .init(
            grossPotentialIncome:   d.grossPotentialIncome,
            vacancyRate:            d.vacancyRate,
            otherIncome:            d.otherIncome,
            operatingExpenses:      d.operatingExpenses,
            opexPropertyManagement: d.opexPropertyManagement,
            opexPropertyTax:        d.opexPropertyTax,
            opexInsurance:          d.opexInsurance,
            opexUtilities:          d.opexUtilities,
            opexMaintenance:        d.opexMaintenance,
            opexCapitalReserves:    d.opexCapitalReserves,
            purchasePrice:          d.purchasePrice,
            closingCosts:           d.closingCosts,
            renovationBudget:       d.renovationBudget,
            loanAmount:             d.loanAmount,
            interestRate:           d.interestRate,
            amortizationMonths:     d.amortizationMonths,
            exitCapRate:            d.exitCapRate
        ))

        var s: [AnalysisSignal] = []

        // Cap Rate
        if m.capRate > 7.0 {
            s.append(.init("Cap rate \(f1(m.capRate))% — strong yield profile", sentiment: .positive))
        } else if m.capRate >= 5.0 {
            s.append(.init("Cap rate \(f1(m.capRate))% — acceptable, not exceptional", sentiment: .neutral))
        } else if m.capRate > 0 {
            s.append(.init("Cap rate \(f1(m.capRate))% — compressed yield risk", sentiment: .warning))
        }

        // LTV
        if m.loanToValue > 80 {
            s.append(.init("LTV \(f1(m.loanToValue))% — highly leveraged position", sentiment: .warning))
        } else if m.loanToValue > 0 {
            s.append(.init("LTV \(f1(m.loanToValue))% — conservative leverage position", sentiment: .positive))
        }

        // DSCR
        if m.debtServiceCoverageRatio > 0 {
            if m.debtServiceCoverageRatio < 1.0 {
                s.append(.init("DSCR \(f2(m.debtServiceCoverageRatio))x — cash flow below debt obligation", sentiment: .critical))
            } else if m.debtServiceCoverageRatio < 1.25 {
                s.append(.init("DSCR \(f2(m.debtServiceCoverageRatio))x — debt service pressure detected", sentiment: .warning))
            } else {
                s.append(.init("DSCR \(f2(m.debtServiceCoverageRatio))x — healthy debt coverage", sentiment: .positive))
            }
        }

        // Vacancy
        if d.vacancyRate > 10 {
            s.append(.init("Vacancy \(f1(d.vacancyRate))% — above market; income erosion risk", sentiment: .warning))
        } else if d.vacancyRate > 0 {
            s.append(.init("Vacancy \(f1(d.vacancyRate))% — within market norms", sentiment: .neutral))
        }

        // Cash-on-Cash
        if m.cashOnCashReturn >= 8.0 {
            s.append(.init("Cash-on-cash \(f1(m.cashOnCashReturn))% — strong equity yield", sentiment: .positive))
        } else if m.cashOnCashReturn < 0 {
                s.append(.init("Cash-on-cash \(f1(m.cashOnCashReturn))% — equity drawdown risk", sentiment: .critical))
        }

        // ── Market Benchmark Signals ─────────────────────────────────────────
        if let bm = MarketBenchmarks.benchmark(for: d.locationCity) {

            // Interest rate vs market
            if d.interestRate > 0 && bm.avgInterestRate > 0 {
                let delta = d.interestRate - bm.avgInterestRate
                if delta > 0.5 {
                    s.append(.init(
                        "Interest rate \(f2(d.interestRate))% is \(f2(delta))pp above \(bm.cityName) avg (\(f2(bm.avgInterestRate))%) — refinancing may improve DSCR",
                        sentiment: .warning,
                        action: .applyBenchmark(value: bm.avgInterestRate, field: "interestRate")
                    ))
                } else if delta < -0.5 {
                    s.append(.init(
                        "Interest rate \(f2(d.interestRate))% is \(f2(abs(delta)))pp below \(bm.cityName) avg — favourable financing terms",
                        sentiment: .positive
                    ))
                }
            }

            // Vacancy vs market benchmark
            if d.vacancyRate > 0 && bm.avgVacancyRate > 0 {
                let delta = d.vacancyRate - bm.avgVacancyRate
                if delta > 2.0 {
                    s.append(.init(
                        "Vacancy \(f1(d.vacancyRate))% is \(f1(delta))pp above \(bm.cityName) avg (\(f1(bm.avgVacancyRate))%) — above-market exposure",
                        sentiment: .warning,
                        action: .applyBenchmark(value: bm.avgVacancyRate, field: "vacancyRate")
                    ))
                } else if delta < -2.0 {
                    s.append(.init(
                        "Vacancy \(f1(d.vacancyRate))% is \(f1(abs(delta)))pp below \(bm.cityName) avg — occupancy advantage",
                        sentiment: .positive
                    ))
                }
            }

            // Cap rate vs market benchmark
            if m.capRate > 0 {
                let delta = m.capRate - bm.avgCapRate
                if delta > 1.0 {
                    s.append(.init(
                        "Cap rate \(f1(m.capRate))% is \(f1(delta))pp above \(bm.cityName) avg (\(f1(bm.avgCapRate))%) — above-market yield premium",
                        sentiment: .positive
                    ))
                } else if delta < -1.0 {
                    s.append(.init(
                        "Cap rate \(f1(m.capRate))% is \(f1(abs(delta)))pp below \(bm.cityName) avg (\(f1(bm.avgCapRate))%) — compressed yield vs local market",
                        sentiment: .warning
                    ))
                }
            }

            // Property tax reasonableness check
            if d.opexPropertyTax > 0 && bm.avgPropertyTaxRate > 0 && d.purchasePrice > 0 {
                let expectedTax = d.purchasePrice * bm.avgPropertyTaxRate / 100
                if d.opexPropertyTax > expectedTax * 1.25 {
                    s.append(.init(
                        "Property tax €\(f0(d.opexPropertyTax)) is >25% above \(bm.cityName) typical (\(f1(bm.avgPropertyTaxRate))% of value = €\(f0(expectedTax))) — verify assessment",
                        sentiment: .warning
                    ))
                }
            }

            // Insurance rate per sqm check
            if d.opexInsurance > 0 && d.totalArea > 0 && bm.avgInsuranceRatePerSqm > 0 {
                let actualPerSqm  = d.opexInsurance / d.totalArea
                let benchmarkRate = bm.avgInsuranceRatePerSqm
                if actualPerSqm > benchmarkRate * 1.5 {
                    s.append(.init(
                        "Insurance €\(f0(actualPerSqm))/m² exceeds \(bm.cityName) avg €\(f0(benchmarkRate))/m² by >\(f0((actualPerSqm/benchmarkRate - 1)*100))% — review policy",
                        sentiment: .warning
                    ))
                }
            }
        }

        return s
    }

    // MARK: Hospitality Analysis

    private func analyzeHospitality(_ d: PropertyDeal) -> [AnalysisSignal] {
        guard d.hospitalityRoomCount > 0 || d.hospitalityADR > 0 else { return [] }

        let m = HospitalityCalculator.calculateFull(inputs: .init(
            roomCount:        d.hospitalityRoomCount,
            adr:              d.hospitalityADR,
            occupancyRate:    d.hospitalityOccupancyRate,
            fbRevenue:        d.hospitalityFBRevenue,
            spaRevenue:       d.hospitalitySpaRevenue,
            meetingRevenue:   d.hospitalityMeetingRevenue,
            otherRevenue:     d.hospitalityOtherRevenue,
            opExRatio:        d.hospitalityOpExRatio,
            directBookingPct: d.hospitalityDirectBookingPct,
            otaBookingPct:    d.hospitalityOTABookingPct,
            distributionCost: d.hospitalityDistributionCost
        ))

        var s: [AnalysisSignal] = []

        // Occupancy
        if d.hospitalityOccupancyRate > 85 {
            s.append(.init("Occupancy \(f1(d.hospitalityOccupancyRate))% — demand exceeding supply", sentiment: .positive))
        } else if d.hospitalityOccupancyRate >= 70 {
            s.append(.init("Occupancy \(f1(d.hospitalityOccupancyRate))% — stable demand profile", sentiment: .neutral))
        } else if d.hospitalityOccupancyRate > 0 {
            s.append(.init("Occupancy \(f1(d.hospitalityOccupancyRate))% — below optimal threshold", sentiment: .warning))
        }

        // ADR baseline check
        if d.hospitalityADR > 0 {
            if d.hospitalityADR < 96 {
                s.append(.init("ADR €\(f0(d.hospitalityADR)) — rate optimization opportunity", sentiment: .warning))
            } else if d.hospitalityADR >= 120 {
                s.append(.init("ADR €\(f0(d.hospitalityADR)) — above typical market rate", sentiment: .positive))
            } else {
                s.append(.init("ADR €\(f0(d.hospitalityADR)) — within market range", sentiment: .neutral))
            }
        }

        // GOP Margin
        if m.gopMargin >= 40 {
            s.append(.init("GOP margin \(f1(m.gopMargin))% — premium operating efficiency", sentiment: .positive))
        } else if m.gopMargin < 20 && m.gopMargin > 0 {
            s.append(.init("GOP margin \(f1(m.gopMargin))% — below industry threshold", sentiment: .warning))
        }

        // Distribution mix
        if d.hospitalityDirectBookingPct >= 50 {
            s.append(.init("Direct booking \(f1(d.hospitalityDirectBookingPct))% — low OTA dependency", sentiment: .positive))
        } else if d.hospitalityOTABookingPct > 40 {
            s.append(.init("OTA exposure \(f1(d.hospitalityOTABookingPct))% — distribution cost pressure", sentiment: .warning))
        }

        // ── Market Benchmark Signals ─────────────────────────────────────────
        if let bm = MarketBenchmarks.benchmark(for: d.locationCity) {

            // ADR vs market benchmark
            if d.hospitalityADR > 0 && bm.avgADR > 0 {
                let delta = d.hospitalityADR - bm.avgADR
                if delta < -15 {
                    s.append(.init(
                        "ADR €\(f0(d.hospitalityADR)) is €\(f0(abs(delta))) below \(bm.cityName) avg (€\(f0(bm.avgADR))) — consider rate uplift to market level",
                        sentiment: .warning,
                        action: .applyBenchmark(value: bm.avgADR, field: "hospitalityADR")
                    ))
                } else if delta > 20 {
                    s.append(.init(
                        "ADR €\(f0(d.hospitalityADR)) is €\(f0(delta)) above \(bm.cityName) avg — premium positioning confirmed",
                        sentiment: .positive
                    ))
                }
            }

            // Occupancy vs market
            if d.hospitalityOccupancyRate > 0 && bm.avgOccupancyRate > 0 {
                let delta = d.hospitalityOccupancyRate - bm.avgOccupancyRate
                if delta < -5 {
                    s.append(.init(
                        "Occupancy \(f1(d.hospitalityOccupancyRate))% is \(f1(abs(delta)))pp below \(bm.cityName) avg (\(f1(bm.avgOccupancyRate))%) — demand capture gap",
                        sentiment: .warning,
                        action: .applyBenchmark(value: bm.avgOccupancyRate, field: "hospitalityOccupancyRate")
                    ))
                } else if delta > 5 {
                    s.append(.init(
                        "Occupancy \(f1(d.hospitalityOccupancyRate))% is \(f1(delta))pp above \(bm.cityName) avg — demand leadership",
                        sentiment: .positive
                    ))
                }
            }
        }

        return s
    }

    // MARK: Design Analysis

    private func analyzeDesign(_ d: PropertyDeal) -> [AnalysisSignal] {
        guard d.designGFA > 0 || d.designDaylighting > 0 || d.designBiophilicCount > 0 else { return [] }

        var s: [AnalysisSignal] = []

        // Daylighting
        if d.designDaylighting >= 80 {
            s.append(.init("Daylighting \(f1(d.designDaylighting))% — excellent natural light integration", sentiment: .positive))
        } else if d.designDaylighting > 0 && d.designDaylighting < 30 {
            s.append(.init("Daylighting \(f1(d.designDaylighting))% — natural light deficit", sentiment: .warning))
        } else if d.designDaylighting > 0 {
            s.append(.init("Daylighting \(f1(d.designDaylighting))% — acceptable light levels", sentiment: .neutral))
        }

        // Benchmark daylighting vs climate expectation
        if let bm = MarketBenchmarks.benchmark(for: d.locationCity), d.designDaylighting > 0 {
            let delta = d.designDaylighting - bm.typicalDaylighting
            if delta < -15 {
                s.append(.init(
                    "Daylighting \(f1(d.designDaylighting))% is \(f1(abs(delta)))pp below \(bm.cityName) climate typical (\(f1(bm.typicalDaylighting))%) — design underperforming location potential",
                    sentiment: .warning
                ))
            } else if delta > 10 {
                s.append(.init(
                    "Daylighting \(f1(d.designDaylighting))% exceeds \(bm.cityName) climate typical by \(f1(delta))pp — optimised for local conditions",
                    sentiment: .positive
                ))
            }
        }

        // Biophilic elements
        if d.designBiophilicCount > 5 {
            s.append(.init("\(d.designBiophilicCount) biophilic elements — strong biophilic integration", sentiment: .positive))
        } else if d.designBiophilicCount > 0 {
            s.append(.init("\(d.designBiophilicCount) biophilic elements — limited biophilic programming", sentiment: .neutral))
        }

        // Space efficiency
        if d.designGFA > 0 && d.designNIA > 0 {
            let ntg = (d.designNIA / d.designGFA) * 100
            if ntg >= 80 {
                s.append(.init("Net-to-gross \(f1(ntg))% — highly efficient floor plate", sentiment: .positive))
            } else if ntg < 65 {
                s.append(.init("Net-to-gross \(f1(ntg))% — circulation efficiency loss", sentiment: .warning))
            }
        }

        // CO2
        if d.designCO2ppm > 1000 {
            s.append(.init("CO2 \(f0(d.designCO2ppm)) ppm — air quality risk", sentiment: .critical))
        } else if d.designCO2ppm > 0 && d.designCO2ppm < 800 {
            s.append(.init("CO2 \(f0(d.designCO2ppm)) ppm — premium indoor air quality", sentiment: .positive))
        }

        // Thermal comfort
        if d.designThermalComfort >= 90 {
            s.append(.init("Thermal comfort \(f1(d.designThermalComfort))% — premium occupant wellness", sentiment: .positive))
        }

        return s
    }

    // MARK: Circular Analysis

    private func analyzeCircular(_ d: PropertyDeal) -> [AnalysisSignal] {
        guard d.circularKgMaterialsUsed > 0 || d.circularRecycledContentPct > 0 else { return [] }

        let m = CircularEconomyCalculator.calculateFull(inputs: .init(
            totalConstructionCost:  d.circularTotalConstructionCost,
            repurposedMaterialCost: d.circularRepurposedMaterialCost,
            co2Embodied:            d.circularCO2Embodied,
            kgMaterialsUsed:        d.circularKgMaterialsUsed,
            kgMaterialsReturned:    d.circularKgMaterialsReturned,
            kgMaterialsDisposed:    d.circularKgMaterialsDisposed,
            recycledContentPct:     d.circularRecycledContentPct,
            renewableContentPct:    d.circularRenewableContentPct,
            wasteGenerated:         d.circularWasteGenerated,
            operationalCarbon:      d.circularOperationalCarbon,
            buildingAreaM2:         d.circularBuildingAreaM2,
            waterRecyclingRate:     d.circularWaterRecyclingRate
        ))

        var s: [AnalysisSignal] = []

        // Recycled content
        if d.circularRecycledContentPct > 50 {
            s.append(.init("Recycled content \(f1(d.circularRecycledContentPct))% — circular material leadership", sentiment: .positive))
        } else if d.circularRecycledContentPct >= 15 {
            s.append(.init("Recycled content \(f1(d.circularRecycledContentPct))% — progressing toward circularity", sentiment: .neutral))
        } else if d.circularRecycledContentPct > 0 {
            s.append(.init("Recycled content \(f1(d.circularRecycledContentPct))% — below circular standards", sentiment: .warning))
        }

        // Carbon intensity
        if m.carbonIntensity > 0.3 {
            s.append(.init("Carbon intensity \(f3(m.carbonIntensity)) tCO2e/m² — embodied carbon risk", sentiment: .critical))
        } else if m.carbonIntensity > 0 && m.carbonIntensity <= 0.1 {
            s.append(.init("Carbon intensity \(f3(m.carbonIntensity)) tCO2e/m² — within net-zero range", sentiment: .positive))
        } else if m.carbonIntensity > 0 {
            s.append(.init("Carbon intensity \(f3(m.carbonIntensity)) tCO2e/m² — monitor trajectory", sentiment: .neutral))
        }

        // Construction cost vs market benchmark
        if let bm = MarketBenchmarks.benchmark(for: d.locationCity),
           d.circularTotalConstructionCost > 0 && d.circularBuildingAreaM2 > 0 {
            let actualPerSqm   = d.circularTotalConstructionCost / d.circularBuildingAreaM2
            let benchmarkPerSqm = bm.avgConstructionCostPerSqm
            let delta = ((actualPerSqm / benchmarkPerSqm) - 1) * 100
            if delta > 30 {
                s.append(.init(
                    "Construction cost €\(f0(actualPerSqm))/m² is \(f0(delta))% above \(bm.cityName) avg (€\(f0(benchmarkPerSqm))/m²) — review specification or procurement",
                    sentiment: .warning
                ))
            } else if delta < -20 {
                s.append(.init(
                    "Construction cost €\(f0(actualPerSqm))/m² is \(f0(abs(delta)))% below \(bm.cityName) avg — efficient procurement or below-spec risk",
                    sentiment: .neutral
                ))
            }
        }

        // MCI
        if m.mciScore >= 0.8 {
            s.append(.init("MCI \(f2(m.mciScore)) — strong circularity coefficient", sentiment: .positive))
        } else if m.mciScore < 0.6 && m.mciScore > 0 {
            s.append(.init("MCI \(f2(m.mciScore)) — linear model risk", sentiment: .warning))
        }

        // Recovery rate
        if m.recoveryRate >= 80 {
            s.append(.init("Recovery rate \(f1(m.recoveryRate))% — materials loop closed", sentiment: .positive))
        }

        return s
    }

    // MARK: Headline + Summary

    private func buildHeadline(deal: PropertyDeal, grade: VibeGrade) -> String {
        let name = deal.propertyName.isEmpty ? "This asset" : deal.propertyName
        switch grade {
        case .a: return "\(name) presents an exceptional risk/return profile."
        case .b: return "\(name) demonstrates strong fundamentals across active profiles."
        case .c: return "\(name) shows moderate performance with identifiable improvement vectors."
        case .d: return "\(name) carries meaningful risk — remediation required before advancement."
        case .f: return "\(name) signals critical underperformance. Strategic review recommended."
        }
    }

    private func buildSummary(
        re: [AnalysisSignal], hosp: [AnalysisSignal],
        des: [AnalysisSignal], circ: [AnalysisSignal],
        mkt: [AnalysisSignal] = [],
        grade: VibeGrade
    ) -> String {
        let all       = re + hosp + des + circ + mkt
        let positives = all.filter { $0.sentiment == .positive }.count
        let warnings  = all.filter { $0.sentiment == .warning  }.count
        let criticals = all.filter { $0.sentiment == .critical }.count
        let profiles  = [!re.isEmpty, !hosp.isEmpty, !des.isEmpty, !circ.isEmpty].filter { $0 }.count
        let actions   = all.compactMap(\.action).count

        guard profiles > 0 else {
            return "No metric data entered. Add financial, hospitality, design, or circular data to generate a full vibe analysis."
        }

        var parts: [String] = []
        parts.append("Analysis covers \(profiles) active profile\(profiles == 1 ? "" : "s") with \(positives) positive signal\(positives == 1 ? "" : "s"), \(warnings) caution\(warnings == 1 ? "" : "s"), and \(criticals) critical flag\(criticals == 1 ? "" : "s").")

        if actions > 0 {
            parts.append("\(actions) actionable benchmark suggestion\(actions == 1 ? " is" : "s are") available — tap [ APPLY ] on any signal to apply the market value.")
        }

        if criticals > 0 {
            parts.append("Critical issues require resolution before this deal can advance in the pipeline.")
        } else if warnings > 0 && (grade == .b || grade == .c) {
            parts.append("Identified cautions are addressable through targeted operational improvements or renegotiated terms.")
        }

        if grade == .a || grade == .b {
            parts.append("Overall risk/return balance supports advancing this deal through the pipeline.")
        }

        return parts.joined(separator: " ")
    }

    // MARK: Plain-text Formatter

    // MARK: SWOT Parsing

    /// Parses the structured LLM SWOT output into a typed value.
    /// Expected format:
    ///   VERDICT: GO
    ///   S: ...
    ///   W: ...
    ///   O: ...
    ///   T: ...
    private func parseSWOT(from raw: String, fallbackGrade: VibeGrade) -> SWOTAnalysis? {
        var verdictRaw = ""
        var s = ""; var w = ""; var o = ""; var t = ""
        for line in raw.components(separatedBy: "\n") {
            let upper = line.trimmingCharacters(in: .whitespaces)
            if upper.hasPrefix("VERDICT:") { verdictRaw = upper.dropPrefix("VERDICT:").trimmingCharacters(in: .whitespaces) }
            else if upper.hasPrefix("S:") { s = upper.dropPrefix("S:").trimmingCharacters(in: .whitespaces) }
            else if upper.hasPrefix("W:") { w = upper.dropPrefix("W:").trimmingCharacters(in: .whitespaces) }
            else if upper.hasPrefix("O:") { o = upper.dropPrefix("O:").trimmingCharacters(in: .whitespaces) }
            else if upper.hasPrefix("T:") { t = upper.dropPrefix("T:").trimmingCharacters(in: .whitespaces) }
        }
        guard !s.isEmpty, !w.isEmpty, !o.isEmpty, !t.isEmpty else { return nil }
        let verdict: DealVerdict
        switch verdictRaw.uppercased() {
        case "GO":     verdict = .go
        case "NO GO":  verdict = .noGo
        default:       verdict = .review
        }
        return SWOTAnalysis(strength: s, weakness: w, opportunity: o, threat: t, verdict: verdict)
    }

    private func formatSWOTSummary(_ swot: SWOTAnalysis) -> String {
        """
VERDICT: \(swot.verdict.label)
S: \(swot.strength)
W: \(swot.weakness)
O: \(swot.opportunity)
T: \(swot.threat)
"""
    }

    private func formatText(
        deal: PropertyDeal, grade: VibeGrade,
        re: [AnalysisSignal], hosp: [AnalysisSignal],
        des: [AnalysisSignal], circ: [AnalysisSignal],
        mkt: [AnalysisSignal] = [],
        summary: String
    ) -> String {
        var lines: [String] = []
        let name = deal.propertyName.isEmpty ? "UNTITLED DEAL" : deal.propertyName.uppercased()

        lines.append("VIBE CHECK // \(name)")
        if let score = deal.porteosScore {
            lines.append("SCORE: \(Int(score.rounded())) / 100  |  GRADE: \(grade.rawValue)  |  \(grade.label)")
        } else {
            lines.append("GRADE: \(grade.rawValue)  |  \(grade.label)  |  SCORE: PENDING")
        }
        lines.append("")

        func appendSection(_ title: String, _ signals: [AnalysisSignal]) {
            guard !signals.isEmpty else { return }
            lines.append("// \(title)")
            signals.forEach { sig in
                var line = "  \(sig.prefix) \(sig.message)"
                if case .applyBenchmark(let v, let f) = sig.action {
                    line += " [BENCHMARK: \(f)=\(String(format: "%.2f", v))]"
                }
                lines.append(line)
            }
            lines.append("")
        }

        appendSection("REAL ESTATE",           re)
        appendSection("HOSPITALITY",           hosp)
        appendSection("DESIGN",                des)
        appendSection("CIRCULAR ECONOMY",      circ)
        appendSection("MARKET INTELLIGENCE",   mkt)

        lines.append("// ASSESSMENT")
        lines.append(summary)

        return lines.joined(separator: "\n")
    }

    // MARK: Formatters

    private func f0(_ v: Double) -> String { String(format: "%.0f", v) }
    private func f1(_ v: Double) -> String { String(format: "%.1f", v) }
    private func f2(_ v: Double) -> String { String(format: "%.2f", v) }
    private func f3(_ v: Double) -> String { String(format: "%.3f", v) }
}

// MARK: - String helper

private extension String {
    func dropPrefix(_ prefix: String) -> String {
        guard hasPrefix(prefix) else { return self }
        return String(dropFirst(prefix.count))
    }
}
