import { spawnSync } from "node:child_process";
import { copyFileSync, existsSync, mkdirSync, rmSync } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const ARTIFACTS = [
  {
    name: "libwebview-windows-x64",
    sourceLibrary: ["lib", "webview.lib"],
    targetDir: "windows-x64",
    targetLibrary: "webview.lib",
  },
  {
    name: "libwebview-macos-universal",
    sourceLibrary: ["lib", "libwebview.a"],
    targetDir: "macos-universal",
    targetLibrary: "libwebview.a",
  },
  {
    name: "libwebview-linux-x64",
    sourceLibrary: ["lib", "libwebview.a"],
    targetDir: "linux-x64",
    targetLibrary: "libwebview.a",
  },
];

function fail(message) {
  console.error(message);
  process.exit(1);
}

function run(command, args, options = {}) {
  const result = spawnSync(command, args, {
    encoding: "utf8",
    stdio: options.captureOutput ? "pipe" : "inherit",
    ...options,
  });
  if (result.status !== 0) {
    const details = options.captureOutput
      ? (result.stderr || result.stdout || "").trim()
      : "";
    fail(details ? `${command} failed: ${details}` : `${command} failed.`);
  }
  return result.stdout ?? "";
}

function parseArgs(argv) {
  let repo = "justjavac/libwebview";
  let runId = "";

  for (let index = 0; index < argv.length; index += 1) {
    const arg = argv[index];
    if (arg === "--repo") {
      repo = argv[index + 1] ?? fail("Missing value for --repo.");
      index += 1;
    } else if (arg === "--run-id") {
      runId = argv[index + 1] ?? fail("Missing value for --run-id.");
      index += 1;
    } else if (arg === "--help" || arg === "-h") {
      console.log(
        "Usage: node ./scripts/sync_libwebview.mjs [--repo owner/name] [--run-id 123]",
      );
      process.exit(0);
    } else {
      fail(`Unknown argument: ${arg}`);
    }
  }

  return { repo, runId };
}

function repoRoot() {
  const scriptDir = path.dirname(fileURLToPath(import.meta.url));
  return path.resolve(scriptDir, "..");
}

function latestSuccessfulRunId(repo) {
  const output = run(
    "gh",
    [
      "run",
      "list",
      "--repo",
      repo,
      "--workflow",
      "build",
      "--status",
      "completed",
      "--limit",
      "20",
      "--json",
      "databaseId,conclusion",
    ],
    { captureOutput: true },
  );
  const runs = JSON.parse(output);
  const successful = runs.find((run) => run.conclusion === "success");
  if (!successful) {
    fail(`No successful libwebview workflow run found in ${repo}.`);
  }
  return String(successful.databaseId);
}

function copyArtifact(downloadRoot, libRoot, artifact) {
  const artifactRoot = path.join(downloadRoot, artifact.name);
  if (!existsSync(artifactRoot)) {
    fail(`Downloaded artifact is missing: ${artifact.name}`);
  }

  const targetDir = path.join(libRoot, artifact.targetDir);
  mkdirSync(targetDir, { recursive: true });

  copyFileSync(
    path.join(artifactRoot, ...artifact.sourceLibrary),
    path.join(targetDir, artifact.targetLibrary),
  );
  copyFileSync(
    path.join(artifactRoot, "BUILD_INFO.txt"),
    path.join(targetDir, "BUILD_INFO.txt"),
  );
}

function main() {
  const { repo, runId } = parseArgs(process.argv.slice(2));
  const root = repoRoot();
  const resolvedRunId = runId || latestSuccessfulRunId(repo);
  const downloadDir = path.join(root, "target", "libwebview-sync");
  const libRoot = path.join(root, "lib");

  rmSync(downloadDir, { recursive: true, force: true });
  run("gh", ["run", "download", resolvedRunId, "--repo", repo, "--dir", downloadDir]);

  for (const artifact of ARTIFACTS) {
    copyArtifact(downloadDir, libRoot, artifact);
  }

  console.log(`Updated vendored native libraries from ${repo} run ${resolvedRunId}.`);
}

main();
