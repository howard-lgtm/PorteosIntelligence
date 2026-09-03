# Porteos Intelligence — External Services Setup Guide

Complete guide to configuring all external integrations: AI/LLM providers, browser extension, email monitoring, and news feeds.

---

## Table of Contents

1. [AI/LLM Providers](#aillm-providers)
2. [Browser Extension](#browser-extension)
3. [Email Monitoring (IMAP)](#email-monitoring-imap)
4. [News Feeds (RSS)](#news-feeds-rss)
5. [Geocoding (MapKit)](#geocoding-mapkit)
6. [Troubleshooting](#troubleshooting)

---

## AI/LLM Providers

The app supports 3 LLM providers for AI Vibe (SWOT analysis) and RESEARCH chat. Choose ONE:

### Option 1: Ollama (Local, Recommended)

**Pros:**
- ✅ Free, unlimited usage
- ✅ No API keys needed
- ✅ Completely private (data never leaves your Mac)
- ✅ No internet required after model download

**Cons:**
- ⚠️ Requires ~4-8GB disk space per model
- ⚠️ Slower on older Macs
- ⚠️ Quality depends on model size

#### Installation

```bash
# Install Ollama via Homebrew
brew install ollama

# Start Ollama server (keep this terminal open)
ollama serve
# Output: "Ollama is running on http://localhost:11434"
```

#### Download a Model

```bash
# In a NEW terminal (keep ollama serve running)

# Small, fast model (2.5GB) — good for testing
ollama pull phi4-mini

# OR: Better quality model (4.7GB) — recommended
ollama pull qwen2.5-coder:7b

# OR: High-quality reasoning model (9GB) — best results
ollama pull deepseek-r1:14b
```

**Verify:**
```bash
ollama list
# Should show your downloaded model(s)
```

#### Configure in Porteos

1. Open Porteos Intelligence
2. **Settings → AI Provider**
3. Select: **"Local (Ollama)"**
4. Base URL: `http://localhost:11434` (default)
5. Model Name: Enter the model you pulled (e.g., `qwen2.5-coder:7b`)
6. Click **Save**

#### Test

1. Select any deal
2. **Inspector → AI VIBE tab**
3. Click **`[ REGENERATE ]`**
4. Should see "Analyzing..." then SWOT analysis appears (~5-10 seconds)

---

### Option 2: OpenAI (Cloud, Easiest)

**Pros:**
- ✅ Highest quality responses
- ✅ Fast (cloud GPUs)
- ✅ No local setup

**Cons:**
- ⚠️ Costs $0.01-$0.02 per analysis (gpt-4o-mini)
- ⚠️ Requires internet
- ⚠️ Data sent to OpenAI servers

#### Get API Key

1. Visit https://platform.openai.com/api-keys
2. Sign in or create account
3. Click **"Create new secret key"**
4. Name: "Porteos Intelligence"
5. Copy key (starts with `sk-...`)

**Important:** You'll need to add payment method at https://platform.openai.com/account/billing

#### Configure in Porteos

1. Open Porteos Intelligence
2. **Settings → AI Provider**
3. Select: **"OpenAI (ChatGPT)"**
4. Paste API key
5. Click **Save**

**Key stored securely in macOS Keychain**

#### Test

1. Select any deal
2. **Inspector → AI VIBE tab**
3. Click **`[ REGENERATE ]`**
4. Should see "Analyzing..." then SWOT analysis appears (~2-3 seconds)

**Cost Estimate:**
- AI Vibe analysis: ~500-1000 tokens = $0.01
- RESEARCH chat turn: ~300-800 tokens = $0.005
- Monthly (50 analyses): ~$0.50

---

### Option 3: Google Gemini (Cloud, Free Tier)

**Pros:**
- ✅ Free tier: 15 requests/minute
- ✅ Good quality
- ✅ No payment method required initially

**Cons:**
- ⚠️ Requires internet
- ⚠️ Rate limits on free tier
- ⚠️ Data sent to Google servers

#### Get API Key

1. Visit https://aistudio.google.com/app/apikey
2. Sign in with Google account
3. Click **"Create API key"**
4. Select "Create API key in new project" (or choose existing)
5. Copy key (long alphanumeric string)

#### Configure in Porteos

1. Open Porteos Intelligence
2. **Settings → AI Provider**
3. Select: **"Google Gemini"**
4. Paste API key
5. Click **Save**

**Key stored securely in macOS Keychain**

#### Test

1. Select any deal
2. **Inspector → AI VIBE tab**
3. Click **`[ REGENERATE ]`**
4. Should see "Analyzing..." then SWOT analysis appears (~3-5 seconds)

**Rate Limits:**
- Free tier: 15 requests/minute, 1500/day
- Paid tier: 2000/minute (if you upgrade)

---

### Token Limits by Provider

| Provider | Max Tokens | Use Case |
|----------|-----------|----------|
| **Ollama** | 4,096 | Good for long research responses |
| **OpenAI** | 3,000 | Concise, high-quality answers |
| **Gemini** | 3,000 | Balanced responses |

**Note:** If you hit token limits, responses may be truncated with a warning.

---

## Browser Extension

One-click property import from 12 major real estate sites.

### Supported Sites

**United States:**
- Zillow.com
- Realtor.com
- Redfin.com
- Trulia.com

**Portugal:**
- Idealista.pt
- Casa.sapo.pt
- RE/MAX.pt
- Imovirtual.com

**Spain:**
- Idealista.com
- Fotocasa.es

**Sweden:**
- Hemnet.se
- Booli.se

### Installation (Chrome, Arc, Edge, Brave)

**Step 1: Locate Extension Folder**
```
PorteosIntelligence/BrowserExtension/PorteosImporter/
```

**Step 2: Load Extension**

1. Open Chrome (or Arc, Edge, Brave)
2. Navigate to: `chrome://extensions`
3. Enable **"Developer mode"** (top-right toggle)
4. Click **"Load unpacked"**
5. Navigate to and select: `PorteosImporter/` folder
6. Extension appears with Porteos icon

**Step 3: Pin Extension** (optional but recommended)

1. Click puzzle icon in browser toolbar
2. Find "Porteos Importer"
3. Click pin icon

### Usage

1. **Start Porteos Intelligence app** (must be running)
2. Visit a supported listing page (e.g., https://www.zillow.com/homedetails/...)
3. **`[ SEND TO PORTEOS ]`** button appears (bottom-right overlay)
4. Click button
5. Toast: "Sent to Porteos!"
6. Deal appears in app within 1-2 seconds

### What Data is Extracted?

| Field | Source |
|-------|--------|
| Property Name | Listing title |
| Address | Full address |
| Purchase Price | Listed price |
| Bedrooms/Bathrooms | Property details |
| Total Area (sqft/m²) | Square footage |
| Location City | Parsed from address |
| Location Country | Inferred from site domain |
| Images | Listing photos (up to 10) |

### Troubleshooting Extension

**Button doesn't appear:**
- ✅ Check app is running (Dock icon visible)
- ✅ Check `HTTP` indicator in app top-right is **green** (server on port 9000)
- ✅ Reload page (⌘R)
- ✅ Check browser console (F12 → Console) for errors

**Button appears but "Connection failed":**
- ✅ App must be running
- ✅ Port 9000 not blocked by firewall
- ✅ Check: `lsof -i :9000` should show Porteos process

**Deal doesn't appear in app:**
- ✅ Check app for error toasts
- ✅ Look in "ALL" pipeline tab (may not match current filter)
- ✅ Duplicate detection: If listing already imported, won't create second deal

**Scraped data is wrong:**
- ✅ Site may have changed HTML structure
- ✅ Report to developer with URL for scraper fix

### Reloading Extension After Updates

If you update `content.js` or `manifest.json`:

1. Go to `chrome://extensions`
2. Find "Porteos Importer"
3. Click **↻** (reload icon)
4. Refresh listing page

**Extension changes require manual reload** — not automatic.

---

## Email Monitoring (IMAP)

Auto-import property listings forwarded to your email.

### How It Works

1. Forward listing emails (from Zillow, Idealista, etc.) to a dedicated inbox
2. Porteos polls IMAP every 10 minutes
3. Parses listings, imports as deals
4. Marks emails as read

### Prerequisites

- **Email account** with IMAP access
- **App passwords enabled** (for Gmail, Yahoo, iCloud)

### Supported Email Providers

| Provider | IMAP Server | Port | Notes |
|----------|-------------|------|-------|
| **Gmail** | `imap.gmail.com` | 993 | Requires App Password |
| **Yahoo** | `imap.mail.yahoo.com` | 993 | Requires App Password |
| **iCloud** | `imap.mail.me.com` | 993 | Requires App Password |
| **Outlook** | `outlook.office365.com` | 993 | Standard password |
| **Custom** | Your server | 993 | IMAP/SSL required |

### Setup (Gmail Example)

**Step 1: Enable IMAP in Gmail**

1. Gmail → **Settings** (gear icon)
2. **See all settings**
3. **Forwarding and POP/IMAP** tab
4. **Enable IMAP**
5. **Save Changes**

**Step 2: Create App Password**

1. Visit https://myaccount.google.com/apppasswords
2. App name: "Porteos Intelligence"
3. Click **Generate**
4. Copy 16-character password (e.g., `abcd efgh ijkl mnop`)

**Step 3: Configure in Porteos**

1. Open Porteos Intelligence
2. **Settings → Email Monitoring**
3. Fill in:
   - **IMAP Server:** `imap.gmail.com`
   - **Port:** `993`
   - **Username:** Your full Gmail address
   - **Password:** App password (paste without spaces: `abcdefghijklmnop`)
4. Click **`[ TEST CONNECTION ]`**
   - Success: "Connected successfully!"
   - Failure: See troubleshooting below
5. Click **`[ SAVE ]`**
6. Click **`[ START MONITORING ]`**

**Service runs in background, checks every 10 minutes**

### What Emails Are Detected?

**Supported formats:**
- Zillow listing alerts
- Realtor.com saved searches
- Idealista alerts (Portuguese/Spanish)
- Generic property listing emails (best-effort parsing)

**Parser looks for:**
- Property name/address
- Price
- Bedrooms/bathrooms
- Square footage
- Listing URL

**If parsing fails, email is ignored** (not imported as incomplete deal).

### Monitoring Status

**In app:**
- **Settings → Email Monitoring**
- **Status:** "Monitoring active" / "Not configured" / "Error: ..."
- **Last check:** Timestamp
- **Messages imported:** Count

### Stopping Monitoring

1. **Settings → Email Monitoring**
2. Click **`[ STOP MONITORING ]`**

**Credentials remain saved** — restart anytime.

### Troubleshooting Email

**"Connection failed" on test:**
- ✅ IMAP enabled in email provider settings
- ✅ App password used (not regular password for Gmail/Yahoo)
- ✅ Server and port correct (993 for SSL)
- ✅ Username is full email address
- ✅ No spaces in app password

**Monitoring started but no emails imported:**
- ✅ Forward test listing email to inbox
- ✅ Wait 10 minutes (or click `[ CHECK NOW ]`)
- ✅ Check inbox has unseen messages
- ✅ Parser may not recognize format (check console logs)

**Security concerns:**
- ✅ Credentials stored in **macOS Keychain** (encrypted)
- ✅ Connection uses **IMAP/SSL** (port 993)
- ✅ App never sends credentials to external servers
- ✅ Delete credentials: Settings → Email → `[ CLEAR CREDENTIALS ]`

---

## News Feeds (RSS)

Auto-configured, no setup required.

### How It Works

**Global Intelligence** profile fetches market news from:
- **35 metros** across 13 countries
- **10 intelligence sectors** (regulation, tourism, rate outlook, etc.)
- **RSS feeds** from industry sources

### Registry

**Location:** `PorteosIntelligence/Data/MarketFeedRegistry.swift`

**Covered Regions:**
- USA: San Francisco, New York, Los Angeles, etc.
- Europe: Lisbon, Barcelona, Paris, Amsterdam, etc.
- Scandinavia: Stockholm, Oslo, Copenhagen
- Asia: Selected metros (future expansion)

### Feed Sources

**Example sectors:**
- **Regulatory:** Zoning changes, STR laws
- **Market:** Supply pipeline, price trends
- **Tourism:** Visitor stats, hospitality demand
- **Rates:** Central bank policy, mortgage rates

**All feeds are public RSS** — no API keys required.

### Caching

- **Fetch schedule:** Daily
- **Cache duration:** 60 days
- **Storage:** In-memory (not persisted to SwiftData)

### Usage

1. **Navigate to Global Intelligence** (⌘6)
2. **Select market filter** (e.g., "Lisbon")
3. **Select sector filter** (e.g., "Regulation")
4. News feed shows filtered headlines

**First load may take 10-30 seconds** as feeds are fetched.

### Troubleshooting News Feeds

**"No articles found":**
- ✅ Market or sector may have no recent coverage
- ✅ Try different market/sector combo
- ✅ Internet connection required

**Feeds not updating:**
- ✅ Cache is 60 days — old articles persist
- ✅ Force refresh: Quit app, relaunch, revisit Global Intelligence

**Adding custom feeds:**
- Edit `MarketFeedRegistry.swift`
- Add RSS URL to appropriate market + sector
- Rebuild app

---

## Geocoding (MapKit)

Auto-configured, no setup required.

### How It Works

When you save a deal with an address:
1. `GeocodingService` extracts: Address, City, Country
2. Sends to **MapKit `MKGeocodingRequest`** (Apple's native service)
3. Receives: Latitude, Longitude
4. Saves to `PropertyDeal.latitude` / `.longitude`
5. Deal appears on **Global Intelligence** portfolio map

### Requirements

- **macOS 14.6+** (MapKit geocoding requires this version)
- **Internet connection** (Apple's geocoding service is cloud-based)
- **No API key** (native Apple service, free)

### Geocode Status

Each deal has a `geocodeStatus`:
- **`none`:** Not attempted yet
- **`pending`:** In progress
- **`ok`:** Successfully geocoded
- **`failed`:** Address couldn't be resolved

### Manual Geocoding

If a deal fails to geocode:

1. Select deal
2. **Inspector → MEDIA tab → GeoAsset Context Card**
3. Click **`[ RE-GEOCODE ]`**

### Clearing Geocode

To remove coordinates:

1. Select deal
2. **Inspector → MEDIA tab → GeoAsset Context Card**
3. Click **`[ CLEAR PIN ]`**

**Note:** Geocoding is NOT required for other app features — only affects map display.

---

## Service Dependencies Matrix

| Feature | Requires | Optional |
|---------|----------|----------|
| **Core dashboards** | None | - |
| **AI Vibe** | Ollama/OpenAI/Gemini | - |
| **RESEARCH chat** | Ollama/OpenAI/Gemini | - |
| **Browser import** | HTTP server (auto) | Extension installed |
| **Email import** | IMAP credentials | - |
| **Global Intelligence map** | Internet (geocoding) | - |
| **News feeds** | Internet (RSS) | - |
| **PDF export** | None | - |

**Core app works offline** if you skip AI features and don't use email/news/geocoding.

---

## Troubleshooting

### All Services

**Check HTTP server status:**
- Top-right indicator: **Green `HTTP`** = running, **Red `HTTP`** = failed
- Port 9000 must be free
- Kill blocking process: `lsof -ti:9000 | xargs kill -9`

**Check internet connection:**
- AI (cloud providers), news feeds, geocoding require internet
- Ollama (local AI) works offline after model download

**Check Keychain access:**
- API keys and IMAP credentials stored in macOS Keychain
- If "Keychain access denied" error: System Settings → Privacy → Keychain → Allow Porteos

### Provider-Specific

**Ollama not responding:**
```bash
# Check if ollama is running
ps aux | grep ollama

# Restart ollama
killall ollama
ollama serve
```

**OpenAI "Invalid API key":**
- Key must start with `sk-`
- Regenerate key at https://platform.openai.com/api-keys
- Check billing: https://platform.openai.com/account/billing

**Gemini rate limit:**
- Free tier: 15 requests/minute
- Wait 1 minute, try again
- Upgrade for higher limits

**IMAP "Authentication failed":**
- Use app password (not account password) for Gmail/Yahoo/iCloud
- Enable IMAP in provider settings
- Verify username is full email address

---

## Summary

**Minimum Setup (Core Features Only):**
- ✅ No external services required
- ✅ Local data only

**Recommended Setup (AI + Import):**
- ✅ Ollama installed + model downloaded
- ✅ Browser extension loaded

**Full Setup (All Features):**
- ✅ Ollama OR OpenAI/Gemini
- ✅ Browser extension loaded
- ✅ Email monitoring configured (optional)

**Next:** See [`DATA_MODEL_GUIDE.md`](DATA_MODEL_GUIDE.md) for SwiftData schema details.
