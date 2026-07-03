# PORTEOS INTELLIGENCE v2.06 — CURSOR SwiftUI HANDOFF GUIDE
# Figma file ID: 7XdLK0I2aWj7KVkvhnJEyE
# See also: DESIGN_TOKENS.md · COMPONENT_SPECS.md · FIGMA_FRAME_INDEX.md

---

## 0. AUTHORITY HIERARCHY

PRIMARY   = 660×1014 dashboard columns → module anatomy, cell layout, data display
SECONDARY = 1200×800 app shell         → integration, pane widths, shell chrome
Conflict? → PRIMARY wins.

---

## 1. GLOBAL LAWS

```swift
cornerRadius = 0        // everywhere, no exceptions
font = "JetBrains Mono" // only this font, always
shadows = none          // no drop shadows
