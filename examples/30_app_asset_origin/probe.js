const reportFailure = (message) =>
  window.reportAssetOriginFailure(message).catch(() => {});

const setText = (id, value) => {
  const node = document.getElementById(id);
  if (node) {
    node.textContent = String(value);
  }
};

const setStatus = (className, message) => {
  const panel = document.getElementById("probe-panel");
  if (panel) {
    panel.classList.remove("ready", "failed");
    panel.classList.add(className);
  }
  setText("status-text", message);
};

const renderReport = (result) => {
  setStatus("ready", "Probe completed. Window will stay open.");
  setText("href", result.href);
  setText("origin", result.origin);
  setText("secure-context", result.is_secure_context);
  setText("cross-origin-isolated", result.cross_origin_isolated);
  setText(
    "shared-array-buffer",
    `${result.shared_array_buffer_type}, length=${result.shared_array_buffer_length ?? "n/a"}`,
  );
  setText("payload", JSON.stringify(result, null, 2));
};

const renderFailure = (message) => {
  setStatus("failed", "Probe failed. Window will stay open for inspection.");
  setText("payload", message);
};

window.addEventListener("error", (event) => {
  renderFailure(String(event.message));
  void reportFailure("window error: " + String(event.message));
});

window.addEventListener("unhandledrejection", (event) => {
  renderFailure(String(event.reason));
  void reportFailure("unhandled rejection: " + String(event.reason));
});

const report = async () => {
  const result = {
    href: window.location.href,
    origin: window.location.origin,
    is_secure_context: window.isSecureContext,
    cross_origin_isolated: window.crossOriginIsolated,
    shared_array_buffer_type: typeof SharedArrayBuffer,
    shared_array_buffer_length: null,
  };
  if (typeof SharedArrayBuffer === "function") {
    result.shared_array_buffer_length = new SharedArrayBuffer(16).byteLength;
  }
  renderReport(result);
  await window.reportAssetOriginResult(result);
};

void report().catch((error) => {
  renderFailure(String(error));
  void reportFailure("probe transport error: " + String(error));
});
