///|
#external
pub type TrayState

///|
pub struct Tray {
  state : TrayState
  mut destroyed : Bool
}

///|
extern "C" fn is_windows_ffi() -> Bool = "desktop_tray_is_windows"

///|
extern "C" fn create_state_ffi(window : Int64) -> TrayState = "desktop_tray_create"

///|
extern "C" fn destroy_state_ffi(state : TrayState) -> Unit = "desktop_tray_destroy"

///|
extern "C" fn state_is_null(state : TrayState) -> Bool = "moonbit_is_null"

///|
#borrow(tooltip)
extern "C" fn tray_show_ffi(state : TrayState, tooltip : Bytes) -> Bool = "desktop_tray_show"

///|
extern "C" fn tray_hide_ffi(state : TrayState) -> Bool = "desktop_tray_hide"

///|
#borrow(tooltip)
extern "C" fn tray_set_tooltip_ffi(
  state : TrayState,
  tooltip : Bytes,
) -> Bool = "desktop_tray_set_tooltip"

///|
/// Returns whether the tray package supports the current platform.
pub fn is_supported() -> Bool {
  is_windows_ffi()
}

///|
/// Fails with a descriptive error when tray support is unavailable.
pub fn ensure_supported() -> Result[Unit, String] {
  if is_supported() {
    Ok(())
  } else {
    Err("tray package currently supports Windows native builds only")
  }
}

///|
/// Encodes an optional tooltip as a UTF-16 buffer for the native tray API.
fn to_wstr(value : String?) -> Bytes {
  match value {
    Some(value) => @ffi.to_wstr(value)
    None => @ffi.to_wstr("")
  }
}

///|
/// Returns the live native tray state or an error when the handle is unusable.
fn Tray::resolve_state(self : Tray) -> Result[TrayState, String] {
  if self.destroyed {
    Err("tray handle has been destroyed")
  } else if state_is_null(self.state) {
    Err("tray package failed to initialize")
  } else {
    Ok(self.state)
  }
}

///|
/// Creates a tray handle associated with a native window.
///
/// Parameters:
/// - `window_handle` - The owning native window handle used by the platform tray implementation.
pub fn create(window_handle : Int64) -> Result[Tray, String] {
  match ensure_supported() {
    Err(error) => Err(error)
    Ok(_) => {
      let state = create_state_ffi(window_handle)
      if state_is_null(state) {
        Err("tray package failed to initialize")
      } else {
        Ok(Tray::{ state, destroyed: false })
      }
    }
  }
}

///|
/// Shows the tray icon and optionally updates its tooltip text.
pub fn Tray::show(
  self : Tray,
  tooltip? : String? = None,
) -> Result[Bool, String] {
  match self.resolve_state() {
    Err(error) => Err(error)
    Ok(state) =>
      if tray_show_ffi(state, to_wstr(tooltip)) {
        Ok(true)
      } else {
        Err("tray.show failed")
      }
  }
}

///|
/// Hides the tray icon while keeping the native tray handle alive.
pub fn Tray::hide(self : Tray) -> Result[Bool, String] {
  match self.resolve_state() {
    Err(error) => Err(error)
    Ok(state) =>
      if tray_hide_ffi(state) {
        Ok(false)
      } else {
        Err("tray.hide failed")
      }
  }
}

///|
/// Updates the tray tooltip and returns the current visibility state.
pub fn Tray::set_tooltip(self : Tray, tooltip : String) -> Result[Bool, String] {
  match self.resolve_state() {
    Err(error) => Err(error)
    Ok(state) =>
      if tray_set_tooltip_ffi(state, @ffi.to_wstr(tooltip)) {
        Ok(true)
      } else {
        Err("tray.set_tooltip failed")
      }
  }
}

///|
/// Destroys the native tray handle and marks this wrapper as unusable.
pub fn Tray::destroy(self : Tray) -> Unit {
  if !self.destroyed {
    destroy_state_ffi(self.state)
    self.destroyed = true
  }
}
