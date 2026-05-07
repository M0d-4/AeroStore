import fs from "node:fs";
import path from "node:path";
import zlib from "node:zlib";

// Minimal PNG writer (RGBA8) + simple vector-ish renderer (no deps).

function crc32(buf) {
  let c = 0xffffffff;
  for (let i = 0; i < buf.length; i++) {
    c ^= buf[i];
    for (let k = 0; k < 8; k++) c = (c >>> 1) ^ (0xedb88320 & (-(c & 1)));
  }
  return (c ^ 0xffffffff) >>> 0;
}

function chunk(type, data) {
  const t = Buffer.from(type, "ascii");
  const len = Buffer.alloc(4);
  len.writeUInt32BE(data.length, 0);
  const crc = Buffer.alloc(4);
  const c = crc32(Buffer.concat([t, data]));
  crc.writeUInt32BE(c, 0);
  return Buffer.concat([len, t, data, crc]);
}

function writePngRGBA({ width, height, rgba }) {
  const signature = Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]);
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(width, 0);
  ihdr.writeUInt32BE(height, 4);
  ihdr[8] = 8; // bit depth
  ihdr[9] = 6; // RGBA
  ihdr[10] = 0;
  ihdr[11] = 0;
  ihdr[12] = 0;

  // Filter byte per row (0 = none)
  const stride = width * 4;
  const raw = Buffer.alloc((stride + 1) * height);
  for (let y = 0; y < height; y++) {
    raw[y * (stride + 1)] = 0;
    rgba.copy(raw, y * (stride + 1) + 1, y * stride, (y + 1) * stride);
  }
  const compressed = zlib.deflateSync(raw, { level: 9 });

  const iend = Buffer.alloc(0);
  return Buffer.concat([
    signature,
    chunk("IHDR", ihdr),
    chunk("IDAT", compressed),
    chunk("IEND", iend),
  ]);
}

function clamp01(x) {
  return x < 0 ? 0 : x > 1 ? 1 : x;
}

function lerp(a, b, t) {
  return a + (b - a) * t;
}

function mixColor(c1, c2, t) {
  return [
    lerp(c1[0], c2[0], t),
    lerp(c1[1], c2[1], t),
    lerp(c1[2], c2[2], t),
    lerp(c1[3], c2[3], t),
  ];
}

function srgbToByte(x) {
  return Math.round(clamp01(x) * 255);
}

function drawIcon(size) {
  const w = size;
  const h = size;
  const buf = Buffer.alloc(w * h * 4);

  // Background: deep charcoal with subtle top-left vignette.
  const bg1 = [0.07, 0.08, 0.10, 1.0];
  const bg2 = [0.11, 0.12, 0.16, 1.0];

  for (let y = 0; y < h; y++) {
    for (let x = 0; x < w; x++) {
      const u = x / (w - 1);
      const v = y / (h - 1);
      const t = clamp01(0.15 + 0.85 * (0.65 * u + 0.35 * v));
      const c = mixColor(bg1, bg2, t);
      const dx = u - 0.18;
      const dy = v - 0.20;
      const r2 = dx * dx + dy * dy;
      const glow = Math.exp(-r2 / 0.03) * 0.10;
      const idx = (y * w + x) * 4;
      buf[idx + 0] = srgbToByte(c[0] + glow);
      buf[idx + 1] = srgbToByte(c[1] + glow);
      buf[idx + 2] = srgbToByte(c[2] + glow);
      buf[idx + 3] = 255;
    }
  }

  // Ribbon path (approx of the FluxLogoView curves).
  const inset = w * 0.22;
  const left = inset;
  const right = w - inset;
  const top = h * 0.24;
  const mid = h * 0.50;
  const bottom = h * 0.76;

  const p0 = [right, top];
  const c1 = [w * 0.62, top];
  const c2 = [w * 0.36, h * 0.40];
  const p1 = [left, mid];

  const p2 = [w * 0.62, mid];
  const c3 = [w * 0.47, h * 0.60];
  const c4 = [w * 0.32, bottom];
  const p3 = [left, bottom];

  const gradA = [0.98, 0.40, 0.24, 1.0]; // orange
  const gradB = [0.98, 0.66, 0.26, 1.0]; // amber
  const gradC = [0.30, 0.80, 0.94, 1.0]; // cyan

  function bezier(t, a, b, c, d) {
    const mt = 1 - t;
    const mt2 = mt * mt;
    const t2 = t * t;
    const x = a[0] * mt2 * mt + 3 * b[0] * mt2 * t + 3 * c[0] * mt * t2 + d[0] * t2 * t;
    const y = a[1] * mt2 * mt + 3 * b[1] * mt2 * t + 3 * c[1] * mt * t2 + d[1] * t2 * t;
    return [x, y];
  }

  // Stroke painting: stamp circles along sampled curve.
  const stroke = Math.max(2, Math.round(w * 0.038));
  const glowStroke = Math.max(3, Math.round(stroke * 1.45));

  function stampCircle(cx, cy, r, color, soft = 0.0) {
    const x0 = Math.max(0, Math.floor(cx - r - 1));
    const x1 = Math.min(w - 1, Math.ceil(cx + r + 1));
    const y0 = Math.max(0, Math.floor(cy - r - 1));
    const y1 = Math.min(h - 1, Math.ceil(cy + r + 1));
    const rr = r * r;
    const softR = r * (1 + soft);
    const softRR = softR * softR;

    for (let y = y0; y <= y1; y++) {
      for (let x = x0; x <= x1; x++) {
        const dx = x + 0.5 - cx;
        const dy = y + 0.5 - cy;
        const d2 = dx * dx + dy * dy;
        if (d2 > softRR) continue;
        let a = 1.0;
        if (soft > 0 && d2 > rr) {
          const t = (Math.sqrt(d2) - r) / (softR - r);
          a = clamp01(1.0 - t);
        }

        const idx = (y * w + x) * 4;
        const dstA = buf[idx + 3] / 255;
        const srcA = color[3] * a;
        const outA = srcA + dstA * (1 - srcA);
        if (outA <= 0) continue;
        const dst = [buf[idx] / 255, buf[idx + 1] / 255, buf[idx + 2] / 255];
        const out = [
          (color[0] * srcA + dst[0] * dstA * (1 - srcA)) / outA,
          (color[1] * srcA + dst[1] * dstA * (1 - srcA)) / outA,
          (color[2] * srcA + dst[2] * dstA * (1 - srcA)) / outA,
        ];
        buf[idx + 0] = srgbToByte(out[0]);
        buf[idx + 1] = srgbToByte(out[1]);
        buf[idx + 2] = srgbToByte(out[2]);
        buf[idx + 3] = Math.round(outA * 255);
      }
    }
  }

  function ribbonColor(t) {
    // 3-stop gradient
    if (t < 0.5) return mixColor(gradA, gradB, t / 0.5);
    return mixColor(gradB, gradC, (t - 0.5) / 0.5);
  }

  function paintCurve(a, b, c, d, tStart, tEnd) {
    const steps = Math.max(120, Math.round(w * 0.65));
    for (let i = 0; i <= steps; i++) {
      const t = i / steps;
      const p = bezier(t, a, b, c, d);
      const tt = lerp(tStart, tEnd, t);

      // glow pass
      const glow = ribbonColor(tt);
      stampCircle(p[0], p[1], glowStroke / 2, [1, 1, 1, 0.14], 0.8);

      // main ribbon
      const col = ribbonColor(tt);
      stampCircle(p[0], p[1], stroke / 2, [col[0], col[1], col[2], 1.0], 0.35);
    }
  }

  paintCurve(p0, c1, c2, p1, 0.0, 0.55);
  // small connector "kink"
  stampCircle(p2[0], p2[1], stroke / 2, [0.98, 0.66, 0.26, 1.0], 0.35);
  paintCurve(p2, c3, c4, p3, 0.55, 1.0);

  return { width: w, height: h, rgba: buf };
}

function main() {
  const repoRoot = process.cwd();
  const appIconDir = path.join(repoRoot, "AltStore", "Resources", "Icons.xcassets", "AppIcon.appiconset");

  const sizes = [
    20, 29, 40, 50, 57, 58, 60, 72, 76, 80, 87, 100, 114, 120, 144, 152, 167, 180, 1024,
  ];

  if (!fs.existsSync(appIconDir)) {
    throw new Error(`Missing appiconset at ${appIconDir}`);
  }

  for (const s of sizes) {
    const outPath = path.join(appIconDir, `${s}.png`);
    const img = drawIcon(s);
    const png = writePngRGBA(img);
    fs.writeFileSync(outPath, png);
  }

  // Also update Classic/App.png (used as preview in Alt Icons UI).
  const classicAppPath = path.join(repoRoot, "AltStore", "Resources", "Icons.xcassets", "Classic", "App.imageset", "App.png");
  if (fs.existsSync(classicAppPath)) {
    const img = drawIcon(512);
    fs.writeFileSync(classicAppPath, writePngRGBA(img));
  }

  console.log("Generated FluxStore app icon PNGs.");
}

main();

