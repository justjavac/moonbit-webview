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
- MoonBit generates the reusable bulk payload and checksum. The native channel
  layer copies those bytes into a reusable WebView2 shared buffer, posts it to
  JS, and JS receives it through `chrome.webview`'s `sharedbufferreceived`
  event.
- JS verifies the shared buffer byte length and checksum, then releases it with
  `chrome.webview.releaseBuffer(...)`.
- The scalar `sum(x, y)` benchmark compares an optimized JSON bind call with a
  read-write WebView2 SharedBuffer command buffer.

The prototype keeps the newer WebView2 COM ABI local to
`shared_buffer_benchmark_windows.c`. The vendored WebView2 header currently
does not expose these newer interfaces, so this example deliberately avoids
turning the experiment into a public Lepus API yet.

## Scalar Sum Flow

The current bind mechanism is asynchronous, so the JavaScript shape is
effectively `let s = await sum(x, y)`.

For the JSON path:

1. JS calls `window.sumJson(x, y)`.
2. The bind wrapper serializes the arguments as a compact JSON argument array.
3. MoonBit receives the request id and raw JSON request in
   `webview.bind("sumJson", ...)`.
4. MoonBit decodes the two integers, calls the MoonBit `sum(x, y)` function,
   and responds with a numeric JSON result.
5. The JS promise resolves to the number.

For the SharedBuffer path:

1. JS calls `window.prepareSharedSumBuffer()` once.
2. Native creates one 64-byte WebView2 SharedBuffer with read-write access and
   posts it to JS.
3. JS keeps a `DataView` over that buffer.
4. For each call, JS writes `x` and `y` as little-endian `Int32` values at
   offsets 0 and 4, then calls `window.sumSharedBuffer()` with no arguments.
5. MoonBit does not decode per-call arguments for this path. It asks the native
   channel layer to read `x` and `y` from the shared buffer, calls the same
   MoonBit `sum(x, y)` function, then asks the channel layer to write the result
   at offset 8.
6. MoonBit returns a constant acknowledgement. After the promise resolves, JS
   reads the result from offset 8.

This is a single-lane prototype. Concurrent calls would need a sequence field,
ownership rules, or a ring buffer with explicit synchronization.

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

### Scalar Sum

For scalar `sum(x, y)`, both paths are highly optimized:

- JSON uses positional numeric arguments and a numeric response, not request or
  response objects.
- SharedBuffer uses a pre-posted read-write command buffer and sends no x/y data
  in the hot-path JSON control message.

Five-run averages on the development machine:

| Mode | Calls/run | JSON bind ms/call | SharedBuffer ms/call | Speedup |
| ---- | --------: | ----------------: | -------------------: | ------: |
| debug native | 5000 | 0.169 | 0.149 | 1.13x |
| release native | 5000 | 0.164 | 0.150 | 1.09x |

The scalar result is intentionally modest. For an 8-byte input and 4-byte
output, JSON serialization is no longer the dominant cost. The remaining cost
is mostly the asynchronous WebView bind round trip, promise scheduling, and
native callback dispatch. SharedBuffer still wins slightly because x/y avoid
per-call JSON decoding, but it pays native channel reads/writes and cannot
remove the RPC boundary.

### Bulk Payload

These numbers are the average of five debug/native runs on the same development
machine after moving bulk payload generation into MoonBit:

| Payload | Runs | JSON bridge ms/run | SharedBuffer ms/run | Speedup |
| -------: | ---: | -----------------: | ------------------: | ------: |
| 64 bytes | 500 | 0.192 | 0.214 | 0.90x |
| 1024 bytes | 300 | 0.315 | 0.213 | 1.48x |
| 16384 bytes | 150 | 2.530 | 0.359 | 7.05x |
| 65536 bytes | 80 | 22.738 | 1.609 | 14.13x |
| 262144 bytes | 20 | 83.253 | 4.562 | 18.25x |
| 1048576 bytes | 10 | 333.450 | 16.440 | 20.28x |
| 4194304 bytes | 4 | 1366.085 | 61.332 | 22.27x |

The JSON baseline sends a large string through the current `webview.bind(...)`
path and decodes it on the MoonBit side. The SharedBuffer path uses JSON only
for control messages; MoonBit generates the bulk bytes as `Bytes`, the native
channel layer copies them into a WebView2 shared buffer, and WebView2 delivers
that shared buffer to JavaScript without serializing the payload as JSON.

The optimized prototype reuses one native shared buffer per active capacity, so
tiny payloads no longer pay `CreateSharedBuffer(...)` on every iteration. The
remaining fixed cost is mostly MoonBit payload generation, the MoonBit-to-native
buffer copy, the binding request, WebView2 shared-buffer event delivery, Promise
scheduling, checksum validation, and JS-side `releaseBuffer(...)`.

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

This prototype proves that native-to-JS shared-buffer delivery and a single-lane
read-write command buffer for JS-to-MoonBit scalar arguments are viable on
WebView2 runtimes that expose `ICoreWebView2_17` and
`ICoreWebView2Environment12`. Because MoonBit does not yet have a direct view
over WebView2 shared-buffer memory in this prototype, the MoonBit bulk path
still copies from MoonBit `Bytes` into the native shared buffer before posting.
A production design can keep JSON for control messages, and move large byte
payloads through shared buffers identified by a buffer id, offset, and length.

## Follow-Up Work

- Upgrade or vendor a WebView2 SDK header that exposes SharedBuffer interfaces
  directly.
- Move the COM ABI out of this example and into a Windows runtime/native module.
- Expose a MoonBit-side writable view over shared-buffer memory, so MoonBit can
  fill the WebView2 buffer directly instead of generating `Bytes` and copying.
- Turn the read-write command-buffer prototype into a production protocol with
  sequence numbers, ownership, and concurrency rules.
- Define lifetime rules for shared buffers, including release, reuse, and
  window teardown behavior.
- Add release-mode and repeated-run benchmarks before treating the exact ratios
  as product numbers.
