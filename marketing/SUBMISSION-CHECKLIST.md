# Voltsy v1.0 — App Store Submission Checklist

Status after the autonomous overnight run of 2026-06-08. Everything below the line is DONE; the
"YOUR MORNING STEPS" section needs your logins and ~30–45 min, then Voltsy can be submitted.

## DONE autonomously (in code + on TestFlight + in App Store Connect)
- ✅ **Pro (€4.99 lifetime, StoreKit 2)**: paywall, purchase, Restore, entitlement gating; `isPro` removes ads. Local `.storekit` config wired to the scheme for sim testing.
- ✅ **Pro IAP created in App Store Connect** via API: `com.lawoflarge.voltsy.pro`, NON_CONSUMABLE, $4.99 (≈€4.99), display name "Voltsy Pro", description + **review screenshot uploaded**, price schedule verified. (iapId 6778176009)
- ✅ **AdMob integrated**: GoogleMobileAds 13.x + UserMessagingPlatform 3.x (SPM), banner on the weekly-recap surface only, UMP consent → ATT → MobileAds.start, gated by `AdGate` (Pro + consent + 3-session grace). Verified: app launches with the SDK and the UMP consent form presents.
- ✅ **Info.plist**: `GADApplicationIdentifier` (TEST), `NSUserTrackingUsageDescription`, `SKAdNetworkItems` (Google primary).
- ✅ **App Store metadata (en-US)** pushed via API: description, keywords, promotional text.
- ✅ **Build 6** (Pro + AdMob) uploaded, processed VALID, in the **Internal** TestFlight group.
- ✅ Draft App Store screenshots in `marketing/screenshots/` (mood gallery, Live Activity, paywall).
- ✅ ASO copy in `marketing/aso/en-US.md`; privacy policy text in `marketing/privacy/privacy.md`.

---

## YOUR MORNING STEPS (need your Google / Apple logins)

### 1. Real AdMob IDs (your Google/AdMob account) — REQUIRED before submission
Test ad IDs in a production submission = guaranteed rejection.
- [ ] In the AdMob console: create (or reuse) an **iOS app** for Voltsy, link it to the App Store listing (App Store ID 6778094814).
- [ ] Create a **banner** ad unit (and optionally interstitial/app-open/rewarded for later).
- [ ] Swap the two TEST IDs for the real ones:
  - `apps/Voltsy/Resources/Info.plist` → `GADApplicationIdentifier` (real `ca-app-pub-…~…` app ID)
  - `apps/Voltsy/Sources/Ads/AdConfig.swift` → `bannerUnitID` (real `ca-app-pub-…/…`)
- [ ] Deploy **app-ads.txt** on the support/marketing domain (line: `google.com, pub-XXXX, DIRECT, f08c47fec0942fa0`) and link the AdMob app to the store listing (mirrors the NetGuard/PulseCheck fill fix).
- [ ] **Publish a UMP/GDPR consent message** in AdMob (EEA) and an ATT message — otherwise the EEA form won't serve.

### 2. Support + Privacy URLs (need hosting) — REQUIRED
ASC warns en-US is missing `supportUrl`.
- [ ] Host `marketing/privacy/privacy.md` as a web page (Vercel or GitHub Pages — Voltsy has no site yet).
- [ ] Set **Support URL** and **Privacy Policy URL** in App Store Connect (or `asc apps info edit --support-url …` for support; privacy URL is in App Privacy).

### 3. App Store listing fields not settable via the API used
- [ ] **Subtitle**: "Cute battery care & widget" (app-level; set in ASC UI).
- [ ] **App Privacy nutrition labels**: declare AdMob data use — Identifiers + Usage Data used for Third-Party Advertising & Measurement (linked to identity only if ATT-allowed); battery data stays on-device. Pro = no ads.
- [ ] **Age rating** questionnaire (expected 4+).
- [ ] **Polished screenshots**: replace the drafts in `marketing/screenshots/` with a framed 6.9" set (5 frames, Volt in every frame) + optional app-preview video; upload via `asc apps screenshots upload` or the UI.

### 4. Device verification (real iPhone, TestFlight Build 6)
- [ ] Charging **Live Activity** (Build 5/6): plug in → Lock Screen + Dynamic Island show Volt + %, fill, ETA; ends on unplug.
- [ ] **Paywall purchase + Restore** in sandbox: buy Pro → ads disappear; delete & reinstall → Restore re-grants Pro.
- [ ] **Ads**: as a free user past the 3-session grace, the banner shows on the weekly recap; Pro hides it.

### 5. Submit
- [ ] With real ad IDs in a new build (Build 7), screenshots, support/privacy URLs, App Privacy, and age rating set → submit the app version **with the Pro IAP bundled** (first release must include the IAP) via `asc` or the ASC UI.

## Reusable facts
- App: "Voltsy: Battery Life Buddy", App Store ID **6778094814**, bundle `com.lawoflarge.voltsy`, team R95M36AU2X.
- IAP: `com.lawoflarge.voltsy.pro` (iapId 6778176009), $4.99 non-consumable, review screenshot uploaded.
- Build pipeline: `xcodegen generate` → archive Release (manual, both targets) → export with `build/ExportOptions.plist` → `altool --apiKey REDACTED_ASC_KEY_ID --apiIssuer REDACTED_ASC_ISSUER_ID` → `asc builds wait` + `asc builds add-groups --group 34067b3b-3cb4-40e7-b4f2-6d02b2f74843`. Bump `CURRENT_PROJECT_VERSION` each build.
- Test ad IDs currently in use: app `ca-app-pub-3940256099942544~1458002511`, banner `ca-app-pub-3940256099942544/2934735716`.
