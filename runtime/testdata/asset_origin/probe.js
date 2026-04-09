const reportFailure = (message) =>
  window.reportAssetOriginFailure(message).catch(() => {});

window.addEventListener("error", (event) => {
  void reportFailure("window error: " + String(event.message));
});

window.addEventListener("unhandledrejection", (event) => {
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
  await window.reportAssetOriginResult(result);
};

void report().catch((error) => {
  void reportFailure("probe transport error: " + String(error));
});
