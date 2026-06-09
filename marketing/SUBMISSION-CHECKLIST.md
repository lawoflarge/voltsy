# Voltsy v1.0 — App Store Submission ✅ SUBMITTED 2026-06-09

**Status: Version 1.0 (Build 7) + Pro IAP both WAITING_FOR_REVIEW.** Only Apple's review is pending.

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
- Build pipeline: `xcodegen generate` → archive Release (manual, both targets) → export `build/ExportOptions.plist` → `altool --apiKey REDACTED_ASC_KEY_ID --apiIssuer 538cb0d4-…`. Bump `CURRENT_PROJECT_VERSION` per build.
