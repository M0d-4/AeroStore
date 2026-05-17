#!/usr/bin/env node
/**
 * Resizes repo-root icon.png into AppIcon.appiconset, Classic/App.png, and AeroStoreMark.
 * macOS: uses `sips`. Windows: run from repo root after placing icon.png (or use CI on macOS).
 */
import fs from "node:fs";
import path from "node:path";
import { execSync } from "node:child_process";

const repoRoot = process.cwd();
const source = path.join(repoRoot, "icon.png");
if (!fs.existsSync(source)) {
  console.error("Missing icon.png at repo root.");
  process.exit(1);
}

const appIconDir = path.join(
  repoRoot,
  "AltStore",
  "Resources",
  "Icons.xcassets",
  "AppIcon.appiconset"
);
const markDir = path.join(
  repoRoot,
  "AltStore",
  "Resources",
  "Icons.xcassets",
  "AeroStoreMark.imageset"
);
const classicApp = path.join(
  repoRoot,
  "AltStore",
  "Resources",
  "Icons.xcassets",
  "Classic",
  "App.imageset",
  "App.png"
);

const sizes = [
  20, 29, 40, 50, 57, 58, 60, 72, 76, 80, 87, 100, 114, 120, 144, 152, 167, 180, 1024,
];

function resize(out, size) {
  fs.mkdirSync(path.dirname(out), { recursive: true });
  execSync(`sips -z ${size} ${size} "${source}" --out "${out}"`, { stdio: "inherit" });
}

for (const s of sizes) {
  resize(path.join(appIconDir, `${s}.png`), s);
}

fs.mkdirSync(markDir, { recursive: true });
fs.copyFileSync(source, path.join(markDir, "AeroStoreMark.png"));
if (fs.existsSync(path.dirname(classicApp))) {
  resize(classicApp, 512);
}

console.log("Applied icon.png to AppIcon, AeroStoreMark, and Classic/App.");
