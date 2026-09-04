# Porteos Intelligence — Quick Reference Card

**For:** MLX Bionic (Qwen3.8-27b 4-bit)  
**Print this:** Keep beside your terminal for quick lookups

---

## 🚀 First Day Commands

```bash
# Setup environment
chmod +x setup.sh && ./setup.sh

# Open project
open PorteosIntelligence.xcodeproj

# Build: ⌘B
# Run: ⌘R
# Test: ⌘U
# Clean: ⌘⇧K
```

---

## 📚 Documentation Priority

**Read in this order:**

1. **HANDOVER.md** ← Start here
2. **README.md** ← What the app does
3. **DEVELOPER_SETUP.md** ← How to build
4. **ARCHITECTURE.md** ← How it's structured
5. **DATA_MODEL_GUIDE.md** ← Database schema
6. **CALCULATOR_SYSTEM.md** ← Business logic

**Reference as needed:**
- SWIFTDATA_MIGRATION.md (before schema changes)
- LLM_INTEGRATION.md (before AI changes)
- BROWSER_EXTENSION_GUIDE.md (before scraper changes)
- MULTI_WINDOW_SYSTEM.md (before UI state changes)

---

## 🎯 Architecture at a Glance

```
Models (SwiftData)
    ↓
ViewModels (@Observable)
    ↓
Views (SwiftUI)

Calculators ← Pure functions, no side effects
Services ← Side effects (network, email, files)
```

**RULE:** Views NEVER talk to Models directly. Always go through ViewModels.

---

## 🗂️ Critical File Locations

```
PorteosIntelligence/
├── PorteosIntelligenceApp.swift      # Entry, ModelContainer
├── Models/PropertyDeal.swift         # Core model (474 lines)
├── ViewModels/PropertyDealViewModel  # MVVM bridge
├── Views/Shell/AppShell.swift        # 3-pane layout
├── Services/LLMAnalysisService       # AI gateway
├── Calculators/RealEstateCalculator  # Financial metrics
└── Utilities/DesignTokens.swift      # Colors (NEVER hardcode)
```

---

## ⚠️ High-Risk Operations (Read Docs First!)

| Action | Read This First | Risk |
|--------|----------------|------|
| Modify `PropertyDeal` schema | SWIFTDATA_MIGRATION.md | Data loss |
| Edit files >500 lines | Relevant doc + code sections | Context overflow |
| Add UI component | 01_TERMINAL_DESIGN_SYSTEM.md | Design violations |
| Modify LLM prompts | LLM_INTEGRATION.md | Breaking AI features |
| Change calculators | CALCULATOR_SYSTEM.md | Breaking metrics |

---

## 🧪 Testing Pattern

```swift
// Unit test template
import XCTest
@testable import PorteosIntelligence

final class MyCalculatorTests: XCTestCase {
    func testMetric() {
        let result = RealEstateCalculator.capRate(noi: 50000, purchasePrice: 1000000)
        XCTAssertEqual(result, 5.0, accuracy: 0.01)
    }
}
```

**Run tests:** ⌘U in Xcode

---

## 🎨 Design System Rules

**Terminal Aesthetic (STRICT):**

```swift
// ✅ CORRECT
Text("Hello")
    .foregroundColor(DesignTokens.textPrimary)
    .font(.system(size: 14, design: .monospaced))
    .cornerRadius(0)  // ZERO rounded corners

// ❌ WRONG
Text("Hello")
    .foregroundColor(.blue)  // Never hardcode colors
    .font(.body)  // Not monospaced
    .cornerRadius(8)  // No rounded corners allowed
```

**Font:** JetBrains Mono ONLY  
**Corners:** 0px radius (terminal aesthetic)  
**Colors:** Use DesignTokens.swift ALWAYS

---

## 🔧 Common Tasks

### Add Field to PropertyDeal

1. Read SWIFTDATA_MIGRATION.md
2. Add field with default:
   ```swift
   var newField: Double = 0.0  // Default prevents crash
   ```
3. Update FullDealEditSheet input
4. Build, test persistence

### Add Metric to Calculator

1. Read CALCULATOR_SYSTEM.md
2. Add pure function:
   ```swift
   static func metricName(input: Double) -> Double {
       guard input != 0 else { return 0 }
       return calculation
   }
   ```
3. Add computed property in ViewModel
4. Display in dashboard
5. Write unit test

### Modify AI Prompt

1. Read LLM_INTEGRATION.md
2. Find prompt in LLMAnalysisService
3. Edit string template
4. Test with Ollama or OpenAI

### Debug Issue

1. Set breakpoint in Xcode (click line number)
2. Run app (⌘R)
3. Trigger issue
4. Inspect variables
5. Step through code (F6)

---

## 🚨 Emergency Contacts

**Build fails:** Check DEVELOPER_SETUP.md troubleshooting  
**Data loss:** Read SWIFTDATA_MIGRATION.md backup section  
**Crash:** Enable Exception Breakpoint in Xcode  
**Context overflow:** Use documentation summaries, not full files  

**Original Developer:** info@htdstudio.net  
**Response Time:** 24-48 hours

---

## 📊 Validation Checklist

Before considering handover complete:

- [ ] Build app from scratch
- [ ] Run all unit tests (⌘U)
- [ ] Add optional field to PropertyDeal
- [ ] Add metric to RealEstateCalculator
- [ ] Modify SWOT prompt
- [ ] Debug intentional crash
- [ ] Complete feature from PUNCHLIST.md

---

## 💡 Pro Tips

1. **Context Window:** Read docs FIRST, then request specific code sections
2. **Large Files:** Never load >500 lines in full, use summaries
3. **Calculators:** Must be pure (no async, no side effects)
4. **SwiftData:** Always add defaults to new fields
5. **Design:** Use DesignTokens, never hardcode colors
6. **Testing:** Write test before changing calculator
7. **Git:** Commit small, incremental changes
8. **Xcode:** Clean build folder (⌘⇧K) if weird errors

---

## 🔍 Quick File Search

```bash
# Find all files with keyword
grep -r "PropertyDeal" --include="*.swift"

# Find file by name
find . -name "*Calculator*" -type f

# Count lines in key files
wc -l PorteosIntelligence/Models/*.swift
```

---

## 📦 Dependencies

**External:** ZERO  
**Frameworks:** SwiftUI, SwiftData, MapKit (all native)  
**Fonts:** JetBrains Mono (manual install required)

---

## 🎯 Success Metrics

**Week 1:** Build app, understand architecture  
**Week 2:** Add field + metric independently  
**Week 3:** Complete feature from PUNCHLIST.md  
**Week 4:** Own the codebase 🎉

---

**Version:** 1.0 (Sept 4, 2026)  
**Keep this accessible:** Print or pin to terminal
