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
