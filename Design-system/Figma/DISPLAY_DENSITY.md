# Display Density — Standard (1×) vs Large (2×)

**Status:** Spec agreed · Settings toggle wired · Full UI migration pending Figma token pass  
**Last updated:** 7 July 2026

---

## Modes

| Mode | Multiplier | Target | Example metric label | Example metric value | Row height |
|------|------------|--------|----------------------|----------------------|------------|
| **Standard** | 1× | Laptop / 13–14" | 11pt | 14pt | 28pt |
| **Large** | 2× | External / 27"+ | 22pt | 28pt | 56pt |

Typography, row heights, and vertical spacing scale **together**. Pane widths (nav 260, inspector 280) do **not** scale.

---

## Settings UI

**Settings → GENERAL → DISPLAY_DENSITY**

```
[ STANDARD ]  [ LARGE ]
1× — laptop     2× — external display
```

Persisted: `UserDefaults` key `porteos.displayDensity`

---

## Code

| File | Role |
|------|------|
| `Utilities/DisplayDensity.swift` | `DisplayDensity` enum, `DisplayDensityStore`, environment key |
| `Views/Sheets/SettingsView.swift` | Toggle control |
| `Views/Splash/RootView.swift` | Injects store into environment |

### Usage in views (migration pattern)

```swift
@Environment(\.displayDensity) private var density

Text("NOI")
    .font(density.monoFont(size: 11, weight: .medium))

Text("€125,000")
    .font(density.monoFont(size: 14, weight: .bold))

// Row
.frame(height: density.rowHeight())
```

Migrate incrementally during UI redesign — not all views wired yet.

---

## Figma tokens

See `porteos.tokens.json` → `porteos/density` for `standard` and `large` (2×) size sets.

---

## Notes

- Literal 2× is intentional per product decision; tune to 1.5× in testing only if layouts break.
- `@Observable` store triggers re-render when mode changes in Settings.
- Do not use system Dynamic Type alone — it conflicts with fixed grid rhythm.
