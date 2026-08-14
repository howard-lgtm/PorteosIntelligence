import Foundation
import CoreGraphics
import CoreText
import AppKit

// MARK: - ReportOptions

struct ReportOptions {
    var includeAIAnalysis: Bool = true
    var includeScenarios:  Bool = true
    var includeValidation: Bool = true
    var darkMode:          Bool = false  // false = light mode (print-safe), true = dark theme
}

// MARK: - PDFReportGenerator
//
// Generates an A4 (595 × 842 pt) PDF report for a PropertyDeal using macOS
// CoreGraphics PDF context. All drawing is done via CGContext + CoreText so
// no UIKit/AppKit view rendering is required.
//
// Pages:
//   1 – Cover / executive summary
//   2 – Real Estate financials (revenue → OpEx → profitability → leverage → returns)
//   3 – Hospitality + Design + Circular Economy performance
//   4 – AI Vibe Assessment          (if options.includeAIAnalysis)
//   5 – Data Validation Log         (if options.includeValidation)
//   6 – Saved Sensitivity Scenarios (if options.includeScenarios && !scenarios.isEmpty)

final class PDFReportGenerator {

    // MARK: – Page geometry

    private let W:  CGFloat = 595   // A4 width  (pts)
    private let H:  CGFloat = 842   // A4 height (pts)
    private let M:  CGFloat = 40    // uniform margin
    private var cW: CGFloat { W - 2 * M }   // content width = 515

    // MARK: – Page state

    private var pageNumber  = 0
    private var darkMode    = false   // set from options each render

    // MARK: – Color resolver (light mode by default, dark mode optional)
    //
    // When darkMode = false (default): Light mode for print
    //   - Inverts shell colors (bg → white, text → black)
    //   - Converts accent colors to grayscale for print-safe output
    //
    // When darkMode = true: Dark theme for visual presentation
    //   - Uses original design-system colors (black bg, white text, colored accents)

    private func c(_ color: CGColor) -> CGColor {
        // Dark mode: return original colors unchanged
        if darkMode { return color }

        // Light mode: convert for print-safe output
        let srgb = color.converted(
            to: CGColorSpace(name: CGColorSpace.sRGB)!,
            intent: .defaultIntent, options: nil
        ) ?? color
        let comp = srgb.components ?? []
        guard comp.count >= 3 else { return color }

        func near(_ a: CGFloat, _ b: CGFloat) -> Bool { abs(a - b) < 0.01 }

        let r = comp[0], g = comp[1], b2 = comp[2]

        // SHELL COLORS: Invert for print
        // Background #0A0A0A → White
        if near(r, 0.039) && near(g, 0.039) && near(b2, 0.039) {
            return NSColor.white.cgColor }
        // Surface #111111 → Light Gray
        if near(r, 0.067) && near(g, 0.067) && near(b2, 0.067) {
            return NSColor(white: 0.96, alpha: 1).cgColor }
        // Border #333333 → Medium Gray
        if near(r, 0.200) && near(g, 0.200) && near(b2, 0.200) {
            return NSColor(white: 0.80, alpha: 1).cgColor }
        // Text Primary #F8F9FA → Black
        if near(r, 0.973) && near(g, 0.976) && near(b2, 0.980) {
            return NSColor.black.cgColor }
        // Text Secondary #94A3B8 → Dark Gray
        if near(r, 0.580) && near(g, 0.639) && near(b2, 0.722) {
            return NSColor(white: 0.30, alpha: 1).cgColor }
        // Text Dim #666666 → Medium Gray
        if near(r, 0.400) && near(g, 0.400) && near(b2, 0.400) {
            return NSColor(white: 0.45, alpha: 1).cgColor }

        // ACCENT COLORS: Convert to grayscale for print
        // Rust    #C25E30 → Dark Gray  (primary accent — headings, section bars)
        if near(r, 0.761) && near(g, 0.369) && near(b2, 0.188) {
            return NSColor(white: 0.30, alpha: 1).cgColor }
        // Red     #EF4444 → Dark Gray  (critical signals)
        if near(r, 0.937) && near(g, 0.267) && near(b2, 0.267) {
            return NSColor(white: 0.30, alpha: 1).cgColor }
        // Green   #10B981 → Medium Gray (positive signals, NOI)
        if near(r, 0.063) && near(g, 0.725) && near(b2, 0.506) {
            return NSColor(white: 0.40, alpha: 1).cgColor }
        // Teal    #14B8A6 → Medium Gray (hospitality accent)
        if near(r, 0.078) && near(g, 0.722) && near(b2, 0.651) {
            return NSColor(white: 0.40, alpha: 1).cgColor }
        // Purple  #A855F7 → Medium Gray (design accent)
        if near(r, 0.659) && near(g, 0.333) && near(b2, 0.969) {
            return NSColor(white: 0.40, alpha: 1).cgColor }
        // Blue    #3B82F6 → Medium Gray (circular accent)
        if near(r, 0.231) && near(g, 0.510) && near(b2, 0.965) {
            return NSColor(white: 0.40, alpha: 1).cgColor }
        // Amber   #F59E0B → Light Gray  (warnings)
        if near(r, 0.961) && near(g, 0.620) && near(b2, 0.043) {
            return NSColor(white: 0.50, alpha: 1).cgColor }

        // Unrecognized colors pass through
        return color
    }

    // MARK: – Color palette  (CGColor – used for fills, strokes, and text)

    private let bg     = CGColor.porteos("#0A0A0A")
    private let surf   = CGColor.porteos("#111111")
    private let border = CGColor.porteos("#333333")
    private let tp1    = CGColor.porteos("#F8F9FA")   // text primary
    private let tp2    = CGColor.porteos("#94A3B8")   // text secondary
    private let tp3    = CGColor.porteos("#666666")   // text dim
    private let rust   = CGColor.porteos("#C25E30")
    private let teal   = CGColor.porteos("#14B8A6")
    private let purple = CGColor.porteos("#A855F7")
    private let blue   = CGColor.porteos("#3B82F6")
    private let green  = CGColor.porteos("#27C93F")
    private let red    = CGColor.porteos("#FF5F56")
    private let amber  = CGColor.porteos("#FFBD2E")

    // MARK: – Fonts

    private func jm(_ size: CGFloat) -> CTFont {
        if let f = NSFont(name: "JetBrains Mono",      size: size) { return f as CTFont }
        if let f = NSFont(name: "JetBrainsMono-Regular", size: size) { return f as CTFont }
        return NSFont.monospacedSystemFont(ofSize: size, weight: .regular) as CTFont
    }

    private func jmB(_ size: CGFloat) -> CTFont {
        if let f = NSFont(name: "JetBrains Mono Bold",  size: size) { return f as CTFont }
        if let f = NSFont(name: "JetBrainsMono-Bold",   size: size) { return f as CTFont }
        return NSFont.monospacedSystemFont(ofSize: size, weight: .bold) as CTFont
    }

    // MARK: – Public API

    func generateReport(
        deal:      PropertyDeal,
        options:   ReportOptions,
        scenarios: [DealScenario] = []
    ) -> Data {
        darkMode = options.darkMode

        let pdfData = NSMutableData()
        guard let consumer = CGDataConsumer(data: pdfData as CFMutableData) else { return Data() }
        var mediaBox = CGRect(x: 0, y: 0, width: W, height: H)
        guard let ctx = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else { return Data() }

        let reM   = RealEstateCalculator.calculateFull(inputs: reInputs(deal))
        let hospM = HospitalityCalculator.calculateFull(inputs: hospInputs(deal))
        let desM  = DesignCalculator.calculateFull(inputs: desInputs(deal))
        let circM = CircularEconomyCalculator.calculateFull(inputs: circInputs(deal))
        let msgs  = DataValidator.validate(deal: deal)

        pageNumber = 0

        startPage(ctx)
        drawCover(ctx, deal: deal, reM: reM)
        ctx.endPDFPage()

        startPage(ctx)
        drawRealEstate(ctx, deal: deal, m: reM)
        drawFooter(ctx, deal: deal)
        ctx.endPDFPage()

        startPage(ctx)
        drawMultiProfile(ctx, deal: deal, hosp: hospM, des: desM, circ: circM)
        drawFooter(ctx, deal: deal)
        ctx.endPDFPage()

        if options.includeAIAnalysis {
            startPage(ctx)
            drawAIAnalysis(ctx, deal: deal)
            drawFooter(ctx, deal: deal)
            ctx.endPDFPage()
        }

        if options.includeValidation {
            startPage(ctx)
            drawValidation(ctx, deal: deal, messages: msgs)
            drawFooter(ctx, deal: deal)
            ctx.endPDFPage()
        }

        if options.includeScenarios && !scenarios.isEmpty {
            startPage(ctx)
            drawScenarios(ctx, deal: deal, scenarios: scenarios)
            drawFooter(ctx, deal: deal)
            ctx.endPDFPage()
        }

        ctx.closePDF()
        return pdfData as Data
    }

    // MARK: – Page management

    private func startPage(_ ctx: CGContext) {
        pageNumber += 1
        ctx.beginPDFPage(nil)
        fill(ctx, CGRect(x: 0, y: 0, width: W, height: H), bg)
    }

    private func drawFooter(_ ctx: CGContext, deal: PropertyDeal) {
        let y: CGFloat = 28
        hline(ctx, x: M, y: y + 12, width: cW, color: border)
        let f = jm(7.5)
        text(ctx, "PORTEOS INTELLIGENCE  //  CONFIDENTIAL", x: M, y: y, font: f, color: tp3)
        let name = deal.propertyName.uppercased()
        let nW = lineWidth(name, font: f)
        text(ctx, name, x: W / 2 - nW / 2, y: y, font: f, color: tp3)
        text(ctx, "PAGE \(pageNumber)", x: 0, y: y, font: f, color: tp3, rightAlignTo: M + cW)
    }

    // MARK: – Page 1: Cover

    private func drawCover(_ ctx: CGContext, deal: PropertyDeal, reM: RealEstateCalculator.FullMetrics) {
        let accent = primaryAccent(deal)

        // ── Top accent stripe ──────────────────────────────────────────────────
        fill(ctx, CGRect(x: 0, y: H - 5, width: W, height: 5), accent)

        // ── App identity ───────────────────────────────────────────────────────
        text(ctx, "PORTEOS INTELLIGENCE TERMINAL",
             x: M, y: H - M - 20, font: jmB(17), color: tp1)

        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm"
        text(ctx, "DEAL ANALYSIS REPORT  //  GENERATED: \(df.string(from: Date()))",
             x: M, y: H - M - 36, font: jm(8.5), color: tp3)

        hline(ctx, x: M, y: H - M - 48, width: cW, color: accent)

        // ── Deal name (large) ──────────────────────────────────────────────────
        let dealName = deal.propertyName.isEmpty ? "UNTITLED DEAL" : deal.propertyName.uppercased()
        text(ctx, dealName, x: M, y: H - M - 88, font: jmB(22), color: tp1)

        let locType = "\(deal.locationCity.uppercased())  //  \(deal.propertyType.uppercased())"
        text(ctx, locType, x: M, y: H - M - 108, font: jm(9.5), color: tp2)

        // Status badge
        let statusColor = statusAccent(deal.status)
        let badgeW: CGFloat = 100
        fill(ctx, CGRect(x: M, y: H - M - 136, width: badgeW, height: 18), statusColor.copy(alpha: 0.12)!)
        strokeRect(ctx, CGRect(x: M, y: H - M - 136, width: badgeW, height: 18), statusColor)
        text(ctx, deal.status.rawValue.uppercased(), x: M + 8, y: H - M - 131, font: jm(9), color: statusColor)

        // ── Porteos score (right side) ─────────────────────────────────────────
        // Combine score + denominator on one line so the large numeral cannot
        // drift into the deal-name / location / status-badge zone above.
        let scoreStr  = deal.porteosScore.map { "\(Int($0.rounded())) / 100" } ?? "-- / 100"
        text(ctx, "PORTEOS SCORE", x: 0, y: H - M - 100, font: jm(8), color: tp3, rightAlignTo: M + cW)
        text(ctx, scoreStr,         x: 0, y: H - M - 138, font: jmB(32), color: accent, rightAlignTo: M + cW)

        hline(ctx, x: M, y: H - M - 182, width: cW, color: border)

        // ── Quick stats (3 columns) ────────────────────────────────────────────
        let colW   = cW / 3
        let statsY: CGFloat = H - M - 208

        func stat(_ label: String, _ value: String, col: Int) {
            let x = M + CGFloat(col) * colW
            if col > 0 { vline(ctx, x: x - 1, y1: statsY - 6, y2: statsY + 24, color: border) }
            text(ctx, label, x: x + (col > 0 ? 8 : 0), y: statsY + 16, font: jm(7.5), color: tp3)
            text(ctx, value, x: x + (col > 0 ? 8 : 0), y: statsY,     font: jmB(12), color: tp1)
        }

        stat("PURCHASE PRICE", currency(deal.purchasePrice), col: 0)
        stat("LOAN AMOUNT",    currency(deal.loanAmount),    col: 1)
        stat("TOTAL AREA",     UnitSystemService.shared.formatArea(deal.totalArea, country: deal.locationCountry),  col: 2)

        hline(ctx, x: M, y: statsY - 14, width: cW, color: border)

        // ── Profile weights bar chart ──────────────────────────────────────────
        let wY: CGFloat = statsY - 26
        text(ctx, "// PROFILE WEIGHTS", x: M, y: wY, font: jm(8), color: tp3)

        let profiles: [(String, Double, CGColor)] = [
            ("REAL ESTATE",   deal.weightRealEstate,  rust),
            ("HOSPITALITY",   deal.weightHospitality, teal),
            ("DESIGN",        deal.weightDesign,       purple),
            ("CIRCULAR",      deal.weightCircular,     blue),
        ]

        let barAreaW = cW / 4 - 6
        let barY: CGFloat = wY - 22
        for (i, (label, weight, color)) in profiles.enumerated() {
            let x = M + CGFloat(i) * (barAreaW + 6)
            text(ctx, label, x: x, y: barY + 14, font: jm(7), color: tp3)
            fill(ctx, CGRect(x: x, y: barY, width: barAreaW, height: 6), surf)
            fill(ctx, CGRect(x: x, y: barY, width: barAreaW * CGFloat(weight / 100), height: 6), color)
            text(ctx, "\(Int(weight.rounded()))%", x: x, y: barY - 13, font: jmB(9), color: color)
        }

        hline(ctx, x: M, y: barY - 25, width: cW, color: border)

        // ── Key RE metrics ─────────────────────────────────────────────────────
        // Extra vertical gap so section header cannot collide with profile % row above
        // or the first KPI label row below (was ~4pt — caused "NOI" overlap).
        let metricsY: CGFloat = barY - 50
        text(ctx, "// KEY FINANCIAL INDICATORS", x: M, y: metricsY, font: jm(8), color: tp3)

        let metY: CGFloat = metricsY - 22
        func kv(_ label: String, _ value: String, col: Int) {
            let x = M + CGFloat(col) * (cW / 3)
            text(ctx, label, x: x, y: metY + 12, font: jm(7.5), color: tp3)
            text(ctx, value, x: x, y: metY,      font: jmB(11), color: tp1)
        }
        kv("NOI",       currency(reM.netOperatingIncome),        col: 0)
        kv("CAP RATE",  pct(reM.capRate),                        col: 1)
        kv("DSCR",      "\(f2(reM.debtServiceCoverageRatio))×",  col: 2)

        let metY2: CGFloat = metY - 32
        kv("CFBT",      currency(reM.cashFlowBeforeTax),  col: 0)
        kv("LTV",       pct(reM.loanToValue),              col: 1)
        kv("CoC RETURN", pct(reM.cashOnCashReturn),        col: 2)

        hline(ctx, x: M, y: metY2 - 16, width: cW, color: border)

        // ── Metadata row ───────────────────────────────────────────────────────
        let mdY: CGFloat = metY2 - 30
        df.dateStyle = .medium
        df.timeStyle = .none
        text(ctx, "CREATED: \(df.string(from: deal.createdAt))  //  UPDATED: \(df.string(from: deal.updatedAt))",
             x: M, y: mdY, font: jm(7.5), color: tp3)

        if !deal.notes.isEmpty {
            text(ctx, "// NOTES", x: M, y: mdY - 16, font: jm(7.5), color: tp3)
            wrappedText(ctx, String(deal.notes.prefix(280)),
                        rect: CGRect(x: M, y: mdY - 82, width: cW, height: 60),
                        font: jm(8.5), color: tp2)
        }

        // ── Bottom confidentiality bar ─────────────────────────────────────────
        fill(ctx, CGRect(x: 0, y: 0, width: W, height: 40), surf)
        text(ctx, "// CONFIDENTIAL — THIS REPORT CONTAINS PROPRIETARY INFORMATION. DO NOT DISTRIBUTE.",
             x: M, y: 14, font: jm(7.5), color: tp3)
    }

    // MARK: – Page 2: Real Estate Financials

    private func drawRealEstate(_ ctx: CGContext, deal: PropertyDeal, m: RealEstateCalculator.FullMetrics) {
        var y = H - M

        y = sectionHeader(ctx, "01 // REAL ESTATE FINANCIALS", at: y, accent: rust)
        y -= 10

        y = subHeader(ctx, "REVENUE", at: y)
        y = metricRow(ctx, "GROSS POTENTIAL INCOME",     currency(m.grossPotentialIncome),    y: y, alt: true)
        y = metricRow(ctx, "VACANCY LOSS (\(pct(deal.vacancyRate)))", "−\(currency(m.vacancyLoss))", y: y, valueColor: red)
        y = metricRow(ctx, "EFFECTIVE GROSS INCOME",     currency(m.effectiveGrossIncome),    y: y, alt: true)
        y = metricRow(ctx, "OTHER INCOME",               currency(m.otherIncome),             y: y)
        y = metricRow(ctx, "TOTAL REVENUE",              currency(m.totalRevenue),            y: y, alt: true, valueColor: tp1, bold: true)
        y -= 8

        y = subHeader(ctx, "OPERATING EXPENSES", at: y)
        y = metricRow(ctx, "PROPERTY MANAGEMENT",  currency(m.opexPropertyManagement), y: y, alt: true)
        y = metricRow(ctx, "PROPERTY TAX",         currency(m.opexPropertyTax),        y: y)
        y = metricRow(ctx, "INSURANCE",            currency(m.opexInsurance),           y: y, alt: true)
        y = metricRow(ctx, "UTILITIES",            currency(m.opexUtilities),           y: y)
        y = metricRow(ctx, "MAINTENANCE",          currency(m.opexMaintenance),         y: y, alt: true)
        y = metricRow(ctx, "CAPITAL RESERVES",     currency(m.opexCapitalReserves),     y: y)
        y = metricRow(ctx, "TOTAL OPEX (\(pct(m.opExRatio)) of EGI)", currency(m.totalOpEx), y: y, alt: true, valueColor: red, bold: true)
        y -= 8

        y = subHeader(ctx, "PROFITABILITY", at: y)
        y = metricRow(ctx, "NET OPERATING INCOME", currency(m.netOperatingIncome), y: y, alt: true, valueColor: green)
        y = metricRow(ctx, "EBITDA",               currency(m.ebitda),             y: y)
        y = metricRow(ctx, "CAP RATE",             pct(m.capRate),                 y: y, alt: true, valueColor: rust)
        y = metricRow(ctx, "CASH FLOW BEFORE TAX", currency(m.cashFlowBeforeTax),  y: y)
        y -= 8

        y = subHeader(ctx, "LEVERAGE", at: y)
        y = metricRow(ctx, "LOAN AMOUNT",           currency(m.loanAmount),                                    y: y, alt: true)
        y = metricRow(ctx, "LOAN TO VALUE (LTV)",   pct(m.loanToValue),                                        y: y)
        y = metricRow(ctx, "LOAN TO COST (LTC)",    pct(m.loanToCost),                                         y: y, alt: true)
        y = metricRow(ctx, "ANNUAL INTEREST RATE",  pct(m.annualInterestRate),                                  y: y)
        y = metricRow(ctx, "ANNUAL DEBT SERVICE",   currency(m.annualDebtService),                              y: y, alt: true)
        y = metricRow(ctx, "DEBT SERVICE COVERAGE", "\(f2(m.debtServiceCoverageRatio))×", y: y,
                      valueColor: m.debtServiceCoverageRatio >= 1.25 ? green : red)
        y = metricRow(ctx, "DEBT YIELD",            pct(m.debtYield),                                          y: y, alt: true)
        y -= 8

        y = subHeader(ctx, "RETURNS (5-YEAR HOLD)", at: y)
        y = metricRow(ctx, "TOTAL EQUITY INVESTED",  currency(m.totalEquityInvested), y: y, alt: true)
        y = metricRow(ctx, "CASH-ON-CASH RETURN",    pct(m.cashOnCashReturn),         y: y, valueColor: rust)
        y = metricRow(ctx, "EQUITY MULTIPLE (5Y)",   "\(f2(m.equityMultiple5Y))×",    y: y, alt: true)
        y = metricRow(ctx, "UNLEVERED IRR",          pct(m.unleveredIRR),             y: y)
        _ = metricRow(ctx, "LEVERED IRR",            pct(m.leveredIRR),               y: y, alt: true, valueColor: green)
    }

    // MARK: – Page 3: Hospitality + Design + Circular

    private func drawMultiProfile(
        _ ctx: CGContext,
        deal: PropertyDeal,
        hosp: HospitalityCalculator.FullMetrics,
        des:  DesignCalculator.FullMetrics,
        circ: CircularEconomyCalculator.FullMetrics
    ) {
        var y = H - M

        // ── Hospitality ────────────────────────────────────────────────────────
        y = sectionHeader(ctx, "02 // HOSPITALITY PERFORMANCE", at: y, accent: teal)
        y -= 8

        y = metricRow(ctx, "ROOMS",                "\(deal.hospitalityRoomCount)",    y: y, alt: true)
        y = metricRow(ctx, "AVERAGE DAILY RATE",    currency(hosp.adr),               y: y)
        y = metricRow(ctx, "OCCUPANCY RATE",        pct(hosp.occupancyRate),          y: y, alt: true, valueColor: teal)
        y = metricRow(ctx, "RevPAR",               currency(hosp.revPAR),            y: y)
        y = metricRow(ctx, "TRevPAR",              currency(hosp.trevPAR),           y: y, alt: true)
        y = metricRow(ctx, "TOTAL REVENUE",        currency(hosp.totalRevenue),      y: y)
        y = metricRow(ctx, "GOP",                  currency(hosp.gop),               y: y, alt: true, valueColor: green)
        y = metricRow(ctx, "GOP MARGIN",           pct(hosp.gopMargin),              y: y)
        y = metricRow(ctx, "EBITDA MARGIN",        pct(hosp.ebitdaMargin),           y: y, alt: true)
        y -= 12

        // ── Design ────────────────────────────────────────────────────────────
        y = sectionHeader(ctx, "03 // DESIGN PERFORMANCE", at: y, accent: purple)
        y -= 8

        // GFA/NIA: use designGFA if populated, fall back to totalArea for the PDF.
        // Guard against 0 (unfilled) to avoid showing "0 m²" or misleading values.
        let gfaDisplay = des.gfa > 0 ? UnitSystemService.shared.formatArea(des.gfa, country: deal.locationCountry)
                       : deal.totalArea > 0 ? "\(UnitSystemService.shared.formatArea(deal.totalArea, country: deal.locationCountry)) (built area)" : "—"
        let niaDisplay = des.nia > 0 ? UnitSystemService.shared.formatArea(des.nia, country: deal.locationCountry) : "—"
        y = metricRow(ctx, "GFA",                  gfaDisplay,                      y: y, alt: true)
        y = metricRow(ctx, "NIA",                  niaDisplay,                      y: y)
        y = metricRow(ctx, "NET-TO-GROSS RATIO",   des.netToGrossRatio > 0 ? pct(des.netToGrossRatio) : "—",  y: y, alt: true, valueColor: purple)
        y = metricRow(ctx, "SPACE UTILIZATION",    des.spaceUtilization > 0 ? pct(des.spaceUtilization) : "—", y: y)
        y = metricRow(ctx, "DAYLIGHTING COVERAGE", des.daylighting > 0 ? pct(des.daylighting) : "—",          y: y, alt: true)
        y = metricRow(ctx, "INDOOR CO₂",           des.co2ppm > 0 ? "\(Int(des.co2ppm)) ppm" : "—",           y: y)
        y = metricRow(ctx, "AIR CHANGES / HOUR",   des.ach > 0 ? "\(f1(des.ach)) ACH" : "—",                 y: y, alt: true)
        y = metricRow(ctx, "THERMAL COMFORT",      des.thermalComfort > 0 ? pct(des.thermalComfort) : "—",    y: y)
        y = metricRow(ctx, "ACOUSTIC COMFORT",     des.acousticComfort > 0 ? pct(des.acousticComfort) : "—", y: y, alt: true)
        y = metricRow(ctx, "BIOPHILIC ELEMENTS",   des.biophilicCount > 0 ? "\(des.biophilicCount)" : "—",   y: y)
        y -= 12

        // ── Circular Economy ──────────────────────────────────────────────────
        y = sectionHeader(ctx, "04 // CIRCULAR ECONOMY PERFORMANCE", at: y, accent: blue)
        y -= 8

        y = metricRow(ctx, "RECYCLED CONTENT",          pct(circ.recycledContentPct),          y: y, alt: true, valueColor: blue)
        y = metricRow(ctx, "RENEWABLE CONTENT",         pct(circ.renewableContentPct),         y: y)
        y = metricRow(ctx, "MATERIAL CIRCULARITY INDEX", f2(circ.mciScore),                    y: y, alt: true, valueColor: blue)
        y = metricRow(ctx, "OVERALL CE SCORE",          pct(circ.overallCEScore),              y: y)
        y = metricRow(ctx, "RECOVERY RATE",             pct(circ.recoveryRate),                y: y, alt: true, valueColor: green)
        y = metricRow(ctx, "EMBODIED CARBON",           "\(f1(circ.embodiedCarbon)) tCO₂e",   y: y)
        y = metricRow(ctx, "CARBON INTENSITY",          "\(f1(circ.carbonIntensity)) kgCO₂/m²", y: y, alt: true)
        y = metricRow(ctx, "WASTE GENERATED",           "\(f0(circ.wasteGenerated)) kg",       y: y)
        _ = metricRow(ctx, "WATER RECYCLING RATE",      pct(circ.waterRecyclingRate),          y: y, alt: true)
    }

    // MARK: – Page 4: AI Vibe Analysis

    private func drawAIAnalysis(_ ctx: CGContext, deal: PropertyDeal) {
        var y = H - M
        y = sectionHeader(ctx, "05 // AI VIBE ASSESSMENT", at: y, accent: amber)
        y -= 14

        // Grade + status
        if let rawText = deal.aiAnalysisText, !rawText.isEmpty {
            text(ctx, "// ANALYSIS OUTPUT", x: M, y: y, font: jm(8), color: tp3)
            y -= 14
            wrappedText(ctx, rawText,
                        rect: CGRect(x: M, y: M + 50, width: cW, height: y - M - 56),
                        font: jm(9), color: tp2)
        } else {
            text(ctx, "// NO ANALYSIS AVAILABLE", x: M, y: y - 12, font: jmB(10), color: tp3)
            text(ctx, "// RUN THE AI VIBE CHECK IN THE INSPECTOR PANE BEFORE EXPORTING THE REPORT.",
                 x: M, y: y - 30, font: jm(9), color: tp3)
        }
    }

    // MARK: – Page 5: Data Validation Log

    private func drawValidation(_ ctx: CGContext, deal: PropertyDeal, messages: [ValidationMessage]) {
        var y = H - M
        y = sectionHeader(ctx, "06 // DATA VALIDATION LOG", at: y, accent: amber)
        y -= 12

        if messages.isEmpty {
            text(ctx, "// NO VALIDATION ISSUES — ALL FIELDS WITHIN ACCEPTABLE RANGES.",
                 x: M, y: y - 14, font: jm(10), color: green)
            return
        }

        let criticals = messages.filter { $0.severity == .critical }
        let warnings  = messages.filter { $0.severity == .warning  }

        if !criticals.isEmpty {
            y = subHeader(ctx, "CRITICAL ISSUES (\(criticals.count))", at: y)
            for msg in criticals {
                guard y > M + 56 else { break }
                fill(ctx, CGRect(x: M,     y: y - 20, width: 3,      height: 20), red)
                fill(ctx, CGRect(x: M + 3, y: y - 20, width: cW - 3, height: 20), red.copy(alpha: 0.05)!)
                let line = "[ERR]  \(msg.field.uppercased()): \(msg.message)"
                text(ctx, line, x: M + 10, y: y - 14, font: jm(9), color: red)
                y -= 24
            }
            y -= 8
        }

        if !warnings.isEmpty {
            y = subHeader(ctx, "WARNINGS (\(warnings.count))", at: y)
            for msg in warnings {
                guard y > M + 56 else { break }
                fill(ctx, CGRect(x: M,     y: y - 20, width: 3,      height: 20), amber)
                fill(ctx, CGRect(x: M + 3, y: y - 20, width: cW - 3, height: 20), amber.copy(alpha: 0.05)!)
                let line = "[WARN]  \(msg.field.uppercased()): \(msg.message)"
                text(ctx, line, x: M + 10, y: y - 14, font: jm(9), color: amber)
                y -= 24
            }
        }
    }

    // MARK: – Page 6: Saved Scenarios

    private func drawScenarios(_ ctx: CGContext, deal: PropertyDeal, scenarios: [DealScenario]) {
        var y = H - M
        y = sectionHeader(ctx, "07 // SAVED SENSITIVITY SCENARIOS", at: y, accent: rust)
        y -= 10

        text(ctx, "// \(scenarios.count) SCENARIO(S) SAVED",
             x: M, y: y, font: jm(8), color: tp3)
        y -= 20

        let df = DateFormatter()
        df.dateFormat = "MMM dd, yyyy"

        for (i, sc) in scenarios.enumerated() {
            guard y > M + 72 else { break }
            let rowH: CGFloat = 54
            let accent = accentForProfile(sc.profile)

            fill(ctx, CGRect(x: M,     y: y - rowH, width: cW,     height: rowH), i % 2 == 0 ? surf : bg)
            fill(ctx, CGRect(x: M,     y: y - rowH, width: 3,      height: rowH), accent)

            text(ctx, sc.name.uppercased(),
                 x: M + 12, y: y - 16, font: jmB(10), color: tp1)
            text(ctx, "\(df.string(from: sc.createdAt))  //  \(sc.profile.uppercased())",
                 x: M + 12, y: y - 30, font: jm(8), color: tp3)

            let adjStr = sc.adjustments
                .sorted { $0.key < $1.key }
                .map { k, v in "\(shortKey(k)): \(v >= 0 ? "+" : "")\(f1(v))" }
                .joined(separator: "  ·  ")
            text(ctx, adjStr.isEmpty ? "// NO ADJUSTMENTS" : adjStr,
                 x: M + 12, y: y - 44, font: jm(8.5), color: tp2)

            y -= rowH + 4
        }
    }

    // MARK: – Drawing Primitives

    @discardableResult
    private func sectionHeader(_ ctx: CGContext, _ label: String, at y: CGFloat, accent: CGColor) -> CGFloat {
        let h: CGFloat = 26
        fill(ctx, CGRect(x: M,     y: y - h, width: 3,      height: h), accent)
        fill(ctx, CGRect(x: M + 3, y: y - h, width: cW - 3, height: h), surf)
        text(ctx, label, x: M + 12, y: y - 18, font: jmB(11), color: accent)
        return y - h
    }

    @discardableResult
    private func subHeader(_ ctx: CGContext, _ label: String, at y: CGFloat) -> CGFloat {
        let h: CGFloat = 16
        fill(ctx, CGRect(x: M, y: y - h, width: cW, height: h), bg)
        text(ctx, "// \(label)", x: M + 8, y: y - 12, font: jm(8), color: tp3)
        return y - h
    }

    @discardableResult
    private func metricRow(
        _ ctx: CGContext,
        _ label: String,
        _ value: String,
        y: CGFloat,
        alt: Bool = false,
        valueColor: CGColor? = nil,
        bold: Bool = false
    ) -> CGFloat {
        let h: CGFloat = 20
        fill(ctx, CGRect(x: M, y: y - h, width: cW, height: h), alt ? surf : bg)
        text(ctx, label, x: M + 8, y: y - 14, font: jm(9.5), color: tp2)
        let vFont = bold ? jmB(9.5) : jm(9.5)
        text(ctx, value, x: 0, y: y - 14, font: vFont, color: valueColor ?? tp1, rightAlignTo: M + cW - 8)
        return y - h
    }

    private func text(
        _ ctx: CGContext,
        _ str: String,
        x: CGFloat,
        y: CGFloat,
        font: CTFont,
        color: CGColor,
        rightAlignTo: CGFloat? = nil
    ) {
        guard !str.isEmpty else { return }
        let nsColor = NSColor(cgColor: c(color)) ?? .white
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: nsColor]
        let line = CTLineCreateWithAttributedString(NSAttributedString(string: str, attributes: attrs))
        var drawX = x
        if let rx = rightAlignTo {
            drawX = rx - CGFloat(CTLineGetTypographicBounds(line, nil, nil, nil))
        }
        ctx.textMatrix    = .identity
        ctx.textPosition  = CGPoint(x: drawX, y: y)
        CTLineDraw(line, ctx)
    }

    @discardableResult
    private func wrappedText(
        _ ctx: CGContext,
        _ str: String,
        rect: CGRect,
        font: CTFont,
        color: CGColor
    ) -> CGFloat {
        guard !str.isEmpty else { return 0 }
        let nsColor = NSColor(cgColor: c(color)) ?? .white
        let paraStyle = NSMutableParagraphStyle()
        paraStyle.lineSpacing = 2
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font, .foregroundColor: nsColor, .paragraphStyle: paraStyle
        ]
        let attrStr = NSAttributedString(string: str, attributes: attrs)
        let setter  = CTFramesetterCreateWithAttributedString(attrStr)
        let path    = CGPath(rect: rect, transform: nil)
        let frame   = CTFramesetterCreateFrame(setter, CFRangeMake(0, 0), path, nil)
        CTFrameDraw(frame, ctx)
        let sz = CTFramesetterSuggestFrameSizeWithConstraints(
            setter, CFRangeMake(0, 0), nil,
            CGSize(width: rect.width, height: .greatestFiniteMagnitude), nil
        )
        return sz.height
    }

    private func fill(_ ctx: CGContext, _ rect: CGRect, _ color: CGColor) {
        ctx.setFillColor(c(color))
        ctx.fill(rect)
    }

    private func strokeRect(_ ctx: CGContext, _ rect: CGRect, _ color: CGColor, lw: CGFloat = 1) {
        ctx.setStrokeColor(c(color))
        ctx.setLineWidth(lw)
        ctx.stroke(rect)
    }

    private func hline(_ ctx: CGContext, x: CGFloat, y: CGFloat, width: CGFloat, color: CGColor) {
        ctx.setStrokeColor(c(color))
        ctx.setLineWidth(1)
        ctx.beginPath()
        ctx.move(to: CGPoint(x: x, y: y))
        ctx.addLine(to: CGPoint(x: x + width, y: y))
        ctx.strokePath()
    }

    private func vline(_ ctx: CGContext, x: CGFloat, y1: CGFloat, y2: CGFloat, color: CGColor) {
        ctx.setStrokeColor(c(color))
        ctx.setLineWidth(1)
        ctx.beginPath()
        ctx.move(to: CGPoint(x: x, y: y1))
        ctx.addLine(to: CGPoint(x: x, y: y2))
        ctx.strokePath()
    }

    private func lineWidth(_ s: String, font: CTFont) -> CGFloat {
        let attrs: [NSAttributedString.Key: Any] = [.font: font]
        let line = CTLineCreateWithAttributedString(NSAttributedString(string: s, attributes: attrs))
        return CGFloat(CTLineGetTypographicBounds(line, nil, nil, nil))
    }

    // MARK: – Calculator Input Builders

    private func reInputs(_ d: PropertyDeal) -> RealEstateCalculator.FullInputs {
        .init(grossPotentialIncome:   d.grossPotentialIncome,
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
              exitCapRate:            d.exitCapRate)
    }

    private func hospInputs(_ d: PropertyDeal) -> HospitalityCalculator.FullInputs {
        .init(roomCount:        d.hospitalityRoomCount,
              adr:              d.hospitalityADR,
              occupancyRate:    d.hospitalityOccupancyRate,
              fbRevenue:        d.hospitalityFBRevenue,
              spaRevenue:       d.hospitalitySpaRevenue,
              meetingRevenue:   d.hospitalityMeetingRevenue,
              otherRevenue:     d.hospitalityOtherRevenue,
              opExRatio:        d.hospitalityOpExRatio,
              directBookingPct: d.hospitalityDirectBookingPct,
              otaBookingPct:    d.hospitalityOTABookingPct,
              distributionCost: d.hospitalityDistributionCost)
    }

    private func desInputs(_ d: PropertyDeal) -> DesignCalculator.FullInputs {
        .init(gfa:                 d.designGFA,
              nia:                 d.designNIA,
              circulationPct:      d.designCirculationPct,
              spaceUtilization:    d.designSpaceUtilization,
              daylighting:         d.designDaylighting,
              co2ppm:              d.designCO2ppm,
              ach:                 d.designACH,
              thermalComfort:      d.designThermalComfort,
              acousticComfort:     d.designAcousticComfort,
              biophilicCount:      d.designBiophilicCount,
              greenWallM2:         d.designGreenWallM2,
              viewsToNaturePct:    d.designViewsToNaturePct,
              naturalMaterialsPct: d.designNaturalMaterialsPct,
              movablePartitionPct: d.designMovablePartitionPct,
              multiUseSpaces:      d.designMultiUseSpaces,
              adaptabilityScore:   d.designAdaptabilityScore)
    }

    private func circInputs(_ d: PropertyDeal) -> CircularEconomyCalculator.FullInputs {
        .init(totalConstructionCost:  d.circularTotalConstructionCost,
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
              waterRecyclingRate:     d.circularWaterRecyclingRate)
    }

    // MARK: – Format Helpers

    private func currency(_ v: Double) -> String {
        let a = Swift.abs(v)
        let prefix = v < 0 ? "−€" : "€"
        if a >= 1_000_000 { return "\(prefix)\(String(format: "%.2f", a / 1_000_000))M" }
        if a >= 1_000     { return "\(prefix)\(String(format: "%.1f", a / 1_000))K" }
        return "\(prefix)\(String(format: "%.0f", a))"
    }

    private func pct(_ v: Double) -> String { String(format: "%.1f%%", v) }
    private func f0(_ v: Double)  -> String { String(format: "%.0f",   v) }
    private func f1(_ v: Double)  -> String { String(format: "%.1f",   v) }
    private func f2(_ v: Double)  -> String { String(format: "%.2f",   v) }

    private func primaryAccent(_ deal: PropertyDeal) -> CGColor {
        let m = max(deal.weightRealEstate, deal.weightHospitality, deal.weightDesign, deal.weightCircular)
        if m == deal.weightRealEstate  { return rust   }
        if m == deal.weightHospitality { return teal   }
        if m == deal.weightDesign      { return purple }
        return blue
    }

    private func accentForProfile(_ profile: String) -> CGColor {
        switch profile {
        case "realEstate":  return rust
        case "hospitality": return teal
        case "design":      return purple
        default:            return blue
        }
    }

    private func statusAccent(_ status: DealStatus) -> CGColor {
        switch status {
        case .viable:   return green
        case .acquired: return teal
        case .review:   return amber
        case .rejected: return red
        case .pipeline: return blue
        }
    }

    private func shortKey(_ key: String) -> String {
        let map: [String: String] = [
            "vacancyAdj": "vac",  "opexAdj": "opex",   "rateAdj": "rate",
            "adrAdj": "adr",      "occupancyAdj": "occ", "opexRatioAdj": "opex%",
            "daylightingAdj": "day", "biophilicAdj": "bio", "spaceUtilizationAdj": "spc",
            "recycledContentAdj": "rec", "renewableContentAdj": "ren", "wasteReductionAdj": "wst",
        ]
        return map[key] ?? key
    }
}

// MARK: - CGColor Hex Helper

private extension CGColor {
    static func porteos(_ hex: String) -> CGColor {
        let h = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        var v: UInt64 = 0
        Scanner(string: h).scanHexInt64(&v)
        return CGColor(
            red:   CGFloat((v >> 16) & 0xFF) / 255,
            green: CGFloat((v >> 8)  & 0xFF) / 255,
            blue:  CGFloat(v         & 0xFF) / 255,
            alpha: 1
        )
    }
}
