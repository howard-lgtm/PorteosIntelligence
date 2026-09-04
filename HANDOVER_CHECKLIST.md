# MLX Bionic Handover Checklist

**Purpose:** Track your onboarding progress for Porteos Intelligence  
**Target:** Complete all items over 4 weeks to achieve full handover  
**Update this file:** Check items as you complete them

---

## Week 1: Environment & Foundation

### Day 1: Setup (Target: 2 hours)

- [ ] Clone repository to local machine
- [ ] Run `chmod +x setup.sh && ./setup.sh`
- [ ] Fix any FAILED checks from setup script
- [ ] Verify Xcode 16.6+ installed
- [ ] Verify JetBrains Mono font installed
- [ ] Open `PorteosIntelligence.xcodeproj` in Xcode
- [ ] Build project successfully (⌘B)
- [ ] Run project successfully (⌘R)
- [ ] App launches and shows empty deal list
- [ ] Run unit tests (⌘U) — all pass

**Deliverable:** Screenshot of running app + passing tests

---

### Day 2: Documentation (Target: 3 hours)

**Phase 1 Documentation:**

- [ ] Read HANDOVER.md (30 min)
- [ ] Read README.md (15 min)
- [ ] Read DEVELOPER_SETUP.md (30 min)
- [ ] Read ARCHITECTURE.md (45 min)
  - [ ] Understand MVVM pattern
  - [ ] Understand 3-pane shell
  - [ ] Understand calculator pattern
- [ ] Read EXTERNAL_SERVICES.md (30 min)
- [ ] Read DATA_MODEL_GUIDE.md (30 min)
  - [ ] Understand PropertyDeal model
  - [ ] Understand 6 model relationships

**Deliverable:** One-paragraph summary of architecture in your own words

---

### Day 3: Code Exploration (Target: 3 hours)

**Core Files to Study:**

- [ ] `PorteosIntelligenceApp.swift` (entry point)
- [ ] `Models/PropertyDeal.swift` (read sections, not full file)
  - [ ] Lines 1-100 (properties)
  - [ ] Lines 100-200 (more properties)
  - [ ] Lines 400-474 (computed properties)
- [ ] `Calculators/RealEstateCalculator.swift` (full file, ~200 lines)
  - [ ] Understand pure function pattern
  - [ ] Understand cap rate formula
  - [ ] Understand NOI formula
- [ ] `ViewModels/PropertyDealViewModel.swift` (sections)
  - [ ] Understand @Observable pattern
  - [ ] Understand calculated metrics
- [ ] `Views/Shell/AppShell.swift` (structure only)
  - [ ] Understand 3-pane layout
- [ ] `Utilities/DesignTokens.swift` (full file)
  - [ ] Understand color system
  - [ ] Understand spacing system

**Deliverable:** Document 3 things you found interesting or confusing

---

### Day 4: First Code Change (Target: 2 hours)

**Task: Add a simple field to PropertyDeal**

- [ ] Read SWIFTDATA_MIGRATION.md (risk mitigation)
- [ ] Backup database: `~/Library/Containers/net.htdstudio.PorteosIntelligence/Data/Library/Application Support/default.store`
- [ ] Add field: `var testField: String = "default"` to PropertyDeal
- [ ] Build project (⌘B)
- [ ] Run project (⌘R)
- [ ] Create new deal and verify field exists
- [ ] Delete test field
- [ ] Build again to confirm no errors

**Deliverable:** Git diff of your changes (even if reverted)

---

### Day 5: First Metric (Target: 3 hours)

**Task: Add a simple calculated metric**

- [ ] Read CALCULATOR_SYSTEM.md
- [ ] Add function to RealEstateCalculator:
  ```swift
  static func pricePerSqft(purchasePrice: Double, totalArea: Double) -> Double {
      guard totalArea > 0 else { return 0 }
      return purchasePrice / totalArea
  }
  ```
- [ ] Add computed property to PropertyDealViewModel:
  ```swift
  var pricePerSqft: Double {
      RealEstateCalculator.pricePerSqft(
          purchasePrice: deal.purchasePrice,
          totalArea: deal.totalArea
      )
  }
  ```
- [ ] Display in RealEstateDashboardView
- [ ] Write unit test:
  ```swift
  func testPricePerSqft() {
      let result = RealEstateCalculator.pricePerSqft(
          purchasePrice: 500000,
          totalArea: 2000
      )
      XCTAssertEqual(result, 250.0, accuracy: 0.01)
  }
  ```
- [ ] Run test (⌘U) and verify it passes
- [ ] Create test deal, verify metric displays correctly

**Deliverable:** Git commit with working metric + test

---

**Week 1 Checkpoint:**

- [ ] Environment fully configured
- [ ] All Phase 1 docs read
- [ ] Core files explored
- [ ] First code change completed
- [ ] First metric added with test
- [ ] Confidence level: Can navigate codebase independently

---

## Week 2: Knowledge Transfer

### Day 1: Phase 2 Documentation (Target: 4 hours)

**Advanced Documentation:**

- [ ] Read SWIFTDATA_MIGRATION.md (45 min)
  - [ ] Understand backup + reset strategy
  - [ ] Understand safe vs unsafe changes
  - [ ] Understand testing strategy
- [ ] Read LLM_INTEGRATION.md (60 min)
  - [ ] Understand multi-provider architecture
  - [ ] Understand prompt patterns
  - [ ] Understand error handling
- [ ] Read CALCULATOR_SYSTEM.md (45 min)
  - [ ] Understand all 5 calculator modules
  - [ ] Understand key formulas
- [ ] Read BROWSER_EXTENSION_GUIDE.md (45 min)
  - [ ] Understand scraper pattern
  - [ ] Understand 12 supported sites
- [ ] Read MULTI_WINDOW_SYSTEM.md (45 min)
  - [ ] Understand @AppStorage sync
  - [ ] Understand WindowGroup pattern

**Deliverable:** Notes on each doc's most important concepts

---

### Day 2: External Services (Target: 3 hours)

**Optional but Recommended:**

- [ ] Install Ollama: https://ollama.com/download
- [ ] Pull model: `ollama pull llama3.2:latest`
- [ ] Start Ollama server: `ollama serve`
- [ ] Open app Settings → LLM Provider → Ollama
- [ ] Set URL: `http://localhost:11434`
- [ ] Set model: `llama3.2:latest`
- [ ] Test AI Vibe feature on a deal
- [ ] Verify SWOT analysis generates

**Alternative (if Ollama fails):**

- [ ] Use OpenAI instead
- [ ] Add API key in Settings
- [ ] Test AI Vibe with OpenAI

**Deliverable:** Screenshot of working AI Vibe panel

---

### Day 3: Browser Extension (Target: 2 hours)

**Install and Test:**

- [ ] Open Chrome: `chrome://extensions/`
- [ ] Enable "Developer mode" (top right)
- [ ] Click "Load unpacked"
- [ ] Select: `BrowserExtension/` folder
- [ ] Navigate to Zillow listing (USA)
- [ ] Click [ SEND TO PORTEOS ] button
- [ ] Verify deal appears in app
- [ ] Test with another site (Idealista Portugal)

**Study Scraper Code:**

- [ ] Open `BrowserExtension/content.js`
- [ ] Find `initZillow()` function (lines 200-300)
- [ ] Understand scraper pattern
- [ ] Find `extractZillowData()` function
- [ ] Understand data extraction utilities

**Deliverable:** Successfully import 2 properties from different sites

---

### Day 4: AI Prompt Modification (Target: 2 hours)

**Task: Customize SWOT prompt**

- [ ] Read LLM_INTEGRATION.md (refresh)
- [ ] Open `Services/LLMAnalysisService.swift`
- [ ] Find `generateSWOT()` function (line ~200)
- [ ] Find prompt template string
- [ ] Add custom instruction: "Focus on cash-on-cash return"
- [ ] Build and run app
- [ ] Generate SWOT on test deal
- [ ] Verify output reflects your change
- [ ] Revert change (or commit if improvement)

**Deliverable:** Git diff of prompt change + screenshot of result

---

### Day 5: Debugging Practice (Target: 2 hours)

**Task: Intentionally break something and fix it**

- [ ] Open `Calculators/RealEstateCalculator.swift`
- [ ] Find `capRate()` function
- [ ] Comment out guard statement (introduce crash)
- [ ] Build and run
- [ ] Create deal with zero purchase price
- [ ] Observe crash or error
- [ ] Enable Exception Breakpoint (⌘7 → Breakpoints → +)
- [ ] Reproduce crash with breakpoint
- [ ] Inspect variables in debugger
- [ ] Identify issue
- [ ] Uncomment guard
- [ ] Verify fix

**Deliverable:** Written explanation of debugging process

---

**Week 2 Checkpoint:**

- [ ] All Phase 2 docs read
- [ ] External services configured (at least one)
- [ ] Browser extension tested
- [ ] AI prompt modified
- [ ] Debugging skills validated
- [ ] Confidence level: Can make targeted changes independently

---

## Week 3: Independent Development

### Feature Selection

**Pick ONE feature from PUNCHLIST.md:**

- [ ] Review PUNCHLIST.md
- [ ] Select feature (recommend: Medium complexity)
- [ ] Document choice and reasoning
- [ ] Get approval from original developer (optional)

**Example features:**
- Add new property type
- Add new market benchmark city
- Add new calculator metric
- Enhance dashboard view
- Add email parsing rule

---

### Planning (Target: 2 hours)

- [ ] Read relevant documentation for your feature
- [ ] Identify files that need changes
- [ ] List affected components:
  - [ ] Models?
  - [ ] Calculators?
  - [ ] Services?
  - [ ] ViewModels?
  - [ ] Views?
- [ ] Sketch implementation approach
- [ ] Identify potential risks
- [ ] Write test plan

**Deliverable:** Implementation plan (1-2 pages)

---

### Implementation (Target: 6-8 hours)

**Development Process:**

- [ ] Create feature branch: `git checkout -b feature/my-feature`
- [ ] Make small, incremental changes
- [ ] Test after each change
- [ ] Write unit tests for new logic
- [ ] Update documentation if needed
- [ ] Follow design system (DesignTokens, JetBrains Mono)
- [ ] Check for linter warnings
- [ ] Run full test suite (⌘U)
- [ ] Manual testing in app

**Quality Gates (from .cursor/rules/zero-defect-quality.mdc):**

- [ ] No compiler warnings
- [ ] No force unwraps
- [ ] No hardcoded colors
- [ ] No rounded corners
- [ ] JetBrains Mono font used
- [ ] All tests pass
- [ ] No crashes during testing
- [ ] Feature works as intended

**Deliverable:** Working feature on branch

---

### Code Review Prep (Target: 1 hour)

- [ ] Clean up debug code
- [ ] Remove commented-out code
- [ ] Review your own changes (git diff)
- [ ] Write clear commit messages
- [ ] Update PUNCHLIST.md if feature complete
- [ ] Document any decisions made
- [ ] Prepare questions for review

**Deliverable:** Pull request or email to original developer

---

**Week 3 Checkpoint:**

- [ ] Feature selected and planned
- [ ] Feature implemented
- [ ] All quality gates passed
- [ ] Ready for code review
- [ ] Confidence level: Can complete features independently

---

## Week 4: Handover Completion

### Code Review (Target: 2 hours)

- [ ] Submit code to original developer
- [ ] Address review feedback
- [ ] Make requested changes
- [ ] Re-test after changes
- [ ] Get approval
- [ ] Merge to main branch

**Deliverable:** Merged feature

---

### Documentation Updates (Target: 2 hours)

- [ ] Update relevant .md files with new knowledge
- [ ] Add any gotchas you discovered
- [ ] Document decisions made
- [ ] Update PUNCHLIST.md
- [ ] Update PROJECT_STATUS.md

**Deliverable:** Documentation commits

---

### Knowledge Transfer (Target: 2 hours)

**Create handover notes:**

- [ ] List 5 things you wish you knew on Day 1
- [ ] Document any confusing areas
- [ ] Suggest documentation improvements
- [ ] Note any tools/scripts you created
- [ ] Identify areas needing more tests

**Deliverable:** HANDOVER_RETROSPECTIVE.md

---

### Final Validation (Target: 2 hours)

**Complete all validation tasks:**

- [ ] Validation Task 1: Read & Build ✅
- [ ] Validation Task 2: Add Simple Field ✅
- [ ] Validation Task 3: Add Simple Metric ✅
- [ ] Validation Task 4: Modify AI Prompt ✅
- [ ] Validation Task 5: Debug an Issue ✅
- [ ] Validation Task 6: Complete Independent Feature ✅

**Self-assessment:**

- [ ] I can build the app from scratch
- [ ] I understand the MVVM architecture
- [ ] I can safely modify SwiftData models
- [ ] I can add/modify calculator metrics
- [ ] I can modify AI prompts
- [ ] I can debug issues independently
- [ ] I can complete features without guidance
- [ ] I feel confident owning this codebase

---

### Handover Meeting (Target: 1 hour)

**Schedule call with original developer:**

- [ ] Demo your completed feature
- [ ] Walk through code changes
- [ ] Discuss architecture decisions
- [ ] Ask clarifying questions
- [ ] Confirm transition plan
- [ ] Discuss ongoing support
- [ ] Get final approval

**Deliverable:** Handover signed off ✅

---

**Week 4 Checkpoint:**

- [ ] Code reviewed and merged
- [ ] Documentation updated
- [ ] All validation tasks complete
- [ ] Self-assessment: Confident
- [ ] Handover meeting complete
- [ ] Officially own the codebase 🎉

---

## Post-Handover (Ongoing)

### First 30 Days After Handover

- [ ] Complete 2-3 more features from PUNCHLIST.md
- [ ] Write additional unit tests for coverage
- [ ] Improve documentation based on your experience
- [ ] Optimize any performance issues
- [ ] Fix any bugs discovered

### First 60 Days

- [ ] Implement larger feature
- [ ] Consider architecture improvements
- [ ] Add integration tests
- [ ] Enhance error handling
- [ ] Document new patterns

### First 90 Days

- [ ] You're now the expert 🎓
- [ ] Update handover docs for next developer
- [ ] Mentor others if needed
- [ ] Plan next major features

---

## Escalation Protocol

**If you get stuck:**

1. Re-read relevant documentation
2. Search codebase for similar patterns
3. Check TROUBLESHOOTING.md (when created)
4. Check GitHub Issues
5. Email original developer: info@htdstudio.net (24-48h response)

**Emergency contact (critical production issues only):**
- Original developer: info@htdstudio.net
- Include: "URGENT - Porteos Intelligence" in subject

---

## Success Criteria

**Handover is COMPLETE when all of these are ✅:**

- [ ] Week 1 checkpoint complete
- [ ] Week 2 checkpoint complete
- [ ] Week 3 checkpoint complete
- [ ] Week 4 checkpoint complete
- [ ] All validation tasks complete
- [ ] At least one feature merged
- [ ] Self-assessment: Confident
- [ ] Original developer sign-off

**🎉 CONGRATULATIONS! You now own Porteos Intelligence! 🎉**

---

**Tracking:**

- Start date: _______________
- Week 1 complete: _______________
- Week 2 complete: _______________
- Week 3 complete: _______________
- Week 4 complete: _______________
- Handover date: _______________

**Notes:**

(Use this space for personal notes, questions, or observations)

---

**Version:** 1.0 (Sept 4, 2026)  
**Last updated by:** Original development team
