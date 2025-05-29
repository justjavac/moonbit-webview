/// This module provides the FFI (Foreign Function Interface) for the webview library.
/// It allows the main application to call functions defined in the webview library.
/// 
/// see: https://github.com/webview/webview/blob/f1a9d6b6fb8bcc2e266057224887a3d628f30f90/webview.i

///| typedef void *webview_t;
pub extern type Webview_t

///| extern webview_t webview_create(int debug, void *window);
pub extern "C" fn webview_create(debug : Int, window : Int64) -> Webview_t = "webview_create"

///| extern void webview_destroy(webview_t w);
pub extern "C" fn webview_destroy(webview : Webview_t) -> Int = "webview_destroy"

///| extern void webview_run(webview_t w);
pub extern "C" fn webview_run(webview : Webview_t) -> Int = "webview_run"

///| extern void webview_terminate(webview_t w);
pub extern "C" fn webview_terminate(webview : Webview_t) -> Int = "webview_terminate"

///| extern void webview_dispatch(webview_t w, void (*fn)(webview_t w, void *arg), void *arg);
pub extern "C" fn webview_dispatch(
  webview : Webview_t,
  call_closure : FuncRef[(Webview_t, (Webview_t) -> Unit) -> Unit],
  closure : () -> Unit
) -> Int = "webview_dispatch"

///| extern void *webview_get_window(webview_t w);
pub extern "C" fn webview_get_window(webview : Webview_t) -> Int64 = "webview_get_window"

///| extern void *webview_get_native_handle(webview_t w, webview_native_handle_kind_t kind);
pub extern "C" fn webview_get_native_handle(
  webview : Webview_t,
  kind : NativeHandleKind
) -> Int64 = "webview_get_native_handle"

///| extern void webview_set_title(webview_t w, const char *title);
pub extern "C" fn webview_set_title(webview : Webview_t, title : Bytes) -> Int = "webview_set_title"

///| extern void webview_set_size(webview_t w, int width, int height, webview_hint_t hints);
pub extern "C" fn webview_set_size(
  webview : Webview_t,
  width : Int,
  height : Int,
  hint : SizeHint
) -> Int = "webview_set_size"

///| extern void webview_navigate(webview_t w, const char *url);
pub extern "C" fn webview_navigate(webview : Webview_t, html : Bytes) -> Int = "webview_navigate"

///| extern void webview_set_html(webview_t w, const char *html);
pub extern "C" fn webview_set_html(webview : Webview_t, html : Bytes) -> Int = "webview_set_html"

///| extern void webview_init(webview_t w, const char *js);
pub extern "C" fn webview_init(webview : Webview_t, js : Bytes) -> Int = "webview_init"

///| extern void webview_eval(webview_t w, const char *js);
pub extern "C" fn webview_eval(webview : Webview_t, js : Bytes) -> Int = "webview_eval"

///| extern void webview_bind(webview_t w, const char *name, void (*fn)(const char *id, const char *req, void *arg), void *arg);
pub extern "C" fn webview_bind(
  webview : Webview_t,
  name : Bytes,
  call_closure : FuncRef[
    (Bytes, Bytes, Ref[Bytes], (Bytes, Bytes, Ref[Bytes]) -> Unit) -> Unit,
  ],
  closure : (Bytes, Bytes, Ref[Bytes]) -> Unit
) -> Int = "webview_bind"

///| extern void webview_unbind(webview_t w, const char *name);
pub extern "C" fn webview_unbind(webview : Webview_t, name : Bytes) -> Int = "webview_unbind"

///| extern void webview_return(webview_t w, const char *seq, int status, const char *result);
pub extern "C" fn webview_return(
  webview : Webview_t,
  seq : Bytes,
  status : Int,
  result : Bytes
) -> Int = "webview_return"
