# Streak Persistence Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Persist the daily care streak and Power Nap freeze-token balance so the streak survives beyond the 30-day sample window, each completed day is finalized exactly once, and tokens accrue/deplete as a real saldo — replacing the current recompute-from-samples-with-hardcoded-`freezeTokens:1`.

**Architecture:** A new pure engine `StreakLedgerEngine.advance` folds *completed* days (strictly before today, oldest first) into a persisted `StreakProgress` value (current/longest streak, token balance, last weekly-refill ISO week, last finalized day, whether the last day was frozen). Free tier has token capacity 1, refilled to capacity at each new ISO week. `BatteryStore` persists `StreakProgress` as a SwiftData singleton. `HomeViewModel` finalizes completed days on each ingest, then displays `currentStreak` plus a provisional +1 if today is already healthy. The existing `StreakAssembler`/`DayHealthEvaluator`/`StreakEngine` stay; only the live wiring changes.

**Tech Stack:** Swift 6, SwiftData, Swift Testing, iOS 26.

---

## File Structure
- Create `packages/VoltsyKit/Sources/BatteryEngines/StreakLedger.swift` — `StreakProgress` value type + `StreakLedgerEngine.advance` (pure).
- Create `packages/VoltsyKit/Tests/BatteryEnginesTests/StreakLedgerEngineTests.swift` — pure-logic tests.
- Modify `packages/VoltsyKit/Sources/BatteryStore/BatteryStore.swift` — add `StreakProgressRecord` SwiftData model + load/save singleton helpers.
- Create `packages/VoltsyKit/Tests/BatteryStoreTests/StreakProgressStoreTests.swift` — round-trip persistence test (in-memory).
- Modify `apps/Voltsy/Sources/Home/HomeViewModel.swift` — finalize completed days via the store + engine, display finalized + provisional-today.

## Design notes (locked)
- **Healthy day** = `DayHealthEvaluator.evaluate(...).isHealthy` (reused). No-data days are skipped by the caller (only feed days with known samples).
- **Completed day** = any calendar day strictly before `calendar.startOfDay(for: now)` that has data and is after `lastFinalizedDay`.
- **Token rule (free):** capacity 1. At the first completed day whose ISO `weekOfYear`+`yearForWeekOfYear` differs from `lastRefillWeek`, set `tokens = max(tokens, capacity)` and update `lastRefillWeek`. A bad day spends a token to freeze (streak preserved); with no token the streak resets to 0.
- **Week key** = `yearForWeekOfYear * 100 + weekOfYear` (refill only triggers on change, so year rollover is fine).
- **Provisional today** is NOT finalized (it can still go bad before midnight); the UI adds +1 only for display.

---

### Task 1: Pure `StreakProgress` + `StreakLedgerEngine.advance`

**Files:**
- Create: `packages/VoltsyKit/Sources/BatteryEngines/StreakLedger.swift`
- Test: `packages/VoltsyKit/Tests/BatteryEnginesTests/StreakLedgerEngineTests.swift`

- [ ] **Step 1: Write failing tests**

```swift
import Testing
import Foundation
@testable import BatteryEngines

private let utc: Calendar = {
    var c = Calendar(identifier: .gregorian); c.timeZone = TimeZone(identifier: "UTC")!; return c
}()
private func day(_ y: Int, _ m: Int, _ d: Int) -> Date {
    utc.date(from: DateComponents(year: y, month: m, day: d))!
}

@Suite struct StreakLedgerEngineTests {
    @Test func healthyDaysExtendStreakAndSpendNoTokens() {
        let start = StreakProgress(currentStreak: 0, longestStreak: 0, tokens: 1,
                                   lastRefillWeek: 0, lastFinalizedDay: nil, lastDayFrozen: false)
        let days = [(day: day(2026, 6, 1), healthy: true), (day: day(2026, 6, 2), healthy: true)]
        let out = StreakLedgerEngine.advance(start, completedDays: days, capacity: 1, calendar: utc)
        #expect(out.currentStreak == 2)
        #expect(out.longestStreak == 2)
        #expect(out.tokens == 1)            // weekly refill kept it at capacity, none spent
        #expect(out.lastFinalizedDay == day(2026, 6, 2))
    }

    @Test func badDayWithTokenFreezesAndSpends() {
        let start = StreakProgress(currentStreak: 3, longestStreak: 5, tokens: 1,
                                   lastRefillWeek: 999999, lastFinalizedDay: day(2026, 6, 1),
                                   lastDayFrozen: false)
        let out = StreakLedgerEngine.advance(start, completedDays: [(day(2026, 6, 2), false)],
                                             capacity: 1, calendar: utc)
        #expect(out.currentStreak == 3)     // preserved
        #expect(out.tokens == 0)            // spent
        #expect(out.lastDayFrozen == true)
    }

    @Test func badDayWithoutTokenResets() {
        let start = StreakProgress(currentStreak: 4, longestStreak: 4, tokens: 0,
                                   lastRefillWeek: 999999, lastFinalizedDay: day(2026, 6, 1),
                                   lastDayFrozen: false)
        let out = StreakLedgerEngine.advance(start, completedDays: [(day(2026, 6, 2), false)],
                                             capacity: 1, calendar: utc)
        #expect(out.currentStreak == 0)
        #expect(out.tokens == 0)
        #expect(out.lastDayFrozen == false)
    }

    @Test func newWeekRefillsTokenToCapacity() {
        let wk23 = utc.component(.weekOfYear, from: day(2026, 6, 1))
        let start = StreakProgress(currentStreak: 1, longestStreak: 1, tokens: 0,
                                   lastRefillWeek: 2026 * 100 + wk23,
                                   lastFinalizedDay: day(2026, 6, 1), lastDayFrozen: false)
        let out = StreakLedgerEngine.advance(start, completedDays: [(day(2026, 6, 8), false)],
                                             capacity: 1, calendar: utc)
        #expect(out.tokens == 0)            // refilled to 1, then spent
        #expect(out.currentStreak == 1)     // frozen, preserved
        #expect(out.lastDayFrozen == true)
    }

    @Test func emptyCompletedDaysIsIdentity() {
        let start = StreakProgress(currentStreak: 7, longestStreak: 9, tokens: 1,
                                   lastRefillWeek: 1, lastFinalizedDay: day(2026, 6, 1),
                                   lastDayFrozen: false)
        let out = StreakLedgerEngine.advance(start, completedDays: [], capacity: 1, calendar: utc)
        #expect(out == start)
    }
}
```

- [ ] **Step 2: Run tests, verify they fail** — `swift test --package-path packages/VoltsyKit` → FAIL (no `StreakLedgerEngine`).

- [ ] **Step 3: Implement**

```swift
// Sources/BatteryEngines/StreakLedger.swift
import Foundation

public struct StreakProgress: Sendable, Equatable {
    public var currentStreak: Int
    public var longestStreak: Int
    public var tokens: Int
    public var lastRefillWeek: Int          // yearForWeekOfYear*100 + weekOfYear; 0 = never refilled
    public var lastFinalizedDay: Date?
    public var lastDayFrozen: Bool

    public init(currentStreak: Int, longestStreak: Int, tokens: Int,
                lastRefillWeek: Int, lastFinalizedDay: Date?, lastDayFrozen: Bool) {
        self.currentStreak = currentStreak; self.longestStreak = longestStreak
        self.tokens = tokens; self.lastRefillWeek = lastRefillWeek
        self.lastFinalizedDay = lastFinalizedDay; self.lastDayFrozen = lastDayFrozen
    }
}

public enum StreakLedgerEngine {
    /// Fold completed days (oldest first, strictly before today, with data) into the ledger.
    public static func advance(_ start: StreakProgress,
                               completedDays: [(day: Date, healthy: Bool)],
                               capacity: Int, calendar: Calendar) -> StreakProgress {
        var p = start
        for entry in completedDays {
            let wk = calendar.component(.weekOfYear, from: entry.day)
            let yr = calendar.component(.yearForWeekOfYear, from: entry.day)
            let key = yr * 100 + wk
            if key != p.lastRefillWeek {            // new ISO week -> refill to capacity
                p.tokens = max(p.tokens, capacity)
                p.lastRefillWeek = key
            }
            if entry.healthy {
                p.currentStreak += 1
                p.lastDayFrozen = false
            } else if p.tokens > 0 {
                p.tokens -= 1
                p.lastDayFrozen = true            // streak preserved
            } else {
                p.currentStreak = 0
                p.lastDayFrozen = false
            }
            p.longestStreak = max(p.longestStreak, p.currentStreak)
            p.lastFinalizedDay = entry.day
        }
        return p
    }
}
```

- [ ] **Step 4: Run tests, verify they pass.**
- [ ] **Step 5: Commit** — `git add -A && git commit -m "feat(engines): persistable StreakLedgerEngine.advance (TDD)"`

---

### Task 2: Persist `StreakProgress` in `BatteryStore`

**Files:**
- Modify: `packages/VoltsyKit/Sources/BatteryStore/BatteryStore.swift`
- Test: `packages/VoltsyKit/Tests/BatteryStoreTests/StreakProgressStoreTests.swift`

- [ ] **Step 1: Write failing test** (in-memory store round-trip)

```swift
import Testing
import Foundation
import SwiftData
import BatteryEngines
@testable import BatteryStore

@Suite @MainActor struct StreakProgressStoreTests {
    private func memStore() throws -> BatteryStore {
        let cfg = ModelConfiguration(isStoredInMemoryOnly: true)
        let c = try ModelContainer(for: BatterySampleRecord.self, StreakProgressRecord.self,
                                   configurations: cfg)
        return BatteryStore(container: c)
    }
    @Test func defaultsThenRoundTrips() throws {
        let s = try memStore()
        #expect(s.loadStreakProgress().currentStreak == 0)   // sensible default
        var p = s.loadStreakProgress()
        p.currentStreak = 5; p.tokens = 0; p.lastRefillWeek = 42
        try s.saveStreakProgress(p)
        #expect(s.loadStreakProgress().currentStreak == 5)
        #expect(s.loadStreakProgress().tokens == 0)
        #expect(s.loadStreakProgress().lastRefillWeek == 42)
    }
}
```

- [ ] **Step 2: Run, verify fail** (no `StreakProgressRecord` / methods).

- [ ] **Step 3: Implement** — add to `BatteryStore.swift`:

```swift
@Model
final class StreakProgressRecord {
    var currentStreak: Int
    var longestStreak: Int
    var tokens: Int
    var lastRefillWeek: Int
    var lastFinalizedDay: Date?
    var lastDayFrozen: Bool
    init(currentStreak: Int = 0, longestStreak: Int = 0, tokens: Int = 1,
         lastRefillWeek: Int = 0, lastFinalizedDay: Date? = nil, lastDayFrozen: Bool = false) {
        self.currentStreak = currentStreak; self.longestStreak = longestStreak
        self.tokens = tokens; self.lastRefillWeek = lastRefillWeek
        self.lastFinalizedDay = lastFinalizedDay; self.lastDayFrozen = lastDayFrozen
    }
}
```

Register `StreakProgressRecord.self` in EVERY `ModelContainer(for:)` call in `shared()`, `local()`, `inMemoryFallback()` — introduce `static let schemaTypes: [any PersistentModel.Type] = [BatterySampleRecord.self, StreakProgressRecord.self]` and pass `for: schemaTypes` everywhere. Add:

```swift
import BatteryEngines  // for StreakProgress (see dependency NOTE below)

extension BatteryStore {
    func loadStreakProgress() -> StreakProgress {
        let rec = (try? container.mainContext.fetch(FetchDescriptor<StreakProgressRecord>()))?.first
        guard let r = rec else {
            return StreakProgress(currentStreak: 0, longestStreak: 0, tokens: 1,
                                  lastRefillWeek: 0, lastFinalizedDay: nil, lastDayFrozen: false)
        }
        return StreakProgress(currentStreak: r.currentStreak, longestStreak: r.longestStreak,
                              tokens: r.tokens, lastRefillWeek: r.lastRefillWeek,
                              lastFinalizedDay: r.lastFinalizedDay, lastDayFrozen: r.lastDayFrozen)
    }
    func saveStreakProgress(_ p: StreakProgress) throws {
        let ctx = container.mainContext
        let rec = (try? ctx.fetch(FetchDescriptor<StreakProgressRecord>()))?.first ?? {
            let r = StreakProgressRecord(); ctx.insert(r); return r
        }()
        rec.currentStreak = p.currentStreak; rec.longestStreak = p.longestStreak
        rec.tokens = p.tokens; rec.lastRefillWeek = p.lastRefillWeek
        rec.lastFinalizedDay = p.lastFinalizedDay; rec.lastDayFrozen = p.lastDayFrozen
        try ctx.save()
    }
}
```

> DEPENDENCY NOTE: `BatteryStore` must `import BatteryEngines` for `StreakProgress`. Check `packages/VoltsyKit/Package.swift`: if the `BatteryStore` target does not already depend on `BatteryEngines`, EITHER add that dependency (if it does not create a cycle) OR move `StreakProgress` into `VoltsyCore` (already imported by `BatteryStore`) and `import VoltsyCore` from `BatteryEngines`. Prefer placing `StreakProgress` in `VoltsyCore` to keep the graph acyclic. Update Task 1's `import`/file location accordingly if you choose `VoltsyCore`.

- [ ] **Step 4: Run tests, verify pass** (existing 30 + new still green).
- [ ] **Step 5: Commit** — `feat(store): persist StreakProgress singleton (TDD)`

---

### Task 3: Wire finalize-on-ingest into `HomeViewModel`

**Files:**
- Modify: `apps/Voltsy/Sources/Home/HomeViewModel.swift`

- [ ] **Step 1: Replace the streak computation** in `ingest(_:)`. After computing `recent`:

```swift
// Finalize all completed days (strictly before today, with data) into the persisted ledger.
let cal = Calendar.current
let today = cal.startOfDay(for: Date())
var progress = store.loadStreakProgress()
let lastFinal = progress.lastFinalizedDay
let byDay = Dictionary(grouping: recent.filter { $0.isLevelKnown }) { cal.startOfDay(for: $0.timestamp) }
let completed = byDay.keys
    .filter { $0 < today && (lastFinal == nil || $0 > lastFinal!) }
    .sorted()
    .map { (day: $0, healthy: DayHealthEvaluator.evaluate(daySamples: byDay[$0]!).isHealthy) }
progress = StreakLedgerEngine.advance(progress, completedDays: completed, capacity: 1, calendar: cal)
try? store.saveStreakProgress(progress)

// Display: finalized streak + provisional +1 if today is already healthy.
let todaySamples = (byDay[today] ?? [])
let todayHealthy = !todaySamples.isEmpty && DayHealthEvaluator.evaluate(daySamples: todaySamples).isHealthy
let displayCurrent = progress.currentStreak + (todayHealthy ? 1 : 0)
streak = StreakState(current: displayCurrent,
                     longest: max(progress.longestStreak, displayCurrent),
                     tokensRemaining: progress.tokens,
                     frozeMostRecentDay: progress.lastDayFrozen)
```

Remove the old `StreakAssembler.dayOutcomes` + `StreakEngine.compute(..., freezeTokens: 1)` lines from `ingest`.

- [ ] **Step 2: Build for sim** — `xcodegen generate && xcodebuild -project Voltsy.xcodeproj -scheme Voltsy -configuration Debug -sdk iphonesimulator -destination 'id=<UDID>' -derivedDataPath build/dd build` → BUILD SUCCEEDED.
- [ ] **Step 3: Verify** — install + launch on sim, screenshot: Home still renders, streak hint shows honestly (0 with no real day data). On device the streak now persists across launches.
- [ ] **Step 4: Commit** — `feat(home): persist streak via ledger instead of recompute`

---

## Self-Review
- Spec §192 (streak +1/healthy day): Task 1 healthy path. §193 (one free Power Nap, freeze): Task 1 token spend + capacity 1. Weekly refill: `newWeekRefillsTokenToCapacity`. Persistence beyond 30-day window: Task 2. Honest 0 with no data: provisional-today only adds when today healthy. ✓
- Types consistent: `StreakProgress` fields identical across Tasks 1–3; `StreakLedgerEngine.advance` signature identical. ✓
- Dependency caveat called out in Task 2 (place `StreakProgress` to keep the graph acyclic). ✓
