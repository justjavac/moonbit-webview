///|
test "Webview::emit_extension delivers events to JavaScript listeners" {
  let expected_event = ExtensionNoticeEvent::{
    extension: "math",
    name: "computed",
    payload: ExtensionNotice::{ message: "MoonBit extension emitted 42" },
  }
  let mut seen_event : ExtensionNoticeEvent? = None
  let mut js_error : String? = None
  let webview = @webview.Webview::new()
  @runtime.install_extension(webview, @runtime.Extension::new("math", fn(_extension) {  }))
  webview.bind("reportExtensionFailure", fn(id, req) {
    let request_id = @ffi.from_cstr(id)
    let message_result : Result[String, String] = decode_single_argument(req)
    match message_result {
      Ok(message) => js_error = Some(message)
      Err(message) =>
        js_error = Some("Failed to decode extension failure payload: " + message)
    }
    webview.response(request_id, 0, "null")
    webview.terminate()
  })
  webview.bind("reportExtensionEvent", fn(id, req) {
    let request_id = @ffi.from_cstr(id)
    let event_result : Result[ExtensionNoticeEvent, String] = decode_single_argument(
      req,
    )
    match event_result {
      Ok(event) => seen_event = Some(event)
      Err(message) =>
        js_error = Some("Failed to decode extension event payload: " + message)
    }
    webview.response(request_id, 0, "null")
    webview.terminate()
  })
  webview.bind("requestNativeExtensionEvent", fn(id, _req) {
    let request_id = @ffi.from_cstr(id)
    @runtime.emit_extension(webview, "math", "computed", ExtensionNotice::{
      message: "MoonBit extension emitted 42",
    })
    webview.response(request_id, 0, "null")
  })
  webview.set_html(
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
      #|             const moonbit = window.__MoonBit__;
      #|             return !!moonbit && !!moonbit.events;
      #|           },
      #|           () => {
      #|             const moonbit = window.__MoonBit__;
      #|             const timeoutId = window.setTimeout(() => {
      #|               void reportFailure("emit_extension listener timeout");
      #|             }, 1000);
      #|             moonbit.events.on("math.computed", (event) => {
      #|               window.clearTimeout(timeoutId);
      #|               void window.reportExtensionEvent(event).catch(() => {});
      #|             });
      #|             window.setTimeout(() => {
      #|               window.requestNativeExtensionEvent().catch((error) => {
      #|                 window.clearTimeout(timeoutId);
      #|                 void reportFailure("emit_extension transport error: " + String(error));
      #|               });
      #|             }, 0);
      #|           },
      #|           "extension runtime",
      #|         );
      #|       });
      #|     </script>
      #|   </body>
      #| </html>,
    ),
  )
  webview.run()
  assert_eq(seen_event, Some(expected_event))
  assert_eq(js_error, None)
}

///|
test "App::extension_host and App::emit_extension deliver runtime events" {
  let expected_event = ExtensionNoticeEvent::{
    extension: "math",
    name: "computed",
    payload: ExtensionNotice::{ message: "MoonBit app extension emitted 42" },
  }
  let mut seen_event : ExtensionNoticeEvent? = None
  let mut js_error : String? = None
  let config = @runtime.AppConfig::new(
    @runtime.WindowConfig::new("runtime-extension-events", 800, 600),
    @runtime.AppEntry::Html(
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
  let app = @runtime.App::new(config)
  let webview = app.webview()
  app.extension_host().install(@runtime.Extension::new("math", fn(_extension) {  }))
  webview.bind("reportAppExtensionFailure", fn(id, req) {
    let request_id = @ffi.from_cstr(id)
    let message_result : Result[String, String] = decode_single_argument(req)
    match message_result {
      Ok(message) => js_error = Some(message)
      Err(message) =>
        js_error = Some("Failed to decode app extension failure payload: " + message)
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
        js_error = Some("Failed to decode app extension event payload: " + message)
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
  assert_eq(seen_event, Some(expected_event))
  assert_eq(js_error, None)
}

///|
test "panic ExtensionHost::install rejects duplicate extension names" {
  let webview = @webview.Webview::new()
  let host = @runtime.ExtensionHost::new(webview)
  let extension = @runtime.Extension::new("math", fn(_extension) {  })
  host.install(extension)
  host.install(extension)
}

///|
test "panic ExtensionHost::install rejects reserved extension names" {
  let webview = @webview.Webview::new()
  let host = @runtime.ExtensionHost::new(webview)
  host.install(@runtime.Extension::new("@@internal", fn(_extension) {  }))
}

///|
test "panic ExtensionHost::install rejects special JavaScript property names" {
  let webview = @webview.Webview::new()
  let host = @runtime.ExtensionHost::new(webview)
  host.install(@runtime.Extension::new("__proto__", fn(_extension) {  }))
}

///|
test "Extension lifecycle hooks run on install and destroy" {
  let mut installed_extension : String? = None
  let mut destroyed_extension : String? = None
  let webview = @webview.Webview::new()
  @runtime.install_extension(webview, 
    @runtime.Extension::new(
      "math",
      fn(_extension) {  },
      on_install=fn(extension) { installed_extension = Some(extension.name()) },
      on_destroy=fn(extension) { destroyed_extension = Some(extension.name()) },
    ),
  )
  assert_eq(installed_extension, Some("math"))
  assert_eq(destroyed_extension, None)
  @runtime.extension_host(webview).destroy()
  assert_eq(destroyed_extension, Some("math"))
}

///|
test "Webview::extension_host reuses the default host" {
  let webview = @webview.Webview::new()
  let first = @runtime.extension_host(webview)
  first.install(@runtime.Extension::new("math", fn(_extension) {  }))
  let second = @runtime.extension_host(webview)
  second.install(@runtime.Extension::new("stats", fn(_extension) {  }))
}

///|
test "panic ExtensionContext::op rejects reserved API names" {
  let webview = @webview.Webview::new()
  let host = @runtime.ExtensionHost::new(webview)
  host.install(
    @runtime.Extension::new("math", fn(extension) {
      extension.op("@@on", fn(payload : Json) { payload })
    }),
  )
}

///|
test "panic ExtensionContext::op rejects special JavaScript property names" {
  let webview = @webview.Webview::new()
  let host = @runtime.ExtensionHost::new(webview)
  host.install(
    @runtime.Extension::new("math", fn(extension) {
      extension.op("constructor", fn(payload : Json) { payload })
    }),
  )
}

///|
test "panic ExtensionContext::op rejects duplicate APIs" {
  let webview = @webview.Webview::new()
  let host = @runtime.ExtensionHost::new(webview)
  host.install(
    @runtime.Extension::new("math", fn(extension) {
      extension.op("identity", fn(payload : Json) { payload })
      extension.op("identity", fn(payload : Json) { payload })
    }),
  )
}



