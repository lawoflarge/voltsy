# Voltsy Monetization (Pro + AdMob) & App Store Submission Prep — Plan

> Autonomous overnight execution. REQUIRED SUB-SKILL: superpowers:test-driven-development for pure logic. UI verified by simulator screenshot; the live charging/consent/ATT flows are device-verified by Levin.

**Goal:** Bring Voltsy to a submit-ready v1: €4.99 lifetime Pro (StoreKit 2) with paywall + restore + entitlement gating, AdMob (banner + UMP consent + ATT pre-prompt) for the free tier, App Store screenshots + ASO metadata, and everything stageable in App Store Connect via the `asc` API. Ship Build 6 to TestFlight.

**Hard blockers requiring Levin (queued for morning, NOT attempted):**
1. Real AdMob app + ad-unit IDs (his Google/AdMob account) → integrate with Google's public TEST IDs, config-swappable.
2. Final "Submit for Review" — not pressed with test ad IDs (= guaranteed rejection). Everything else staged.
3. App Privacy "nutrition labels" if the API can't fully set the ad-SDK data-collection declaration.

**Architecture:**
- New SPM product `Monetization` in VoltsyKit: pure `AdGate` (TDD) + `ProStore` (StoreKit 2, @MainActor @Observable) exposing `isPro`.
- `Ads` lives in the app target (UIKit/GoogleMobileAds can't sit in the cross-platform package): `ConsentManager` (UMP + ATT), `AdBanner` (UIViewRepresentable), gated by `ProStore.isPro` + consent.
- Free tier shows a banner ONLY on a secondary "Insights"/recap surface, never on the mascot home (spec §10).
- `Voltsy.storekit` local config wired into the scheme for sim purchase testing.

**Tech:** StoreKit 2, GoogleMobileAds SPM (UserMessagingPlatform bundled), AppTrackingTransparency, SwiftUI, Swift Testing, XcodeGen, asc CLI.

---

## Phase P1 — Pro / StoreKit 2

### Task P1.1: `AdGate` pure engine (TDD)
- Create `packages/VoltsyKit/Sources/Monetization/AdGate.swift`, test `packages/VoltsyKit/Tests/MonetizationTests/AdGateTests.swift`.
- Rule: `shouldShowAds(isPro:, hasConsent:, completedSessions:, graceSessions:) -> Bool` → `false` if isPro; `false` if !hasConsent; `false` while `completedSessions < graceSessions` (ad-light grace); else `true`.
- Tests: pro→false; no-consent→false; within grace→false; eligible→true.

### Task P1.2: `ProStore` (StoreKit 2)
- Create `packages/VoltsyKit/Sources/Monetization/ProStore.swift`: product id `com.lawoflarge.voltsy.pro`; `@MainActor @Observable final class`; `loadProduct()`, `purchase()`, `restore()`, transaction listener; `isPro` derived from `Transaction.currentEntitlements`. No persistence (StoreKit is source of truth).
- Add `Monetization` library to `Package.swift` (depends on nothing else; pure + StoreKit which is platform framework).

### Task P1.3: `.storekit` config + scheme
- Create `Voltsy.storekit` with one non-consumable `com.lawoflarge.voltsy.pro`, $4.99.
- Add explicit `schemes:` block in project.yml wiring `run.storeKitConfiguration: Voltsy.storekit`.

### Task P1.4: Paywall + entitlement gating
- Create `apps/Voltsy/Sources/Paywall/PaywallView.swift`: value-first copy ("Pay once, keep Volt happy forever, never see an ad again"), price from product, Buy + prominent Restore, honest fine print.
- Wire `ProStore` into `VoltsyApp` env; add a "Go Pro" entry on Home; gate (Pro hides ads).
- Build + sim screenshot of the paywall.

---

## Phase P2 — AdMob + consent + ATT (test IDs)

### Task P2.1: SDK + Info.plist
- Add `https://github.com/googleads/swift-package-manager-google-mobile-ads` to project.yml packages; depend `GoogleMobileAds` in the Voltsy target.
- Info.plist: `GADApplicationIdentifier` = TEST `ca-app-pub-3940256099942544~1458002511`; `NSUserTrackingUsageDescription`; `SKAdNetworkItems` (Google's set).

### Task P2.2: ConsentManager (UMP + ATT)
- Create `apps/Voltsy/Sources/Ads/ConsentManager.swift`: request UMP consent info, present form if required, then ATT pre-prompt → `ATTrackingManager.requestTrackingAuthorization`, then `MobileAds.shared.start`.

### Task P2.3: Banner + gating
- Create `apps/Voltsy/Sources/Ads/AdBanner.swift` (UIViewRepresentable, adaptive anchored banner, TEST unit `ca-app-pub-3940256099942544/2934735716`).
- Show banner on a secondary surface only (e.g. the weekly recap sheet footer), gated by `AdGate.shouldShowAds(...)` with `ProStore.isPro` + consent.
- Build + sim screenshot (test banner renders).

---

## Phase P3 — Screenshots + ASO + privacy

### Task P3.1: App Store screenshots (5, mascot-forward)
- Capture via sim (6.9" iPhone 17 Pro Max): Home (Volt + ring), data/care view, charging Live Activity (gallery), streak/achievements, mood grid. Save to `marketing/screenshots/`.

### Task P3.2: ASO metadata files
- `marketing/aso/` : title ("Voltsy: Battery Care Buddy", ≤30), subtitle, keywords (100 chars, no dup), description, promo text, release notes. Honest-copy guardrail (no "real health %").

### Task P3.3: Privacy policy
- `marketing/privacy/privacy.md` (+ simple HTML) — data: AdMob ad identifiers (free tier), no account, on-device storage. Note hosting (Vercel) as a morning step if no host exists.

---

## Phase P4 — Ship Build 6 + stage ASC

### Task P4.1: Build 6
- Bump `CURRENT_PROJECT_VERSION` to 6, xcodegen, archive (Release, manual, both targets), export, altool upload, `asc builds wait` + add to Internal group.

### Task P4.2: Create Pro IAP via asc
- `asc iap setup --app 6778094814 --type NON_CONSUMABLE --reference-name "Voltsy Pro" --product-id com.lawoflarge.voltsy.pro --locale en-US --display-name "Voltsy Pro" --price 4.99 --base-territory "United States"`.
- Add review screenshot (`asc iap review-screenshots`/`images`), localized description.

### Task P4.3: Push metadata + screenshots via asc
- `asc apps metadata` (pull → edit canonical → apply) for title/subtitle/keywords/description/release notes; `asc apps screenshots upload`.

---

## Phase P5 — Morning checklist (document)
Write `marketing/SUBMISSION-CHECKLIST.md`: real AdMob app+units+app-ads.txt+store-link+UMP message; swap test→real ad IDs (one config file); confirm App Privacy labels; final app-version submit (`asc`); IAP bundled.
