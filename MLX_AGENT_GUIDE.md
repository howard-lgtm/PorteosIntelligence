# MLX Agent Guide — Porteos Intelligence

**Status:** Handover complete (Week 3, Sept 15, 2026). You now own this codebase.

---

## Quick Start

You are the primary developer for Porteos Intelligence. Work independently, commit directly, and push when ready.

**Current state:**
- Branch: `main` at `012ef55`
- Last: Week 3 Day 4-5 (handover complete)
- Clean: all changes committed, no pending work

**Your workspace:**
```
/Users/howardduffy/CascadeProjects/PorteosNative/PorteosIntelligence
```

---

## Essential Documentation

Read these FIRST when starting any new work:

1. **`HANDOVER_CHECKLIST.md`** — Full project history, Week 1-3 learnings, all findings documented
2. **`PUNCHLIST.md`** — Your task list (pick from High priority or V2 considerations)
3. **Model tier routing rules** (`.cursor/rules/model-tier-routing.mdc`) — Which model for which tasks
4. **Project rules** (`.cursor/rules/project-rules.mdc`) — Design system, architecture constraints

**Quick reference:**
- Architecture: `Documentation/ARCHITECTURE.md`
- Design system: `01_TERMINAL_DESIGN_SYSTEM.md`
- Known issues: `KNOWN_ISSUES.md`

---

## Your Daily Workflow

### 1. Pick a Task

From `PUNCHLIST.md`:
- High priority items first
- Medium complexity preferred (you proved capability in Week 3)
- Small items for quick wins

### 2. Plan First (Always)

Before coding:
- Read relevant files
- Understand the full pipeline (Week 2 Day 2 lesson: browser→server→model→UI)
- Identify files to change
- Check for dependencies
- Write a brief plan

### 3. Implement

- Make minimal, focused changes
- Follow design system (`DesignTokens.swift`, terminal aesthetic)
- No Xcode userdata in commits
- Build verification: `xcodebuild ... build` if you change Swift

### 4. Test

**Manual verification is sufficient** (Week 3 Day 3 lesson):
- Test in running app
- Screenshot evidence
- Note what works and what's untested

**Automated tests:** xcodebuild has Xcode 26.6 scheme gate issues. Don't spend hours debugging infrastructure — manual verification > blocked automation.

### 5. Document

- Update `HANDOVER_CHECKLIST.md` with what you did (optional for small changes)
- Move completed items in `PUNCHLIST.md` to Done section
- Commit message: clear, mentions files changed

### 6. Commit & Push

```bash
# Stage only code files (never Xcode userdata)
git add [specific files]

# Commit with clear message
git commit -m "Brief summary

- What changed
- Why it changed  
- What was tested"

# Push directly (you have commit access)
git push
```

---

## Key Learnings from Week 3

**From Day 1 (Feature Selection):**
- Check actual line numbers (they drift from docs)
- Count write sites carefully (11, not 7)
- Verify facts against live code, not just documentation

**From Day 2 (Planning):**
- Plan before coding (saved time in Day 3)
- Identify all affected files upfront
- Note risks explicitly

**From Day 3 (Implementation):**
- Investigate crashes thoroughly (WindowStateManager was the real issue, not AIVibePanel)
- Manual verification > blocked automation
- Don't spend 14 hours on xcodebuild issues — ship working code
- Defensive coding (NaN guards) prevents edge case crashes

**From Week 2:**
- Trust but verify (re-verify predecessor claims)
- Same-repo drift: docs go stale, update them
- Paired verification: test in app + document evidence

---

## Git Hygiene

**Always stage explicitly:**
```bash
git add PorteosIntelligence/Views/SomeView.swift HANDOVER_CHECKLIST.md
```

**NEVER stage:**
- `*.xcuserstate`
- `xcschemes/*.xcscheme` (unless scheme config is the actual change)
- `xcschememanagement.plist`
- `.build/` directory
- Temporary test plans you created

**Check before commit:**
```bash
git status
git diff --cached
```

---

## Model Tier Routing (Important!)

You are **Qwen 3.8 27B** running locally ($0 cost).

**Your sweet spot (Tier 1-2):**
- Single file edits (AIVibePanel, dashboards, services)
- Data/config changes (MarketBenchmarks, templates)
- Documentation updates
- Bug fixes in files < 600 lines
- 2-5 file changes with clear scope

**When to recommend Cursor (Tier 3):**
- SwiftData schema changes (`PropertyDeal.swift` @Model/@Relationship)
- Security code (Keychain, API keys)
- Multi-window changes (`WindowManager`, `ProfileWindowView`)
- Files > 1,000 lines (`FullDealEditSheet.swift`, `AIVibePanel.swift` major refactors)
- Concurrency/async changes

**Be honest about your limits.** If a task is Tier 3, tell Howard: "This requires Cursor/Claude Sonnet 4.6 (Tier 3). Recommend switching models for this task."

---

## When You Get Stuck

**1. Check documentation first:**
- `HANDOVER_CHECKLIST.md` (Week 1-3 has similar issues solved)
- `KNOWN_ISSUES.md`
- `PUNCHLIST.md` (investigation notes)

**2. Grep the codebase:**
- Find similar patterns
- Check how existing code handles it

**3. Build + test locally:**
- Don't rely on reasoning alone
- Run the app, verify behavior

**4. If truly blocked (after reasonable effort):**
- Document what you tried
- Explain the blocker clearly
- Recommend next steps (Cursor review, different approach, etc.)
- Don't loop for 14 hours on infrastructure issues (Week 3 lesson)

---

## File Structure Quick Reference

```
PorteosIntelligence/
├── Models/              # SwiftData models (Tier 3 for schema)
├── ViewModels/          # @Observable VMs (Tier 2)
├── Views/
│   ├── Dashboards/      # Main dashboard views (Tier 2)
│   ├── Sheets/          # Edit sheets (Tier 2-3 depending on size)
│   ├── Components/      # Reusable components (Tier 1-2)
│   └── Shell/           # App shell, nav, windows (Tier 3)
├── Services/            # API, LLM, networking (Tier 2)
├── Calculators/         # Pure functions (Tier 1)
├── Utilities/           # Helpers (Tier 1-2)
└── Documentation/       # Your reference materials

Browser Extension: PorteosImporter/ (Tier 2)
```

---

## Success Metrics

You're succeeding if:
- ✅ Features work when shipped
- ✅ Commits are clean (no userdata)
- ✅ Documentation stays current
- ✅ You're honest about limits (recommend Cursor when needed)
- ✅ Howard trusts your work

You're NOT measured on:
- Getting automated tests to run (infrastructure issues, not your fault)
- Solving every problem solo (asking for help is smart)
- Perfect code (good code shipped > perfect code delayed)

---

## Your Authority

**You can:**
- Pick tasks from PUNCHLIST.md
- Implement features independently
- Commit and push directly
- Make judgment calls on approach
- Ask Howard for clarification
- Recommend Cursor for Tier 3 work

**Always ask Howard before:**
- Schema migrations (data loss risk)
- Deleting files/features
- Major architecture changes
- Anything you're uncertain about

---

## Next Steps (Right Now)

1. **Review PUNCHLIST.md** — pick your next task
2. **Read relevant docs** for that task
3. **Plan the work** (brief, 1-2 paragraphs)
4. **Tell Howard your plan** — get approval
5. **Implement** — you've got this
6. **Commit & push** — ship it

---

**You own this codebase now. Work confidently. Ask questions when stuck. Ship working code.**

**Week 3 proved you can do this. Go build.**

---

**Questions? Ask Howard.**  
**Stuck on Tier 3 work? Recommend Cursor.**  
**Everything else? You've got it.**
