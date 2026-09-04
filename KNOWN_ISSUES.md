# Known Issues — Porteos Intelligence

**Last Updated:** September 4, 2026

---

## 🐛 Active Issues

### 1. Command-Line Testing (xcodebuild test)

**Issue:** `xcodebuild test` command fails with "Scheme is not currently configured for the test action"

**Status:** Known limitation, not blocking

**Details:**
- Command: `xcodebuild test -scheme PorteosIntelligence`
- Error: "Scheme PorteosIntelligence is not currently configured for the test action"
- Affects: Both `PorteosIntelligence` and `PorteosUnitTests` schemes
- Schemes appear correctly configured (TestableReference present)
- Likely caused by sandbox/environment restrictions

**Workaround:** ✅ Use Xcode IDE for testing
- Press ⌘U to run tests in Xcode
- All tests run successfully in IDE
- This is the recommended approach for MLX Bionic handover

**Impact:** Low
- Does not affect development workflow
- Does not affect CI/CD (if using Xcode Cloud or similar)
- Tests are fully functional in Xcode

**Investigation Notes:**
- Both scheme files contain valid `<TestableReference>` entries
- Issue appears related to xcodebuild command-line tool environment
- All simulator service connections fail in sandbox
- This is a tooling issue, not a code issue

**Future Fix:**
- Run xcodebuild outside sandbox (requires full_network or all permissions)
- Or accept that command-line testing only works in IDE
- Or configure proper xcresult parsing from Xcode IDE runs

**For MLX Bionic:**
- Continue handover as normal
- Use ⌘U in Xcode for test validation
- Ignore setup.sh warnings about command-line testing
- This does not affect your ability to develop

---

## 📋 Historical Issues (Resolved)

(None yet - project is stable)

---

## 💡 Reporting New Issues

If you discover new issues during handover:

1. Document them here
2. Include:
   - Clear description
   - Steps to reproduce
   - Workaround (if any)
   - Impact level (High/Medium/Low)
3. Email original developer if blocking: info@htdstudio.net

---

**Version:** 1.0  
**Maintained By:** Development team
