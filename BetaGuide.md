# Porteos Intelligence — Beta Guide
**Version 1.0 Beta · August 2026 · macOS only (Apple Silicon + Intel via Rosetta 2)**

Thank you for being part of this early access group. This guide covers everything you need to get started and give meaningful feedback.

---

## What Porteos Intelligence Is

A terminal-style investment intelligence platform for real estate and hospitality deal analysis. It combines financial calculators, AI-generated SWOT analysis, market benchmarks, and a global intelligence news feed — all running locally on your Mac with your own data, never in the cloud.

---

## Before You Start

### 1. System Requirements
- macOS 14 Sonoma or later (required for data layer)
- Intel Macs: works via Rosetta 2 (automatic, no action needed)
- Internet connection for news feeds and cloud AI (optional)

### 2. AI Analysis — Choose One Option

The AI Vibe checker and Intel Brief require a language model. Pick whichever fits you:

**Option A — Local (Ollama) · Recommended for privacy**
Runs fully on your machine. No API key, no cost, no data leaves your device.
1. Download Ollama from [ollama.ai](https://ollama.ai)
2. Open Terminal and run: `ollama serve`
3. Pull a model: `ollama pull phi4-mini`
4. In Porteos → Settings → AI Provider → select **Local (Ollama)**

**Option B — OpenAI (ChatGPT API) · Easiest setup**
1. Go to [platform.openai.com/api-keys](https://platform.openai.com/api-keys)
2. Create an API key
3. In Porteos → Settings → AI Provider → select **OpenAI** → paste your key
4. Cost: approximately $0.01 per AI Vibe analysis (gpt-4o-mini)

**Option C — Google Gemini · Free tier available**
1. Go to [aistudio.google.com/app/apikey](https://aistudio.google.com/app/apikey)
2. Create an API key (free tier: 15 requests/minute)
3. In Porteos → Settings → AI Provider → select **Gemini** → paste your key

> The app is fully functional without AI — dashboards, calculators, market data, and multi-window all work. AI features are additive.

---

## Installing the Browser Extension

The Porteos Importer lets you send listings from Zillow, Idealista, Casa SAPO, RE/MAX Portugal, and Hemnet into the app with one click.

**Works on:** Chrome, Edge, Arc, Brave, Vivaldi (all Chromium-based)
**Does not work on:** Safari, Firefox (coming later)

### Install from Chrome Web Store (easiest)
[Porteos Importer](https://chrome.google.com/webstore/detail/dkgbibkdnoadaedfajhnjhnmopckgoll)

### Manual install
1. Download and unzip `PorteosImporter.zip` (shared separately)
2. Open Chrome → go to `chrome://extensions`
3. Toggle **Developer mode** ON (top-right corner)
4. Click **Load unpacked** → select the unzipped `PorteosImporter` folder
5. The Porteos icon appears in your extensions bar

**Note:** The Porteos Intelligence app must be running and the ingestion server must be active for imports to work. Check the `HTTP` indicator in the top-right of the app — it should show green.

---

## Key Features to Test

### Importing a Deal
- **Browser extension:** Visit a listing on Zillow, Idealista, or Casa SAPO. The `[ SEND TO PORTEOS ]` button appears bottom-right. Click it — the deal appears in Porteos within seconds.
- **Manual:** Click `[ ./NEW_DEAL ]` in the bottom-left, fill in the BASE tab at minimum (name, location, purchase price).
- **Research JSON:** Paste structured research data using `[ IMPORT RESEARCH JSON ]` in the edit sheet.

### The Porteos Score
Each deal gets a score from 0–100 (grade A–F). It's calculated from:
- Cap rate and yield vs market benchmarks
- DSCR (debt service coverage) and LTV
- Cash-on-cash return
- Design and circular economy inputs (if filled)
- Regulatory advisory flags (heritage, planning status, STR licence)

Scores are property-type-aware — a hotel and a residential flat are judged by different metrics. Unfilled profile tabs don't penalise the score.

### AI Vibe Checker
Open any deal → Inspector panel → `[AI VIBE]` tab → `[ REGENERATE ]`. Produces a SWOT analysis calibrated to the property type (Hotel, Residential, Farm/Rural, Multi-Dwelling, Commercial). Your deal notes feed directly into the analysis.

### Multi-Window Profiles
In the left nav, hover over any profile name (REAL ESTATE, HOSPITALITY, DESIGN, CIRCULAR ECONOMY) — a `[ ↗ ]` button appears. Click it to open that profile in an independent window on any screen. All windows stay in sync — changing the selected deal updates all open windows simultaneously.

### Global Intelligence
The GLOBAL INTELLIGENCE section provides market-filtered news feeds and a daily AI intelligence brief for your portfolio markets. The INTEL tab shows 5 AI-generated market signals, contributing headlines (tap to expand article previews), and 4 signal cards (REG. PRESSURE, RATE OUTLOOK, TOURISM INDEX, SUPPLY PIPELINE) — tap any card to see the supporting articles.

### Market Preload
When adding or editing a deal, `[ PRELOAD MARKET ASSUMPTIONS ]` fills financial benchmarks (cap rate, ADR, RevPAR, OpEx, etc.) from a database of 80+ cities. Always review and adjust before relying on preloaded values.

### Unit System
The app automatically switches between metric (m², €) and imperial (ft², $) based on the deal's country. US deals → ft²/$. European deals → m²/€. Override in Settings → Units.

---

## Known Limitations in This Beta

- **Safari extension:** Not supported in this version. Chrome/Arc/Edge recommended.
- **Windows:** macOS only. Windows version planned for a future release.
- **Live market data:** Cap rates, ADR, and benchmark figures are 2024–25 static estimates, not live feeds. Treat as directional guidance, not precision data.
- **Onboarding:** A guided onboarding experience is coming in the next version. For now, this guide is your reference.
- **SOC/ISO compliance:** Security hardening is planned post-beta. Do not store sensitive client data in this version.

---

## What We'd Love Feedback On

1. **First impression** — what's confusing on first open?
2. **Deal import** — does the browser extension work on the sites you use?
3. **Score accuracy** — does the Porteos Score align with your professional judgement on deals you know?
4. **AI Vibe quality** — are the SWOT bullets relevant and specific, or generic?
5. **Multi-window** — useful for your workflow, or not?
6. **Missing property types or markets** — what's not covered that you need?
7. **Anything broken** — screenshot and send

---

## Sending Feedback

[Contact details / email to be added]

Please include the app version (shown in Settings) and your macOS version when reporting issues.

---

*Porteos Intelligence is under active development. Your feedback directly shapes what gets built next.*
