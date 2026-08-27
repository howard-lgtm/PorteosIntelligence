# Porteos Intelligence — Wild Release Distribution

Install on **your Macs** without the App Store. Uses **Developer ID** signing + **notarization** so Gatekeeper accepts the app on each machine.

**Bundle ID:** `com.porteos.native.v2`  
**Version:** 1.0 (build 1)  
**Team:** `A33AU765BV`

---

## Prerequisites

1. **Apple Developer Program** membership (you have team `A33AU765BV`)
2. **Developer ID Application** certificate in Keychain (create at [developer.apple.com](https://developer.apple.com/account/resources/certificates/list) if missing)
3. Xcode signed in: **Xcode → Settings → Accounts** → your Apple ID → team selected
4. Target **PorteosIntelligence** → **Signing & Capabilities** → **Automatically manage signing** ON, team `A33AU765BV`

---

## Option A — Xcode (recommended first time)

### 1. Pre-flight

- Scheme: **PorteosIntelligence**
- Destination: **My Mac**
- Edit Scheme → **Run** / **Archive** → **Build Configuration: Release** (Archive uses Release by default)

### 2. Archive

1. **Product → Archive**
2. When Organizer opens, select the archive → **Distribute App**
3. **Custom** → **Next**
4. **Developer ID** → **Next**
5. **Upload** (includes notarization) or **Export** (sign locally, notarize separately)
6. Follow prompts; use **Automatically manage signing**

### 3. Install on this Mac

Drag **PorteosIntelligence.app** to **Applications**.

### 4. Copy to other Macs

- AirDrop, USB drive, iCloud Drive, or zip the `.app`
- On the other Mac: copy to **Applications**, open once
- If notarized + stapled: opens normally
- If not notarized: **System Settings → Privacy & Security → Open Anyway** (one time)

---

## Option B — Command line

From repo root:

```bash
chmod +x scripts/export-wild-release.sh
./scripts/export-wild-release.sh
```

Output: `build/export/PorteosIntelligence.app`

### Notarize (after export)

One-time setup — store an app-specific password in Keychain:

```bash
xcrun notarytool store-credentials "AC_PASSWORD" \
  --apple-id "your@email.com" \
  --team-id A33AU765BV \
  --password "xxxx-xxxx-xxxx-xxxx"
```

Submit and staple:

```bash
ditto -c -k --keepParent build/export/PorteosIntelligence.app PorteosIntelligence.zip
xcrun notarytool submit PorteosIntelligence.zip --keychain-profile "AC_PASSWORD" --wait
xcrun stapler staple build/export/PorteosIntelligence.app
```

Verify:

```bash
spctl -a -vv build/export/PorteosIntelligence.app
# Expected: accepted / source=Notarized Developer ID
```

---

## Install checklist (each Mac)

| Step | Action |
|------|--------|
| 1 | Copy app to `/Applications` |
| 2 | First launch — confirm Pi icon in Dock |
| 3 | Create or import a test deal |
| 4 | **Server Config** — start HTTP listener (default port **9000**) |
| 5 | Optional: load browser extension (see below) |
| 6 | Optional: **Email Setup** — Gmail app password + test connection |

**Data does not sync** between Macs. Export CSV/JSON from one machine and import on another if needed.

---

## Browser extension (per Mac, separate from app signing)

Chrome → **Extensions** → **Developer mode** → **Load unpacked**

Folder:

`BrowserExtension/PorteosImporter/`

Requires Porteos Intelligence running with HTTP server on `localhost:9000`.

---

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| “App is damaged” | Re-export with Developer ID; do not copy Debug builds from DerivedData |
| Gatekeeper blocks open | Notarize + staple, or Open Anyway once |
| No Developer ID cert | Certificates portal → Developer ID Application |
| Archive fails signing | Xcode Accounts → Download Manual Profiles |
| Fonts look wrong | Release build bundles fonts via `INFOPLIST_KEY_ATSApplicationFontsPath` |
| Ingestion server won’t bind | Sandbox allows network server; check port 9000 not in use |
| `build.db disk I/O error` | **Product → Clean Build Folder**, quit Xcode, delete DerivedData for this project |

---

## What you are NOT doing

- No App Store Connect listing
- No public TestFlight (optional later)
- No Mac App Store review

This is **direct distribution** for personal / internal use across your machines.

---

## Local LLM — Ollama Setup & Model Recommendations

Porteos Intelligence uses **Ollama** (`http://localhost:11434`) for AI Vibe analysis (SWOT + Go/Review/NoGo) and the Global Intelligence daily brief. All inference is local — no portfolio data leaves the device.

### Install Ollama

```bash
# Download from https://ollama.com or via Homebrew:
brew install ollama

# Start the server (runs in background):
ollama serve
```

### Configure in Porteos

**Settings → INTELLIGENCE** — set endpoint and model name, then `[ TEST CONNECTION ]`.  
Default endpoint: `http://localhost:11434`  
Default model: `qwen2.5:0.5b`

### Model recommendations by hardware

The model weights must fit in available RAM (unified memory on Apple Silicon).

#### Apple Silicon (M-series)

| Model | Pull command | RAM needed | Speed | Quality | Notes |
|-------|-------------|-----------|-------|---------|-------|
| `qwen2.5:0.5b` | `ollama pull qwen2.5:0.5b` | ~1 GB | Instant | ⭐⭐ | Default — fast fallback |
| `phi4-mini` | `ollama pull phi4-mini` | ~3.5 GB | Very fast | ⭐⭐⭐⭐ | **Recommended start** — best analytical reasoning per GB |
| `qwen2.5:3b` | `ollama pull qwen2.5:3b` | ~3 GB | Very fast | ⭐⭐⭐ | Natural upgrade from 0.5b, same family |
| `llama3.2:3b` | `ollama pull llama3.2:3b` | ~3 GB | Very fast | ⭐⭐⭐ | Solid instruction following |
| `mistral:7b` | `ollama pull mistral:7b` | ~6 GB | Fast | ⭐⭐⭐⭐ | Excellent structured output |
| `qwen2.5:14b` | `ollama pull qwen2.5:14b` | ~11 GB | Moderate | ⭐⭐⭐⭐⭐ | Serious quality jump for 18GB+ machines |
| `qwen2.5:32b` | `ollama pull qwen2.5:32b` | ~22 GB | Slower (~20s) | ⭐⭐⭐⭐⭐⭐ | **Best on 32GB M2 Max** — investment-grade analysis |

**Ceiling by machine:**

| Machine | Practical ceiling |
|---------|-----------------|
| M2 Max 32 GB (dev machine) | `qwen2.5:32b` — exceptional |
| M2/M3 Pro 18 GB | `qwen2.5:14b` — very good |
| M1/M2 16 GB | `mistral:7b` / `qwen2.5:7b` — solid |
| M1 8 GB | `phi4-mini` / `qwen2.5:3b` — comfortable |

> **Note:** M-series unified memory means the full RAM is available to the GPU — a 32 GB M2 Max outperforms most Windows consumer GPUs for local inference because RTX 4090 only has 24 GB VRAM.

#### Windows / Linux (discrete GPU)

| GPU VRAM | Practical ceiling |
|----------|-----------------|
| RTX 4090 (24 GB) | `llama3:70b` Q4 — cuts through it |
| RTX 4070 (12 GB) | `qwen2.5:14b` |
| RTX 3060 (8 GB) | `mistral:7b` |
| RTX 3050 (6 GB) | `phi4-mini` / `qwen2.5:3b` |

For CPU-only Windows machines, use 3B models and expect 5-15 tok/s.

### Recommended sequence

```bash
# Step 1 — immediate quality improvement, minimal cost:
ollama pull phi4-mini

# Step 2 — if you want deeper analytical SWOT:
ollama pull qwen2.5:14b

# Step 3 — best this machine can do (32 GB only):
ollama pull qwen2.5:32b
```

Switch model in **Settings → INTELLIGENCE → MODEL** — no rebuild required.

### Privacy

- Ollama runs entirely on-device. Porteos does not send data to any external API.
- The SWOT prompt includes deal name, score, signals, and market benchmarks — all local data.
- Configured endpoint and model name are stored in `UserDefaults` (not Keychain — not sensitive).

---

## What you are NOT doing

- No App Store Connect listing
- No public TestFlight (optional later)
- No Mac App Store review

This is **direct distribution** for personal / internal use across your machines.

---

## Related docs

- [`PACKAGE_v1_STATUS.md`](PACKAGE_v1_STATUS.md)
- [`PACKAGE_v1_PUNCHLIST.md`](PACKAGE_v1_PUNCHLIST.md) — PKG section
