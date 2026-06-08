# Voltsy ⚡️

**Voltsy: Battery Life Buddy** — an iOS battery-care companion built around **Volt**, a
cute battery mascot whose mood and translucent belly react live to your battery. A daily
care-loop (streak + care score) nudges healthy charging habits.

Honest by design: Voltsy shows **on-device estimates from your own usage** — it never
claims to read Apple's real battery-health %, cycle count, or capacity (those aren't
available to third-party apps). Free + AdMob, €4.99 lifetime Pro.

## Layout (monorepo)
- `packages/VoltsyKit` — pure, host-testable logic (`VoltsyCore`, `BatteryEngines`, `BatteryStore`)
- `apps/Voltsy` — the iOS app (battery sensing + SwiftUI, incl. the parametric `Volt` mascot)
- `docs/superpowers/` — specs + plans

## Develop
- Logic tests: `swift test --package-path packages/VoltsyKit`
- Generate the Xcode project: `xcodegen generate` (`Voltsy.xcodeproj` is git-ignored)
- Build (sim): `xcodebuild -project Voltsy.xcodeproj -scheme Voltsy -destination 'generic/platform=iOS Simulator' build`

> Battery APIs return no real data on the simulator (level is always `-1`) — verify
> sensing and Volt's moods on a physical device.

## Status
Plans 1–3 built (engines, mascot, daily care streak); 30 logic tests green. First build
live on internal TestFlight (iPhone-only; App Group + Widget deferred to a later milestone).

## Tech
SwiftUI · SwiftData · iOS 26 · XcodeGen · Swift Testing
