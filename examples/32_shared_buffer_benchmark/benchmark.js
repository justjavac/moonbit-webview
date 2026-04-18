const cases = [
  { size: 64, iterations: 500 },
  { size: 1024, iterations: 300 },
  { size: 16 * 1024, iterations: 150 },
  { size: 64 * 1024, iterations: 80 },
  { size: 256 * 1024, iterations: 20 },
  { size: 1024 * 1024, iterations: 10 },
  { size: 4 * 1024 * 1024, iterations: 4 },
];

const sumCase = { iterations: 5000, warmup: 100 };
const SUM_BUFFER_BYTES = 64;
const SUM_X_OFFSET = 0;
const SUM_Y_OFFSET = 4;
const SUM_RESULT_OFFSET = 8;

const pendingBuffers = new Map();
let pendingSumBuffer = null;
let sumBuffer = null;
let sumView = null;

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

const checksumBytes = (buffer, length) => {
  const view = new Uint8Array(buffer, 0, length);
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

const sumInputs = (index) => ({
  x: (index * 17 + 12345) % 1_000_000,
  y: (index * 31 + 67890) % 1_000_000,
});

const onSharedBufferReceived = (event) => {
  const data = normalizeAdditionalData(event.additionalData);
  if (data.kind === "lepus-sum-buffer") {
    let buffer = null;
    try {
      buffer = event.getBuffer();
      if (buffer.byteLength < SUM_BUFFER_BYTES) {
        throw new Error(
          `Shared sum buffer is too small: expected ${SUM_BUFFER_BYTES}, got ${buffer.byteLength}`,
        );
      }
      if (!pendingSumBuffer) {
        return;
      }
      if (sumBuffer) {
        releaseBuffer(sumBuffer);
      }
      sumBuffer = buffer;
      sumView = new DataView(sumBuffer);
      buffer = null;
      pendingSumBuffer.resolve();
      pendingSumBuffer = null;
    } catch (error) {
      if (pendingSumBuffer) {
        pendingSumBuffer.reject(error);
        pendingSumBuffer = null;
      } else {
        throw error;
      }
    } finally {
      if (buffer) {
        releaseBuffer(buffer);
      }
    }
    return;
  }

  const sequence = Number(data.sequence);
  const waiter = pendingBuffers.get(sequence);
  if (!waiter) {
    return;
  }
  pendingBuffers.delete(sequence);
  let buffer = null;
  try {
    buffer = event.getBuffer();
    const logicalSize = Number(data.size);
    const expectedCapacity = Number(data.capacity ?? buffer.byteLength);
    if (buffer.byteLength < logicalSize) {
      throw new Error(
        `SharedBuffer length mismatch for #${sequence}: expected at least ${logicalSize}, got ${buffer.byteLength}`,
      );
    }
    if (buffer.byteLength !== expectedCapacity) {
      throw new Error(
        `SharedBuffer capacity mismatch for #${sequence}: expected ${expectedCapacity}, got ${buffer.byteLength}`,
      );
    }
    const checksum = checksumBytes(buffer, logicalSize);
    if (checksum !== Number(data.checksum)) {
      throw new Error(
        `SharedBuffer checksum mismatch for #${sequence}: expected ${data.checksum}, got ${checksum}`,
      );
    }
    waiter.resolve({
      sequence,
      size: logicalSize,
      capacity: buffer.byteLength,
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

const waitForSumBuffer = () =>
  new Promise((resolve, reject) => {
    const timeout = window.setTimeout(() => {
      pendingSumBuffer = null;
      reject(new Error("Timed out waiting for shared sum buffer"));
    }, 5000);
    pendingSumBuffer = {
      resolve: () => {
        window.clearTimeout(timeout);
        resolve();
      },
      reject: (error) => {
        window.clearTimeout(timeout);
        reject(error);
      },
    };
  });

const prepareSharedSumBuffer = async () => {
  const wait = waitForSumBuffer();
  try {
    await Promise.all([window.prepareSharedSumBuffer(), wait]);
  } catch (error) {
    pendingSumBuffer = null;
    throw error;
  }
};

const releaseSumBuffer = () => {
  if (sumBuffer) {
    releaseBuffer(sumBuffer);
    sumBuffer = null;
    sumView = null;
  }
};

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

const runJsonSumCase = async ({ iterations, warmup }) => {
  for (let index = 0; index < warmup; index += 1) {
    const { x, y } = sumInputs(index);
    await window.sumJson(x, y);
  }

  const started = performance.now();
  let checksum = 0;
  for (let index = 0; index < iterations; index += 1) {
    const { x, y } = sumInputs(index);
    const expected = x + y;
    const result = await window.sumJson(x, y);
    if (result !== expected) {
      throw new Error(`JSON sum mismatch: expected ${expected}, got ${result}`);
    }
    checksum = (checksum + (result >>> 0)) >>> 0;
  }
  const elapsed = performance.now() - started;
  return {
    elapsed_ms: elapsed,
    per_run_ms: elapsed / iterations,
    checksum,
  };
};

const runSharedSumCase = async ({ iterations, warmup }) => {
  if (!sumView) {
    throw new Error("Shared sum buffer is not prepared");
  }

  for (let index = 0; index < warmup; index += 1) {
    const { x, y } = sumInputs(index);
    sumView.setInt32(SUM_X_OFFSET, x, true);
    sumView.setInt32(SUM_Y_OFFSET, y, true);
    await window.sumSharedBuffer();
  }

  const started = performance.now();
  let checksum = 0;
  for (let index = 0; index < iterations; index += 1) {
    const { x, y } = sumInputs(index);
    const expected = x + y;
    sumView.setInt32(SUM_X_OFFSET, x, true);
    sumView.setInt32(SUM_Y_OFFSET, y, true);
    await window.sumSharedBuffer();
    const result = sumView.getInt32(SUM_RESULT_OFFSET, true);
    if (result !== expected) {
      throw new Error(
        `SharedBuffer sum mismatch: expected ${expected}, got ${result}`,
      );
    }
    checksum = (checksum + (result >>> 0)) >>> 0;
  }
  const elapsed = performance.now() - started;
  return {
    elapsed_ms: elapsed,
    per_run_ms: elapsed / iterations,
    checksum,
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

const addSumResultRow = (name, iterations, result) => {
  const body = document.getElementById("sum-results");
  if (!body) {
    return;
  }
  const node = document.createElement("tr");
  node.innerHTML = `
    <td>${name}</td>
    <td>${iterations}</td>
    <td>${formatNumber(result.per_run_ms)}</td>
    <td>${result.checksum}</td>
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
      ? "Running scalar sum and bulk payload cases..."
      : "Running JSON baselines; native shared buffer is unavailable.",
  );

  const sumResults = {
    iterations: sumCase.iterations,
    warmup: sumCase.warmup,
    json: await runJsonSumCase(sumCase),
    shared: null,
    speedup: null,
  };
  addSumResultRow("JSON bind", sumCase.iterations, sumResults.json);
  if (sharedSupported) {
    await prepareSharedSumBuffer();
    sumResults.shared = await runSharedSumCase(sumCase);
    sumResults.speedup =
      sumResults.json.per_run_ms / sumResults.shared.per_run_ms;
    addSumResultRow(
      `SharedBuffer (${formatNumber(sumResults.speedup)}x)`,
      sumCase.iterations,
      sumResults.shared,
    );
  }

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
    text(
      "payload",
      JSON.stringify({ capabilities, sumResults, results }, null, 2),
    );
  }
  releaseSumBuffer();
  if (sharedSupported) {
    await window.releaseSharedBuffer();
  }

  const report = {
    href: window.location.href,
    secure_context: window.isSecureContext,
    cross_origin_isolated: window.crossOriginIsolated,
    shared_array_buffer_available: typeof SharedArrayBuffer === "function",
    capabilities,
    sum: sumResults,
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
