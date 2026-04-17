const cases = [
  { size: 256 * 1024, iterations: 20 },
  { size: 1024 * 1024, iterations: 10 },
  { size: 4 * 1024 * 1024, iterations: 4 },
];

const pendingBuffers = new Map();

const text = (id, value) => {
  const node = document.getElementById(id);
  if (node) {
    node.textContent = String(value);
  }
};

const setStatus = (state, message) => {
  const box = document.getElementById("status-box");
  if (box) {
    box.dataset.state = state;
  }
  text("status-text", message);
};

const reportFailure = async (message) => {
  setStatus("failed", message);
  text("payload", message);
  await window.reportSharedBufferBenchmarkFailure(message);
};

const normalizeAdditionalData = (value) => {
  if (typeof value === "string") {
    try {
      return JSON.parse(value);
    } catch {
      return {};
    }
  }
  if (value && typeof value === "object") {
    return value;
  }
  return {};
};

const checksumBytes = (buffer) => {
  const view = new Uint8Array(buffer);
  let checksum = 0;
  for (let index = 0; index < view.length; index += 1) {
    checksum = (checksum + view[index]) >>> 0;
  }
  return checksum;
};

const releaseBuffer = (buffer) => {
  if (window.chrome?.webview?.releaseBuffer) {
    window.chrome.webview.releaseBuffer(buffer);
  }
};

const onSharedBufferReceived = (event) => {
  const data = normalizeAdditionalData(event.additionalData);
  const sequence = Number(data.sequence);
  const waiter = pendingBuffers.get(sequence);
  if (!waiter) {
    return;
  }
  pendingBuffers.delete(sequence);
  let buffer = null;
  try {
    buffer = event.getBuffer();
    const checksum = checksumBytes(buffer);
    if (checksum !== Number(data.checksum)) {
      throw new Error(
        `SharedBuffer checksum mismatch for #${sequence}: expected ${data.checksum}, got ${checksum}`,
      );
    }
    if (buffer.byteLength !== Number(data.size)) {
      throw new Error(
        `SharedBuffer length mismatch for #${sequence}: expected ${data.size}, got ${buffer.byteLength}`,
      );
    }
    waiter.resolve({
      sequence,
      size: buffer.byteLength,
      checksum,
    });
  } catch (error) {
    waiter.reject(error);
  } finally {
    if (buffer) {
      releaseBuffer(buffer);
    }
  }
};

const waitForSharedBuffer = (sequence) =>
  new Promise((resolve, reject) => {
    const timeout = window.setTimeout(() => {
      pendingBuffers.delete(sequence);
      reject(new Error(`Timed out waiting for SharedBuffer #${sequence}`));
    }, 5000);
    pendingBuffers.set(sequence, {
      resolve: (value) => {
        window.clearTimeout(timeout);
        resolve(value);
      },
      reject: (error) => {
        window.clearTimeout(timeout);
        reject(error);
      },
    });
  });

const runJsonCase = async ({ size, iterations }) => {
  const payload = "x".repeat(size);
  const started = performance.now();
  let rawRequestLength = 0;
  for (let index = 0; index < iterations; index += 1) {
    const ack = await window.benchmarkJsonPayload({ size, payload });
    rawRequestLength = ack.raw_request_length;
  }
  const elapsed = performance.now() - started;
  return {
    elapsed_ms: elapsed,
    per_run_ms: elapsed / iterations,
    raw_request_length: rawRequestLength,
  };
};

const runSharedBufferCase = async ({ size, iterations }, sequenceRef) => {
  const started = performance.now();
  for (let index = 0; index < iterations; index += 1) {
    sequenceRef.value += 1;
    const sequence = sequenceRef.value;
    const wait = waitForSharedBuffer(sequence);
    await Promise.all([
      window.requestSharedBuffer({ size, sequence }),
      wait,
    ]);
  }
  const elapsed = performance.now() - started;
  await window.releaseSharedBuffer();
  return {
    elapsed_ms: elapsed,
    per_run_ms: elapsed / iterations,
  };
};

const formatNumber = (value) =>
  Number.isFinite(value) ? value.toFixed(3) : "n/a";

const addResultRow = (row) => {
  const body = document.getElementById("results");
  if (!body) {
    return;
  }
  const node = document.createElement("tr");
  node.innerHTML = `
    <td>${row.size}</td>
    <td>${row.iterations}</td>
    <td>${formatNumber(row.json.per_run_ms)}</td>
    <td>${row.shared ? formatNumber(row.shared.per_run_ms) : "unsupported"}</td>
    <td>${row.speedup ? `${formatNumber(row.speedup)}x` : "n/a"}</td>
  `;
  body.appendChild(node);
};

const run = async () => {
  text("secure-context", window.isSecureContext);
  text("isolated", window.crossOriginIsolated);
  text("sab", typeof SharedArrayBuffer === "function" ? "available" : "missing");
  if (window.chrome?.webview?.addEventListener) {
    window.chrome.webview.addEventListener(
      "sharedbufferreceived",
      onSharedBufferReceived,
    );
  }
  const capabilities = await window.probeSharedBuffer();
  const sharedSupported =
    capabilities.supported &&
    typeof SharedArrayBuffer === "function" &&
    Boolean(window.chrome?.webview?.addEventListener);
  text(
    "native-shared",
    sharedSupported ? "available" : capabilities.last_error,
  );
  setStatus(
    "running",
    sharedSupported
      ? "Running JSON and SharedBuffer cases..."
      : "Running JSON baseline; native shared buffer is unavailable.",
  );

  const sequenceRef = { value: 0 };
  const results = [];
  for (const benchCase of cases) {
    const json = await runJsonCase(benchCase);
    let shared = null;
    let speedup = null;
    if (sharedSupported) {
      shared = await runSharedBufferCase(benchCase, sequenceRef);
      speedup = json.per_run_ms / shared.per_run_ms;
    }
    const row = {
      size: benchCase.size,
      iterations: benchCase.iterations,
      json,
      shared,
      speedup,
    };
    results.push(row);
    addResultRow(row);
    text("payload", JSON.stringify({ capabilities, results }, null, 2));
  }

  const report = {
    href: window.location.href,
    secure_context: window.isSecureContext,
    cross_origin_isolated: window.crossOriginIsolated,
    shared_array_buffer_available: typeof SharedArrayBuffer === "function",
    capabilities,
    cases: results,
  };
  setStatus("ready", "Benchmark completed.");
  text("payload", JSON.stringify(report, null, 2));
  await window.reportSharedBufferBenchmark(report);
};

window.addEventListener("error", (event) => {
  void reportFailure("window error: " + String(event.message));
});

window.addEventListener("unhandledrejection", (event) => {
  void reportFailure("unhandled rejection: " + String(event.reason));
});

void run().catch((error) => {
  void reportFailure("benchmark failed: " + String(error));
});
