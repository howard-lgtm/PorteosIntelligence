# Porteos Intelligence — Developer Setup Guide

Complete environment setup guide from zero to first successful build.

---

## System Requirements

### Hardware
- **Mac:** Intel or Apple Silicon (Universal binary)
- **RAM:** 8GB minimum, 16GB+ recommended
- **Storage:** 5GB for Xcode + project

### Software
- **macOS:** 14.6 Sonoma or later (required for SwiftData and MapKit features)
- **Xcode:** 16.6 or later
- **Swift:** 5.9+ (bundled with Xcode)
- **Git:** 2.x (pre-installed on macOS or via `brew install git`)

---

## 1. Install Xcode

### Option A: Mac App Store (Recommended)
1. Open Mac App Store
2. Search for "Xcode"
3. Download and install (14GB download, ~40GB installed)

### Option B: Apple Developer
1. Visit [developer.apple.com/download](https://developer.apple.com/download)
2. Download Xcode 16.6 or later
3. Extract and move to `/Applications/`

### Verify Installation
```bash
xcodebuild -version
# Expected: Xcode 16.6 or later

swift --version
# Expected: Swift version 5.9+ or later
```

### Command Line Tools
Xcode should automatically prompt to install Command Line Tools. If not:
```bash
xcode-select --install
```

---

## 2. Install JetBrains Mono Font (Required)

The terminal aesthetic requires JetBrains Mono. The app will not display correctly without it.

### Download & Install
1. Visit [jetbrains.com/lp/mono](https://www.jetbrains.com/lp/mono/)
2. Download the font package
3. Extract and install all font files (TTF or OTF)
4. Verify: Open Font Book, search for "JetBrains Mono"

**The app will fail to render properly if this font is missing.**

---

## 3. Clone Repository

```bash
# Clone from GitHub
git clone https://github.com/howard-lgtm/PorteosIntelligence.git
cd PorteosIntelligence

# Verify structure
ls -l
# Expected: PorteosIntelligence.xcodeproj, PorteosIntelligence/, BrowserExtension/, etc.
```

---

## 4. Open Project in Xcode

```bash
open PorteosIntelligence.xcodeproj
```

**Do NOT open the `.xcworkspace` file** — this project does not use CocoaPods or SPM, so you want the `.xcodeproj` directly.

---

## 5. Configure Build Settings (Usually Automatic)

Xcode should detect your system and configure automatically. Verify:

1. Select **PorteosIntelligence** target in left sidebar
2. **General** tab:
   - **Deployment Info:** macOS 14.6 or later
   - **Architectures:** Universal (Apple Silicon, Intel)
3. **Signing & Capabilities** tab:
   - **Team:** Select your Apple Developer team (or use "Sign to Run Locally")
   - **Bundle Identifier:** Leave as `net.htdstudio.PorteosIntelligence` or change to your own

### If You Don't Have an Apple Developer Account
- Select **Signing & Capabilities**
- **Team:** Choose your personal team (auto-generated)
- Xcode will create a development certificate for you

---

## 6. First Build

```bash
# In Xcode: ⌘B (Build)
# Expected: "Build Succeeded" (1-3 minutes on first build)
```

**Common Build Issues:**

| Error | Fix |
|-------|-----|
| "JetBrains Mono font not found" | Install font (step 2), restart Xcode |
| "Signing failed" | Select a valid team in Signing & Capabilities |
| "SwiftData schema error" | Clean build folder: ⇧⌘K, then rebuild |
| "macOS 14.6 SDK not found" | Update Xcode to 16.6+ |

---

## 7. Run the App

```bash
# In Xcode: ⌘R (Run)
# Expected: App launches in ~5-10 seconds, shows boot splash, then 3-pane shell
```

### First Launch Behavior
1. **Boot splash:** 2-3 second animated intro (may skip in debug mode)
2. **Empty state:** No deals yet — add one manually or via browser extension
3. **Background services:**
   - HTTP ingestion server starts on port 9000 (for browser extension)
   - Email monitoring service idle (not configured)
   - News aggregator idle (will fetch on first Global Intelligence visit)

---

## 8. Verify Core Functionality

### Create a Test Deal
1. Click **`[ ./NEW_DEAL ]`** (bottom-left)
2. Fill **BASE** tab:
   - Property Name: "Test Property"
   - Address: "123 Main St, San Francisco, CA"
   - Property Type: "Residential - Single Family"
   - Purchase Price: 1000000
   - Location City: "San Francisco"
   - Location Country: "United States"
3. Click **`[ SAVE ]`**
4. Deal appears in left nav with a Porteos Score (0-100)

### Verify Features
- ☑ **Left nav:** Deal list loads, shows scores
- ☑ **Inspector:** Tabs (WEIGHTS, AI VIBE, MEDIA) render
- ☑ **Profiles:** Switch between profiles (⌘1-⌘6) — dashboards render
- ☑ **Multi-window:** Hover profile name → **`[ ↗ ]`** opens new window
- ☑ **HTTP server:** Green `HTTP` indicator in top-right (means port 9000 active)

---

## 9. Run Unit Tests

```bash
# In Xcode: ⌘U (Test)
# Expected: 7 test bundles run, all pass
```

**Test Coverage:**
- `DesignCalculatorTests` — Space efficiency, biophilic elements
- `CircularEconomyCalculatorTests` — Material flow, carbon lifecycle
- `PorteosScoreCalculatorTests` — Composite scoring algorithm
- `HospitalityCalculatorTests` — RevPAR, ADR, GOP
- `PorteosIntelligenceTests` — General app tests
- `PorteosIntelligenceUITests` — Launch tests

If tests fail, **do not proceed** — investigate and fix before making changes.

---

## 10. Optional: Install External Services

### Ollama (Local AI)

**For AI Vibe and RESEARCH features:**

```bash
# Install Ollama
brew install ollama

# Start Ollama server
ollama serve
# Runs on http://localhost:11434

# Pull a model (in new terminal)
ollama pull qwen2.5:0.5b
# or: ollama pull phi4-mini

# Configure in app
# Settings → AI Provider → Select "Local (Ollama)"
```

### Browser Extension

**For one-click listing imports:**

1. Open Chrome (or Arc, Edge, Brave)
2. Navigate to `chrome://extensions`
3. Enable **Developer mode** (top-right toggle)
4. Click **Load unpacked**
5. Select folder: `PorteosIntelligence/BrowserExtension/PorteosImporter/`
6. Extension appears in toolbar

**Test:**
- Visit https://www.zillow.com/homedetails/123-Main-St-San-Francisco-CA-94102/...
- Click **`[ SEND TO PORTEOS ]`** (bottom-right overlay)
- Deal appears in app within 2 seconds

**Note:** App must be running for extension to work (HTTP server on port 9000).

---

## 11. Development Tools

### Xcode Schemes

**PorteosIntelligence (default):**
- **Run:** Debug build, localhost mode
- **Test:** Runs all test bundles
- **Profile:** Performance analysis
- **Analyze:** Static analysis for memory leaks
- **Archive:** Release build for distribution

### Build Configurations

| Configuration | Purpose | Optimizations |
|--------------|---------|---------------|
| **Debug** | Development, Xcode running | None, fast compile |
| **Release** | Production, TestFlight, App Store | Full, slower compile |

### Useful Scripts

**Typography check:**
```bash
./scripts/typography-check.sh
# Verifies all UI text uses JetBrains Mono, flags violations
```

**Export release build:**
```bash
./scripts/export-wild-release.sh
# Builds .app bundle with Developer ID signing
# Output: ~/Desktop/PorteosIntelligence.app
```

---

## 12. Code Editor Setup (Optional)

### Xcode Extensions
- **SwiftFormat:** Auto-format on save (optional, not currently in project)
- **SwiftLint:** Code quality checks (optional, not currently in project)

### Cursor IDE Integration
The project includes `.cursor/rules/` with AI coding standards. If using Cursor:
- Rules automatically apply to AI-generated code
- Enforces design system, MVVM patterns, and quality gates

---

## 13. Debugging Tools

### Xcode Debugger
- **Breakpoints:** Click line number gutter
- **LLDB Console:** View output, run commands
- **View Hierarchy:** Debug → View Debugging → Capture View Hierarchy

### Common Debug Scenarios

**App crashes on launch:**
```
1. Clean build folder: ⇧⌘K
2. Delete DerivedData: ~/Library/Developer/Xcode/DerivedData/PorteosIntelligence-*
3. Restart Xcode
4. Rebuild
```

**SwiftData "schema mismatch" error:**
```
1. Quit app
2. Delete database: ~/Library/Containers/net.htdstudio.PorteosIntelligence/Data/Library/Application Support/default.store
3. Relaunch app (fresh DB created)
```

**LLM features not working:**
```
1. Check Settings → AI Provider
2. For Ollama: Verify `ollama serve` running in terminal
3. For OpenAI/Gemini: Verify API key set in Settings
4. Check Inspector → AI VIBE → Error message
```

**Browser extension not connecting:**
```
1. Verify app is running
2. Check top-right `HTTP` indicator is green
3. Open browser console (F12), look for "Failed to fetch http://localhost:9000"
4. Reload extension in chrome://extensions
```

---

## 14. Next Steps

Once you've successfully built and run the app:

1. **Read architecture:** [ARCHITECTURE.md](ARCHITECTURE.md)
2. **Understand data model:** [DATA_MODEL_GUIDE.md](DATA_MODEL_GUIDE.md)
3. **Learn design system:** [01_TERMINAL_DESIGN_SYSTEM.md](01_TERMINAL_DESIGN_SYSTEM.md)
4. **Review development rules:** [PorteosIntelligence/DEVELOPMENT_RULES.md](PorteosIntelligence/DEVELOPMENT_RULES.md)
5. **Check project status:** [PROJECT_STATUS.md](PROJECT_STATUS.md)
6. **Pick a task:** [PUNCHLIST.md](PUNCHLIST.md)

---

## Troubleshooting

### Build Errors

**"Module 'SwiftUI' not found"**
- Xcode Command Line Tools not installed
- Run: `xcode-select --install`

**"JetBrains Mono font not available"**
- Font not installed or Xcode needs restart
- Install font, quit Xcode, reopen project

**"Code signing failed"**
- No valid team selected
- Go to Signing & Capabilities, select team or "Sign to Run Locally"

### Runtime Issues

**App launches but shows blank window**
- Database corruption
- Delete: `~/Library/Containers/net.htdstudio.PorteosIntelligence/Data/`
- Relaunch

**"HTTP server failed to start"**
- Port 9000 already in use
- Kill process: `lsof -ti:9000 | xargs kill -9`
- Relaunch app

**AI Vibe button does nothing**
- No AI provider configured
- Settings → AI Provider → Choose Ollama/OpenAI/Gemini
- Configure API key if using cloud providers

---

## FAQ

**Q: Do I need an Apple Developer account?**  
A: Not for local development. Xcode creates a free personal team. Only needed for App Store distribution.

**Q: Can I use VSCode or other editors?**  
A: For viewing code, yes. For building/running, you need Xcode (Swift/SwiftUI requires it).

**Q: Is internet required?**  
A: Not for building or running core features. Only for AI features (unless using Ollama locally), news feeds, and geocoding.

**Q: Where is the database stored?**  
A: `~/Library/Containers/net.htdstudio.PorteosIntelligence/Data/Library/Application Support/default.store`

**Q: How do I reset the app completely?**  
A: Delete the container folder above, then relaunch. All data is lost (unrecoverable).

**Q: Can I build for Windows or Linux?**  
A: No. SwiftUI + SwiftData + MapKit are macOS-only. Cross-platform version would require full rewrite.

---

## Getting Help

1. **Check existing docs:** Most questions answered in linked documentation
2. **Search issues:** https://github.com/howard-lgtm/PorteosIntelligence/issues
3. **Ask the team:** info@htdstudio.net

---

**Setup Complete!** You should now have a working development environment. Proceed to [ARCHITECTURE.md](ARCHITECTURE.md) to understand the system design.
