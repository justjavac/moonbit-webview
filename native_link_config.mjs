#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { execFileSync } from "node:child_process";

function nativeLinkPath(filePath) {
  if (process.platform !== "win32") {
    return filePath;
  }
  return filePath.replace(/\\/g, "/");
}

function requireFile(filePath) {
  if (!fs.existsSync(filePath)) {
    throw new Error(`Missing vendored native library: ${filePath}`);
  }
  return filePath;
}

function splitFlags(rawFlags) {
  return rawFlags
    .split(/\s+/)
    .map((value) => value.trim())
    .filter(Boolean);
}

function linuxSystemLinkFlags() {
  try {
    return splitFlags(
      execFileSync(
        "pkg-config",
        ["--libs", "gtk+-3.0", "webkit2gtk-4.1"],
        { encoding: "utf8" },
      ),
    );
  } catch (error) {
    throw new Error(
      "Failed to resolve Linux system link flags via pkg-config for gtk+-3.0 and webkit2gtk-4.1. " +
      "Install the development packages before building MoonBit code.\n" +
      String(error),
    );
  }
}

function main() {
  const payload = JSON.parse(fs.readFileSync(0, "utf8"));
  const env = payload.env ?? {};
  const isWindows = process.platform === "win32" || env.OS === "Windows_NT";
  const rootDir = path.dirname(fileURLToPath(import.meta.url));
  const vendoredLibDir = path.join(rootDir, "lib");

  if (isWindows) {
    const platformLibDir = nativeLinkPath(path.join(vendoredLibDir, "windows-x64"));
    requireFile(path.join(vendoredLibDir, "windows-x64", "webview.lib"));
    const webviewStaticLib = nativeLinkPath(path.join(platformLibDir, "webview"));
    process.stdout.write(JSON.stringify({
      link_configs: [
        {
          package: "justjavac/webview",
          link_libs: [
            webviewStaticLib,
            "advapi32",
            "ole32",
            "shell32",
            "shlwapi",
            "user32",
            "version",
          ],
        },
      ],
    }));
    return;
  }

  if (process.platform === "darwin") {
    const platformLibDir = nativeLinkPath(path.join(vendoredLibDir, "macos-universal"));
    requireFile(path.join(vendoredLibDir, "macos-universal", "libwebview.a"));
    process.stdout.write(JSON.stringify({
      link_configs: [
        {
          package: "justjavac/webview",
          link_search_paths: [platformLibDir],
          link_libs: ["webview", "dl"],
          link_flags: ["-framework", "WebKit"],
        },
      ],
    }));
    return;
  }

  const platformLibDir = nativeLinkPath(path.join(vendoredLibDir, "linux-x64"));
  requireFile(path.join(vendoredLibDir, "linux-x64", "libwebview.a"));
  process.stdout.write(JSON.stringify({
    link_configs: [
      {
        package: "justjavac/webview",
        link_search_paths: [platformLibDir],
        link_libs: ["webview"],
        link_flags: linuxSystemLinkFlags(),
      },
    ],
  }));
}

main();
