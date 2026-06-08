# Voltsy Plan 1 — Foundation, Sensing, Store & Pure Engines

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A running SwiftUI iOS app that displays live battery state and a computed "Volt mood" (placeholder shape — the real Volt vector is Plan 2), backed by a fully unit-tested pure-logic core and an App-Group SwiftData time-series.

**Architecture:** A local Swift Package (`VoltsyKit`) holds platform-agnostic, host-testable logic: `VoltsyCore` (value types), `BatteryEngines` (pure `SessionEngine`, `CareScoreEngine`, `VoltStateMapper`), and `BatteryStore` (SwiftData time-series, injected `ModelContainer` so tests use in-memory). The iOS app target (`Voltsy`) holds the UIKit-bound `BatteryMonitor` (sensing) and SwiftUI views, composing the package into a live screen. XcodeGen generates the Xcode project from `project.yml`.

**Tech Stack:** Swift 6, SwiftUI, iOS 26, Swift Package Manager (local package), SwiftData, Swift Testing, XcodeGen.

---

## Milestone roadmap (the full v1 — only Plan 1 is detailed below)

| Plan | Title | Produces |
|---|---|---|
| **1 (this doc)** | Foundation, Sensing, Store & Pure Engines | Running app: live battery → tested CareScore + Volt mood (placeholder mascot) |
| 2 | Volt the mascot | Concept-art-locked SwiftUI vector Volt, all emotional states, translucent belly = level, animated, cosmetics architecture |
| 3 | Care loop & gamification | Streak + freeze tokens, achievements, 20–80% challenge, coaching tips, weekly recap card, Volt-voiced notifications |
| 4 | Surfaces | Home-screen WidgetKit widget (pre-baked poses) + charging Live Activity (ActivityKit) |
| 5 | Monetization & Ads | StoreKit 2 lifetime + cosmetics IAP, entitlement gating, value-first paywall, AdMob + UMP + ATT, bulletproof restore |
| 6 | ASO & submission | Mascot icon, 5 character screenshots, preview video, metadata, local Mac build + ASC upload |

Each later plan is written just-in-time after the previous milestone is verified.

---

## File structure (Plan 1)

```
voltsy/
├── project.yml                              # XcodeGen: Voltsy app target
├── .gitignore
├── .github/workflows/ci.yml                 # build + swift test on PR
├── packages/
│   └── VoltsyKit/
│       ├── Package.swift
│       ├── Sources/
│       │   ├── VoltsyCore/                  # pure value types (Foundation only)
│       │   │   ├── BatterySample.swift
│       │   │   ├── BatteryChargeState.swift
│       │   │   ├── ThermalLevel.swift
│       │   │   ├── HealthTint.swift
│       │   │   └── VoltState.swift
│       │   ├── BatteryEngines/              # pure logic (depends on VoltsyCore)
│       │   │   ├── BatterySession.swift
│       │   │   ├── SessionEngine.swift
│       │   │   ├── CareScore.swift
│       │   │   ├── CareScoreEngine.swift
│       │   │   └── VoltStateMapper.swift
│       │   └── BatteryStore/                # SwiftData (depends on VoltsyCore)
│       │       ├── BatterySampleRecord.swift
│       │       └── BatteryStore.swift
│       └── Tests/
│           ├── VoltsyCoreTests/BatterySampleTests.swift
│           ├── BatteryEnginesTests/
│           │   ├── SessionEngineTests.swift
│           │   ├── CareScoreEngineTests.swift
│           │   └── VoltStateMapperTests.swift
│           └── BatteryStoreTests/BatteryStoreTests.swift
└── apps/
    └── Voltsy/
        ├── Sources/
        │   ├── VoltsyApp.swift              # @main, composition root
        │   ├── Sensing/BatteryMonitor.swift # UIKit-bound (UIDevice/ProcessInfo)
        │   ├── Home/HomeViewModel.swift
        │   └── Home/HomeView.swift          # placeholder mascot
        ├── Resources/
        │   ├── Assets.xcassets/             # AccentColor, AppIcon placeholder
        │   └── Info.plist
        └── Voltsy.entitlements              # App Group
```

---

## Task 0: Repo scaffold (XcodeGen project, package skeleton, CI)

**Files:**
- Create: `~/Data/Claude/voltsy/.gitignore`
- Create: `~/Data/Claude/voltsy/packages/VoltsyKit/Package.swift`
- Create: `~/Data/Claude/voltsy/project.yml`
- Create: `~/Data/Claude/voltsy/apps/Voltsy/Resources/Info.plist`
- Create: `~/Data/Claude/voltsy/apps/Voltsy/Voltsy.entitlements`
- Create: `~/Data/Claude/voltsy/.github/workflows/ci.yml`

- [ ] **Step 1: Create `.gitignore`**

```gitignore
.DS_Store
*.xcodeproj
*.xcworkspace
!default.xcworkspace
xcuserdata/
DerivedData/
.build/
build/
*.ipa
*.dSYM.zip
.secrets/
```

- [ ] **Step 2: Create the package manifest `packages/VoltsyKit/Package.swift`**

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "VoltsyKit",
    platforms: [.iOS(.v26), .macOS(.v15)],
    products: [
        .library(name: "VoltsyCore", targets: ["VoltsyCore"]),
        .library(name: "BatteryEngines", targets: ["BatteryEngines"]),
        .library(name: "BatteryStore", targets: ["BatteryStore"]),
    ],
    targets: [
        .target(name: "VoltsyCore"),
        .target(name: "BatteryEngines", dependencies: ["VoltsyCore"]),
        .target(name: "BatteryStore", dependencies: ["VoltsyCore"]),
        .testTarget(name: "VoltsyCoreTests", dependencies: ["VoltsyCore"]),
        .testTarget(name: "BatteryEnginesTests", dependencies: ["BatteryEngines"]),
        .testTarget(name: "BatteryStoreTests", dependencies: ["BatteryStore"]),
    ]
)
```

- [ ] **Step 3: Create `apps/Voltsy/Resources/Info.plist`**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>UILaunchScreen</key>
    <dict/>
    <key>UIApplicationSceneManifest</key>
    <dict>
        <key>UIApplicationSupportsMultipleScenes</key>
        <false/>
    </dict>
</dict>
</plist>
```

- [ ] **Step 4: Create `apps/Voltsy/Voltsy.entitlements`**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.com.lawoflarge.voltsy</string>
    </array>
</dict>
</plist>
```

- [ ] **Step 5: Create `project.yml` (XcodeGen)**

```yaml
name: Voltsy
options:
  bundleIdPrefix: com.lawoflarge
  deploymentTarget:
    iOS: "26.0"
  developmentLanguage: en
settings:
  base:
    DEVELOPMENT_TEAM: R95M36AU2X
    SWIFT_VERSION: "6.0"
    MARKETING_VERSION: "1.0.0"
    CURRENT_PROJECT_VERSION: "1"
packages:
  VoltsyKit:
    path: packages/VoltsyKit
targets:
  Voltsy:
    type: application
    platform: iOS
    sources:
      - path: apps/Voltsy/Sources
      - path: apps/Voltsy/Resources
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.lawoflarge.voltsy
        INFOPLIST_FILE: apps/Voltsy/Resources/Info.plist
        CODE_SIGN_ENTITLEMENTS: apps/Voltsy/Voltsy.entitlements
        GENERATE_INFOPLIST_FILE: NO
        ENABLE_USER_SCRIPT_SANDBOXING: YES
    dependencies:
      - package: VoltsyKit
        product: VoltsyCore
      - package: VoltsyKit
        product: BatteryEngines
      - package: VoltsyKit
        product: BatteryStore
```

- [ ] **Step 6: Create `.github/workflows/ci.yml`**

```yaml
name: CI
on:
  pull_request:
  push:
    branches: [main]
jobs:
  test:
    runs-on: macos-15
    steps:
      - uses: actions/checkout@v4
      - name: Run package unit tests
        run: swift test --package-path packages/VoltsyKit
```

- [ ] **Step 7: Verify the package builds and XcodeGen is available**

Run: `cd ~/Data/Claude/voltsy && swift build --package-path packages/VoltsyKit && which xcodegen`
Expected: package builds with no sources yet (empty targets compile to empty modules); `xcodegen` path prints. If `xcodegen` is missing: `brew install xcodegen`.

- [ ] **Step 8: Commit**

```bash
cd ~/Data/Claude/voltsy
git add .gitignore project.yml packages/VoltsyKit/Package.swift apps/Voltsy/Resources/Info.plist apps/Voltsy/Voltsy.entitlements .github/workflows/ci.yml
git commit -m "chore: scaffold Voltsy monorepo (XcodeGen + VoltsyKit package + CI)"
```

---

## Task 1: Core value types (`VoltsyCore`)

**Files:**
- Create: `packages/VoltsyKit/Sources/VoltsyCore/BatteryChargeState.swift`
- Create: `packages/VoltsyKit/Sources/VoltsyCore/ThermalLevel.swift`
- Create: `packages/VoltsyKit/Sources/VoltsyCore/HealthTint.swift`
- Create: `packages/VoltsyKit/Sources/VoltsyCore/BatterySample.swift`
- Create: `packages/VoltsyKit/Sources/VoltsyCore/VoltState.swift`
- Test: `packages/VoltsyKit/Tests/VoltsyCoreTests/BatterySampleTests.swift`

- [ ] **Step 1: Write the failing test**

```swift
// Tests/VoltsyCoreTests/BatterySampleTests.swift
import Testing
import Foundation
@testable import VoltsyCore

@Suite("BatterySample")
struct BatterySampleTests {
    @Test("percent rounds the 0...1 level to a whole number")
    func percentRounds() {
        let s = BatterySample(timestamp: Date(timeIntervalSince1970: 0), level: 0.474,
                              state: .unplugged, lowPowerMode: false, thermal: .nominal)
        #expect(s.percent == 47)
    }

    @Test("isLevelKnown is false for the -1 sentinel")
    func unknownLevel() {
        let s = BatterySample(timestamp: Date(timeIntervalSince1970: 0), level: -1,
                              state: .unknown, lowPowerMode: false, thermal: .nominal)
        #expect(s.isLevelKnown == false)
        #expect(s.percent == 0)
    }

    @Test("ThermalLevel is comparable by severity")
    func thermalComparable() {
        #expect(ThermalLevel.serious > ThermalLevel.fair)
        #expect(ThermalLevel.nominal < ThermalLevel.critical)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --package-path packages/VoltsyKit --filter VoltsyCoreTests`
Expected: FAIL — `BatterySample` / `ThermalLevel` not found.

- [ ] **Step 3: Write the implementations**

```swift
// Sources/VoltsyCore/BatteryChargeState.swift
public enum BatteryChargeState: String, Codable, Sendable, Equatable, CaseIterable {
    case unknown, unplugged, charging, full
}
```

```swift
// Sources/VoltsyCore/ThermalLevel.swift
public enum ThermalLevel: Int, Codable, Sendable, Equatable, Comparable, CaseIterable {
    case nominal = 0, fair = 1, serious = 2, critical = 3
    public static func < (lhs: ThermalLevel, rhs: ThermalLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
```

```swift
// Sources/VoltsyCore/HealthTint.swift
public enum HealthTint: String, Codable, Sendable, Equatable {
    case green, amber, red
}
```

```swift
// Sources/VoltsyCore/BatterySample.swift
import Foundation

public struct BatterySample: Codable, Sendable, Equatable {
    public let timestamp: Date
    public let level: Double            // 0.0...1.0, or -1 if unknown
    public let state: BatteryChargeState
    public let lowPowerMode: Bool
    public let thermal: ThermalLevel

    public init(timestamp: Date, level: Double, state: BatteryChargeState,
                lowPowerMode: Bool, thermal: ThermalLevel) {
        self.timestamp = timestamp
        self.level = level
        self.state = state
        self.lowPowerMode = lowPowerMode
        self.thermal = thermal
    }

    public var isLevelKnown: Bool { level >= 0 }
    public var percent: Int { isLevelKnown ? Int((level * 100).rounded()) : 0 }
}
```

```swift
// Sources/VoltsyCore/VoltState.swift
public enum VoltMood: String, Codable, Sendable, Equatable, CaseIterable {
    case energetic        // 80–100%, healthy
    case content          // 40–80%, the sweet spot
    case tired            // 15–30%
    case critical         // 1–10%
    case charging         // plugged in and rising
    case overcharged      // sustained 100%
    case overheating      // high thermal state
    case zen              // Low Power Mode
}

public struct VoltState: Sendable, Equatable {
    public let mood: VoltMood
    public let bellyFill: Double        // 0...1 — what the mascot renders
    public let tint: HealthTint

    public init(mood: VoltMood, bellyFill: Double, tint: HealthTint) {
        self.mood = mood
        self.bellyFill = bellyFill
        self.tint = tint
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --package-path packages/VoltsyKit --filter VoltsyCoreTests`
Expected: PASS (3 tests).

- [ ] **Step 5: Commit**

```bash
git add packages/VoltsyKit/Sources/VoltsyCore packages/VoltsyKit/Tests/VoltsyCoreTests
git commit -m "feat(core): add battery value types (BatterySample, ThermalLevel, VoltState)"
```

---

## Task 2: `VoltStateMapper` (pure mood mapping — the mascot's brain)

**Files:**
- Create: `packages/VoltsyKit/Sources/BatteryEngines/VoltStateMapper.swift`
- Test: `packages/VoltsyKit/Tests/BatteryEnginesTests/VoltStateMapperTests.swift`

**Mapping priority (first match wins):** 1) thermal ≥ serious → `overheating`; 2) state == charging → `charging`; 3) state == full && minutesAtFull ≥ 60 → `overcharged`; 4) state == full → `energetic`; 5) level ≤ 0.10 → `critical`; 6) lowPowerMode → `zen`; 7) level ≤ 0.30 → `tired`; 8) level < 0.80 → `content`; 9) else → `energetic`. Unknown level (−1) → `content`, bellyFill 0.5.

- [ ] **Step 1: Write the failing test**

```swift
// Tests/BatteryEnginesTests/VoltStateMapperTests.swift
import Testing
import VoltsyCore
@testable import BatteryEngines

@Suite("VoltStateMapper")
struct VoltStateMapperTests {
    private func map(level: Double, state: BatteryChargeState = .unplugged,
                     thermal: ThermalLevel = .nominal, lpm: Bool = false,
                     minutesAtFull: Int = 0, tint: HealthTint = .green) -> VoltState {
        VoltStateMapper.map(level: level, state: state, thermal: thermal,
                            lowPowerMode: lpm, minutesAtFull: minutesAtFull, tint: tint)
    }

    @Test("overheating beats everything, even while charging")
    func overheating() {
        #expect(map(level: 0.5, state: .charging, thermal: .serious).mood == .overheating)
        #expect(map(level: 0.05, thermal: .critical).mood == .overheating)
    }

    @Test("charging beats a low level")
    func chargingBeatsLow() {
        #expect(map(level: 0.05, state: .charging).mood == .charging)
    }

    @Test("sustained full is overcharged; fresh full celebrates")
    func fullStates() {
        #expect(map(level: 1.0, state: .full, minutesAtFull: 90).mood == .overcharged)
        #expect(map(level: 1.0, state: .full, minutesAtFull: 5).mood == .energetic)
    }

    @Test("discharging boundaries: critical / zen / tired / content / energetic")
    func dischargingBoundaries() {
        #expect(map(level: 0.10).mood == .critical)
        #expect(map(level: 0.08, lpm: true).mood == .critical)      // critical beats LPM
        #expect(map(level: 0.25, lpm: true).mood == .zen)           // LPM beats tired
        #expect(map(level: 0.25).mood == .tired)
        #expect(map(level: 0.30).mood == .tired)
        #expect(map(level: 0.50).mood == .content)
        #expect(map(level: 0.85).mood == .energetic)
    }

    @Test("bellyFill clamps and unknown level is neutral")
    func belly() {
        #expect(map(level: 0.42).bellyFill == 0.42)
        #expect(map(level: 1.5).bellyFill == 1.0)
        let unknown = map(level: -1, state: .unknown)
        #expect(unknown.mood == .content)
        #expect(unknown.bellyFill == 0.5)
    }

    @Test("tint passes through")
    func tintPassthrough() {
        #expect(map(level: 0.5, tint: .red).tint == .red)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --package-path packages/VoltsyKit --filter VoltStateMapperTests`
Expected: FAIL — `VoltStateMapper` not found.

- [ ] **Step 3: Write the implementation**

```swift
// Sources/BatteryEngines/VoltStateMapper.swift
import VoltsyCore

public enum VoltStateMapper {
    public static let overchargedThresholdMinutes = 60
    public static let criticalCeiling = 0.10
    public static let tiredCeiling = 0.30
    public static let healthyFloor = 0.80

    public static func map(level: Double, state: BatteryChargeState, thermal: ThermalLevel,
                           lowPowerMode: Bool, minutesAtFull: Int, tint: HealthTint) -> VoltState {
        guard level >= 0 else {
            return VoltState(mood: .content, bellyFill: 0.5, tint: tint)
        }
        let belly = min(1.0, max(0.0, level))
        let mood: VoltMood

        if thermal >= .serious {
            mood = .overheating
        } else if state == .charging {
            mood = .charging
        } else if state == .full && minutesAtFull >= overchargedThresholdMinutes {
            mood = .overcharged
        } else if state == .full {
            mood = .energetic
        } else if level <= criticalCeiling {
            mood = .critical
        } else if lowPowerMode {
            mood = .zen
        } else if level <= tiredCeiling {
            mood = .tired
        } else if level < healthyFloor {
            mood = .content
        } else {
            mood = .energetic
        }
        return VoltState(mood: mood, bellyFill: belly, tint: tint)
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --package-path packages/VoltsyKit --filter VoltStateMapperTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add packages/VoltsyKit/Sources/BatteryEngines/VoltStateMapper.swift packages/VoltsyKit/Tests/BatteryEnginesTests/VoltStateMapperTests.swift
git commit -m "feat(engines): add VoltStateMapper with priority-ordered mood mapping"
```

---

## Task 3: `SessionEngine` (segment charge/discharge sessions, gap-tolerant)

**Files:**
- Create: `packages/VoltsyKit/Sources/BatteryEngines/BatterySession.swift`
- Create: `packages/VoltsyKit/Sources/BatteryEngines/SessionEngine.swift`
- Test: `packages/VoltsyKit/Tests/BatteryEnginesTests/SessionEngineTests.swift`

**Rules:** a session is a maximal run of same-kind consecutive samples (charge = `.charging`/`.full`; discharge = `.unplugged`). A state-kind change ends a session. A time gap larger than `gapThreshold` (default 30 min) ends a session (don't compute a rate across a sleep gap). Sessions need ≥ 2 samples. `minutesAtFull(asOf:)` = minutes of the most recent contiguous tail where `state == .full`.

- [ ] **Step 1: Write the failing test**

```swift
// Tests/BatteryEnginesTests/SessionEngineTests.swift
import Testing
import Foundation
import VoltsyCore
@testable import BatteryEngines

@Suite("SessionEngine")
struct SessionEngineTests {
    private let t0 = Date(timeIntervalSince1970: 1_700_000_000)
    private func s(_ minutes: Double, _ level: Double, _ state: BatteryChargeState) -> BatterySample {
        BatterySample(timestamp: t0.addingTimeInterval(minutes * 60), level: level,
                      state: state, lowPowerMode: false, thermal: .nominal)
    }

    @Test("empty and single-sample inputs yield no sessions")
    func sparse() {
        #expect(SessionEngine.sessions(from: []).isEmpty)
        #expect(SessionEngine.sessions(from: [s(0, 0.5, .unplugged)]).isEmpty)
    }

    @Test("a clean discharge run is one discharge session with %/h rate")
    func discharge() {
        let samples = [s(0, 0.80, .unplugged), s(30, 0.75, .unplugged), s(60, 0.70, .unplugged)]
        let sessions = SessionEngine.sessions(from: samples)
        #expect(sessions.count == 1)
        #expect(sessions[0].kind == .discharge)
        // 10% over 1h = -10 %/h
        #expect(abs(sessions[0].ratePerHour - (-10)) < 0.001)
    }

    @Test("a charge then discharge produces two sessions")
    func twoSessions() {
        let samples = [s(0, 0.40, .charging), s(20, 0.60, .charging),
                       s(40, 0.58, .unplugged), s(70, 0.50, .unplugged)]
        let sessions = SessionEngine.sessions(from: samples)
        #expect(sessions.count == 2)
        #expect(sessions[0].kind == .charge)
        #expect(sessions[1].kind == .discharge)
    }

    @Test("a large time gap splits a session")
    func gapSplits() {
        let samples = [s(0, 0.80, .unplugged), s(20, 0.76, .unplugged),
                       s(400, 0.40, .unplugged), s(420, 0.36, .unplugged)] // 380-min gap
        let sessions = SessionEngine.sessions(from: samples)
        #expect(sessions.count == 2)
    }

    @Test("minutesAtFull counts the most recent contiguous full tail")
    func minutesAtFull() {
        let samples = [s(0, 0.98, .charging), s(10, 1.0, .full), s(70, 1.0, .full)]
        let m = SessionEngine.minutesAtFull(from: samples)
        #expect(m == 60)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --package-path packages/VoltsyKit --filter SessionEngineTests`
Expected: FAIL — `SessionEngine` not found.

- [ ] **Step 3: Write the implementations**

```swift
// Sources/BatteryEngines/BatterySession.swift
import Foundation
import VoltsyCore

public struct BatterySession: Sendable, Equatable {
    public enum Kind: Sendable, Equatable { case charge, discharge }
    public let kind: Kind
    public let start: Date
    public let end: Date
    public let startLevel: Double
    public let endLevel: Double

    public var duration: TimeInterval { end.timeIntervalSince(start) }
    public var levelDelta: Double { endLevel - startLevel }
    /// Percentage points per hour (signed). 0 if duration is non-positive.
    public var ratePerHour: Double {
        let hours = duration / 3600
        guard hours > 0 else { return 0 }
        return (levelDelta * 100) / hours
    }
}
```

```swift
// Sources/BatteryEngines/SessionEngine.swift
import Foundation
import VoltsyCore

public enum SessionEngine {
    public static let gapThreshold: TimeInterval = 30 * 60   // 30 minutes

    private static func kind(for state: BatteryChargeState) -> BatterySession.Kind? {
        switch state {
        case .charging, .full: return .charge
        case .unplugged: return .discharge
        case .unknown: return nil
        }
    }

    public static func sessions(from samples: [BatterySample]) -> [BatterySession] {
        let usable = samples
            .filter { $0.isLevelKnown && kind(for: $0.state) != nil }
            .sorted { $0.timestamp < $1.timestamp }
        guard usable.count >= 2 else { return [] }

        var result: [BatterySession] = []
        var runStartIdx = 0

        func flush(_ startIdx: Int, _ endIdx: Int) {
            guard endIdx > startIdx else { return }
            let first = usable[startIdx], last = usable[endIdx]
            guard let k = kind(for: first.state) else { return }
            result.append(BatterySession(kind: k, start: first.timestamp, end: last.timestamp,
                                         startLevel: first.level, endLevel: last.level))
        }

        for i in 1..<usable.count {
            let prev = usable[i - 1], cur = usable[i]
            let kindChanged = kind(for: prev.state) != kind(for: cur.state)
            let gapped = cur.timestamp.timeIntervalSince(prev.timestamp) > gapThreshold
            if kindChanged || gapped {
                flush(runStartIdx, i - 1)
                runStartIdx = i
            }
        }
        flush(runStartIdx, usable.count - 1)
        return result
    }

    /// Minutes of the most recent contiguous tail where state == .full.
    public static func minutesAtFull(from samples: [BatterySample]) -> Int {
        let sorted = samples.sorted { $0.timestamp < $1.timestamp }
        guard let last = sorted.last, last.state == .full else { return 0 }
        var startOfFull = last.timestamp
        for sample in sorted.reversed() {
            if sample.state == .full { startOfFull = sample.timestamp } else { break }
        }
        return Int(last.timestamp.timeIntervalSince(startOfFull) / 60)
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --package-path packages/VoltsyKit --filter SessionEngineTests`
Expected: PASS (5 tests).

- [ ] **Step 5: Commit**

```bash
git add packages/VoltsyKit/Sources/BatteryEngines/BatterySession.swift packages/VoltsyKit/Sources/BatteryEngines/SessionEngine.swift packages/VoltsyKit/Tests/BatteryEnginesTests/SessionEngineTests.swift
git commit -m "feat(engines): add SessionEngine (gap-tolerant session segmentation)"
```

---

## Task 4: `CareScoreEngine` (honest heuristic + confidence gating)

**Files:**
- Create: `packages/VoltsyKit/Sources/BatteryEngines/CareScore.swift`
- Create: `packages/VoltsyKit/Sources/BatteryEngines/CareScoreEngine.swift`
- Test: `packages/VoltsyKit/Tests/BatteryEnginesTests/CareScoreEngineTests.swift`

**Heuristic:** start at 100, subtract penalties: heat exposure (minutes at thermal ≥ serious × 0.05), deep discharges (each discharge session ending ≤ 5% × 4), 100%-dwell (minutes at full beyond 60-min grace × 0.02). Clamp 0...100. Tint: ≥80 green, 50..<80 amber, <50 red. **Confidence gating:** `appAccruedCycles` = sum of per-discharge-session level drop; if accrued cycles < `minCyclesForScore` (3) → confidence `.insufficient`, and `value` is `nil` (UI must not show a number). This is the spec's "never show an unfounded health number."

- [ ] **Step 1: Write the failing test**

```swift
// Tests/BatteryEnginesTests/CareScoreEngineTests.swift
import Testing
import Foundation
import VoltsyCore
@testable import BatteryEngines

@Suite("CareScoreEngine")
struct CareScoreEngineTests {
    private let t0 = Date(timeIntervalSince1970: 1_700_000_000)
    private func s(_ minutes: Double, _ level: Double, _ state: BatteryChargeState,
                   _ thermal: ThermalLevel = .nominal) -> BatterySample {
        BatterySample(timestamp: t0.addingTimeInterval(minutes * 60), level: level,
                      state: state, lowPowerMode: false, thermal: thermal)
    }

    @Test("insufficient history gates the value to nil")
    func gating() {
        let score = CareScoreEngine.score(from: [s(0, 0.8, .unplugged), s(30, 0.78, .unplugged)])
        #expect(score.value == nil)
        if case .insufficient = score.confidence {} else { Issue.record("expected .insufficient") }
    }

    @Test("clean usage past the data threshold scores high and green")
    func cleanHigh() {
        // three full-ish discharge cycles, no heat, no deep discharge, no overcharge dwell
        var samples: [BatterySample] = []
        for cycle in 0..<3 {
            let base = Double(cycle) * 600
            samples.append(s(base, 0.80, .unplugged))
            samples.append(s(base + 120, 0.30, .unplugged))
            samples.append(s(base + 130, 0.30, .charging))
            samples.append(s(base + 240, 0.80, .charging))
        }
        let score = CareScoreEngine.score(from: samples)
        #expect(score.value != nil)
        #expect((score.value ?? 0) >= 90)
        #expect(score.tint == .green)
    }

    @Test("heavy heat exposure lowers the score and reddens the tint")
    func heatHurts() {
        var samples: [BatterySample] = []
        for cycle in 0..<3 {
            let base = Double(cycle) * 600
            samples.append(s(base, 0.80, .unplugged, .critical))
            samples.append(s(base + 300, 0.30, .unplugged, .critical)) // 300 min hot per cycle
            samples.append(s(base + 310, 0.30, .charging, .critical))
            samples.append(s(base + 600, 0.80, .charging, .critical))
        }
        let score = CareScoreEngine.score(from: samples)
        #expect((score.value ?? 100) < 50)
        #expect(score.tint == .red)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --package-path packages/VoltsyKit --filter CareScoreEngineTests`
Expected: FAIL — `CareScoreEngine` not found.

- [ ] **Step 3: Write the implementations**

```swift
// Sources/BatteryEngines/CareScore.swift
import VoltsyCore

public struct CareScore: Sendable, Equatable {
    public enum Confidence: Sendable, Equatable {
        case insufficient(accruedCycles: Double, needed: Double)
        case estimating(accruedCycles: Double)
    }
    public let value: Int?            // nil until enough data — UI must not invent a number
    public let confidence: Confidence
    public let tint: HealthTint

    public init(value: Int?, confidence: Confidence, tint: HealthTint) {
        self.value = value
        self.confidence = confidence
        self.tint = tint
    }
}
```

```swift
// Sources/BatteryEngines/CareScoreEngine.swift
import Foundation
import VoltsyCore

public enum CareScoreEngine {
    public static let minCyclesForScore: Double = 3
    public static let heatPenaltyPerMinute = 0.05      // minutes at thermal >= serious
    public static let deepDischargePenalty = 4.0       // per discharge session ending <= 5%
    public static let overchargeGraceMinutes = 60.0
    public static let overchargePenaltyPerMinute = 0.02

    public static func appAccruedCycles(from sessions: [BatterySession]) -> Double {
        sessions.filter { $0.kind == .discharge }
                .reduce(0) { $0 + max(0, -$1.levelDelta) }
    }

    public static func score(from samples: [BatterySample]) -> CareScore {
        let sorted = samples.sorted { $0.timestamp < $1.timestamp }
        let sessions = SessionEngine.sessions(from: sorted)
        let accrued = appAccruedCycles(from: sessions)

        guard accrued >= minCyclesForScore else {
            return CareScore(value: nil,
                             confidence: .insufficient(accruedCycles: accrued, needed: minCyclesForScore),
                             tint: .green)
        }

        // Heat exposure: minutes where thermal >= serious, attributed to the interval before each sample.
        var hotMinutes = 0.0
        for i in 1..<sorted.count {
            if sorted[i].thermal >= .serious {
                hotMinutes += sorted[i].timestamp.timeIntervalSince(sorted[i - 1].timestamp) / 60
            }
        }

        let deepDischarges = sessions.filter { $0.kind == .discharge && $0.endLevel <= 0.05 }.count
        let overchargeMinutes = max(0, Double(SessionEngine.minutesAtFull(from: sorted)) - overchargeGraceMinutes)

        var value = 100.0
        value -= hotMinutes * heatPenaltyPerMinute
        value -= Double(deepDischarges) * deepDischargePenalty
        value -= overchargeMinutes * overchargePenaltyPerMinute
        let clamped = Int(min(100, max(0, value)).rounded())

        let tint: HealthTint = clamped >= 80 ? .green : (clamped >= 50 ? .amber : .red)
        return CareScore(value: clamped, confidence: .estimating(accruedCycles: accrued), tint: tint)
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --package-path packages/VoltsyKit --filter CareScoreEngineTests`
Expected: PASS (3 tests).

- [ ] **Step 5: Commit**

```bash
git add packages/VoltsyKit/Sources/BatteryEngines/CareScore.swift packages/VoltsyKit/Sources/BatteryEngines/CareScoreEngine.swift packages/VoltsyKit/Tests/BatteryEnginesTests/CareScoreEngineTests.swift
git commit -m "feat(engines): add CareScoreEngine with confidence gating + honest heuristic"
```

---

## Task 5: `BatteryStore` (SwiftData time-series, injected container)

**Files:**
- Create: `packages/VoltsyKit/Sources/BatteryStore/BatterySampleRecord.swift`
- Create: `packages/VoltsyKit/Sources/BatteryStore/BatteryStore.swift`
- Test: `packages/VoltsyKit/Tests/BatteryStoreTests/BatteryStoreTests.swift`

- [ ] **Step 1: Write the failing test**

```swift
// Tests/BatteryStoreTests/BatteryStoreTests.swift
import Testing
import Foundation
import SwiftData
import VoltsyCore
@testable import BatteryStore

@MainActor
@Suite("BatteryStore")
struct BatteryStoreTests {
    private func inMemoryStore() throws -> BatteryStore {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: BatterySampleRecord.self, configurations: config)
        return BatteryStore(container: container)
    }

    @Test("append then fetch round-trips a sample")
    func roundTrip() throws {
        let store = try inMemoryStore()
        let sample = BatterySample(timestamp: Date(timeIntervalSince1970: 100), level: 0.42,
                                   state: .unplugged, lowPowerMode: true, thermal: .fair)
        try store.append(sample)
        let all = try store.recentSamples(limit: 10)
        #expect(all.count == 1)
        #expect(all[0] == sample)
    }

    @Test("recentSamples returns newest first and respects the limit")
    func ordering() throws {
        let store = try inMemoryStore()
        for i in 0..<5 {
            try store.append(BatterySample(timestamp: Date(timeIntervalSince1970: Double(i)),
                                           level: 0.5, state: .unplugged, lowPowerMode: false, thermal: .nominal))
        }
        let recent = try store.recentSamples(limit: 2)
        #expect(recent.count == 2)
        #expect(recent[0].timestamp > recent[1].timestamp)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --package-path packages/VoltsyKit --filter BatteryStoreTests`
Expected: FAIL — `BatteryStore` not found.

- [ ] **Step 3: Write the implementations**

```swift
// Sources/BatteryStore/BatterySampleRecord.swift
import Foundation
import SwiftData
import VoltsyCore

@Model
public final class BatterySampleRecord {
    public var timestamp: Date
    public var level: Double
    public var stateRaw: String
    public var lowPowerMode: Bool
    public var thermalRaw: Int

    public init(_ sample: BatterySample) {
        self.timestamp = sample.timestamp
        self.level = sample.level
        self.stateRaw = sample.state.rawValue
        self.lowPowerMode = sample.lowPowerMode
        self.thermalRaw = sample.thermal.rawValue
    }

    public func toSample() -> BatterySample {
        BatterySample(timestamp: timestamp, level: level,
                      state: BatteryChargeState(rawValue: stateRaw) ?? .unknown,
                      lowPowerMode: lowPowerMode,
                      thermal: ThermalLevel(rawValue: thermalRaw) ?? .nominal)
    }
}
```

```swift
// Sources/BatteryStore/BatteryStore.swift
import Foundation
import SwiftData
import VoltsyCore

@MainActor
public final class BatteryStore {
    public static let appGroupID = "group.com.lawoflarge.voltsy"
    private let container: ModelContainer

    public init(container: ModelContainer) {
        self.container = container
    }

    /// App-Group-backed store shared by the app, widget, and Live Activity.
    public static func shared() throws -> BatteryStore {
        let config = ModelConfiguration(groupContainer: .identifier(appGroupID))
        let container = try ModelContainer(for: BatterySampleRecord.self, configurations: config)
        return BatteryStore(container: container)
    }

    /// In-memory store so a missing App Group entitlement never crashes launch.
    public static func inMemoryFallback() -> BatteryStore {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: BatterySampleRecord.self, configurations: config)
        return BatteryStore(container: container)
    }

    public func append(_ sample: BatterySample) throws {
        let ctx = container.mainContext
        ctx.insert(BatterySampleRecord(sample))
        try ctx.save()
    }

    public func recentSamples(limit: Int) throws -> [BatterySample] {
        var descriptor = FetchDescriptor<BatterySampleRecord>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)])
        descriptor.fetchLimit = limit
        return try container.mainContext.fetch(descriptor).map { $0.toSample() }
    }

    public func samples(since date: Date) throws -> [BatterySample] {
        let descriptor = FetchDescriptor<BatterySampleRecord>(
            predicate: #Predicate { $0.timestamp >= date },
            sortBy: [SortDescriptor(\.timestamp, order: .forward)])
        return try container.mainContext.fetch(descriptor).map { $0.toSample() }
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --package-path packages/VoltsyKit --filter BatteryStoreTests`
Expected: PASS (2 tests).

- [ ] **Step 5: Run the FULL package suite**

Run: `swift test --package-path packages/VoltsyKit`
Expected: PASS — all suites (VoltsyCore, BatteryEngines, BatteryStore) green.

- [ ] **Step 6: Commit**

```bash
git add packages/VoltsyKit/Sources/BatteryStore packages/VoltsyKit/Tests/BatteryStoreTests
git commit -m "feat(store): add SwiftData BatteryStore with App-Group + in-memory injection"
```

---

## Task 6: `BatteryMonitor` (UIKit sensing, in the app target)

**Files:**
- Create: `apps/Voltsy/Sources/Sensing/BatteryMonitor.swift`

This is UIKit-bound (`UIDevice`, `ProcessInfo`) so it lives in the iOS app target, not the host-testable package. It is verified on a **physical device** (the simulator reports no real battery data — see spec §11).

- [ ] **Step 1: Write `BatteryMonitor`**

```swift
// apps/Voltsy/Sources/Sensing/BatteryMonitor.swift
import Foundation
import UIKit
import VoltsyCore

@MainActor
@Observable
public final class BatteryMonitor {
    public private(set) var current: BatterySample

    private let onSample: @MainActor (BatterySample) -> Void

    public init(onSample: @escaping @MainActor (BatterySample) -> Void) {
        self.onSample = onSample
        UIDevice.current.isBatteryMonitoringEnabled = true
        self.current = BatteryMonitor.snapshot()

        let center = NotificationCenter.default
        for name: NSNotification.Name in [
            UIDevice.batteryLevelDidChangeNotification,
            UIDevice.batteryStateDidChangeNotification,
            .NSProcessInfoPowerStateDidChange,
            ProcessInfo.thermalStateDidChangeNotification
        ] {
            center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.refresh() }
            }
        }
        onSample(current)
    }

    /// Call from a SwiftUI TimelineView tick to pick up rounding changes the OS didn't post.
    public func refresh() {
        let sample = BatteryMonitor.snapshot()
        guard sample != current else { return }
        current = sample
        onSample(sample)
    }

    private static func snapshot() -> BatterySample {
        let device = UIDevice.current
        let state: BatteryChargeState
        switch device.batteryState {
        case .charging: state = .charging
        case .full: state = .full
        case .unplugged: state = .unplugged
        default: state = .unknown
        }
        let thermal: ThermalLevel
        switch ProcessInfo.processInfo.thermalState {
        case .nominal: thermal = .nominal
        case .fair: thermal = .fair
        case .serious: thermal = .serious
        case .critical: thermal = .critical
        @unknown default: thermal = .nominal
        }
        return BatterySample(
            timestamp: Date(),
            level: Double(device.batteryLevel),   // -1.0 when unknown
            state: state,
            lowPowerMode: ProcessInfo.processInfo.isLowPowerModeEnabled,
            thermal: thermal)
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add apps/Voltsy/Sources/Sensing/BatteryMonitor.swift
git commit -m "feat(app): add BatteryMonitor (UIDevice/ProcessInfo sensing)"
```

---

## Task 7: App composition root + placeholder Home screen

**Files:**
- Create: `apps/Voltsy/Sources/Home/HomeViewModel.swift`
- Create: `apps/Voltsy/Sources/Home/HomeView.swift`
- Create: `apps/Voltsy/Sources/VoltsyApp.swift`
- Create: `apps/Voltsy/Resources/Assets.xcassets/AccentColor.colorset/Contents.json`
- Create: `apps/Voltsy/Resources/Assets.xcassets/AppIcon.appiconset/Contents.json`
- Create: `apps/Voltsy/Resources/Assets.xcassets/Contents.json`

- [ ] **Step 1: Create the asset catalog stubs**

`apps/Voltsy/Resources/Assets.xcassets/Contents.json`:
```json
{ "info" : { "author" : "xcode", "version" : 1 } }
```
`apps/Voltsy/Resources/Assets.xcassets/AccentColor.colorset/Contents.json`:
```json
{
  "colors" : [ { "idiom" : "universal", "color" : { "color-space" : "srgb",
    "components" : { "red" : "0.20", "green" : "0.80", "blue" : "0.40", "alpha" : "1.000" } } } ],
  "info" : { "author" : "xcode", "version" : 1 }
}
```
`apps/Voltsy/Resources/Assets.xcassets/AppIcon.appiconset/Contents.json`:
```json
{ "images" : [ { "idiom" : "universal", "platform" : "ios", "size" : "1024x1024" } ],
  "info" : { "author" : "xcode", "version" : 1 } }
```

- [ ] **Step 2: Create `HomeViewModel`**

```swift
// apps/Voltsy/Sources/Home/HomeViewModel.swift
import Foundation
import VoltsyCore
import BatteryEngines
import BatteryStore

@MainActor
@Observable
final class HomeViewModel {
    private let store: BatteryStore
    private(set) var monitor: BatteryMonitor!
    private(set) var voltState: VoltState =
        VoltState(mood: .content, bellyFill: 0.5, tint: .green)
    private(set) var careScore: CareScore =
        CareScore(value: nil, confidence: .insufficient(accruedCycles: 0, needed: 3), tint: .green)

    init(store: BatteryStore) {
        self.store = store
        self.monitor = BatteryMonitor { [weak self] sample in
            self?.ingest(sample)
        }
    }

    func tick() { monitor.refresh() }

    private func ingest(_ sample: BatterySample) {
        try? store.append(sample)
        let recent = (try? store.samples(since: Date().addingTimeInterval(-60 * 60 * 24 * 30))) ?? [sample]
        let score = CareScoreEngine.score(from: recent)
        let minutesFull = SessionEngine.minutesAtFull(from: recent)
        voltState = VoltStateMapper.map(level: sample.level, state: sample.state,
                                        thermal: sample.thermal, lowPowerMode: sample.lowPowerMode,
                                        minutesAtFull: minutesFull, tint: score.tint)
        careScore = score
    }
}
```

- [ ] **Step 3: Create `HomeView` (placeholder mascot)**

```swift
// apps/Voltsy/Sources/Home/HomeView.swift
import SwiftUI
import VoltsyCore
import BatteryEngines

struct HomeView: View {
    @State var model: HomeViewModel

    private var tintColor: Color {
        switch model.voltState.tint { case .green: .green; case .amber: .orange; case .red: .red }
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 5)) { _ in
            VStack(spacing: 24) {
                // Placeholder "Volt" — replaced by the real vector mascot in Plan 2.
                ZStack(alignment: .bottom) {
                    RoundedRectangle(cornerRadius: 28).stroke(tintColor, lineWidth: 4)
                    RoundedRectangle(cornerRadius: 24)
                        .fill(tintColor.opacity(0.5))
                        .frame(height: 180 * model.voltState.bellyFill)
                        .padding(6)
                }
                .frame(width: 120, height: 180)
                .overlay(Text(emoji(model.voltState.mood)).font(.system(size: 48)))

                Text(model.voltState.mood.rawValue.capitalized).font(.title2.bold())

                careCard

                Text("On-device estimate from your usage — not Apple's measured cycle count or capacity.")
                    .font(.caption).foregroundStyle(.secondary)
                    .multilineTextAlignment(.center).padding(.horizontal)
            }
            .padding()
            .onAppear { model.tick() }
        }
    }

    @ViewBuilder private var careCard: some View {
        VStack(spacing: 4) {
            Text("Battery Care").font(.headline)
            switch model.careScore.confidence {
            case .insufficient:
                Text("Getting to know your battery…").foregroundStyle(.secondary)
            case .estimating:
                Text("\(model.careScore.value ?? 0)").font(.system(size: 44, weight: .bold))
                    .foregroundStyle(tintColor)
            }
        }
        .padding().frame(maxWidth: .infinity)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 16))
    }

    private func emoji(_ mood: VoltMood) -> String {
        switch mood {
        case .energetic: "😄"; case .content: "🙂"; case .tired: "🥱"; case .critical: "😵"
        case .charging: "😋"; case .overcharged: "🤢"; case .overheating: "🥵"; case .zen: "😌"
        }
    }
}
```

- [ ] **Step 4: Create the app entry point `VoltsyApp.swift`**

```swift
// apps/Voltsy/Sources/VoltsyApp.swift
import SwiftUI
import BatteryStore

@main
struct VoltsyApp: App {
    @State private var model: HomeViewModel = {
        let store = (try? BatteryStore.shared()) ?? BatteryStore.inMemoryFallback()
        return HomeViewModel(store: store)
    }()

    var body: some Scene {
        WindowGroup { HomeView(model: model) }
    }
}
```

- [ ] **Step 5: Generate the project and build for the simulator**

Run:
```bash
cd ~/Data/Claude/voltsy && xcodegen generate
xcodebuild -project Voltsy.xcodeproj -scheme Voltsy \
  -destination 'generic/platform=iOS Simulator' build | tail -20
```
Expected: `BUILD SUCCEEDED`. (The simulator shows `batteryLevel == -1` / unknown, so Volt will read as the neutral `content` placeholder — correct behavior; real states are verified on device in Step 6.)

- [ ] **Step 6: Manual device verification**

On a physical iPhone (iOS 26), run the app from Xcode and confirm: the placeholder battery fill tracks the real charge %, the mood label changes when you unplug/plug in, enabling Low Power Mode flips Volt to `zen`, and the care card reads "Getting to know your battery…" on first launch (insufficient data). Record the result in the commit message.

- [ ] **Step 7: Commit**

```bash
git add apps/Voltsy/Sources apps/Voltsy/Resources
git commit -m "feat(app): wire composition root + placeholder Home screen (device-verified)"
```

---

## Task 8: README + plan close-out

**Files:**
- Create: `~/Data/Claude/voltsy/README.md`

- [ ] **Step 1: Write `README.md`**

```markdown
# Voltsy

iOS battery-care companion with the **Volt** mascot. Honest on-device estimates
(never claims Apple's real cycle count / health %), free + AdMob, €4.99 lifetime Pro.

## Layout (monorepo)
- `packages/VoltsyKit` — pure, host-testable logic (`VoltsyCore`, `BatteryEngines`, `BatteryStore`)
- `apps/Voltsy` — iOS app (sensing + SwiftUI)
- `docs/superpowers/` — specs + plans

## Develop
- Logic tests: `swift test --package-path packages/VoltsyKit`
- Generate Xcode project: `xcodegen generate`
- Build: `xcodebuild -project Voltsy.xcodeproj -scheme Voltsy -destination 'generic/platform=iOS Simulator' build`

> Battery APIs return no real data on the simulator — verify sensing on a physical device.
```

- [ ] **Step 2: Run the full suite one last time**

Run: `swift test --package-path packages/VoltsyKit`
Expected: PASS (all suites).

- [ ] **Step 3: Commit**

```bash
git add README.md
git commit -m "docs: add README"
```

---

## Self-review (against spec §1–§16)

- **Engines pure + TDD (§6, §13):** ✅ VoltsyCore/BatteryEngines/BatteryStore are host-testable via `swift test`; Sensing/UI are device-verified.
- **Honest data model + confidence gating (§3, §7):** ✅ `CareScore.value` is `nil` until `minCyclesForScore`; UI shows the estimate disclaimer; no IOKit, no cycle-count/health-% claims.
- **Gap tolerance (§6):** ✅ `SessionEngine.gapThreshold` splits sessions across sleep gaps.
- **App Group sharing (§5, §6):** ✅ `BatteryStore.shared()` uses `group.com.lawoflarge.voltsy` (consumed by widget/Live Activity in Plan 4).
- **Volt moods (§8):** ✅ all 8 Plan-1 moods mapped; `stalledCharging` deliberately deferred (ambiguous to detect) and noted.
- **Deferred to later plans (by design):** real vector mascot + cosmetics (Plan 2), streak/achievements/notifications/recap (Plan 3), widget + Live Activity (Plan 4), monetization + ads (Plan 5), ASO + submission (Plan 6). The roadmap table documents the split.
- **Type consistency:** `BatterySample`, `VoltState`/`VoltMood`, `CareScore`, `BatterySession`, `BatteryStore` signatures match across all tasks (mapper input order = level, state, thermal, lowPowerMode, minutesAtFull, tint everywhere; `CareScore` has a public init used by `HomeViewModel`).

## Open considerations carried to later plans
- Deployment target is iOS 26 per spec; lowering to iOS 18 would widen install base — revisit before Plan 6 submission if reach matters more than newest APIs.
- Background sampling (`BGTaskScheduler`) is intentionally not in Plan 1 (foreground sensing is enough for the testable slice); add in Plan 3/4 when the care loop needs off-screen data, scoped honestly as opportunistic.
