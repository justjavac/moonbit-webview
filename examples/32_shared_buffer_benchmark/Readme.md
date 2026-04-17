# SharedBuffer Benchmark

This example is a Windows/WebView2 prototype for validating whether Lepus can
move bulk binary data between native code and JavaScript through WebView2 shared
buffers instead of the current JSON binding path.

Run it with:

```sh
moon -C examples run 32_shared_buffer_benchmark --target native
```

The page prints a final JSON report to the native console and then closes the
window.

## What It Validates

- The app entry is served through `AppEntry::Asset(...)`, so the page runs on
  the secure `https://app.localhost/` asset origin.
- The page checks `window.isSecureContext`, `window.crossOriginIsolated`, and
  `SharedArrayBuffer` availability.
- The native stub probes the current WebView2 runtime for:
  - `ICoreWebView2_17`
  - `ICoreWebView2Environment12`
  - `ICoreWebView2Environment12::CreateSharedBuffer(...)`
  - `ICoreWebView2_17::PostSharedBufferToScript(...)`
- The native side allocates and fills a WebView2 shared buffer, posts it to JS,
  and JS receives it through `chrome.webview`'s `sharedbufferreceived` event.
- JS verifies the shared buffer byte length and checksum, then releases it with
  `chrome.webview.releaseBuffer(...)`.

The prototype keeps the newer WebView2 COM ABI local to
`shared_buffer_benchmark_windows.c`. The vendored WebView2 header currently
does not expose these newer interfaces, so this example deliberately avoids
turning the experiment into a public Lepus API yet.

## Verification Result

On the development machine used for this prototype, the SharedBuffer path was
available:

```json
{
  "is_windows": true,
  "has_controller": true,
  "has_core_webview": true,
  "has_webview2_17": true,
  "has_environment12": true,
  "can_create_shared_buffer": true,
  "supported": true,
  "last_error": "ok"
}
```

The page also reported:

```json
{
  "href": "https://app.localhost/",
  "secure_context": true,
  "cross_origin_isolated": true,
  "shared_array_buffer_available": true
}
```

## Performance Result

These numbers came from a debug/native run on the same development machine:

| Payload | Runs | JSON bridge ms/run | SharedBuffer ms/run | Speedup |
| -------: | ---: | -----------------: | ------------------: | ------: |
| 262144 bytes | 20 | 49.810 | 2.800 | 17.79x |
| 1048576 bytes | 10 | 247.763 | 4.331 | 57.21x |
| 4194304 bytes | 4 | 1180.166 | 16.019 | 73.67x |

The JSON baseline sends a large string through the current `webview.bind(...)`
path and decodes it on the MoonBit side. The SharedBuffer path uses JSON only
for control messages; the bulk bytes are written into a native shared buffer and
delivered to JavaScript without serializing the payload as JSON.

This benchmark is intentionally small and directional rather than final. The
two paths do not perform exactly the same work: the SharedBuffer path includes a
JS checksum pass over the received bytes, while the JSON baseline exercises the
current bridge's serialization and parse costs. The result is still enough to
show that large binary payloads should not use the JSON bridge as their data
plane.

## Current Conclusion

The current project does not yet provide a formal SharedArrayBuffer or WebView2
SharedBuffer communication layer. Existing usage before this example was limited
to availability probes in asset-origin examples.

This prototype proves that the native-to-JS half of the zero-copy direction is
viable on WebView2 runtimes that expose `ICoreWebView2_17` and
`ICoreWebView2Environment12`. A production design can keep JSON for control
messages, and move large byte payloads through shared buffers identified by a
buffer id, offset, and length.

## Follow-Up Work

- Upgrade or vendor a WebView2 SDK header that exposes SharedBuffer interfaces
  directly.
- Move the COM ABI out of this example and into a Windows runtime/native module.
- Add a read-write shared-buffer mode for JS-to-native data flow.
- Define lifetime rules for shared buffers, including release, reuse, and
  window teardown behavior.
- Add release-mode and repeated-run benchmarks before treating the exact ratios
  as product numbers.
