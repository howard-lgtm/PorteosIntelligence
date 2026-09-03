# Multi-Window System — Independent Profile Windows

Complete guide to the multi-window architecture, state synchronization, and window management.

---

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [WindowGroup Configuration](#windowgroup-configuration)
4. [State Synchronization](#state-synchronization)
5. [Opening Profile Windows](#opening-profile-windows)
6. [WindowManager Service](#windowmanager-service)
7. [ProfileWindowValue](#profilewindowvalue)
8. [Real-Time Sync Mechanism](#real-time-sync-mechanism)
9. [Adding New Windows](#adding-new-windows)
10. [Debugging Multi-Window](#debugging-multi-window)

---

## Overview

Porteos Intelligence supports **multiple independent windows**, each displaying a different profile dashboard. All windows share the same SwiftData container and stay synchronized in real-time.

### Use Cases

- **Multi-monitor setups:** Real Estate on screen 1, Hospitality on screen 2
- **Parallel analysis:** Compare different aspects side-by-side
- **Presentation mode:** Show specific dashboard without switching views
- **Focus workflows:** Keep one dashboard always visible

### Key Features

✅ **Independent windows:** Each has own navigation, full dashboard  
✅ **Real-time sync:** Selection changes propagate instantly  
✅ **Persistent state:** Windows remember position and size  
✅ **Any profile:** Can open same profile multiple times  
✅ **Shared data:** All windows read from same SwiftData container  

---

## Architecture

### Window Types

```
Main Window (AppShell)
├── 3-pane layout
├── All 6 profiles accessible
├── Navigation + Inspector
└── Primary window (cannot close)

Profile Windows (ProfileWindowView)
├── Single dashboard only
├── No navigation pane
├── No inspector pane
├── Can open multiple
└── Can close individually
```

### Visual Structure

```
┌────────────────────────────────────────────────────┐
│  Main Window (1440×900)                            │
│  ┌──────┬─────────────────────┬──────────┐        │
│  │ Nav  │   Dashboard         │Inspector │        │
│  │      │   (any profile)     │          │        │
│  │      │                     │          │        │
│  │ [ ↗ ]│                     │          │        │
│  └──────┴─────────────────────┴──────────┘        │
└────────────────────────────────────────────────────┘
            ↓ Click [ ↗ ]
┌────────────────────────────────────────────────────┐
│  Profile Window: Real Estate (1200×800)            │
│  ┌──────────────────────────────────────────────┐ │
│  │         Real Estate Dashboard                 │ │
│  │         (full width, no nav/inspector)        │ │
│  │                                               │ │
│  └──────────────────────────────────────────────┘ │
└────────────────────────────────────────────────────┘
```

---

## WindowGroup Configuration

### App Entry Point

**File:** `PorteosIntelligenceApp.swift`

```swift
@main
struct PorteosIntelligenceApp: App {
    var body: some Scene {
        // ── Main Window ────────────────────────────────────────
        WindowGroup {
            AppShell()
                .modelContainer(sharedModelContainer)
                .environment(\.displayDensity, DisplayDensityStore.shared)
        }
        .defaultSize(width: 1440, height: 900)
        .commands {
            AppCommandsProvider()
        }
        
        // ── Profile Windows ────────────────────────────────────
        WindowGroup("Profile", id: "profile", for: ProfileWindowValue.self) { $value in
            ProfileWindowView(windowValue: $value)
                .modelContainer(sharedModelContainer)
                .frame(minWidth: 900, minHeight: 600)
        }
        .defaultSize(width: 1200, height: 800)
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
    }
}
```

**Key Points:**
- **`WindowGroup("Profile")`** — Creates profile window scene
- **`for: ProfileWindowValue.self`** — Window identifier type
- **`$value`** — Binding to window-specific data
- **`.modelContainer(sharedModelContainer)`** — Share SwiftData
- **`.defaultSize`** — Initial window dimensions

---

## State Synchronization

### Synchronized State

**What syncs across windows:**
- ✅ **Selected deal ID** — When any window changes selection, all update
- ✅ **SwiftData changes** — Create/update/delete deal → all windows reflect
- ✅ **Display density** — 1×/2× mode (via environment)

**What DOESN'T sync:**
- ❌ **Profile selection** — Each window shows different profile independently
- ❌ **Scroll position** — Each window scrolls independently
- ❌ **Inspector state** — Only main window has inspector

### Sync Mechanism

**Storage:** `@AppStorage` (UserDefaults-backed, observable)

```swift
// In any View that needs selected deal
@AppStorage("selectedDealID") private var selectedDealID: String = ""

// When user selects deal
selectedDealID = deal.id.uuidString  // ← All windows observe this change
```

**Behind the scenes:**
1. User clicks deal in Window A
2. Window A writes `selectedDealID` to `@AppStorage`
3. UserDefaults broadcasts change notification
4. Windows B, C, D receive notification
5. SwiftUI re-renders with new `selectedDealID`
6. All windows now show same deal

---

## Opening Profile Windows

### UI Flow

**In NavigationPane (left sidebar):**

```
PROFILE SECTIONS
  ⌘1  COMMAND CENTER
  ⌘2  REAL ESTATE       [ ↗ ]  ← Hover reveals button
  ⌘3  HOSPITALITY       [ ↗ ]
  ⌘4  DESIGN            [ ↗ ]
  ⌘5  CIRCULAR ECONOMY  [ ↗ ]
  ⌘6  GLOBAL INTEL      [ ↗ ]
```

**On hover:**
- `[ ↗ ]` button appears to right of profile name
- Clicking opens new window with that profile

### Implementation

**File:** `NavigationPane.swift`

```swift
ForEach(ProfileType.allCases, id: \.self) { profile in
    HStack {
        // Profile name button
        Button(action: { selectedProfile = profile }) {
            HStack {
                Text(profile.emoji)
                Text(profile.rawValue.uppercased())
            }
        }
        .buttonStyle(ProfileButtonStyle(isSelected: selectedProfile == profile))
        
        Spacer()
        
        // Detach button (on hover)
        Button(action: { openProfileWindow(profile) }) {
            Text("[ ↗ ]")
        }
        .buttonStyle(TerminalButtonStyle())
        .opacity(hoveringProfile == profile ? 1 : 0)  // Show on hover
    }
    .onHover { isHovering in
        hoveringProfile = isHovering ? profile : nil
    }
}
```

**Open window function:**
```swift
@Environment(\.openWindow) private var openWindow

func openProfileWindow(_ profile: ProfileType) {
    let windowValue = ProfileWindowValue(
        profileType: profile,
        timestamp: Date()
    )
    openWindow(id: "profile", value: windowValue)
}
```

---

## WindowManager Service

**File:** `Services/WindowManager.swift`

**Purpose:** Central coordination for window lifecycle and state.

```swift
import SwiftUI
import Combine

@Observable
final class WindowManager {
    static let shared = WindowManager()
    
    private init() {}
    
    // Track open profile windows
    private(set) var openWindows: Set<UUID> = []
    
    // Register window opened
    func registerWindow(_ id: UUID, profile: ProfileType) {
        openWindows.insert(id)
        print("[WindowManager] Opened \(profile.rawValue) window: \(id)")
    }
    
    // Unregister window closed
    func unregisterWindow(_ id: UUID) {
        openWindows.remove(id)
        print("[WindowManager] Closed window: \(id)")
    }
    
    // Get count of open profile windows
    var profileWindowCount: Int {
        openWindows.count
    }
}
```

**Usage in ProfileWindowView:**
```swift
.onAppear {
    WindowManager.shared.registerWindow(windowID, profile: profileType)
}
.onDisappear {
    WindowManager.shared.unregisterWindow(windowID)
}
```

---

## ProfileWindowValue

**File:** `Models/ProfileWindowValue.swift`

**Purpose:** Identifies and configures a profile window.

```swift
import Foundation

struct ProfileWindowValue: Codable, Hashable {
    let profileType: ProfileType
    let timestamp: Date
    
    init(profileType: ProfileType, timestamp: Date = Date()) {
        self.profileType = profileType
        self.timestamp = timestamp
    }
}
```

**Why `Codable`?**
- SwiftUI requires `Codable` for `WindowGroup(for:)` value type
- Enables window restoration (future: reopen windows on app launch)

**Why `timestamp`?**
- Uniqueness: Can open same profile multiple times
- Each window gets unique timestamp → different `Hashable` value
- Without it, opening "Real Estate" twice would focus existing window

**Why `Hashable`?**
- SwiftUI uses hash to track window identity
- Different hashes → different windows

---

## Real-Time Sync Mechanism

### Deal Selection Sync

**Flow diagram:**
```
Window A: User clicks deal "Villa Rosa"
    ↓
selectedDealID = "uuid-villa-rosa"
    ↓
@AppStorage writes to UserDefaults
    ↓
UserDefaults.didChangeNotification
    ↓
SwiftUI observes @AppStorage change
    ↓
Windows B, C, D re-render with new selectedDealID
    ↓
All windows now show "Villa Rosa"
```

**Implementation:**

```swift
// ProfileWindowView.swift
@AppStorage("selectedDealID") private var selectedDealID: String = ""
@Query private var deals: [PropertyDeal]

var selectedDeal: PropertyDeal? {
    deals.first { $0.id.uuidString == selectedDealID }
}

var body: some View {
    VStack {
        if let deal = selectedDeal {
            // Render dashboard with this deal
            profileDashboard(for: deal)
        } else {
            Text("No deal selected")
        }
    }
}
```

### SwiftData Sync

**Flow diagram:**
```
Window A: User edits deal "Villa Rosa" → purchasePrice = 1.5M
    ↓
context.save()
    ↓
SwiftData broadcasts NSManagedObjectContextDidSave
    ↓
All ModelContext instances receive notification
    ↓
@Query results automatically refresh
    ↓
Windows B, C, D re-render with updated price
```

**No manual sync required** — SwiftData handles propagation automatically.

### Display Density Sync

**Custom environment key:**

```swift
// Utilities/DisplayDensity.swift

@Observable
final class DisplayDensityStore {
    static let shared = DisplayDensityStore()
    
    var densityMultiplier: Double {
        get { UserDefaults.standard.double(forKey: "displayDensity") }
        set { UserDefaults.standard.set(newValue, forKey: "displayDensity") }
    }
}

struct DisplayDensityKey: EnvironmentKey {
    static let defaultValue = DisplayDensityStore.shared
}

extension EnvironmentValues {
    var displayDensity: DisplayDensityStore {
        get { self[DisplayDensityKey.self] }
        set { self[DisplayDensityKey.self] = newValue }
    }
}
```

**Usage in windows:**
```swift
@Environment(\.displayDensity) private var displayDensity

var fontSize: CGFloat {
    13 * displayDensity.densityMultiplier  // 1× = 13pt, 2× = 26pt
}
```

---

## Adding New Windows

### Example: Add "Comparison" Window

**Step 1: Create Window Value Type**

```swift
// Models/ComparisonWindowValue.swift

struct ComparisonWindowValue: Codable, Hashable {
    let dealIDs: [String]  // Compare multiple deals
    let timestamp: Date
    
    init(dealIDs: [String], timestamp: Date = Date()) {
        self.dealIDs = dealIDs
        self.timestamp = timestamp
    }
}
```

**Step 2: Create Window View**

```swift
// Views/Comparison/ComparisonWindowView.swift

struct ComparisonWindowView: View {
    @Binding var windowValue: ComparisonWindowValue?
    @Environment(\.modelContext) private var context
    @Query private var deals: [PropertyDeal]
    
    var selectedDeals: [PropertyDeal] {
        guard let value = windowValue else { return [] }
        return deals.filter { value.dealIDs.contains($0.id.uuidString) }
    }
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(selectedDeals) { deal in
                VStack {
                    Text(deal.propertyName)
                    // ... comparison metrics
                }
            }
        }
    }
}
```

**Step 3: Register WindowGroup**

```swift
// PorteosIntelligenceApp.swift

var body: some Scene {
    // ... existing windows
    
    WindowGroup("Comparison", id: "comparison", for: ComparisonWindowValue.self) { $value in
        ComparisonWindowView(windowValue: $value)
            .modelContainer(sharedModelContainer)
    }
    .defaultSize(width: 1600, height: 900)
}
```

**Step 4: Add Open Button**

```swift
// Anywhere in UI
@Environment(\.openWindow) private var openWindow

Button("Compare Selected") {
    let selectedIDs = selectedDeals.map { $0.id.uuidString }
    let windowValue = ComparisonWindowValue(dealIDs: selectedIDs)
    openWindow(id: "comparison", value: windowValue)
}
```

---

## Debugging Multi-Window

### Common Issues

#### Windows Don't Sync

**Symptom:** Change deal in Window A, Window B doesn't update

**Debug:**
1. Check `@AppStorage("selectedDealID")` used in both windows
2. Verify spelling: `selectedDealID` vs `selectedDealId` (case matters!)
3. Check UserDefaults: `defaults read net.htdstudio.PorteosIntelligence selectedDealID`
4. Add logging:
   ```swift
   @AppStorage("selectedDealID") private var selectedDealID: String = "" {
       didSet { print("[Window] selectedDealID changed to: \(selectedDealID)") }
   }
   ```

**Fix:** Ensure consistent key name across all windows

#### Same Profile Opens Multiple Times

**Symptom:** Clicking `[ ↗ ]` focuses existing window instead of opening new

**Cause:** `ProfileWindowValue` not unique (missing timestamp or same hash)

**Fix:** Ensure timestamp is part of `ProfileWindowValue`:
```swift
let windowValue = ProfileWindowValue(
    profileType: profile,
    timestamp: Date()  // ← Unique per call
)
```

#### Window Doesn't Close

**Symptom:** Close button greyed out or window persists

**Cause:** Main `WindowGroup` cannot be closed (by design)

**Fix:** Only profile windows are closable. Main window stays open.

#### SwiftData Changes Don't Propagate

**Symptom:** Edit deal in Window A, Window B shows stale data

**Debug:**
1. Verify `context.save()` called after edit
2. Check `@Query` in Window B (should auto-refresh)
3. Look for SwiftData errors in console
4. Ensure same `modelContainer` injected

**Fix:**
```swift
// After editing deal
do {
    try context.save()
} catch {
    print("Save failed: \(error)")
}
```

---

## Performance Considerations

### Memory Usage

**Each window:**
- Own View hierarchy (~5-10MB)
- Shared SwiftData container (0 additional memory)
- Own `@Query` cache (~1-2MB per window)

**10 windows ≈ 50-120MB total**

**Recommendation:** Limit to 5-6 profile windows max for best performance.

### CPU Usage

**On deal selection change:**
- All windows re-render (~5-10ms per window)
- 5 windows = ~25-50ms total (imperceptible)

**On SwiftData save:**
- `@Query` refreshes in all windows (~10-20ms per window)
- Automatic and asynchronous

**No manual optimization needed** — SwiftUI + SwiftData handle efficiently.

---

## Future Enhancements

### Window Restoration

**Goal:** Reopen profile windows on app launch

**Implementation:**
```swift
// Save window state on close
func saveWindowState() {
    let state = openWindows.map { windowID in
        ["id": windowID, "profile": profileType.rawValue]
    }
    UserDefaults.standard.set(state, forKey: "openProfileWindows")
}

// Restore on app launch
func restoreWindows() {
    guard let state = UserDefaults.standard.array(forKey: "openProfileWindows") as? [[String: String]] else { return }
    
    for window in state {
        guard let profileRaw = window["profile"],
              let profile = ProfileType(rawValue: profileRaw) else { continue }
        
        let windowValue = ProfileWindowValue(profileType: profile)
        openWindow(id: "profile", value: windowValue)
    }
}
```

### Window Positioning

**Goal:** Remember window position/size per profile

**Implementation:**
```swift
struct WindowState: Codable {
    let profile: ProfileType
    let frame: CGRect
}

// Save on window move/resize
func saveWindowFrame(_ frame: CGRect, profile: ProfileType) {
    let state = WindowState(profile: profile, frame: frame)
    // Persist to UserDefaults
}

// Restore on window open
func restoreWindowFrame(for profile: ProfileType) -> CGRect? {
    // Load from UserDefaults
}
```

---

## Summary

**Multi-Window System:**
- Independent profile windows via `WindowGroup`
- Real-time sync via `@AppStorage` + SwiftData
- Shared data container, independent UI state
- Hover-reveal `[ ↗ ]` buttons in NavigationPane

**Key Components:**
- `ProfileWindowValue` — Window identifier (profile + timestamp)
- `WindowManager` — Track open windows
- `@AppStorage("selectedDealID")` — Selection sync
- `@Query` — Auto-refreshing SwiftData queries

**Opening Windows:**
1. Hover profile name in nav
2. Click `[ ↗ ]`
3. New window with that profile dashboard
4. Can open same profile multiple times

**State Sync:**
- Deal selection syncs instantly
- SwiftData changes propagate automatically
- Display density syncs via custom environment

**Performance:**
- 5-6 windows ≈ 50-120MB memory
- Re-renders ~5-10ms per window
- No manual optimization needed

**Critical:** Always inject `modelContainer` to profile windows, otherwise data won't sync.

**Next:** See operational guides (Phase 3) for debugging, testing, and release processes.
