// Voltsy App Store "Glow-Up" — Stage A: native simctl screen capture.
//
// Regenerates the Xcode project (xcodegen, so new screenshot files are included),
// builds the real SwiftUI app (Debug) for the dedicated iPhone 17 Pro Max sim,
// forces light appearance + clean 9:41 status bar, then launches it per-frame with
// `--capture-screen <id>` (handled by ScreenshotHost) and screenshots each target
// screen into ./screens/ at 1320x2868.
//
// These captures are committed, so build.mjs skips this by default.
//   node capture.mjs

import { execFileSync } from "node:child_process";
import path from "node:path";
import { fileURLToPath } from "node:url";
import fs from "node:fs";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const REPO = path.resolve(__dirname, "..", "..");
const SCREENS = path.join(__dirname, "screens");

const SIM = process.env.VOLTSY_SIM || "FE881493-EFC6-40E5-B867-268B8B438044"; // iPhone 17 Pro Max
const BUNDLE = "com.lawoflarge.voltsy";

const SCREENS_MAP = [
  ["01-hero",   "hero"],
  ["02-moods",  "moods"],
  ["03-alert",  "alert"],
  ["04-care",   "care"],
  ["05-widget", "widget"],
  ["06-pro",    "pro"],
];

const sh = (c, a, o = {}) => execFileSync(c, a, { stdio: "inherit", ...o });
const shq = (c, a, o = {}) => execFileSync(c, a, { stdio: ["ignore", "pipe", "pipe"], ...o }).toString();

// ── 0. Regenerate project so new Sources files are picked up ──────────────────
console.log("== Stage A.0: xcodegen generate ==");
try { sh("xcodegen", ["generate"], { cwd: REPO }); }
catch { console.log("  (xcodegen not on PATH or failed — assuming project is current)"); }

// ── 1. Build DEBUG for the simulator ─────────────────────────────────────────
const DD = path.join(__dirname, "out", ".dd");
console.log("== Stage A.1: xcodebuild Debug (sim) ==");
sh("xcodebuild", [
  "build",
  "-scheme", "Voltsy",
  "-configuration", "Debug",
  "-destination", `platform=iOS Simulator,id=${SIM}`,
  "-derivedDataPath", DD,
  "CODE_SIGNING_ALLOWED=NO",
], { cwd: REPO });

const APP = shq("bash", ["-lc",
  `find "${DD}/Build/Products/Debug-iphonesimulator" -maxdepth 1 -name 'Voltsy.app' | head -1`,
]).trim();
if (!APP) throw new Error("Voltsy.app not found in derivedData — did the build succeed?");
console.log(`  app: ${APP}`);

// ── 2. Boot + configure the simulator (no erase — dedicated sim) ──────────────
console.log("\n== Stage A.2: boot + configure sim ==");
try { sh("xcrun", ["simctl", "boot", SIM]); } catch { /* already booted */ }
sh("xcrun", ["simctl", "bootstatus", SIM, "-b"]);
try { sh("xcrun", ["simctl", "ui", SIM, "appearance", "light"]); } catch {}
sh("xcrun", ["simctl", "status_bar", SIM, "override",
  "--time", "9:41",
  "--operatorName", " ",
  "--batteryState", "charged",
  "--batteryLevel", "100",
  "--cellularBars", "4",
  "--wifiBars", "3",
]);
sh("xcrun", ["simctl", "install", SIM, APP]);

// ── 3. Per-frame: launch → settle → screenshot ────────────────────────────────
fs.mkdirSync(SCREENS, { recursive: true });
// warm-up launch: lets any Handoff/Continuity back-indicator time out so frame 1 is clean
try {
  sh("xcrun", ["simctl", "launch", SIM, BUNDLE, "--capture-screen", "care"]);
  sh("bash", ["-lc", "sleep 5"]);
  sh("xcrun", ["simctl", "terminate", SIM, BUNDLE]);
} catch {}

console.log("\n== Stage A.3: per-frame captures ==");
for (const [id, screen] of SCREENS_MAP) {
  try { sh("xcrun", ["simctl", "terminate", SIM, BUNDLE]); } catch {}
  sh("xcrun", ["simctl", "launch", SIM, BUNDLE, "--capture-screen", screen]);
  sh("bash", ["-lc", "sleep 3"]);
  const outFile = path.join(SCREENS, `${id}.png`);
  sh("xcrun", ["simctl", "io", SIM, "screenshot", outFile]);
  console.log(`  captured ${id} -> screens/${id}.png`);
}
try { sh("xcrun", ["simctl", "terminate", SIM, BUNDLE]); } catch {}

console.log("\nDone — screens/ updated (1320x2868 light captures).");
