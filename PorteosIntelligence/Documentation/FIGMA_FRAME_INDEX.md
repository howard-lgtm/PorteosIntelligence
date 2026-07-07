
---

## FILE 4 — `Documentation/FIGMA_FRAME_INDEX.md`

```markdown
# PORTEOS INTELLIGENCE v2.06 — FIGMA FRAME INDEX
# Figma file ID: 7XdLK0I2aWj7KVkvhnJEyE
# Node ID format: select frame → right-click → Copy link → extract node-id=XX-YY → write XX:YY

---

## AUTHORITY KEY
PRIMARY = 660×1014 dashboard columns — use for module anatomy & cell layout
SECONDARY = 1200×800 app shell — use for integration & pane widths only

---

## P0 — IMPLEMENT FIRST

| Priority | Screen | Page | Node ID | Status | Authority |
|---|---|---|---|---|---|
| P0 | RE Dashboard (660×1014) | Dashboards | 28:2 | LOCKED | PRIMARY |
| P0 | Hospitality Dashboard | Dashboards | 37:62 | LOCKED | PRIMARY |
| P0 | Design Dashboard | Dashboards | 49:268 | LOCKED | PRIMARY |
| P0 | Circular Economy Dashboard | Dashboards | 41:352 | LOCKED | PRIMARY |
| P0 | App Shell — Deal Selected | Shell & Navigation | 36:99 | LOCKED | SECONDARY |
| P0 | Inspector — Weights | Inspector & Overlays | 45:2 | LOCKED | SECONDARY |
| P1 | Command Center Dashboard | Dashboards | 43:220 | DRAFT | PRIMARY |

---

## P1 — IMPLEMENT AFTER P0 LOCKED

| Priority | Screen | Page | Node ID | Status | Authority |
|---|---|---|---|---|---|
| P1 | App Shell — Empty | Shell & Navigation | 36:270 | DRAFT | SECONDARY |
| P1 | Inspector — AI Vibe Idle | Inspector & Overlays | 45:47 | DRAFT | SECONDARY |
| P1 | Inspector — AI Vibe Result | Inspector & Overlays | 45:68 | DRAFT | SECONDARY |
| P1 | Command Palette | Inspector & Overlays | 45:116 | DRAFT | SECONDARY |
| P1 | Keyboard Shortcuts Overlay | Inspector & Overlays | 114:11 | DRAFT | SECONDARY |
| P1 | Ingestion Toast | Inspector & Overlays | 45:150 | DRAFT | SECONDARY |
| P1 | Sheet — Deal Compare | Sheets & Modals | 117:11 | DRAFT | SECONDARY |

---

## P2 — SHEETS & MODALS

| Priority | Screen | Page | Node ID | Status | Authority |
|---|---|---|---|---|---|
| P2 | Sheet — Template Picker | Sheets & Modals | 51:268 | DRAFT | SECONDARY |
| P2 | Sheet — Full Edit BASE | Sheets & Modals | 53:270 | DRAFT | SECONDARY |
| P2 | Sheet — Full Edit REAL_ESTATE | Sheets & Modals | 87:28 | DRAFT | SECONDARY |
| P2 | Sheet / Quick Add | Sheets & Modals | 135:328 | DRAFT | SECONDARY |
| P2 | Sheet — Import | Sheets & Modals | 58:24 | DRAFT | SECONDARY |
| P2 | Sheet — Export | Sheets & Modals | 61:26 | DRAFT | SECONDARY |
| P2 | Sheet / PDF Report Generator | Sheets & Modals | 134:328 | DRAFT | SECONDARY |
| P2 | Sheet — Deal Triage | Sheets & Modals | 93:30 | DRAFT | SECONDARY |

---

## P3 — ADMIN & EXTENSION

| Priority | Screen | Page | Node ID | Status | Authority |
|---|---|---|---|---|---|
| P3 | Settings — Email Ingestion | Admin & Extension | — | DRAFT | SECONDARY |
| P3 | Settings — Ingestion Server | Admin & Extension | — | DRAFT | SECONDARY |
| P3 | Settings — General | Admin & Extension | — | DRAFT | SECONDARY |
| P3 | Sheet — Email Alert Monitor | Admin & Extension | — | DRAFT | SECONDARY |
| P3 | Sheet — Deal Ingestion Server | Admin & Extension | — | DRAFT | SECONDARY |
| P3 | Browser Extension 4-state | Admin & Extension | 112:11 | DRAFT | SECONDARY |

---

## PAGE INVENTORY

| Page | Figma Name | Frames | Notes |
|---|---|---|---|
| 00 | Cover & Tokens | 2 | Cover + Handoff sticky |
| 01 | Components | 11+ component sets | Tooltip component included |
| 02 | Shell & Navigation | 4 | 2 shells + 2 proto clones |
| 03 | Dashboards | 6 | 5 dashboards + tooltip context |
| 04 | Inspector & Overlays | 8 | Inspectors, overlays, KB shortcuts |
| 05 | Sheets & Modals | 10 | All deal-flow sheets |
| 06 | Admin & Extension | 6 | Settings, monitors, extension |

---

## DASHBOARD MODULE ORDER — PRIMARY AUTHORITY

