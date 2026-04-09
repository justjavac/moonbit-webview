///|
test "App::extension_host and App::emit_extension deliver runtime events" {
  let expected_event = ExtensionNoticeEvent::{
    extension: "math",
    name: "computed",
    payload: ExtensionNotice::{ message: "MoonBit app extension emitted 42" },
  }
  let mut seen_event : ExtensionNoticeEvent? = None
  let mut js_error : String? = None
  let config = @lepus_runtime.AppConfig::new(
    @lepus_runtime.WindowConfig::new("runtime-extension-events", 800, 600),
    @lepus_runtime.AppEntry::Html(
      (
        #| <html>
        #|   <body>
        #|     <script>
        #|       const reportFailure = (message) =>
        #|         window.reportAppExtensionFailure(message).catch(() => {});
        #|       const waitFor = (predicate, onReady, label, attempts = 0) => {
        #|         if (predicate()) {
        #|           onReady();
        #|           return;
        #|         }
        #|         if (attempts >= 50) {
        #|           void reportFailure(label + " timeout");
        #|           return;
        #|         }
        #|         window.setTimeout(() => {
        #|           waitFor(predicate, onReady, label, attempts + 1);
        #|         }, 20);
        #|       };
        #|       window.addEventListener("error", (event) => {
        #|         void reportFailure("window error: " + String(event.message));
        #|       });
        #|       window.addEventListener("unhandledrejection", (event) => {
        #|         void reportFailure("unhandled rejection: " + String(event.reason));
        #|       });
        #|       window.addEventListener("load", () => {
        #|         waitFor(
        #|           () => {
        #|             const moonbit = window.__MoonBit__;
        #|             return !!moonbit && !!moonbit.math && !!moonbit.events;
        #|           },
        #|           () => {
        #|             const moonbit = window.__MoonBit__;
        #|             const timeoutId = window.setTimeout(() => {
        #|               void reportFailure("app emit_extension listener timeout");
        #|             }, 1000);
        #|             moonbit.events.on("math.computed", (event) => {
        #|               window.clearTimeout(timeoutId);
        #|               void window.reportAppExtensionEvent(event).catch(() => {});
        #|             });
        #|             window.setTimeout(() => {
        #|               window.requestNativeAppExtensionEvent().catch((error) => {
        #|                 window.clearTimeout(timeoutId);
        #|                 void reportFailure("app emit_extension transport error: " + String(error));
        #|               });
        #|             }, 0);
        #|           },
        #|           "app extension runtime",
        #|         );
        #|       });
        #|     </script>
        #|   </body>
        #| </html>,
      ),
    ),
  )
  let app = @lepus_runtime.App::new(config)
  let webview = app.webview()
  @core.extension_host(app.webview()).install(
    @core.Extension::new("tests/math", "math", fn(_extension) {  }),
  )
  webview.bind("reportAppExtensionFailure", fn(id, req) {
    let request_id = @ffi.from_cstr(id)
    let message_result : Result[String, String] = decode_single_argument(req)
    match message_result {
      Ok(message) => js_error = Some(message)
      Err(message) =>
        js_error = Some(
          "Failed to decode app extension failure payload: " + message,
        )
    }
    webview.response(request_id, 0, "null")
    webview.terminate()
  })
  webview.bind("reportAppExtensionEvent", fn(id, req) {
    let request_id = @ffi.from_cstr(id)
    let event_result : Result[ExtensionNoticeEvent, String] = decode_single_argument(
      req,
    )
    match event_result {
      Ok(event) => seen_event = Some(event)
      Err(message) =>
        js_error = Some(
          "Failed to decode app extension event payload: " + message,
        )
    }
    webview.response(request_id, 0, "null")
    webview.terminate()
  })
  webview.bind("requestNativeAppExtensionEvent", fn(id, _req) {
    let request_id = @ffi.from_cstr(id)
    app.emit_extension("math", "computed", ExtensionNotice::{
      message: "MoonBit app extension emitted 42",
    })
    webview.response(request_id, 0, "null")
  })
  app.run()
  assert_true(seen_event == Some(expected_event))
  assert_eq(js_error, None)
}

///|
test "App runtime exposes __MoonBit__ extensions before page load" {
  let expected_response = MultiplyReply::{ total: 42 }
  let expected_event = ExtensionNoticeEvent::{
    extension: "math",
    name: "computed",
    payload: ExtensionNotice::{ message: "MoonBit computed 42" },
  }
  let mut seen_response : MultiplyReply? = None
  let mut seen_event : ExtensionNoticeEvent? = None
  let mut js_error : String? = None
  let config = @lepus_runtime.AppConfig::new(
    @lepus_runtime.WindowConfig::new("runtime-extension", 800, 600),
    @lepus_runtime.AppEntry::Html(
      (
        #| <html>
        #|   <body>
        #|     <script>
        #|       const reportFailure = (message) =>
        #|         window.reportExtensionFailure(message).catch(() => {});
        #|       const waitFor = (predicate, onReady, label, attempts = 0) => {
        #|         if (predicate()) {
        #|           onReady();
        #|           return;
        #|         }
        #|         if (attempts >= 50) {
        #|           void reportFailure(label + " timeout");
        #|           return;
        #|         }
        #|         window.setTimeout(() => {
        #|           waitFor(predicate, onReady, label, attempts + 1);
        #|         }, 20);
        #|       };
        #|       window.addEventListener("error", (event) => {
        #|         void reportFailure("window error: " + String(event.message));
        #|       });
        #|       window.addEventListener("unhandledrejection", (event) => {
        #|         void reportFailure("unhandled rejection: " + String(event.reason));
        #|       });
        #|       window.addEventListener("load", () => {
        #|         waitFor(
        #|           () => {
        #|             const app = window.__MoonBit__;
        #|             return !!app && !!app.math;
        #|           },
        #|           () => {
        #|             const app = window.__MoonBit__;
        #|             app.events.on("math.computed", (event) => {
        #|               void window.reportExtensionEvent(event).catch(() => {});
        #|             });
        #|             app.math
        #|               .multiply({ left: 6, right: 7 })
        #|               .then((response) =>
        #|                 window.reportExtensionResponse(response).catch(() => {}))
        #|               .catch((error) => {
        #|                 void reportFailure("runtime extension transport error: " + String(error));
        #|               });
        #|           },
        #|           "runtime extension",
        #|         );
        #|       });
        #|     </script>
        #|   </body>
        #| </html>,
      ),
    ),
  )
  let app = @lepus_runtime.App::new(config)
  let webview = app.webview()
  let finish = fn() {
    if seen_response is Some(_) && seen_event is Some(_) {
      webview.terminate()
    }
  }
  app.install_extension(
    @core.Extension::new("tests/math", "math", fn(extension) {
      extension.op("multiply", fn(payload : MultiplyPayload) {
        let reply = MultiplyReply::{ total: payload.left * payload.right }
        extension.emit("computed", ExtensionNotice::{
          message: "MoonBit computed " + reply.total.to_string(),
        })
        reply
      })
    }),
  )
  webview.bind("reportExtensionFailure", fn(id, req) {
    let request_id = @ffi.from_cstr(id)
    let message_result : Result[String, String] = decode_single_argument(req)
    match message_result {
      Ok(message) => js_error = Some(message)
      Err(message) =>
        js_error = Some(
          "Failed to decode runtime extension failure payload: " + message,
        )
    }
    webview.response(request_id, 0, "null")
    webview.terminate()
  })
  webview.bind("reportExtensionResponse", fn(id, req) {
    let request_id = @ffi.from_cstr(id)
    let response_result : Result[MultiplyReply, String] = decode_single_argument(
      req,
    )
    match response_result {
      Ok(response) => {
        seen_response = Some(response)
        finish()
      }
      Err(message) => {
        js_error = Some(
          "Failed to decode runtime extension response payload: " + message,
        )
        webview.terminate()
      }
    }
    webview.response(request_id, 0, "null")
  })
  webview.bind("reportExtensionEvent", fn(id, req) {
    let request_id = @ffi.from_cstr(id)
    let event_result : Result[ExtensionNoticeEvent, String] = decode_single_argument(
      req,
    )
    match event_result {
      Ok(event) => {
        seen_event = Some(event)
        finish()
      }
      Err(message) => {
        js_error = Some(
          "Failed to decode runtime extension event payload: " + message,
        )
        webview.terminate()
      }
    }
    webview.response(request_id, 0, "null")
  })
  app.run()
  assert_true(seen_response == Some(expected_response))
  assert_true(seen_event == Some(expected_event))
  assert_eq(js_error, None)
}

///|
test "__MoonBit__ root exposes consolidated extension runtime surfaces" {
  let expected_report = AppRuntimeHelperReport::{
    via_invoke: MultiplyReply::{ total: 42 },
    via_method: MultiplyReply::{ total: 42 },
    via_core: MultiplyReply::{ total: 42 },
    event_count: 3,
  }
  let mut seen_report : AppRuntimeHelperReport? = None
  let mut js_error : String? = None
  let config = @lepus_runtime.AppConfig::new(
    @lepus_runtime.WindowConfig::new("runtime-app-helpers", 800, 600),
    @lepus_runtime.AppEntry::Html(
      (
        #| <html>
        #|   <body>
        #|     <script>
        #|       const reportFailure = (message) =>
        #|         window.reportAppHelperFailure(message).catch(() => {});
        #|       const waitFor = (predicate, onReady, label, attempts = 0) => {
        #|         if (predicate()) {
        #|           onReady();
        #|           return;
        #|         }
        #|         if (attempts >= 50) {
        #|           void reportFailure(label + " timeout");
        #|           return;
        #|         }
        #|         window.setTimeout(() => {
        #|           waitFor(predicate, onReady, label, attempts + 1);
        #|         }, 20);
        #|       };
        #|       window.addEventListener("error", (event) => {
        #|         void reportFailure("window error: " + String(event.message));
        #|       });
        #|       window.addEventListener("unhandledrejection", (event) => {
        #|         void reportFailure("unhandled rejection: " + String(event.reason));
        #|       });
        #|       window.addEventListener("load", () => {
        #|         waitFor(
        #|           () => {
        #|             const app = window.__MoonBit__;
        #|             return !!app &&
        #|               !!app.events &&
        #|               !!app.core?.ops &&
        #|               !!app.math;
        #|           },
        #|           () => {
        #|             const app = window.__MoonBit__;
        #|             const math = app.math;
        #|             let eventCount = 0;
        #|             let results = null;
        #|             const maybeFinish = () => {
        #|               if (!results || eventCount !== 3) {
        #|                 return;
        #|               }
        #|               void window.reportAppHelperReport({
        #|                 via_invoke: results.viaInvoke,
        #|                 via_method: results.viaMethod,
        #|                 via_core: results.viaCore,
        #|                 event_count: eventCount,
        #|               }).catch(() => {});
        #|             };
        #|             math.on("computed", () => {
        #|               eventCount += 1;
        #|               maybeFinish();
        #|             });
        #|             Promise.all([
        #|               math.invoke("multiply", { left: 6, right: 7 }),
        #|               math.multiply({ left: 6, right: 7 }),
        #|               app.core.invokeOp("ext:math/multiply", { left: 6, right: 7 }),
        #|             ])
        #|               .then(([viaInvoke, viaMethod, viaCore]) => {
        #|                 results = { viaInvoke, viaMethod, viaCore };
        #|                 maybeFinish();
        #|               })
        #|               .catch((error) => {
        #|                 void reportFailure("app helper transport error: " + String(error));
        #|               });
        #|           },
        #|           "__MoonBit__ consolidated helpers",
        #|         );
        #|       });
        #|     </script>
        #|   </body>
        #| </html>,
      ),
    ),
  )
  let app = @lepus_runtime.App::new(config)
  let webview = app.webview()
  app.install_extension(
    @core.Extension::new("tests/math", "math", fn(extension) {
      extension.op("multiply", fn(payload : MultiplyPayload) {
        let reply = MultiplyReply::{ total: payload.left * payload.right }
        extension.emit("computed", ExtensionNotice::{
          message: "MoonBit computed " + reply.total.to_string(),
        })
        reply
      })
    }),
  )
  webview.bind("reportAppHelperFailure", fn(id, req) {
    let request_id = @ffi.from_cstr(id)
    let message_result : Result[String, String] = decode_single_argument(req)
    match message_result {
      Ok(message) => js_error = Some(message)
      Err(message) =>
        js_error = Some(
          "Failed to decode app helper failure payload: " + message,
        )
    }
    webview.response(request_id, 0, "null")
    webview.terminate()
  })
  webview.bind("reportAppHelperReport", fn(id, req) {
    let request_id = @ffi.from_cstr(id)
    let report_result : Result[AppRuntimeHelperReport, String] = decode_single_argument(
      req,
    )
    match report_result {
      Ok(report) => seen_report = Some(report)
      Err(message) =>
        js_error = Some(
          "Failed to decode app helper report payload: " + message,
        )
    }
    webview.response(request_id, 0, "null")
    webview.terminate()
  })
  app.run()
  assert_true(seen_report == Some(expected_report))
  assert_eq(js_error, None)
}
