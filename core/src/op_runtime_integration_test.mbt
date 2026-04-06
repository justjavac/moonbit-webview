///|
test "__MoonBit__ core ops expose extension APIs into JavaScript" {
  let expected_report = OpsRuntimeReport::{
    direct: MultiplyReply::{ total: 42 },
    extension: MultiplyReply::{ total: 42 },
    event_count: 2,
  }
  let mut seen_report : OpsRuntimeReport? = None
  let mut js_error : String? = None
  let webview = @webview.Webview::new()
  @lepus_core.install_extension(
    webview,
    @lepus_core.Extension::new("tests/math", "math", fn(extension) {
      extension.op("multiply", fn(payload : MultiplyPayload) {
        let reply = MultiplyReply::{ total: payload.left * payload.right }
        extension.emit("computed", ExtensionNotice::{
          message: "MoonBit computed " + reply.total.to_string(),
        })
        reply
      })
    }),
  )
  webview.bind("reportOpsFailure", fn(id, req) {
    let request_id = @ffi.from_cstr(id)
    let message_result : Result[String, String] = decode_single_argument(req)
    match message_result {
      Ok(message) => js_error = Some(message)
      Err(message) =>
        js_error = Some("Failed to decode ops failure payload: " + message)
    }
    webview.response(request_id, 0, "null")
    webview.terminate()
  })
  webview.bind("reportOpsRuntime", fn(id, req) {
    let request_id = @ffi.from_cstr(id)
    let report_result : Result[OpsRuntimeReport, String] = decode_single_argument(
      req,
    )
    match report_result {
      Ok(report) => seen_report = Some(report)
      Err(message) =>
        js_error = Some("Failed to decode ops runtime report: " + message)
    }
    webview.response(request_id, 0, "null")
    webview.terminate()
  })
  webview.set_html(
    (
      #| <html>
      #|   <body>
      #|     <script>
      #|       const reportFailure = (message) =>
      #|         window.reportOpsFailure(message).catch(() => {});
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
      #|             return !!moonbit && !!moonbit.math && !!moonbit.core?.ops;
      #|           },
      #|           () => {
      #|             const moonbit = window.__MoonBit__;
      #|             let eventCount = 0;
      #|             let results = null;
      #|             const timeoutId = window.setTimeout(() => {
      #|               void reportFailure("ops report timeout");
      #|             }, 1000);
      #|             const maybeFinish = () => {
      #|               if (!results || eventCount !== 2) {
      #|                 return;
      #|               }
      #|               window.reportOpsRuntime({
      #|                 direct: results.direct,
      #|                 extension: results.extension,
      #|                 event_count: eventCount,
      #|               })
      #|                 .then(() => {
      #|                   window.clearTimeout(timeoutId);
      #|                 })
      #|                 .catch((error) => {
      #|                   void reportFailure("ops report transport error: " + String(error));
      #|                 });
      #|             };
      #|             moonbit.events.on("math.computed", () => {
      #|               eventCount += 1;
      #|               maybeFinish();
      #|             });
      #|             Promise.all([
      #|               moonbit.core.invokeOp("ext:math/multiply", { left: 6, right: 7 }),
      #|               moonbit.math.multiply({ left: 6, right: 7 }),
      #|             ])
      #|               .then(([direct, extension]) => {
      #|                 results = { direct, extension };
      #|                 maybeFinish();
      #|               })
      #|               .catch((error) => {
      #|                 void reportFailure("ops transport error: " + String(error));
      #|               });
      #|           },
      #|           "__MoonBit__ runtime",
      #|         );
      #|       });
      #|     </script>
      #|   </body>
      #| </html>,
    ),
  )
  webview.run()
  assert_eq(js_error, None)
  assert_true(seen_report == Some(expected_report))
}
