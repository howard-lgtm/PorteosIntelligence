
---

## Hero image spec (designer to supply)

| Property | Value |
|---|---|
| Layer name in Figma | `splash-hero` |
| Canvas | 720 × 460 pt (design at 1×) |
| Export @1x | `splash-hero.png` — **720 × 460 px** |
| Export @2x | `splash-hero@2x.png` — **1440 × 920 px** (Retina, preferred) |
| Format | PNG-24, sRGB, **no transparency** (full-bleed rectangle) |
| Safe area | Keep important content inside **680 × 420 pt** center (20 pt margin all sides) |
| Crop mode | Cover — no letterboxing, no Figma UI chrome |
| Behaviour | App fades entire image to `#0A0A0A` by t = 0.7s (ease-in). Do **not** bake text into image. |

> **Do not export as JPG** — banding is visible on the fade-to-black.

Current Figma placeholder: rust gradient (`#C25E30 → #0A0A0A`). Replace fill in node `248:483 → splash-image` layer before export.

---

## Window

| Property | Value |
|---|---|
| Type | `NSPanel` — borderless, no title bar |
| Size | 720 × 460 pt |
| Background | `#0A0A0A` |
| Corner radius | 10 pt |
| Position | Centered on primary display at launch |

---

## Animation sequence (~4.4s total) — implemented in code

| Phase | Timing | Description |
|---|---|---|
| 1 | 0.00 – 0.70s | Hero image fully visible → fades to `#0A0A0A` (ease-in) |
| 2 | 0.70 – 0.80s | Dark screen — cursor block appears, begins blinking |
| 3 | 0.80 – 2.40s | Typewriter: 20 chars × 80 ms each, cursor trails right |
| 4 | 2.40 – 2.90s | `v2.06` fades in (0.4s ease-out); progress bar fills to 100% |
| — | 4.40s | Main window appears, splash dismissed |

---

## Typography

| Property | Value |
|---|---|
| Font | JetBrains Mono Regular (already in app bundle) |
| Size | 18 pt |
| Color | `#C25E30` |
| Letter spacing | 3 pt |
| Content | `PORTEOS INTELLIGENCE` |

**Version string:** 11 pt · `#666666` · centered below main text · content: `v2.06`

---

## Cursor

| Property | Value |
|---|---|
| Shape | Rectangle 10 × 24 pt |
| Fill | `#C25E30` |
| Blink interval | 500 ms — opacity 1 → 0 → 1 (linear) |
| Blink phases | Before typing (0.70–0.80s) and after complete (2.40s+) |
| During typing | Always visible, no blink |
| Advance | 11 pt per character |

---

## Progress bar

| Property | Value |
|---|---|
| Track | 640 × 2 pt · `#262626` · x:40 y:428 |
| Fill | `#C25E30` @ 60% opacity |
| Timing | 0s → 10% at 0.8s (ease-out) → 92% at 2.4s (linear) → 100% at 2.9s (ease-out) |

---

## Design tokens

| Token | Hex | Usage |
|---|---|---|
| `rust` | `#C25E30` | Text, cursor, progress fill |
| `canvas-base` | `#0A0A0A` | Window background |
| `text/dim` | `#666666` | Version string |
| `divider` | `#262626` | Progress track |

---

## Figma reference

| Asset | Node |
|---|---|
| Motion frame (timing reference) | `248:483` — *Splash — Motion (macOS)* |
| 3-up design states | `248:454` — *macOS Splash — Reference States* |
| File key | `7XdLK0I2aWj7KVkvhnJEyE` |

---

## Do not export

- Frame sequences, Lottie, GIF, MP4
- Per-frame PNGs (`porteos_splash_000.png` etc.)
- The typewriter animation, cursor, progress bar, or version string — all rendered in code

---

## Export checklist

- [ ] `splash-hero@2x.png` — 1440 × 920 px, PNG-24, full-bleed, no transparency
- [ ] `splash-hero.png` — 720 × 460 px (1× fallback)
- [ ] Rust gradient placeholder **removed** from Figma node `248:483`
- [ ] Hero image reads clearly at 460 pt tall
- [ ] No text baked into hero image
- [ ] File names lowercase and hyphenated (exact match above)
- [ ] `splash-ref-states.png` — exported to `Design-system/Figma/Splash Image/`
- [ ] `splash-ref-motion.png` — exported to `Design-system/Figma/Splash Image/`
