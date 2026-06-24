// Voltsy App Store "Glow-Up" compositor.
//
// Stage B. Composites the REAL native app UI — embedded in a real iPhone 16 Pro Max
// Black-Titanium frame (Koubou, via frame-device.py) — into a premium MINT-CUTE
// light-canvas App Store poster at EXACTLY 1290x2796 (ASC 6.9" `_67`), using
// Playwright/Chromium as an HTML renderer. Fully offline: framed device, fonts and
// the real Voltsy icon are base64-embedded, no network at render time.
//
// Brand: soft mint→green canvas, green (#16A34A) accent, white stage panel behind the
// device, scattered soft bubbles + radial glows, cute but premium.
//
// Usage: node compositor.mjs [--app voltsy] [--frames 01-hero,...] [--locale en-US] [--dpr 2]
// Output: ./out/<id>.png  (exactly 1290x2796)

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { execFileSync } from "node:child_process";

const PLAYWRIGHT_PATH =
  process.env.PLAYWRIGHT_PATH ??
  "/Users/levinschwab/Data/Claude/browser-automation/node_modules/playwright/index.mjs";
const { chromium } = await import(PLAYWRIGHT_PATH);

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const SCREENS = path.join(__dirname, "screens");
const FONTS = path.join(__dirname, "fonts");
const OUT = path.join(__dirname, "out");
const FRAMED = path.join(OUT, ".framed");
const ICON = path.resolve(
  __dirname, "..", "..",
  "apps", "Voltsy", "Resources", "Assets.xcassets", "AppIcon.appiconset", "AppIcon-1024.png"
);

const args = process.argv.slice(2);
const argVal = (name, dflt) => {
  const i = args.indexOf(`--${name}`);
  return i >= 0 && args[i + 1] ? args[i + 1] : dflt;
};
const APP = argVal("app", "voltsy");
const DPR = Number(argVal("dpr", "2"));
const frameFilter = argVal("frames", null);
const LOCALE = argVal("locale", "en-US");

const config = JSON.parse(fs.readFileSync(path.join(__dirname, "config.json"), "utf8"))[APP];
if (!config) throw new Error(`No config for app "${APP}"`);
const P = config.palette;
const W = config.size.w;   // 1290
const H = config.size.h;   // 2796

const b64 = (p) => fs.readFileSync(p).toString("base64");
const FONT_GROTESK = b64(path.join(FONTS, "SpaceGrotesk.ttf"));
const FONT_MONO = b64(path.join(FONTS, "JetBrainsMono.ttf"));
const ICON_URI = `data:image/png;base64,${b64(ICON)}`;
const screenUri = (file) => `data:image/png;base64,${b64(path.join(SCREENS, file))}`;

const SCREEN_W = 1320, SCREEN_H = 2868;

// ── framed device generation (real iPhone Black-Titanium frame, status bar kept) ──
function ensureFramed(screenFile) {
  fs.mkdirSync(FRAMED, { recursive: true });
  const out = path.join(FRAMED, screenFile);
  if (
    !fs.existsSync(out) ||
    fs.statSync(out).mtimeMs < fs.statSync(path.join(SCREENS, screenFile)).mtimeMs
  ) {
    execFileSync(
      "python3",
      [path.join(__dirname, "frame-device.py"), path.join(SCREENS, screenFile), out, "--no-strip"],
      { stdio: "ignore" }
    );
  }
  return `data:image/png;base64,${b64(out)}`;
}

// ── soft bubble field (cute texture) with stage keep-out ─────────────────────────
// Deterministic bubbles scattered around the canvas margins, avoiding the central
// stage panel so they never sit behind the device.
function bubbleField() {
  // Keep-out (stage panel) bounds
  const KX1 = 130, KY1 = 500, KX2 = 1160, KY2 = 2250;
  const inKeepOut = (x, y, r) => x + r > KX1 && x - r < KX2 && y + r > KY1 && y - r < KY2;
  // [x, y, r, fill]
  const greens = ["rgba(34,197,94,0.10)", "rgba(22,163,74,0.08)", "rgba(255,255,255,0.55)"];
  const seeds = [
    [70, 240, 70], [1180, 360, 90], [40, 1500, 120], [1230, 1400, 64],
    [90, 2400, 96], [1190, 2500, 110], [1240, 900, 44], [30, 980, 52],
    [1130, 1900, 40], [120, 1950, 58], [1210, 2080, 36], [60, 640, 38],
    [1260, 1650, 30], [20, 1180, 34], [1150, 600, 30], [150, 2680, 60],
  ];
  const circles = seeds
    .filter(([x, y, r]) => !inKeepOut(x, y, r))
    .map(([x, y, r], i) => `<circle cx="${x}" cy="${y}" r="${r}" fill="${greens[i % greens.length]}"/>`)
    .join("");
  return `<svg class="bubbles" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}">${circles}</svg>`;
}

// ── text helpers ──────────────────────────────────────────────────────────────
function headlineHTML(text, accent) {
  if (accent && text.includes(accent)) {
    const idx = text.indexOf(accent);
    return `${text.slice(0, idx)}<span class="accent">${accent}</span>${text.slice(idx + accent.length)}`;
  }
  return text;
}

function deviceImg(screenFile, klass) {
  return `<img class="device-img ${klass}" src="${ensureFramed(screenFile)}" alt=""/>`;
}

function calloutCard(screenFile, cropFrac, cardW, caption) {
  const [fx, fy, fw, fh] = cropFrac;
  const scale = cardW / (fw * SCREEN_W);
  const imgW = SCREEN_W * scale, imgH = SCREEN_H * scale;
  const tx = -fx * SCREEN_W * scale, ty = -fy * SCREEN_H * scale;
  const clipH = Math.round(fh * SCREEN_H * scale);
  return `<div class="callout-card" style="width:${cardW}px;">
    <div class="callout-clip" style="height:${clipH}px;">
      <img src="${screenUri(screenFile)}" style="width:${imgW}px; height:${imgH}px; transform:translate(${tx}px, ${ty}px);"/>
    </div>
    ${caption ? `<div class="callout-cap"><span class="dot"></span>${caption}</div>` : ""}
  </div>`;
}

function header(f) {
  return `<header class="head">
    <div class="eyebrow">${f.eyebrow}</div>
    <h1 class="headline">${headlineHTML(f.headline, f.accent)}</h1>
    <p class="subline">${f.subline}</p>
  </header>`;
}

function footer() {
  return `<footer class="foot">
    <img class="foot-icon" src="${ICON_URI}"/>
    <span class="wordmark">${config.wordmark}</span>
  </footer>`;
}

// ── layouts ───────────────────────────────────────────────────────────────────
const LAYOUTS = {
  hero(f) {
    return `${header(f)}${deviceImg(f.screen, "dev-hero")}${footer()}`;
  },
  callout(f) {
    const card = f.callout
      ? `<div class="callout-wrap"><div class="leader"></div>${calloutCard(f.screen, f.callout.cropFrac, 560, f.callout.caption)}</div>`
      : "";
    return `${header(f)}${deviceImg(f.screen, "dev-callout")}${card}${footer()}`;
  },
  cta(f) {
    return `${header(f)}${f.cta ? `<div class="cta-btn">${f.cta}</div>` : ""}${deviceImg(f.screen, "dev-cta")}${footer()}`;
  },
};

// ── CSS (mint-cute light canvas) ────────────────────────────────────────────────
function css() {
  return `
  @font-face { font-family:'Grotesk'; src:url(data:font/ttf;base64,${FONT_GROTESK}) format('truetype'); font-weight:300 800; }
  @font-face { font-family:'Mono';    src:url(data:font/ttf;base64,${FONT_MONO})    format('truetype'); font-weight:300 800; }
  * { margin:0; padding:0; box-sizing:border-box; }
  html,body { width:${W}px; height:${H}px; }
  body { position:relative; overflow:hidden; background:${P.canvasTop}; font-family:'Grotesk',sans-serif; -webkit-font-smoothing:antialiased; }

  /* soft mint→green canvas + two radial glows for depth */
  .bg { position:absolute; inset:0;
    background:
      radial-gradient(1200px 900px at 85% 8%, rgba(255,255,255,0.85), rgba(255,255,255,0) 60%),
      radial-gradient(1000px 1000px at 12% 92%, rgba(34,197,94,0.20), rgba(34,197,94,0) 60%),
      linear-gradient(180deg, ${P.canvasTop} 0%, ${P.canvasMid} 52%, ${P.canvasBottom} 100%); }

  .bubbles { position:absolute; left:0; top:0; z-index:0; }

  /* white stage panel behind the device — lifts it off the mint canvas */
  .stage-panel { position:absolute; left:50%; transform:translateX(-50%);
    top:540px; width:1000px; height:1680px; border-radius:56px;
    background: linear-gradient(180deg, ${P.stageTop}, ${P.stageBottom});
    border:1px solid ${P.stageBorder};
    box-shadow:0 40px 90px -24px rgba(15,46,30,0.18); z-index:1; }

  .vignette { position:absolute; inset:0; box-shadow: inset 0 0 420px 120px rgba(61,101,82,0.08); pointer-events:none; z-index:9; }
  .stage { position:absolute; inset:0; z-index:2; }

  .head { position:absolute; top:120px; left:92px; right:92px; z-index:5; text-align:center; }
  .eyebrow  { font-family:'Mono'; font-weight:700; font-size:33px; letter-spacing:0.18em; color:${P.accent}; text-transform:uppercase; margin-bottom:20px; }
  .headline { font-family:'Grotesk'; font-weight:700; font-size:88px; line-height:1.04; letter-spacing:-0.026em; color:${P.ink}; text-wrap:balance; margin:0 auto; max-width:1060px; }
  .headline .accent { color:${P.accent}; }
  .subline  { margin:22px auto 0; max-width:900px; font-family:'Grotesk'; font-weight:500; font-size:34px; line-height:1.32; color:${P.slate}; }

  /* green device shadow */
  .device-img { position:absolute; left:50%; transform:translateX(-50%); z-index:3;
    filter: drop-shadow(0 44px 74px rgba(22,163,74,0.22)) drop-shadow(0 10px 26px rgba(15,46,30,0.12)); }
  .dev-hero    { width:1040px; top:524px; }
  .dev-callout { width:900px;  top:600px; }
  .dev-cta     { width:900px;  top:660px; }

  /* callout card (white, green border) */
  .callout-wrap { position:absolute; right:48px; top:2070px; z-index:8; }
  .callout-card { position:relative; border-radius:32px; overflow:hidden; background:#FFFFFF;
    box-shadow: 0 44px 84px -18px rgba(15,46,30,0.22), 0 0 0 1.5px rgba(22,163,74,0.22), 0 0 60px 0 rgba(34,197,94,0.10); }
  .callout-clip { position:relative; overflow:hidden; width:100%; }
  .callout-clip img { position:absolute; left:0; top:0; max-width:none; }
  .callout-cap { display:flex; align-items:center; gap:12px; padding:16px 26px 18px; font-family:'Mono'; font-weight:700;
    font-size:25px; letter-spacing:0.14em; text-transform:uppercase; color:${P.success}; background:${P.accentTint}; border-top:1px solid rgba(22,163,74,0.14); }
  .callout-cap .dot { width:13px; height:13px; border-radius:50%; background:${P.accent}; flex-shrink:0; }
  .leader { position:absolute; left:-116px; top:78px; width:140px; height:3px; background:linear-gradient(90deg, rgba(22,163,74,0.0), ${P.accent}); z-index:7; }
  .leader::before { content:''; position:absolute; left:-7px; top:-4px; width:14px; height:14px; border-radius:50%; background:${P.accent}; }

  /* cta pill — Voltsy green */
  .cta-btn { position:absolute; top:520px; left:50%; transform:translateX(-50%); z-index:6; padding:26px 56px; border-radius:999px;
    background:linear-gradient(180deg, #34D27B, ${P.green}); color:#FFFFFF; font-weight:700; font-size:31px;
    box-shadow:0 28px 60px -16px rgba(22,163,74,0.45), inset 0 1px 0 rgba(255,255,255,0.35); white-space:nowrap; }

  .foot { position:absolute; left:0; right:0; bottom:64px; z-index:10; display:flex; justify-content:center; align-items:center; gap:18px; }
  .foot-icon { width:60px; height:60px; border-radius:15px; box-shadow:0 6px 18px rgba(15,46,30,0.18); }
  .wordmark { font-family:'Grotesk'; font-weight:700; font-size:42px; letter-spacing:-0.01em; color:${P.ink}; }
  `;
}

function frameHTML(f) {
  const inner = (LAYOUTS[f.layout] || LAYOUTS.hero)(f);
  return `<!doctype html><html><head><meta charset="utf-8"><style>${css()}</style></head>
  <body>
    <div class="bg"></div>
    ${bubbleField()}
    <div class="stage-panel"></div>
    <div class="vignette"></div>
    <div class="stage">${inner}</div>
  </body></html>`;
}

async function main() {
  fs.mkdirSync(OUT, { recursive: true });
  const tmp = path.join(OUT, ".tmp");
  fs.mkdirSync(tmp, { recursive: true });

  const localeMap = (config.locales || {})[LOCALE] || {};
  let frames = config.frames;
  if (frameFilter) {
    const want = frameFilter.split(",").map((s) => s.trim());
    frames = frames.filter((f) => want.includes(f.id));
  }
  frames = frames.map((f) => ({ ...f, ...(localeMap[f.id] || {}) }));

  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: W, height: H }, deviceScaleFactor: DPR });

  for (const f of frames) {
    await page.setContent(frameHTML(f), { waitUntil: "load" });
    await page.evaluate(async () => { await document.fonts.ready; });
    const raw = path.join(tmp, `${f.id}.png`);
    await page.screenshot({ path: raw, clip: { x: 0, y: 0, width: W, height: H } });
    const final = path.join(OUT, `${f.id}.png`);
    execFileSync("sips", ["-z", String(H), String(W), raw, "--out", final], { stdio: "ignore" });
    const dim = execFileSync("sips", ["-g", "pixelWidth", "-g", "pixelHeight", final]).toString();
    console.log(`  ${f.id}  ${/pixelWidth: (\d+)/.exec(dim)[1]}x${/pixelHeight: (\d+)/.exec(dim)[1]}  (${f.layout})`);
  }

  await browser.close();
  fs.rmSync(tmp, { recursive: true, force: true });
  console.log(`\nRendered ${frames.length} frame(s) -> ${OUT}`);
}

main().catch((e) => { console.error(e); process.exit(1); });
