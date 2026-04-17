const reportFailure = (message) =>
  window.reportAssetBundleFailure(message).catch(() => {});

const text = (id, value) => {
  const node = document.getElementById(id);
  if (node) {
    node.textContent = String(value);
  }
};

const setStatus = (state, message) => {
  const card = document.getElementById("status-card");
  if (card) {
    card.dataset.state = state;
  }
  text("status-text", message);
};

const isStylesheetLoaded = () => {
  const marker = getComputedStyle(document.documentElement)
    .getPropertyValue("--asset-bundle-loaded")
    .trim();
  return marker === "yes";
};

const runProbe = async () => {
  const sharedBuffer =
    typeof SharedArrayBuffer === "function" ? new SharedArrayBuffer(32) : null;
  const probe = {
    href: window.location.href,
    origin: window.location.origin,
    script_loaded: true,
    stylesheet_loaded: isStylesheetLoaded(),
    secure_context: window.isSecureContext,
    cross_origin_isolated: window.crossOriginIsolated,
    shared_array_buffer_length: sharedBuffer?.byteLength ?? null,
  };

  text("href", probe.href);
  text("origin", probe.origin);
  text("script-loaded", probe.script_loaded);
  text("stylesheet-loaded", probe.stylesheet_loaded);
  text("secure-context", probe.secure_context);
  text("cross-origin-isolated", probe.cross_origin_isolated);
  text(
    "shared-array-buffer",
    probe.shared_array_buffer_length === null
      ? "unavailable"
      : `${probe.shared_array_buffer_length} bytes`,
  );
  text("payload", JSON.stringify(probe, null, 2));
  setStatus("ready", "Bundle loaded. Window stays open for inspection.");

  await window.reportAssetBundleProbe(probe);
};

window.addEventListener("error", (event) => {
  const message = `window error: ${String(event.message)}`;
  setStatus("failed", message);
  void reportFailure(message);
});

window.addEventListener("unhandledrejection", (event) => {
  const message = `unhandled rejection: ${String(event.reason)}`;
  setStatus("failed", message);
  void reportFailure(message);
});

void runProbe().catch((error) => {
  const message = `probe transport error: ${String(error)}`;
  setStatus("failed", message);
  void reportFailure(message);
});
