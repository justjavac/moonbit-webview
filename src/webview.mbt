///| Native handle kind. The actual type depends on the backend.
pub(all) enum NativeHandleKind {
  /// Top-level window. `GtkWindow` pointer (GTK), `NSWindow` pointer (Cocoa) or `HWND` (Win32).
  Window = 0
  /// Browser widget. `GtkWidget` pointer (GTK), `NSView` pointer (Cocoa) or `HWND` (Win32).
  Widget = 1
  /// Browser controller. `WebKitWebView` pointer (WebKitGTK), `WKWebView`
  /// pointer (Cocoa/WebKit) or `ICoreWebView2Controller` pointer (Win32/WebView2).
  Browser = 2
} derive(Show)

///| Window size hints
pub(all) enum SizeHint {
  /// Width and height are default size.
  None = 0
  /// Width and height are minimum bounds.
  Min = 1
  /// Width and height are maximum bounds.
  Max = 2
  /// Window size can not be changed by a user.
  Fixed = 3
} derive(Show)

///| An instance of a webview window.
/// 
/// Example:
///
/// ```moonbit
/// let webview = @webview.Webview::new(debug=1)
/// webview.set_title("My Webview")
/// webview.set_size(800, 600, @webview.SizeHint::None)
/// webview.set_html("<html><body><h1>Hello, World!</h1></body></html>")
/// webview.dispatch(fn() { webview.terminate() })
/// webview.run()
/// ```
struct Webview {
  handle : Webview_t
  callbacks : Map[String, (Bytes, Bytes) -> Unit]
}

///| Creates a new webview instance from a webview handle.
/// 
/// Parameters:
/// - `debug` - If set to 1, enables debugging mode which provides additional logging.
pub fn Webview::new(debug~ : Int = 0) -> Webview {
  let window : Int64 = 0
  let webview = Webview::{
    handle: webview_create(debug, window),
    callbacks: {},
  }
  webview
}

///| Stops the main loop. It is safe to call this function from another other
/// background thread.
pub fn Webview::destroy(self : Webview) -> Unit {
  for name, _callback in self.callbacks {
    let _ = self.unbind(name)

  }
  let _ = webview_terminate(self.handle)
  let _ = webview_destroy(self.handle)

}

///| Schedules a function to be invoked on the thread with the run/event loop.
/// 
/// Since library functions generally do not have thread safety guarantees,
/// this function can be used to schedule code to execute on the main/GUI
/// thread and thereby make that execution safe in multi-threaded applications.
/// 
/// Parameters:
/// - `callback` - The function to be invoked.
/// - `arg` - An optional argument passed along to the callback function.
pub fn Webview::dispatch(self : Webview, callback : () -> Unit) -> Unit {
  let _ = webview_dispatch(self.handle, fn(w, f) { f(w) }, callback)

}

///| Stops the main loop. It is safe to call this function from another
/// background thread.
pub fn Webview::terminate(self : Webview) -> Unit {
  let _ = webview_terminate(self.handle)

}

///| Binds a function pointer to a new global JavaScript function.
/// 
/// Internally, JS glue code is injected to create the JS function by the
/// given name. The callback function is passed a request identifier,
/// a request string and a user-provided argument. The request string is
/// a JSON array of the arguments passed to the JS function.
/// 
/// Parameters:
/// - `name` - The name of the JavaScript function to bind.
/// - `callback` - The function to be invoked when the JS function is called.
/// - `arg` - An optional user-provided argument passed to the callback function.
/// 
/// Returns:
/// - `WEBVIEW_ERROR_DUPLICATE` - A binding already exists with the specified name.
pub fn Webview::bind(
  self : Webview,
  name : String,
  callback : (Bytes, Bytes) -> Unit
) -> Unit {
  self.callbacks.set(name, callback)
  let _ = webview_bind(
    self.handle,
    @ffi.to_cstr(name),
    fn(id, req, f) { f(id, req) },
    callback,
  )

}

///| Removes a binding created with `webview.bind()`.
/// 
/// Parameters:
/// - `name` - The name of the JavaScript function to unbind.
/// 
/// Returns:
/// - `WEBVIEW_ERROR_NOT_FOUND` - No binding exists with the specified name.
pub fn Webview::unbind(self : Webview, name : String) -> Unit {
  self.callbacks.remove(name)
  let _ = webview_unbind(self.handle, @ffi.to_cstr(name))

}

///| Updates the title of the native window.
/// 
/// Parameters:
/// - `title` - The new title.
pub fn Webview::set_title(self : Webview, title : String) -> Unit {
  let _ = webview_set_title(self.handle, @ffi.to_cstr(title))

}

///| Load HTML content into the webview.
/// 
/// Parameters:
/// - `html` - The HTML content to load.
/// 
/// Example:
/// ```moonbit
/// let webview = @webview.Webview::new()
/// webview.set_html("<html><body><h1>Hello, World!</h1></body></html>")
/// webview.dispatch(fn() { webview.terminate() })
/// webview.run()
/// ```
pub fn Webview::set_html(self : Webview, html : String) -> Unit {
  let _ = webview_set_html(self.handle, @ffi.to_cstr(html))

}

///| Navigates webview to the given URL. URL may be a properly encoded data URI.
/// 
/// Parameters:
/// - `url` - The URL to navigate to.
/// 
/// Example:
/// ```moonbit
/// let webview = @webview.Webview::new()
/// webview.navigate("https://www.example.com")
/// webview.navigate("data:text/html,<h1>Hello, World!</h1>")
/// webview.navigate("data:text/html;base64,PGgxPkhlbGxvPC9oMT4=")
/// webview.dispatch(fn() { webview.terminate() })
/// webview.run()
/// ```
pub fn Webview::navigate(self : Webview, url : String) -> Unit {
  let _ = webview_navigate(self.handle, @ffi.to_cstr(url))
}

///| Returns the native handle of the window associated with the webview instance.
/// The handle can be a `GtkWindow` pointer (GTK), `NSWindow` pointer (Cocoa)
/// or `HWND` (Win32).
pub fn Webview::get_window(self : Webview) -> Int64 {
  webview_get_window(self.handle)
}

///| Get a native handle of choice.
/// 
/// Parameters:
/// - `kind` - The kind of handle to retrieve.
pub fn Webview::get_native_handle(
  self : Webview,
  kind : NativeHandleKind
) -> Int64 {
  webview_get_native_handle(self.handle, kind)
}

///|
/// Returns the internal webview handle of the webview instance. This handle is
/// the raw pointer used by the underlying webview library.
pub fn Webview::get_handle(self : Webview) -> Webview_t {
  self.handle
}

///| Evaluates arbitrary JavaScript code.
/// 
/// Use bindings if you need to communicate the result of the evaluation.
/// 
/// Parameters:
/// - `js` - The JavaScript code to evaluate.
pub fn Webview::eval(self : Webview, js : String) -> Unit {
  let _ = webview_eval(self.handle, @ffi.to_cstr(js))

}

///| Injects JavaScript code to be executed immediately upon loading a page.
/// The code will be executed before `window.onload`.
/// 
/// Parameters:
/// - `js` - The JavaScript code to inject.
pub fn Webview::init(self : Webview, js : String) -> Unit {
  let _ = webview_init(self.handle, @ffi.to_cstr(js))

}

///| Responds to a binding call from the JS side.
/// 
/// This function is safe to call from another thread.
/// 
/// Parameters:
/// - `id` - The identifier of the binding call. Pass along the value received
///    in the binding handler (see `webview.bind()`).
/// - `status` - A status of zero tells the JS side that the binding call was
///    successful; any other value indicates an error.
/// - `result` - The result of the binding call to be returned to the JS side.
///    This must either be a valid JSON value or an empty string for
///    the primitive JS value `undefined`.
pub fn Webview::response(
  self : Webview,
  id : String,
  status : Int,
  result : String
) -> Unit {
  let _ = webview_return(
    self.handle,
    @ffi.to_cstr(id),
    status,
    @ffi.to_cstr(result),
  )

}

///| Updates the size of the native window.
/// 
/// Remarks:
/// - Using `WEBVIEW_HINT_MAX` for setting the maximum window size is not
///   supported with GTK 4 because X11-specific functions such as
///   `gtk_window_set_geometry_hints` were removed. This option has no effect
///   when using GTK 4.
/// - GTK 4 can set a default/initial window size if done early enough;
///   otherwise, this function has no effect. GTK 4 (unlike 3) can't resize
///   a window after it has been set up.
/// 
/// Parameters:
/// - `width` - The new width of the window.
/// - `height` - The new height of the window.
/// - `hints` - Hints for the window size.
pub fn Webview::set_size(
  self : Webview,
  width : Int,
  height : Int,
  hints : SizeHint
) -> Unit {
  let _ = webview_set_size(self.handle, width, height, hints)

}

///| Runs the main loop until it's terminated.
pub fn Webview::run(self : Webview) -> Unit {
  let _ = webview_run(self.handle)
  self.destroy()
}
