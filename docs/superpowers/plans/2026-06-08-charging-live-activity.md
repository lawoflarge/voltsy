# Charging Live Activity Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build Voltsy's charging Live Activity — a Lock Screen + Dynamic Island surface showing Volt eating, the belly filling in real time, and an honest ETA to 80% / full while the phone charges (spec §9, the last open piece of Milestone C).

**Architecture:** A new **pure** `ChargeEstimateEngine` (in `BatteryEngines`, TDD) turns the existing battery-sample history into an honest minutes-to-target estimate. A shared source folder `apps/Shared/LiveActivity/` (compiled into BOTH the app and the widget extension — Apple's canonical pattern for Live Activity attribute sharing) holds the `ActivityAttributes` type and the presentation subviews (parameterized by `ContentState`, no ActivityKit context, so the same views render in the widget's `ActivityConfiguration` *and* in an in-app dev gallery for simulator screenshots). The app drives the lifecycle via a `ChargingActivityController` wired into `HomeViewModel.ingest`; updates are **local** (no push → no extra entitlement, profiles unchanged). The live charging lifecycle is verified on Levin's physical device (the simulator has no real battery — spec §6/§13); the *rendering* is verified by simulator screenshot of the dev gallery.

**Tech Stack:** ActivityKit, WidgetKit, SwiftUI, Swift Testing, XcodeGen, local Mac build/altool pipeline (team `R95M36AU2X`).

---

## File structure

| File | Responsibility | Action |
|---|---|---|
| `packages/VoltsyKit/Sources/VoltsyCore/VoltState.swift` | Add `Hashable` so `VoltState` can live inside an ActivityKit `ContentState` | Modify |
| `packages/VoltsyKit/Sources/BatteryEngines/ChargeEstimateEngine.swift` | Pure ETA: charge rate + minutes-to-level, honestly gated | Create |
| `packages/VoltsyKit/Tests/BatteryEnginesTests/ChargeEstimateEngineTests.swift` | TDD for the engine | Create |
| `apps/Shared/LiveActivity/VoltActivityAttributes.swift` | `ActivityAttributes` + `ContentState` (shared by both iOS targets) | Create |
| `apps/Shared/LiveActivity/ChargingActivityViews.swift` | Lock Screen + DI-region subviews, parameterized by `ContentState` | Create |
| `apps/VoltsyWidget/Sources/VoltChargingLiveActivity.swift` | `ActivityConfiguration` (Lock Screen + Dynamic Island) wiring `context.state` into the shared subviews | Create |
| `apps/VoltsyWidget/Sources/VoltsyWidget.swift` | Add the Live Activity widget to the `@main` `WidgetBundle` | Modify |
| `apps/Voltsy/Sources/LiveActivity/ChargingActivityController.swift` | Start/update/end the Activity from samples | Create |
| `apps/Voltsy/Sources/LiveActivity/ChargingActivityGalleryView.swift` | Dev-only gallery rendering the Lock Screen view for screenshot verification | Create |
| `apps/Voltsy/Sources/Home/HomeViewModel.swift` | Call the controller each ingest | Modify |
| `apps/Voltsy/Resources/Info.plist` | `NSSupportsLiveActivities = true` | Modify |
| `project.yml` | Add `apps/Shared/LiveActivity` to both targets; bump build to 5 | Modify |

---

## Task 1: Make `VoltState` Hashable

**Files:**
- Modify: `packages/VoltsyKit/Sources/VoltsyCore/VoltState.swift:12`

ActivityKit requires `ContentState: Codable & Hashable`; we embed `VoltState` in it so the Live Activity reuses `VoltView` directly. All stored properties (`VoltMood` String enum, `Double`, `HealthTint` String enum) are already `Hashable`, so the conformance is synthesized.

- [ ] **Step 1: Add `Hashable` to the conformance list**

Change line 12 from:

```swift
public struct VoltState: Sendable, Equatable, Codable {
```

to:

```swift
public struct VoltState: Sendable, Equatable, Codable, Hashable {
```

- [ ] **Step 2: Verify the package still builds and tests pass**

Run: `cd ~/Data/Claude/voltsy && swift test --package-path packages/VoltsyKit 2>&1 | tail -5`
Expected: build succeeds, all existing tests pass (52 tests).

- [ ] **Step 3: Commit**

```bash
cd ~/Data/Claude/voltsy
git add packages/VoltsyKit/Sources/VoltsyCore/VoltState.swift
git commit -m "feat(core): make VoltState Hashable for Live Activity ContentState"
```

---

## Task 2: `ChargeEstimateEngine` (pure, TDD)

**Files:**
- Create: `packages/VoltsyKit/Sources/BatteryEngines/ChargeEstimateEngine.swift`
- Test: `packages/VoltsyKit/Tests/BatteryEnginesTests/ChargeEstimateEngineTests.swift`

Honest estimate: a rate is trusted only after a charge run spans ≥ 5 min with a positive level delta (5% quantization needs time to be meaningful). No fabricated ETA on first plug-in.

- [ ] **Step 1: Write the failing tests**

Create `packages/VoltsyKit/Tests/BatteryEnginesTests/ChargeEstimateEngineTests.swift`:

```swift
// Tests/BatteryEnginesTests/ChargeEstimateEngineTests.swift
import Testing
import Foundation
import VoltsyCore
@testable import BatteryEngines

@Suite("ChargeEstimateEngine")
struct ChargeEstimateEngineTests {
    private let t0 = Date(timeIntervalSince1970: 1_700_000_000)
    private func s(_ minutes: Double, _ level: Double, _ state: BatteryChargeState) -> BatterySample {
        BatterySample(timestamp: t0.addingTimeInterval(minutes * 60), level: level,
                      state: state, lowPowerMode: false, thermal: .nominal)
    }

    @Test("no rate when the latest sample is not charging")
    func notCharging() {
        let samples = [s(0, 0.80, .unplugged), s(30, 0.75, .unplugged)]
        #expect(ChargeEstimateEngine.chargeRatePerMinute(from: samples) == nil)
        #expect(ChargeEstimateEngine.minutesToLevel(0.8, from: samples) == nil)
    }

    @Test("rate and ETA from a clean charge run")
    func cleanRun() {
        // 30% → 50% over 40 min → 0.20/40 = 0.005 fraction/min
        let samples = [s(0, 0.30, .charging), s(20, 0.40, .charging), s(40, 0.50, .charging)]
        let rate = ChargeEstimateEngine.chargeRatePerMinute(from: samples)
        #expect(rate != nil)
        #expect(abs(rate! - 0.005) < 1e-6)
        // to 80%: (0.80-0.50)/0.005 = 60 min
        #expect(ChargeEstimateEngine.minutesToLevel(0.8, from: samples) == 60)
        // to full: (1.0-0.50)/0.005 = 100 min
        #expect(ChargeEstimateEngine.minutesToLevel(1.0, from: samples) == 100)
    }

    @Test("no ETA before the run spans the minimum trustworthy duration")
    func tooShort() {
        let samples = [s(0, 0.30, .charging), s(2, 0.35, .charging)] // 2-min span
        #expect(ChargeEstimateEngine.chargeRatePerMinute(from: samples) == nil)
        #expect(ChargeEstimateEngine.minutesToLevel(0.8, from: samples) == nil)
    }

    @Test("no ETA once already at or above the target")
    func alreadyThere() {
        let samples = [s(0, 0.78, .charging), s(20, 0.85, .charging)]
        #expect(ChargeEstimateEngine.minutesToLevel(0.8, from: samples) == nil)
    }

    @Test("full battery yields no charging rate")
    func full() {
        let samples = [s(0, 0.98, .charging), s(20, 1.0, .full)]
        #expect(ChargeEstimateEngine.chargeRatePerMinute(from: samples) == nil)
    }

    @Test("only the most recent charge run after a gap is used")
    func recentRunAfterGap() {
        // old fast run, then a >30-min gap, then a slower recent run
        let samples = [s(0, 0.20, .charging), s(10, 0.50, .charging),
                       s(60, 0.50, .charging), s(120, 0.80, .charging)] // recent: 30% over 60 min
        let rate = ChargeEstimateEngine.chargeRatePerMinute(from: samples)
        #expect(rate != nil)
        #expect(abs(rate! - (0.30 / 60)) < 1e-6) // 0.005, from the recent run only
    }

    @Test("ETA rounds up to whole minutes, never below 1")
    func roundsUp() {
        // 50% → 51% over 10 min → 0.001/min; to 80% = 0.30/0.001 = 300 min
        let samples = [s(0, 0.50, .charging), s(10, 0.51, .charging)]
        #expect(ChargeEstimateEngine.minutesToLevel(0.8, from: samples) == 300)
    }
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `cd ~/Data/Claude/voltsy && swift test --package-path packages/VoltsyKit --filter ChargeEstimateEngine 2>&1 | tail -15`
Expected: FAIL — `cannot find 'ChargeEstimateEngine' in scope`.

- [ ] **Step 3: Write the implementation**

Create `packages/VoltsyKit/Sources/BatteryEngines/ChargeEstimateEngine.swift`:

```swift
// Sources/BatteryEngines/ChargeEstimateEngine.swift
// Honest charging ETA: derive a charge rate from the most recent contiguous charge run,
// project minutes to a target level. Gated so we never fabricate an ETA from a single
// 5%-quantized reading. Pure — no UIKit/IO — exhaustively unit-tested.
import Foundation
import VoltsyCore

public enum ChargeEstimateEngine {
    /// A charge run must span at least this long before its rate is trusted.
    public static let minimumSpan: TimeInterval = 5 * 60

    /// Charge rate as fraction-of-full per minute (> 0), from the most recent contiguous
    /// charge run. nil when the latest sample is not charging, or the run is too short / flat.
    public static func chargeRatePerMinute(from samples: [BatterySample]) -> Double? {
        let known = samples.filter { $0.isLevelKnown }.sorted { $0.timestamp < $1.timestamp }
        guard known.last?.state == .charging else { return nil }
        guard let run = SessionEngine.sessions(from: samples).last, run.kind == .charge else { return nil }
        guard run.duration >= minimumSpan, run.levelDelta > 0 else { return nil }
        return run.levelDelta / (run.duration / 60)
    }

    /// Estimated whole minutes from the latest known level to `target` (0...1) at the current
    /// charge rate. nil when not charging, already at/above target, or the rate isn't trustworthy.
    public static func minutesToLevel(_ target: Double, from samples: [BatterySample]) -> Int? {
        let known = samples.filter { $0.isLevelKnown }.sorted { $0.timestamp < $1.timestamp }
        guard let current = known.last?.level, current < target else { return nil }
        guard let rate = chargeRatePerMinute(from: samples) else { return nil }
        return max(1, Int(((target - current) / rate).rounded(.up)))
    }
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `cd ~/Data/Claude/voltsy && swift test --package-path packages/VoltsyKit --filter ChargeEstimateEngine 2>&1 | tail -15`
Expected: PASS — 7 tests.

- [ ] **Step 5: Commit**

```bash
cd ~/Data/Claude/voltsy
git add packages/VoltsyKit/Sources/BatteryEngines/ChargeEstimateEngine.swift \
        packages/VoltsyKit/Tests/BatteryEnginesTests/ChargeEstimateEngineTests.swift
git commit -m "feat(engines): honest charging ETA (ChargeEstimateEngine, TDD)"
```

---

## Task 3: Shared Live Activity attributes + presentation views

**Files:**
- Create: `apps/Shared/LiveActivity/VoltActivityAttributes.swift`
- Create: `apps/Shared/LiveActivity/ChargingActivityViews.swift`

These files are compiled into BOTH the app and widget targets (wired in Task 6). Everything is guarded by `#if canImport(ActivityKit)` so it is a no-op on macOS (the engine package's test platform).

- [ ] **Step 1: Create the attributes type**

Create `apps/Shared/LiveActivity/VoltActivityAttributes.swift`:

```swift
// apps/Shared/LiveActivity/VoltActivityAttributes.swift
// Shared by the app (starts/updates the Activity) and the widget extension (renders it).
// Added to BOTH targets via project.yml — Apple's canonical pattern for Live Activity
// attribute sharing (matched by type name; ContentState travels as Codable).
#if canImport(ActivityKit)
import ActivityKit
import VoltsyCore

struct VoltActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var voltState: VoltState
        var percent: Int
        var etaMinutes: Int?
        var targetIsFull: Bool   // false → charging toward 80%, true → toward 100%
        var isComplete: Bool     // battery full / target reached
    }
}
#endif
```

- [ ] **Step 2: Create the presentation views**

Create `apps/Shared/LiveActivity/ChargingActivityViews.swift`:

```swift
// apps/Shared/LiveActivity/ChargingActivityViews.swift
// Presentation for the charging Live Activity, parameterized by ContentState (no ActivityKit
// context) so the same views render in the widget's ActivityConfiguration AND in the in-app
// dev gallery for simulator screenshot verification. Volt is the hero on Lock Screen +
// expanded Dynamic Island; the compact/minimal slots use a crisp bolt + percent.
#if canImport(ActivityKit)
import SwiftUI
import VoltsyCore
import VoltMascot

enum ChargingActivityCopy {
    static func eta(_ state: VoltActivityAttributes.ContentState) -> String {
        if state.isComplete { return "Full — you can unplug 💚" }
        let target = state.targetIsFull ? "full" : "80%"
        if let m = state.etaMinutes { return "≈\(m) min to \(target)" }
        return "Charging to \(target)…"
    }
}

struct ChargingLockScreenView: View {
    let state: VoltActivityAttributes.ContentState
    var body: some View {
        HStack(spacing: 14) {
            VoltView(state: state.voltState, size: 56)
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Image(systemName: "bolt.fill").foregroundStyle(.yellow)
                    Text("\(state.percent)%").font(.title3.bold().monospacedDigit())
                }
                Text(ChargingActivityCopy.eta(state))
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(14)
    }
}

struct ChargingExpandedLeading: View {
    let state: VoltActivityAttributes.ContentState
    var body: some View { VoltView(state: state.voltState, size: 40) }
}

struct ChargingExpandedTrailing: View {
    let state: VoltActivityAttributes.ContentState
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "bolt.fill").foregroundStyle(.yellow)
            Text("\(state.percent)%").font(.title3.bold().monospacedDigit())
        }
    }
}

struct ChargingExpandedBottom: View {
    let state: VoltActivityAttributes.ContentState
    var body: some View {
        Text(ChargingActivityCopy.eta(state))
            .font(.subheadline).foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
    }
}
#endif
```

- [ ] **Step 3: Commit** (files are not yet in a target; they compile in Task 6)

```bash
cd ~/Data/Claude/voltsy
git add apps/Shared/LiveActivity/VoltActivityAttributes.swift \
        apps/Shared/LiveActivity/ChargingActivityViews.swift
git commit -m "feat(liveactivity): shared ActivityAttributes + charging presentation views"
```

---

## Task 4: Widget extension — `ActivityConfiguration`

**Files:**
- Create: `apps/VoltsyWidget/Sources/VoltChargingLiveActivity.swift`
- Modify: `apps/VoltsyWidget/Sources/VoltsyWidget.swift:44-47`

- [ ] **Step 1: Create the Live Activity widget**

Create `apps/VoltsyWidget/Sources/VoltChargingLiveActivity.swift`:

```swift
// apps/VoltsyWidget/Sources/VoltChargingLiveActivity.swift
// The charging Live Activity UI: Lock Screen banner + Dynamic Island. Pure presentation —
// it reads context.state and hands it to the shared ChargingActivity* views.
#if canImport(ActivityKit)
import ActivityKit
import WidgetKit
import SwiftUI

struct VoltChargingLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: VoltActivityAttributes.self) { context in
            ChargingLockScreenView(state: context.state)
                .activityBackgroundTint(Color.black.opacity(0.25))
                .activitySystemActionForegroundColor(.primary)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    ChargingExpandedLeading(state: context.state)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    ChargingExpandedTrailing(state: context.state)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    ChargingExpandedBottom(state: context.state)
                }
            } compactLeading: {
                Image(systemName: "bolt.fill").foregroundStyle(.yellow)
            } compactTrailing: {
                Text("\(context.state.percent)%").monospacedDigit()
            } minimal: {
                Image(systemName: "bolt.fill").foregroundStyle(.yellow)
            }
        }
    }
}
#endif
```

- [ ] **Step 2: Register it in the widget bundle**

In `apps/VoltsyWidget/Sources/VoltsyWidget.swift`, change the bundle (lines 44-47) from:

```swift
@main
struct VoltsyWidgetBundle: WidgetBundle {
    var body: some Widget { VoltsyWidget() }
}
```

to:

```swift
@main
struct VoltsyWidgetBundle: WidgetBundle {
    var body: some Widget {
        VoltsyWidget()
        VoltChargingLiveActivity()
    }
}
```

- [ ] **Step 3: Commit**

```bash
cd ~/Data/Claude/voltsy
git add apps/VoltsyWidget/Sources/VoltChargingLiveActivity.swift \
        apps/VoltsyWidget/Sources/VoltsyWidget.swift
git commit -m "feat(widget): charging Live Activity configuration + bundle entry"
```

---

## Task 5: App — controller + dev gallery + HomeViewModel wiring

**Files:**
- Create: `apps/Voltsy/Sources/LiveActivity/ChargingActivityController.swift`
- Create: `apps/Voltsy/Sources/LiveActivity/ChargingActivityGalleryView.swift`
- Modify: `apps/Voltsy/Sources/Home/HomeViewModel.swift`

- [ ] **Step 1: Create the controller**

Create `apps/Voltsy/Sources/LiveActivity/ChargingActivityController.swift`:

```swift
// apps/Voltsy/Sources/LiveActivity/ChargingActivityController.swift
// Drives the charging Live Activity from the live sample stream: start on plug-in,
// update as the charge/ETA changes, end on unplug. Local updates only (no push).
#if canImport(ActivityKit)
import Foundation
import ActivityKit
import VoltsyCore
import BatteryEngines

@MainActor
final class ChargingActivityController {
    private var activity: Activity<VoltActivityAttributes>?

    func sync(samples: [BatterySample], voltState: VoltState) {
        guard let latest = samples.filter({ $0.isLevelKnown })
            .max(by: { $0.timestamp < $1.timestamp }) else { return }

        switch latest.state {
        case .charging:
            let toFull = latest.level >= 0.8
            let eta = ChargeEstimateEngine.minutesToLevel(toFull ? 1.0 : 0.8, from: samples)
            push(VoltActivityAttributes.ContentState(
                voltState: voltState, percent: latest.percent,
                etaMinutes: eta, targetIsFull: toFull, isComplete: false))
        case .full:
            push(VoltActivityAttributes.ContentState(
                voltState: voltState, percent: 100,
                etaMinutes: nil, targetIsFull: true, isComplete: true))
        case .unplugged, .unknown:
            end()
        }
    }

    private func push(_ content: VoltActivityAttributes.ContentState) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        if let activity {
            Task { await activity.update(ActivityContent(state: content, staleDate: nil)) }
        } else {
            activity = try? Activity.request(
                attributes: VoltActivityAttributes(),
                content: ActivityContent(state: content, staleDate: nil))
        }
    }

    private func end() {
        guard let activity else { return }
        let a = activity
        self.activity = nil
        Task { await a.end(nil, dismissalPolicy: .immediate) }
    }
}
#endif
```

- [ ] **Step 2: Create the dev gallery (screenshot target)**

Create `apps/Voltsy/Sources/LiveActivity/ChargingActivityGalleryView.swift`:

```swift
// apps/Voltsy/Sources/LiveActivity/ChargingActivityGalleryView.swift
// Dev-only: renders the Lock Screen Live Activity view across ContentStates so we can verify
// the look via simulator screenshots (the simulator has no real charging event). Not shipped
// as a screen — temporarily set as the app root during verification, then reverted.
#if canImport(ActivityKit)
import SwiftUI
import VoltsyCore

struct ChargingActivityGalleryView: View {
    private let demos: [(String, VoltActivityAttributes.ContentState)] = [
        ("45% → 80%", .init(voltState: VoltState(mood: .charging, bellyFill: 0.45, tint: .green),
                            percent: 45, etaMinutes: 38, targetIsFull: false, isComplete: false)),
        ("82% → full", .init(voltState: VoltState(mood: .charging, bellyFill: 0.82, tint: .green),
                             percent: 82, etaMinutes: 22, targetIsFull: true, isComplete: false)),
        ("30%, no ETA yet", .init(voltState: VoltState(mood: .charging, bellyFill: 0.30, tint: .green),
                             percent: 30, etaMinutes: nil, targetIsFull: false, isComplete: false)),
        ("full", .init(voltState: VoltState(mood: .overcharged, bellyFill: 1.0, tint: .green),
                       percent: 100, etaMinutes: nil, targetIsFull: true, isComplete: true)),
    ]
    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                Text("Charging Live Activity — Lock Screen").font(.headline).padding(.top, 12)
                ForEach(demos, id: \.0) { item in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.0).font(.caption).foregroundStyle(.secondary)
                        ChargingLockScreenView(state: item.1)
                            .background(.black.opacity(0.85), in: RoundedRectangle(cornerRadius: 18))
                            .environment(\.colorScheme, .dark)
                    }
                    .padding(.horizontal, 14)
                }
            }
        }
    }
}
#endif
```

- [ ] **Step 3: Wire the controller into `HomeViewModel`**

In `apps/Voltsy/Sources/Home/HomeViewModel.swift`, add the controller property after `private let notifications = VoltNotifications()` (line 22):

```swift
    private let notifications = VoltNotifications()
    #if canImport(ActivityKit)
    private let liveActivity = ChargingActivityController()
    #endif
```

Then, at the end of `ingest(_:)` (after the `notifications.scheduleEveningStreakReminder(...)` call, line 83), add:

```swift
        notifications.scheduleEveningStreakReminder(streak: displayCurrent)

        #if canImport(ActivityKit)
        liveActivity.sync(samples: recent, voltState: voltState)
        #endif
    }
```

- [ ] **Step 4: Commit**

```bash
cd ~/Data/Claude/voltsy
git add apps/Voltsy/Sources/LiveActivity/ \
        apps/Voltsy/Sources/Home/HomeViewModel.swift
git commit -m "feat(app): charging Live Activity controller + dev gallery + ingest wiring"
```

---

## Task 6: Project wiring — shared sources, Info.plist, build bump

**Files:**
- Modify: `project.yml`
- Modify: `apps/Voltsy/Resources/Info.plist`

- [ ] **Step 1: Add `NSSupportsLiveActivities` to the app Info.plist**

In `apps/Voltsy/Resources/Info.plist`, add this key/value inside the top-level `<dict>` (right before `</dict>` on line 36, after the `ITSAppUsesNonExemptEncryption` block):

```xml
    <key>NSSupportsLiveActivities</key>
    <true/>
```

- [ ] **Step 2: Add the shared sources to both targets and bump the build number**

In `project.yml`:

(a) Change the build number (line 12) from `CURRENT_PROJECT_VERSION: "4"` to `CURRENT_PROJECT_VERSION: "5"`.

(b) Add the shared folder to the **Voltsy** target `sources` (after `apps/Voltsy/Resources`, ~line 22):

```yaml
    sources:
      - path: apps/Voltsy/Sources
      - path: apps/Voltsy/Resources
      - path: apps/Shared/LiveActivity
```

(c) Add the shared folder to the **VoltsyWidget** target `sources` (after `apps/VoltsyWidget/Sources`, ~line 51):

```yaml
    sources:
      - path: apps/VoltsyWidget/Sources
      - path: apps/Shared/LiveActivity
```

- [ ] **Step 3: Regenerate the Xcode project**

Run: `cd ~/Data/Claude/voltsy && xcodegen generate 2>&1 | tail -3`
Expected: `Created project at .../Voltsy.xcodeproj`.

- [ ] **Step 4: Build for the simulator to confirm everything compiles**

Run:
```bash
cd ~/Data/Claude/voltsy && xcodebuild -project Voltsy.xcodeproj -scheme Voltsy \
  -destination 'platform=iOS Simulator,id=FE881493' -configuration Debug \
  build 2>&1 | tail -8
```
Expected: `** BUILD SUCCEEDED **` (both the app and the embedded `VoltsyWidget.appex` compile).

- [ ] **Step 5: Commit**

```bash
cd ~/Data/Claude/voltsy
git add project.yml apps/Voltsy/Resources/Info.plist
git commit -m "chore(ios): wire shared Live Activity sources + NSSupportsLiveActivities + build 5"
```

---

## Task 7: Simulator screenshot verification (rendering)

**Files:** temporary edit to `apps/Voltsy/Sources/VoltsyApp.swift` (reverted, NOT committed).

- [ ] **Step 1: Temporarily point the app root at the gallery**

In `apps/Voltsy/Sources/VoltsyApp.swift`, temporarily replace the body's `HomeView(model: model)` with the gallery:

```swift
    var body: some Scene {
        WindowGroup { ChargingActivityGalleryView() }  // TEMP — revert before shipping
    }
```

- [ ] **Step 2: Boot the sim, build, install, launch**

Run:
```bash
cd ~/Data/Claude/voltsy
xcrun simctl boot FE881493 2>/dev/null; open -a Simulator
xcodebuild -project Voltsy.xcodeproj -scheme Voltsy \
  -destination 'platform=iOS Simulator,id=FE881493' -configuration Debug \
  -derivedDataPath build/dd build 2>&1 | tail -3
xcrun simctl install FE881493 "$(find build/dd/Build/Products -name 'Voltsy.app' | head -1)"
xcrun simctl launch FE881493 com.lawoflarge.voltsy
```
Expected: app launches showing the four Lock Screen demos.

- [ ] **Step 3: Screenshot and inspect**

Run: `cd ~/Data/Claude/voltsy && xcrun simctl io FE881493 screenshot /tmp/voltsy-liveactivity.png`
Then Read `/tmp/voltsy-liveactivity.png`.
Expected/verify: Volt renders with belly fill matching each percent; "≈38 min to 80%", "≈22 min to full", "Charging to 80%…" (no fabricated number), and "Full — you can unplug 💚" copy each appear correctly; text is legible on the dark banner. If anything is off, fix the views in `apps/Shared/LiveActivity/ChargingActivityViews.swift` and re-screenshot.

- [ ] **Step 4: Revert the temporary root edit**

Restore `apps/Voltsy/Sources/VoltsyApp.swift` so the body is again:

```swift
    var body: some Scene {
        WindowGroup { HomeView(model: model) }
    }
```

Run: `cd ~/Data/Claude/voltsy && git status` — expected: clean (no change to VoltsyApp.swift). Confirm the working tree has no unintended edits.

---

## Task 8: Ship Build 5 to internal TestFlight

Reuse the established 2-target manual-signing pipeline (see memory `reference_ios_local_mac_build`; profiles "Voltsy AppStore" + "Voltsy Widget AppStore", `build/ExportOptions.plist` already lists both). Live Activities need NO new entitlement/profile change (local updates only) — so no Safari/Dev-Portal step.

- [ ] **Step 1: Archive (device, Release, manual signing — both targets)**

Run:
```bash
cd ~/Data/Claude/voltsy
xcodebuild -project Voltsy.xcodeproj -scheme Voltsy -configuration Release \
  -destination 'generic/platform=iOS' -archivePath build/Voltsy.xcarchive \
  archive 2>&1 | tail -5
```
Expected: `** ARCHIVE SUCCEEDED **`.

- [ ] **Step 2: Export the IPA with both profiles**

Run:
```bash
cd ~/Data/Claude/voltsy
xcodebuild -exportArchive -archivePath build/Voltsy.xcarchive \
  -exportOptionsPlist build/ExportOptions.plist -exportPath build/export5 2>&1 | tail -5
```
Expected: `** EXPORT SUCCEEDED **`, IPA at `build/export5/Voltsy.ipa`.

- [ ] **Step 3: Upload via the ASC API key**

Run: `cd ~/Data/Claude/voltsy && xcrun altool --upload-app -f build/export5/Voltsy.ipa -t ios --apiKey 8XWLD2B2RQ --apiIssuer <issuer> 2>&1 | tail -5`
(Use the team-scoped key per `reference_ios_local_mac_build`.)
Expected: `No errors uploading`.

- [ ] **Step 4: Wait for processing and add to the Internal group**

Run:
```bash
asc builds wait --build-number 5
asc builds add-groups --build-number 5 --group 34067b3b-3cb4-40e7-b4f2-6d02b2f74843
```
Expected: build 5 processed VALID, encryption exempt, added to "Internal".

- [ ] **Step 5: Push to GitHub**

```bash
cd ~/Data/Claude/voltsy && git push origin main
```

- [ ] **Step 6: Device verification (Levin)**

On the physical iPhone with Build 5 installed: plug in to charge → confirm the Live Activity appears on the Lock Screen with Volt + percent + ETA, fills as charge rises, the Dynamic Island shows the bolt + percent (compact) and Volt + ETA (expanded), and it disappears on unplug. This is the real acceptance check (spec §15) — the simulator only verifies rendering.

---

## Self-Review

**1. Spec coverage** (spec §9 "Charging Live Activity", §6 data flow, §13 testing):
- Lock Screen + Dynamic Island, Volt eating, belly filling, ETA-to-80%/full → Tasks 3/4/5. ✓
- Pure engine, TDD → Task 2. ✓
- Renders from the shared state, lifecycle from live samples → Task 5. ✓
- Physical-device verification for the live surface; simulator for rendering → Tasks 7/8. ✓
- Honest estimate (no fabricated ETA before data is sufficient) → Task 2 gating + "Charging to …" copy. ✓

**2. Placeholder scan:** Only `<issuer>` in Task 8 Step 3 is a deliberate secret reference (the team-scoped issuer ID from `reference_ios_local_mac_build`), not a code placeholder. All code blocks are complete.

**3. Type consistency:** `VoltActivityAttributes.ContentState(voltState:percent:etaMinutes:targetIsFull:isComplete:)` — identical field order/names in the attributes type (Task 3), controller (Task 5), and gallery (Task 5). `ChargeEstimateEngine.minutesToLevel(_:from:)` / `.chargeRatePerMinute(from:)` — identical in tests (Task 2), engine (Task 2), and controller (Task 5). `ChargingLockScreenView(state:)` and `ChargingExpanded{Leading,Trailing,Bottom}(state:)` — defined in Task 3, consumed in Tasks 4/5. Consistent. ✓
