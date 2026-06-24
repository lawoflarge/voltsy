// NetGuard App Store "Glow-Up" — one-command orchestrator.
//
// Pipeline:
//   Stage A  capture    native SwiftUI screens via simctl         (opt-in: --capture)
//   Stage B  composite  light-canvas posters @ 1290x2796         (compositor.mjs)
//   Stage C  stage      copy frames into out/asc/<locale>/
//             for each locale in config.locales (fan-out to all 10)
//   Stage D  validate   `asc screenshots validate` per locale
//   Stage E  upload     `asc screenshots upload --replace` to an editable App Store
//             version (opt-in: --upload --version <x.y.z>)
//
// The captured screens live in ./screens and are committed.  By default Stage A
// is SKIPPED and we re-composite from them (fast, deterministic).
//
// Usage:
//   node build.mjs --app netguard                              # composite + validate (en-US only)
//   node build.mjs --app netguard --all-locales               # composite + validate all 10 locales
//   node build.mjs --app netguard --locale de-DE              # composite + validate one locale
//   node build.mjs --app netguard --capture                   # re-capture first, then composite
//   node build.mjs --app netguard --frames 01-hero            # one frame only
//   node build.mjs --app netguard --all-locales --upload --version 1.4.0   # upload (state-gated)

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { execFileSync } from "node:child_process";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const OUT = path.join(__dirname, "out");

const args = process.argv.slice(2);
const has = (f) => args.includes(`--${f}`);
const val = (name, dflt) => {
  const i = args.indexOf(`--${name}`);
  return i >= 0 && args[i + 1] && !args[i + 1].startsWith("--") ? args[i + 1] : dflt;
};

const APP          = val("app", "netguard");
const FRAMES       = val("frames", null);
const LOCALE_ARG   = val("locale", null);       // single-locale override
const ALL_LOCALES  = has("all-locales");
const DEVICE_TYPE  = val("device-type", "IPHONE_67");  // 1290x2796 → APP_IPHONE_67
const DO_CAPTURE   = has("capture");
const DO_UPLOAD    = has("upload");
const UPLOAD_VER   = val("version", null);
const REPLACE      = !has("no-replace");

const config = JSON.parse(fs.readFileSync(path.join(__dirname, "config.json"), "utf8"))[APP];
if (!config) throw new Error(`No config for app "${APP}"`);
const APP_ID = process.env.ASC_APP_ID || config.appId;

// Determine which locales to process
const ALL_LOCALE_KEYS = Object.keys(config.locales || {});
let locales;
if (ALL_LOCALES) {
  locales = ALL_LOCALE_KEYS;
} else if (LOCALE_ARG) {
  locales = [LOCALE_ARG];
} else {
  locales = ["en-US"];
}

const run = (cmd, cmdArgs, opts = {}) => {
  console.log(`\n$ ${cmd} ${cmdArgs.join(" ")}`);
  return execFileSync(cmd, cmdArgs, { stdio: "inherit", cwd: __dirname, ...opts });
};

// ── state guard for upload ────────────────────────────────────────────────────
function assertEditableVersion(appId, version) {
  const out = execFileSync("asc", ["versions", "list", "--app", appId, "--output", "json"]).toString();
  const v = JSON.parse(out).find((x) => x.versionString === version);
  if (!v) throw new Error(`version ${version} not found in ASC`);
  const editable = ["PREPARE_FOR_SUBMISSION", "DEVELOPER_REJECTED"];
  if (!editable.includes(v.appStoreState)) {
    throw new Error(
      `ABORT: ${version} is ${v.appStoreState}; screenshots need an editable version ` +
      `(PREPARE_FOR_SUBMISSION or DEVELOPER_REJECTED). ` +
      `Uploading to a non-editable version requires a NEW version + full re-review. ` +
      `Create/select an editable version first.`
    );
  }
  console.log(`  version ${version} is ${v.appStoreState} — editable, proceeding.`);
}

// ── Stage A: capture ──────────────────────────────────────────────────────────
if (DO_CAPTURE) {
  console.log("== Stage A: capture native screens ==");
  run("node", ["capture.mjs"]);
} else {
  console.log("== Stage A: capture SKIPPED (using committed ./screens) ==");
}

// ── Stage B: composite for each locale ───────────────────────────────────────
console.log("\n== Stage B: composite posters ==");
for (const locale of locales) {
  console.log(`\n  locale: ${locale}`);
  const compArgs = ["compositor.mjs", "--app", APP, "--locale", locale];
  if (FRAMES) compArgs.push("--frames", FRAMES);
  run("node", compArgs);
}

// ── Stage C: stage for ASC fan-out (all locales) ─────────────────────────────
console.log("\n== Stage C: stage for ASC ==");
const ascRoot = path.join(OUT, "asc");
fs.rmSync(ascRoot, { recursive: true, force: true });

for (const locale of locales) {
  const ascDir = path.join(ascRoot, locale);
  fs.mkdirSync(ascDir, { recursive: true });
  const pngs = fs.readdirSync(OUT)
    .filter((f) => /^\d\d-.*\.png$/.test(f))
    .sort();
  if (pngs.length === 0) {
    throw new Error(`No output PNGs found in ${OUT} for locale ${locale}. Did Stage B succeed?`);
  }
  for (const f of pngs) fs.copyFileSync(path.join(OUT, f), path.join(ascDir, f));
  console.log(`  staged ${pngs.length} frame(s) -> out/asc/${locale}/`);
}

// ── Stage D: validate each locale ────────────────────────────────────────────
console.log("\n== Stage D: validate (asc preflight) ==");
let allValid = true;
for (const locale of locales) {
  const ascDir = path.join(ascRoot, locale);
  // Assert all 6 frames are present
  const staged = fs.readdirSync(ascDir).filter((f) => /\.png$/.test(f));
  if (staged.length !== 6) {
    console.error(`  WARN: ${locale} has ${staged.length} posters (expected 6): ${staged.join(", ")}`);
    allValid = false;
  }
  try {
    run("asc", ["screenshots", "validate", "--path", ascDir, "--device-type", DEVICE_TYPE, "--output", "table"]);
  } catch {
    allValid = false;
    console.error(`  asc validate failed for ${locale}`);
  }
}

// ── Stage E: upload (state-gated, opt-in) ────────────────────────────────────
if (DO_UPLOAD) {
  console.log("\n== Stage E: upload to App Store Connect ==");
  if (!allValid) {
    console.error("  ABORT: validation did not pass for all locales. Fix issues then re-run with --upload.");
    process.exit(1);
  }
  if (!UPLOAD_VER) {
    console.error("  ABORT: --upload requires --version <x.y.z>.");
    process.exit(1);
  }
  // State gate: abort if the version is not editable
  assertEditableVersion(APP_ID, UPLOAD_VER);

  for (const locale of locales) {
    const ascDir = path.join(ascRoot, locale);
    const staged = fs.readdirSync(ascDir).filter((f) => /\.png$/.test(f));
    if (staged.length !== 6) {
      throw new Error(`ABORT: ${locale} has ${staged.length}/6 posters — will not upload an incomplete set.`);
    }
    console.log(`\n  uploading ${locale} (${staged.length} posters)...`);
    const upArgs = [
      "screenshots", "upload",
      "--app", APP_ID,
      "--version", UPLOAD_VER,
      "--device-type", DEVICE_TYPE,
      "--path", ascDir,
    ];
    if (REPLACE) upArgs.push("--replace");
    run("asc", upArgs);
    console.log(`  uploaded ${locale}`);
  }
  console.log(`\nUploaded ${locales.length} locale(s) to ${APP_ID} v${UPLOAD_VER} (${DEVICE_TYPE}).`);
} else {
  console.log("\n== Stage E: upload SKIPPED (pass --upload --version <x.y.z>) ==");
}

console.log(`\nDone. Posters in ${OUT}/  (staged for ASC in out/asc/)`);
