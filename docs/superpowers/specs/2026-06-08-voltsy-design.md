# Voltsy — Design Spec

**Date:** 2026-06-08
**Status:** Draft for review
**Author:** Levin (with Claude Code)
**Repo:** `~/Data/Claude/voltsy` (monorepo, git, SwiftUI, iOS 26)

---

## 1. One-liner

> **Voltsy** is an iOS battery-care companion whose mascot **Volt** — a cute battery with arms and legs — reacts live to your phone's battery state and coaches you into healthy charging habits through a daily care loop. Free with AdMob ads; a €4.99 / $4.99 one-time **lifetime** Pro unlock removes all ads and adds history, advanced insights, and cosmetics.

**Tagline:** *"The battery app you'll actually want to open."*

---

## 2. Why this exists (market context)

The iOS battery category is **saturated and partly sherlocked**: Apple's built-in Battery Health screen (cycle count + max capacity, free, iPhone 15+/iOS 17.4+) already shows the raw numbers, and every paid competitor positions identically — clinical, dark/blue, "Pro / Doctor / Diagnostics", a wall of stats. On raw data a third-party app can only **tie Apple and lose to free rivals**, because iOS blocks the API access that would let it read the real numbers (verified — see §11).

The opening is the homogeneity itself. Market research (multi-agent, adversarially verified, 2026-06-08) found:

- **No charm / no character.** Not one serious diagnostic app has a mascot or a daily-care loop (verified). Cute characters exist only in decorative charging-widget apps with zero diagnostics.
- **No retention loop.** Competitors are open-once-and-forget utilities.
- **Data credibility is universally distrusted.** Reviews call health numbers "fake", "a guess"; they fluctuate hour-to-hour and disagree with Settings. No competitor explains its methodology.
- **Subscription resentment is rampant.** Users explicitly demand one-time pricing; sub-funnel entrants draw 1-star reviews.
- **Ads that persist after paying** are a top grievance.
- **No charming widget / Live Activity surface**, and **no organic distribution** (data apps don't get shared).

**Strategy: lead with the character, not the data.** Reframe the job from "show me battery numbers" (commodity, sherlocked) to "a little buddy who looks after my phone's battery" (emotional, ownable, shareable). Win trust where rivals lose it by being **radically honest that all health output is an on-device estimate** — which also keeps us App-Review-safe.

The moat is **not the mascot alone** (copyable). It is: **mascot + daily care loop (streak) + consistent beloved brand voice + cosmetic attachment + organic TikTok/Lemon8 shareability.** Apple can sherlock a metric, not a character and a habit.

---

## 3. Product principles

1. **Honest estimate, never a false measurement.** We never claim to show "real battery health %" or "real cycle count." Every health/score figure is labeled an on-device estimate, gated behind data sufficiency, with a one-tap methodology explainer and a helper that teaches the user to find Apple's official number in Settings.
2. **Character first, data second.** Volt is the hero of every surface. The data view exists for skeptics, rendered in the cute UI.
3. **Reward good behavior, don't punish absence.** Gamification celebrates good charging habits the user already does; notifications are soft and behavior-rewarding, not guilt-spam — less fatigue, always authentic to the live OS state.
4. **One-time pricing.** €4.99 lifetime unlock. No subscription. Recurring revenue comes from optional cosmetics, never a paywall on basics.
5. **Free tier must feel valuable.** The mascot and the core care score are free; reviews punish paywalling fundamentals.
6. **App-Review-safe by construction.** No IOKit / private symbols, no overclaiming, bulletproof Restore Purchases, true ad removal after unlock.

---

## 4. Scope

**v1 ships the full loop ("voll von Anfang an"):** all emotional states, care score, streak + freeze tokens, achievements, "keep it 20–80%" challenge, multiple cosmetic packs (skins/outfits/seasonal/extra characters), full + deluxe widgets, charging Live Activity, weekly recap share card, Volt-voiced notifications, Free/Pro split, €4.99 lifetime + cosmetic IAPs, AdMob + UMP + ATT.

**Out of scope for v1 (future):** Analytics-log import for the *real* cycle count (BAST-style — explicitly declined for v1: keeps the build lean and friction-free), Apple Watch app/complications, iPad-optimized layout, Android, any backend/cloud sync, paid user acquisition.

---

## 5. Monorepo structure

One repo holds the app, its extensions, the logic as local Swift Package Manager (SPM) modules, docs, scripts, and marketing assets.

```
voltsy/
├── apps/
│   └── Voltsy/                  # iOS app target (Xcode project)
│       ├── Voltsy/             # app sources (composition root, screens, navigation)
│       ├── VoltsyWidgets/      # WidgetKit extension
│       └── VoltsyLiveActivity/ # ActivityKit (charging Live Activity) — may live in app target
├── packages/                    # local SPM packages (no UIKit/SwiftUI in the engine layer)
│   ├── BatterySensing/         # wraps UIDevice / ProcessInfo → BatterySample stream
│   ├── BatteryStore/           # SwiftData models + App Group container access
│   ├── BatteryEngines/         # PURE LOGIC: SessionEngine, CareScoreEngine,
│   │                           #   StreakEngine, VoltStateMapper — fully unit-tested
│   ├── VoltMascot/             # SwiftUI vector mascot rendering + animation + cosmetics
│   ├── Monetization/           # StoreKit 2 / RevenueCat + entitlement gating
│   └── DesignSystem/           # colors, typography, Volt palette, shared components
├── docs/
│   └── superpowers/specs/      # this spec + future specs/plans
├── scripts/                     # local Mac build/upload/screenshot/ASC automation
├── marketing/                   # ASO assets, Volt concept art, screenshots, landing page
└── .github/workflows/           # CI (build + test on PR)
```

- The app's Xcode project depends on the local `packages/*` via SPM. Extensions consume the same packages, so widget/Live Activity render from identical logic + a shared **App Group** store.
- **Open decision for the plan phase:** whether to manage the Xcode project with XcodeGen/Tuist (declarative `.pbxproj`, avoids merge conflicts in a monorepo) or a plain checked-in Xcode project. Default recommendation: keep it simple (plain project) unless conflict pain appears; revisit in planning.
- Build/submission reuses Levin's established **local Mac pipeline** (`xcodebuild archive` + `altool`/`asc`), team `R95M36AU2X`, ASC API key already team-scoped.

---

## 6. Architecture & data flow

```
UIDevice / ProcessInfo
        │
 ┌──────▼──────────┐
 │ BatterySensing   │  enables monitoring, listens to batteryLevel/State,
 └──────┬──────────┘  thermalState, LowPowerMode notifications; TimelineView tick
        │ BatterySample(timestamp, level, state, lowPowerMode, thermalState)
 ┌──────▼──────────┐
 │  BatteryStore    │  SwiftData time-series in the App Group container
 └──────┬──────────┘  (shared by app + widget + Live Activity)
        │
   ┌────┴───────────────┬────────────────────┐
 ┌─▼─────────────┐ ┌────▼──────────┐ ┌────────▼────────┐
 │ SessionEngine  │ │ CareScoreEngine│ │  StreakEngine   │   PURE, TDD
 │ segment charge/│ │ heuristic +    │ │ streak, freeze, │
 │ discharge, %/m,│ │ confidence gate│ │ achievements,   │
 │ %/h, ETA       │ │                │ │ challenges      │
 └─┬─────────────┘ └────┬──────────┘ └────────┬────────┘
   └───────────────┬────┴───────────────────────┘
            ┌───────▼────────┐
            │ VoltStateMapper │  pure: (level,state,thermal,lpm,score) → VoltState enum
            └───────┬────────┘
        ┌───────────┼───────────────┬──────────────┐
   ┌────▼─────┐ ┌───▼────────┐ ┌────▼────────┐ ┌───▼──────────┐
   │ VoltMascot│ │  Widgets   │ │ LiveActivity │ │ Notifications│
   │ (SwiftUI) │ │ (WidgetKit)│ │ (ActivityKit)│ │ Volt voice   │
   └──────────┘ └────────────┘ └─────────────┘ └──────────────┘

  cross-cutting: Monetization (lifetime + cosmetics, entitlement gating)
                 Ads (AdMob + UMP consent + ATT pre-prompt)  — free tier only
```

**Key boundary rule:** `BatteryEngines` and `VoltStateMapper` are **pure** (no UIKit/SwiftUI/IO) → exhaustively unit-tested (TDD). Sensing, store, mascot rendering, widgets, and Live Activities are verified **on physical devices** (the simulator reports no real battery data — verified). The sample log **will have gaps** (background sampling is opportunistic); engines must tolerate gaps.

---

## 7. The honest-data model

### What we CAN show (verified-available signals)
- Approximate charge % (≈5% resolution — present as approximate, never claim exact-to-1%).
- Charging / unplugged / full state; charge-session start/stop/full detection.
- Low Power Mode on/off + its timeline.
- Thermal state (nominal / fair / serious / critical) and cumulative heat exposure over time.
- App-measured charging speed (%/min) and discharge rate (%/h) per logged session.
- Estimated screen-on / standby time remaining from the app's own discharge history.
- Charging history, app-observed charge-session count, time-to-full / time-to-empty.
- A weeks-long trend of effective runtime per full charge (a clearly-labeled wear **proxy**).
- A heuristic **"battery care score"** from allowed proxies — labeled an estimate, never Apple's official health %.
- An **app-accrued cycle counter** (sum of discharged fraction since install) — disclosed as *since-install-only* and divergent from Apple's true lifetime count.
- The device model's published rated cycle life (e.g., 1000 cycles to 80% on iPhone 15+) as static reference.
- A **Settings helper** that teaches the user to find the official cycle count / max capacity in Settings — we explain/link, we do not read it.

### What we CANNOT show (verified-blocked — see §11)
Real cycle count · max capacity / health % · design or full-charge capacity (mAh) · voltage (mV) · current (mA) · power draw · battery temperature in °C · charge level finer than ≈5% · manufacture date / serial / AppleSmartBattery IORegistry fields · anything via IOKit / IOPSCopyPowerSourcesInfo (causes App Review rejection).

### Care-score methodology (the trust feature)
Composite, clearly-labeled score from cumulative **heat exposure**, **full-discharge frequency**, **100%-dwell time**, and **charge-speed degradation**, with `thermalState` and Low Power Mode as covariates so context doesn't fool the trend.
- **Confidence gating:** the score appears only after *N* logged cycles; a confidence indicator grows with data.
- **Always disclosed on-screen:** "On-device estimate derived from your usage — not Apple's measured cycle count or capacity," plus a one-tap methodology explainer.
- The coarse 5% granularity is the central precision limit; the score copy must own it (smooth via trends, never over-promise).

---

## 8. Volt — the mascot

**Concept:** a plump, rounded AA-style battery with stubby arms, mitten hands, and little boot-feet (roundness reads cute). A metal "+" terminal nub on top doubles as a hair-tuft. **Oversized eyes (~40% of the body)** trigger baby-schema affection. The genius detail: a **translucent body whose glowing fill-level *is* the battery percentage** — as charge drops, the glow visibly recedes, so the emotion and the data are the same object. Default vibrant green when healthy; slowly drifts toward amber/red as the long-term **estimated** care score degrades over months.

**Personality:** earnest, upbeat, a little dramatic, deeply loyal — your phone's tiny anxious best friend. Supportive-but-guilt-trippy, never mean. First-person, feeling-first, meme-able copy. Catchphrases: *"Keep me in the green!"*, *"Ahh, not the 100% overnight again…"*, *"Feed me, but not too much."*

### Emotional states (bound to live OS state)
| Battery state | Volt reaction |
|---|---|
| Full 80–100% | energetic & happy, bright green; at exactly 100% subtly overstuffed (teaches 100% isn't the goal) |
| Mid 40–80% (sweet spot) | content & zen, steady green — *"20 to 80, baby."* |
| Low 15–30% | tired & dragging, droopy, amber, yawning |
| Critical 1–10% | dramatic anime swoon, X eyes, red flicker (the shareable hero moment) |
| Charging (rising) | eating/recharging, belly filling in real time (Live Activity hero) |
| Hit 100% | brief confetti; if it *stays* at 100% (overnight) → too-full, queasy *"unplug me soon?"* |
| Overheating (high thermalState) | sweating/melting, flushed — teaches heat = #1 killer |
| Low Power Mode on | meditating/resting — *"Conserving my chi. Namaste."* (frames LPM as self-care) |
| Plugged in, not charging | confused "?" if a real problem; knowing thumbs-up if intentional smart-charging |

### Visual build approach (free, no paid tool)
1. **Lock the look with concept art** generated via the image-generation skill (Gemini Nano Banana — a skill, not a paid subscription): 3–4 cute Volt poses as reference.
2. **Translate to parametric SwiftUI vector** in the `VoltMascot` package: build Volt from `Shape`/`Path`/`Canvas`; the translucent belly fill is data-bound; cosmetics are composable recolor/overlay layers.
3. **Animate with native APIs:** `PhaseAnimator`, `KeyframeAnimator`, `TimelineView` (no third-party runtime).
4. **Keep Volt simple-round:** cuteness comes from big eyes + squash/stretch, not from rendering detail — so it stays charming in code, not geometric-cold.

**Known craft risk:** matching "Duolingo-cute" in pure code is the project's biggest craft risk. Mitigation = the concept-art-first workflow above + iterating the vector against the reference. Widgets and Live Activities cannot run a live state machine → poses are **pre-baked per battery bucket** in the shared store and picked up by WidgetKit.

### Cosmetics system (Pro + IAP revenue)
- **Skins / recolors:** Neon, Pastel, Holographic, Matte-Black "Stealth Volt", Rose Gold, Glitch/Cyberpunk — palette swaps on one vector rig.
- **Outfits / accessories:** hats, glasses, scarves, cape, superhero suit, astronaut helmet — overlay layers that compose with any emotional state (flagship recurring cosmetic).
- **Seasonal theme packs:** Halloween, Winter Holidays, Valentine's, Summer, New Year — time-boxed for FOMO.
- **Extra characters:** Sparky (hyper), Joule (nerdy), Watt (punny) — alternate mascots on the same rig with distinct notification voices.
- **Animated widget packs + premium poses**, and **Home-screen "Look" bundles** (matching alt app icons + Lock Screen widget styles).
- Any "cosmetic crate" must always offer a direct-buy option (avoid loot-box backlash).

---

## 9. Gamification & surfaces

- **Battery-care streak (core loop):** +1 per day the phone stays in healthy bounds (no drain to 0%, no long 100% dwell, no prolonged overheating). Streak flame next to Volt; 7-day = habit-lock milestone (Volt earns a small upgrade); a miss shows a sad/dimmed Volt.
- **"Power Nap" freeze token:** one bad day doesn't reset progress — one free, more via Pro/rewarded ad.
- **"Keep it 20–80%" challenge:** a ring around Volt fills with the share of the day in the green zone; weekly recap "You kept me healthy 86% this week!"
- **Charging-habit coaching:** contextual in-character tips at the teachable moment (each an accurate battery fact, not spam).
- **Achievements/badges:** Goldilocks, Cool Customer, No-Drama, Night Owl Reformed, Centenarian — each unlocks a Volt pose/sticker.
- **Live home-screen widget:** Volt in its current emotional state, belly-fill = battery % (pre-baked poses keyed to buckets).
- **Charging Live Activity (ActivityKit):** Lock Screen + Dynamic Island, Volt eating, belly filling in real time, ETA-to-80% / ETA-to-full — the single most delightful surface.
- **Volt-voiced push notifications** (soft, capped, behavior-rewarding): *"I'm fading… 8% and dropping, got a charger?"*, *"Don't let our 12-day streak fizzle."*
- **Weekly "This week with Volt" recap card**, screenshot-optimized for organic TikTok/Lemon8 reach.

---

## 10. Monetization

### Free vs Pro
- **Free:** Volt + all emotions · approximate charge % + state · care score + estimated health proxy (the headline number, free) · core streak + first cosmetic-light wins · basic widget · basic charging Live Activity · Volt notifications · charging-habit coaching · one free Power Nap token.
- **Pro — €4.99 / $4.99 one-time LIFETIME (non-consumable):** **0 ads forever** (the single most important promise) · full history & analytics · advanced thermal insights · unlimited Power Nap tokens · premium cosmetics starter pack · deluxe animated widgets + premium Live Activity flourishes · matching alternate app icons · reliable customizable alarms.
- **Cosmetics IAP** (the recurring lever on top of the lifetime unlock): seasonal skin packs, extra characters — near-zero marginal cost on the same vector rig.

### Ads (free tier only — conservative, retention-first)
- **Banner:** anchored adaptive, on results/secondary screens only — never on the primary mascot screen, never covering controls, never causing layout shift.
- **Interstitial:** only after a completed action (e.g., finishing a weekly report); never on launch, never back-to-back; frequency-capped (~1 per 3–4 min) via Remote Config.
- **App-open:** only on genuine cold starts; skipped for a new user's first sessions; cached ad discarded after 4h.
- **Rewarded:** opt-in value-for-value ("watch a short ad to unlock a cosmetic for today" / extra Power Nap) — never forced.
- **Ad-light grace period** for early sessions so users feel Volt's value first.
- **Consent:** custom **ATT pre-prompt** shown *after* the user feels value (pushes opt-in to ~50–65% vs ~35% baseline → higher eCPM) + Google **UMP/CMP** for GDPR (EEA/UK). **Pro users see zero ads and zero ATT/consent nags.**

### Paywall
Value-first, one-time. Let the user experience Volt + the free care score + a few streak days, then surface the paywall at attachment moments: tapping a locked cosmetic, opening full history, or hitting the 7-day streak. Single offer headlined emotionally: *"Pay once, keep Volt happy forever, never see an ad again."* Lead with cosmetic/ad-free value over dry diagnostics. **Restore Purchases must be prominent and bulletproof** (the category is full of "paid but still see ads" complaints).

### Realistic expectations (honest)
IAP is the real dollar lever, but **front-loaded, non-recurring**. At ~2–3% lifetime conversion on €4.99 (net ~85% after the 15% Small Business commission): 50k cumulative free users ≈ €4–6k, 100k ≈ €9–13k. Ads net only a few cents/DAU for a niche utility — do **not** chase eCPM with aggressive formats; protecting ratings/retention earns more lifetime impressions. The recurring lever is cosmetics + ASO/TikTok-driven install volume.

---

## 11. Verified technical constraints (iOS 26, 2026 — adversarially verified)

**Available public APIs:**
- `UIDevice.current.batteryLevel` (0.0–1.0; −1.0 unknown; requires `isBatteryMonitoringEnabled = true`; rounded ≈5%, sometimes 1%, **not** app-controllable).
- `UIDevice.current.batteryState` (`.unplugged` / `.charging` / `.full` / `.unknown`).
- `UIDevice.batteryLevelDidChangeNotification` / `batteryStateDidChangeNotification` (foreground-gated, fire on the quantized level).
- `ProcessInfo.isLowPowerModeEnabled` + `NSProcessInfoPowerStateDidChange`.
- `ProcessInfo.thermalState` (`.nominal`/`.fair`/`.serious`/`.critical`) + `NSProcessInfoThermalStateDidChange` — the **only** public thermal signal, an enum, not degrees.
- `BGTaskScheduler` (BGAppRefreshTask ≈30s, opportunistic, system-decided cadence — best-effort gap-filling, never guaranteed/periodic).
- `WidgetKit` TimelineProvider (budgeted refresh; cannot monitor continuously).
- `ActivityKit` Live Activity (updated via ActivityKit/push, **not** a timeline; 4KB cap, ≈8h Dynamic Island / 12h Lock Screen).
- `SwiftUI.TimelineView` (foreground polling/animation cadence); `UNUserNotificationCenter`; StoreKit 2 / RevenueCat; Google UMP; AppTrackingTransparency.

**Blocked (do not attempt — overclaiming misleads users *and* risks rejection):** real cycle count, max capacity / health %, design/full-charge capacity (mAh), voltage, current, power draw, battery temperature (°C), charge level finer than ≈5%, manufacture date / serial / AppleSmartBattery IORegistry, anything via IOKit / IOPSCopyPowerSourcesInfo (macOS-only; private on iOS).

---

## 12. ASO & positioning

- **Name:** character name + a Tier-1 keyword in the 30-char title, e.g. *"Voltsy: Battery Health & Life"*; the subtitle states the cute/companion differentiator. **Avoid the saturated "Pro / Doctor / Diagnostics" lane.**
- **Keyword field (100 chars):** cycle count, charge cycles, battery percentage, battery widget, lock screen battery, charging tips, status, info (no cross-field duplication — Apple dedupes).
- **Icon = the mascot** (one expressive Volt on a bold flat/warm-gradient background; no green-bar/lightning cliché; readable at 1024px).
- **Screenshots:** (1) Volt reacting to your battery, (2) the friendly data view for skeptics, (3) the cute widget / Live Activity, (4) gamified care/streak, (5) the expression/personality grid — Volt in **every** frame; plus a short app-preview video.
- **Honest-copy guardrail:** never claim "real battery health %" or "real cycle count" in the listing — frame as a friendly estimate + Settings helper.

---

## 13. Testing strategy

- **TDD (tests first)** for all pure engines: `SessionEngine`, `CareScoreEngine`, `StreakEngine`, `VoltStateMapper` — including gap-tolerance, confidence gating, and state-boundary mapping.
- **Physical-device verification** for Sensing, Widgets, and Live Activity across iOS versions (simulator has no real battery data; level granularity differs by version).
- **StoreKit test configuration** for purchase + **restore** flows; explicit test that Pro removes **all** ads and survives reinstall/restore.
- **CI:** build + run unit tests on PR (`.github/workflows`).

---

## 14. Risks & mitigations

| Risk | Mitigation |
|---|---|
| **False-advertising / data-ceiling (highest):** claiming "real" health/cycle count misleads + risks rejection | Frame everything as an honest estimate; gate behind data sufficiency; Settings helper; never reference IOKit/IOPS symbols |
| **Mascot is a weak standalone moat** (copyable) | Ship the *whole* loop (mascot + habit + voice + cosmetics + shareability), not just art |
| **Apple sherlock / race-to-the-bottom on data** | Bet rests on emotional/retention value, not data superiority |
| **Coarse 5% granularity** undermines precise %/min math | Own the approximation in copy; smooth via trends; grow confidence with data |
| **Estimated-health accuracy** feels arbitrary → trust collapses | Radical methodology transparency; never brand as Apple's official figure |
| **Background-monitoring limits** (gaps; no continuous/locked monitoring) | Scope honestly; never sell "background monitoring" as Pro; design score to tolerate gaps |
| **Notification fatigue** | Soft, behavior-rewarding cadence with caps + user controls |
| **Monetization ceiling** (front-loaded, few cents/DAU) | Cosmetics for recurring revenue + ASO/TikTok install volume |
| **Ad/ATT execution** (ads after purchase, launch interstitials, missing UMP) | Conservative caps via Remote Config; bulletproof restore + true ad removal; wire ATT pre-prompt + UMP |
| **Pure-SwiftUI cute character craft risk** | Concept-art-first workflow; simple-round design; iterate vector against reference |
| **iOS-update fragility** | Test on physical devices across versions |

---

## 15. Success criteria (v1 acceptance)

- All pure engines have passing unit tests (incl. gap/confidence/boundary cases).
- Volt renders all emotional states from live OS signals on a physical device, with the translucent belly bound to charge %.
- Widget + charging Live Activity render the correct Volt pose from the shared store.
- Free/Pro entitlement gating works; Pro removes **all** ads; Restore Purchases verified across reinstall.
- AdMob + UMP + ATT wired; no ads on the primary mascot screen; Pro sees zero ads/consent nags.
- Care score is shown only past the confidence threshold, always with the estimate disclaimer + methodology explainer + Settings helper.
- No IOKit/private symbols anywhere; store/in-app copy contains no "real battery health %"/"real cycle count" claims.
- ASO assets ready: mascot-as-icon, 5 character-forward screenshots, app-preview video, title/subtitle/keywords.

---

## 16. Open questions for the plan phase

1. Xcode project management in the monorepo: plain checked-in project vs XcodeGen/Tuist?
2. StoreKit 2 directly vs RevenueCat (RevenueCat eases cosmetics catalog + restore, but adds a dependency for a no-backend app).
3. Final app name lock (`Voltsy` working title) + bundle ID under team `R95M36AU2X`.
4. Concept-art direction round for Volt before vector implementation (recommended first implementation step).
