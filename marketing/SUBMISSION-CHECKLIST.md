# Voltsy v1.0 — ✅ APPROVED + LIVE 2026-06-13 (Build 8)

**Status: v1.0 (Build 8) + Pro IAP APPROVED 2026-06-13 — READY_FOR_DISTRIBUTION, on-sale check passed (`/v1/apps/6778094814/appAvailabilityV2` OK). Build 7 had been REJECTED 2026-06-12 (Guideline 2.1 — ATT prompt not appearing on iPadOS 26.5); build 8 fixed it.**

## Build 8 — ATT fix (2026-06-12)
- Root cause: ATT was requested via Home.onAppear → UMP callback during launch (scene not yet foreground-active) and could collide with the notification permission alert fired from `HomeViewModel.init` — iOS silently drops the ATT prompt in both cases (same as RateRadar Guideline 2.1 rejection 50741e54).
- Fix: launch prompts strictly sequenced from first `scenePhase == .active` +600ms: **ATT (awaited) → notifications (awaited) → UMP consent → MobileAds.start**. UMP runs LAST because `loadAndPresentIfRequired` can stall while no consent message is published for Voltsy (EU sim reproduced the hang).
- Verified on iPad Air 11-inch simulator (fresh install): ATT prompt appears first, then notifications, app continues normally.
- Review notes updated + screen recording `Voltsy-ATT-demo-build8.mp4` attached to App Review Information (attachment `00483809`).

## Done
- ✅ **Website (monorepo)**: `web/` → **voltsy.vercel.app** (Vercel project `voltsy`, Root Directory `web`, git-connected → push auto-deploys). `/privacy.html`, `/support.html`, `/app-ads.txt` all live & public.
- ✅ **AdMob**: iOS app "Voltsy" + "Voltsy Banner" unit created (publisher `pub-6563643868702361`).
  - App ID: `ca-app-pub-6563643868702361~4806029723` (Info.plist `GADApplicationIdentifier`)
  - Banner unit: `ca-app-pub-6563643868702361/7240621379` (`AdConfig.bannerUnitID`)
- ✅ **app-ads.txt** deployed: `google.com, pub-6563643868702361, DIRECT, f08c47fec0942fa0`
- ✅ **ASC metadata** (via `asc` API): support/marketing/privacy URLs, subtitle "Cute battery care & widget", copyright, categories Utilities/Lifestyle, **age rating 4+**, **free** pricing, availability **175 territories**, review contact, **3 screenshots** (6.9").
- ✅ **App Privacy** published: Device ID + Product Interaction (Third-Party Advertising & Analytics, tracking); battery data on-device, not declared.
- ✅ **Pro IAP** `com.lawoflarge.voltsy.pro` ($4.99 non-consumable): localization + review screenshot + price + **availability (175 territories)** → READY_TO_SUBMIT → bundled with v1.0 via the version's "Select In-App Purchases".
- ✅ **Build 7** (real AdMob IDs) built locally, uploaded, VALID, attached to v1.0.
- ✅ **Submitted** to App Review (review submission `528ae9f3`).

## Post-launch (NOT blocking review)
- [ ] Once Voltsy is live: link the AdMob app to the App Store listing + publish/extend the EU UMP/GDPR consent message + ATT message to Voltsy (mirrors NetGuard) → EEA ad fill.
- [ ] Device test (Live Activity while charging, Pro purchase + Restore in sandbox, banner after 3-session grace).

## Reusable facts
- App: "Voltsy: Battery Life Buddy", App Store ID **6778094814**, bundle `com.lawoflarge.voltsy`, team R95M36AU2X.
- IAP: `com.lawoflarge.voltsy.pro` (iapId 6778176009).
- AdMob console app id 4806029723; publisher pub-6563643868702361.
- Build pipeline: `xcodegen generate` → archive Release (manual, both targets) → export `build/ExportOptions.plist` → `altool --apiKey $ASC_KEY_ID --apiIssuer $ASC_ISSUER_ID Bump `CURRENT_PROJECT_VERSION` per build.
