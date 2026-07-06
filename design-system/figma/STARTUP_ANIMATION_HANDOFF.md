# Startup Animation — Figma → macOS Handoff

**Status:** Figma export in progress (Howard)  
**App integration:** scaffold ready — awaiting PNG sequence in repo  
**Last updated:** 6 July 2026

---

## 1. Asset source

Copy from local machine into this repo:

| Local (CascadeProjects) | Repo destination |
|-------------------------|------------------|
| `Design-system/Figma/STARTUP_ANIMATION_HANDOFF.md` | `design-system/figma/STARTUP_ANIMATION_HANDOFF.md` (merge/update this file) |
| `Design-system/Figma/Splash Image/porteos_splash_*.png` | `PorteosIntelligence/Resources/Splash/` |

First frame reference: `porteos_splash_000.png`

---

## 2. Figma export spec (fill in when export is complete)

| Property | Value | Notes |
|----------|-------|-------|
| Frame naming | `porteos_splash_{###}.png` | Zero-padded 3 digits |
| First frame | `porteos_splash_000.png` | |
| Last frame | `porteos_splash___` | _TBD_ |
| Total frames | | _TBD_ |
| FPS | | _TBD — typical 24 or 30_ |
| Duration | | _TBD — e.g. 1.5s_ |
| Canvas size | | _TBD — e.g. 1200×800 or 800×600_ |
| Background | `#0F1115` | Match `shell-bg` |
| Loop | No | Play once on cold launch |

---

## 3. How it connects to the app

### Architecture

```
PorteosIntelligenceApp
  └── RootView                    ← new root coordinator
        ├── AppShell()            ← main UI (loads underneath)
        └── SplashView (overlay)  ← full-window, z-index on top
              └── PNG frame sequence timer
```

### Launch sequence

1. **App init** — `ModelContainer` + ingestion services initialise (existing `PorteosIntelligenceApp`).
2. **RootView appears** — `AppShell` mounts immediately (data ready); splash overlay covers it.
3. **SplashView** — plays `porteos_splash_000` → `porteos_splash_NNN` at configured FPS.
4. **Dismiss** — when last frame shown + optional minimum duration elapsed → opacity fade (0.35s) → remove overlay.
5. **AppShell visible** — user lands on last-used state / empty state as today.

### Why overlay, not a separate window?

- macOS SwiftUI `WindowGroup` has no built-in storyboard launch screen like iOS.
- Overlay on `AppShell` lets the app load SwiftData and auto-start ingestion server while the animation plays.
- Avoids a blank window flash before content appears.

### Files

| File | Role |
|------|------|
| `Views/Splash/SplashView.swift` | Frame sequence player |
| `Views/Splash/RootView.swift` | Splash + AppShell coordinator |
| `PorteosIntelligenceApp.swift` | Entry point uses `RootView` instead of `AppShell` |
| `Resources/Splash/*.png` | Frame sequence (bundle resources) |

Xcode uses `PBXFileSystemSynchronizedRootGroup` — files under `PorteosIntelligence/` are picked up automatically.

---

## 4. Configuration

Edit constants at top of `SplashView.swift`:

```swift
static let frameCount = 60        // set from handoff
static let fps: Double = 24       // set from handoff
static let minimumDuration: Double = 1.2  // never shorter than this
static let fadeOutDuration: Double = 0.35
```

Or load from a small `splash-config.json` in the Splash bundle folder if Figma export includes one.

---

## 5. Acceptance criteria

- [ ] Cold launch shows splash on `#0F1115` background — no white flash
- [ ] All frames play in order at correct FPS
- [ ] Splash dismisses smoothly into `AppShell`
- [ ] App is interactive immediately after fade (no extra delay)
- [ ] Missing frames → graceful fallback (static logo / skip splash, log warning)
- [ ] Re-launch behaviour matches decision: every launch vs first launch only

---

## 6. Optional follow-ups

| Item | Priority |
|------|----------|
| User preference: show splash on every launch | Low |
| `UserDefaults` flag: `hasSeenSplash` for first-launch only | Low |
| Replace PNG sequence with Lottie if Figma exports `.json` | Future |
| Match splash to Figma redesign tokens when UI overhaul lands | Medium |

---

## 7. Cursor execution

When PNGs are in `PorteosIntelligence/Resources/Splash/`:

1. Read this file for `frameCount` and `fps`
2. Update `SplashView.swift` constants
3. Run app — verify cold launch
4. Mark punchlist items S4–S5 complete in `PUNCHLIST.md`
