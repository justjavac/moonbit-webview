///|
struct ParsedGlobalHotkey {
  normalized : String
  modifiers : Int
  key : Int
} derive(Debug, Eq)

///|
#external
pub type GlobalHotkeyState

///|
pub struct GlobalHotkeyManager {
  state : GlobalHotkeyState
  registrations : Map[String, Int]
  registration_names : Map[Int, String]
  mut next_id : Int
  mut destroyed : Bool
}

///|
extern "C" fn is_windows_ffi() -> Bool = "desktop_global_shortcut_is_windows"

///|
extern "C" fn create_state_ffi() -> GlobalHotkeyState = "desktop_global_shortcut_create"

///|
extern "C" fn destroy_state_ffi(state : GlobalHotkeyState) -> Unit = "desktop_global_shortcut_destroy"

///|
extern "C" fn state_is_null(state : GlobalHotkeyState) -> Bool = "moonbit_is_null"

///|
#borrow(accelerator)
extern "C" fn register_hotkey_ffi(
  state : GlobalHotkeyState,
  id : Int,
  modifiers : Int,
  key : Int,
  accelerator : Bytes,
) -> Bool = "desktop_global_shortcut_register"

///|
extern "C" fn unregister_hotkey_ffi(
  state : GlobalHotkeyState,
  id : Int,
) -> Bool = "desktop_global_shortcut_unregister"

///|
extern "C" fn take_triggered_id_ffi(state : GlobalHotkeyState) -> Int = "desktop_global_shortcut_take_triggered_id"

///|
/// Returns whether the global hotkey package supports the current platform.
pub fn is_supported() -> Bool {
  is_windows_ffi()
}

///|
/// Fails with a descriptive error when global hotkeys are unsupported.
pub fn ensure_supported() -> Result[Unit, String] {
  if is_supported() {
    Ok(())
  } else {
    Err("globalHotkey package currently supports Windows native builds only")
  }
}

///|
/// Returns the live native manager state or an error when the manager is unusable.
fn GlobalHotkeyManager::resolve_state(
  self : GlobalHotkeyManager,
) -> Result[GlobalHotkeyState, String] {
  if self.destroyed {
    Err("globalHotkey manager has been destroyed")
  } else if state_is_null(self.state) {
    Err("globalHotkey package failed to initialize")
  } else {
    Ok(self.state)
  }
}

///|
/// Creates a native global hotkey manager.
///
/// The returned manager tracks registrations by normalized accelerator string
/// and owns the native state that must later be destroyed.
pub fn create() -> Result[GlobalHotkeyManager, String] {
  ensure_supported().bind(fn(_) {
    let state = create_state_ffi()
    if state_is_null(state) {
      Err("globalHotkey package failed to initialize")
    } else {
      Ok(GlobalHotkeyManager::{
        state,
        registrations: {},
        registration_names: {},
        next_id: 1,
        destroyed: false,
      })
    }
  })
}

///|
/// Parses one accelerator after the manager state has been confirmed usable.
fn GlobalHotkeyManager::resolve_registration_request(
  self : GlobalHotkeyManager,
  accelerator : String,
) -> Result[(GlobalHotkeyState, ParsedGlobalHotkey), String] {
  self
  .resolve_state()
  .bind(fn(state) {
    parse_accelerator(accelerator).map(fn(parsed) { (state, parsed) })
  })
}

///|
/// Returns an existing registration id for one normalized accelerator, if present.
fn GlobalHotkeyManager::registered_id(
  self : GlobalHotkeyManager,
  normalized : String,
) -> Int? {
  self.registrations.get(normalized)
}

///|
/// Stores one successful native registration in the manager bookkeeping tables.
fn GlobalHotkeyManager::store_registration(
  self : GlobalHotkeyManager,
  normalized : String,
  id : Int,
) -> Unit {
  self.next_id += 1
  self.registrations.set(normalized, id)
  self.registration_names.set(id, normalized)
}

///|
/// Removes one successful native registration from the manager bookkeeping tables.
fn GlobalHotkeyManager::forget_registration(
  self : GlobalHotkeyManager,
  normalized : String,
  id : Int,
) -> Unit {
  self.registrations.remove(normalized)
  self.registration_names.remove(id)
}

///|
/// Returns the native registration error string for one normalized accelerator.
fn registration_error(prefix : String, normalized : String) -> String {
  "globalHotkey." + prefix + " failed: " + normalized
}

///|
/// Completes one native registration call and persists the registration locally.
fn GlobalHotkeyManager::register_parsed(
  self : GlobalHotkeyManager,
  state : GlobalHotkeyState,
  parsed : ParsedGlobalHotkey,
) -> Result[Bool, String] {
  guard self.registered_id(parsed.normalized) is None else {
    return Err("globalHotkey already registered: " + parsed.normalized)
  }
  let id = self.next_id
  if register_hotkey_ffi(
      state,
      id,
      parsed.modifiers,
      parsed.key,
      @ffi.to_cstr(parsed.normalized),
    ) {
    self.store_registration(parsed.normalized, id)
    Ok(true)
  } else {
    Err(registration_error("register", parsed.normalized))
  }
}

///|
/// Completes one native unregister call and removes the registration locally.
fn GlobalHotkeyManager::unregister_parsed(
  self : GlobalHotkeyManager,
  state : GlobalHotkeyState,
  parsed : ParsedGlobalHotkey,
) -> Result[Bool, String] {
  match self.registered_id(parsed.normalized) {
    Some(id) =>
      if unregister_hotkey_ffi(state, id) {
        self.forget_registration(parsed.normalized, id)
        Ok(false)
      } else {
        Err(registration_error("unregister", parsed.normalized))
      }
    None => Ok(false)
  }
}

///|
/// Registers a new accelerator with the native global hotkey backend.
///
/// Parameters:
/// - `accelerator` - A shortcut string such as `Ctrl+Shift+K` or `Alt+F12`.
///
/// Returns:
/// - `Ok(true)` when registration succeeds.
/// - `Err(message)` when the accelerator is invalid, duplicated, or rejected by the OS.
pub fn GlobalHotkeyManager::register(
  self : GlobalHotkeyManager,
  accelerator : String,
) -> Result[Bool, String] {
  self
  .resolve_registration_request(accelerator)
  .bind(fn(request) {
    let (state, parsed) = request
    self.register_parsed(state, parsed)
  })
}

///|
/// Unregisters a previously registered accelerator.
///
/// Returns `Ok(false)` when the accelerator was not currently registered.
pub fn GlobalHotkeyManager::unregister(
  self : GlobalHotkeyManager,
  accelerator : String,
) -> Result[Bool, String] {
  self
  .resolve_registration_request(accelerator)
  .bind(fn(request) {
    let (state, parsed) = request
    self.unregister_parsed(state, parsed)
  })
}

///|
/// Returns every currently registered accelerator in normalized form.
pub fn GlobalHotkeyManager::list(self : GlobalHotkeyManager) -> Array[String] {
  let accelerators : Array[String] = []
  for accelerator, _ in self.registrations {
    accelerators.push(accelerator)
  }
  accelerators
}

///|
/// Returns the next triggered accelerator, if one is waiting in the native queue.
pub fn GlobalHotkeyManager::take_triggered(
  self : GlobalHotkeyManager,
) -> String? {
  match self.resolve_state() {
    Err(_) => None
    Ok(state) =>
      match self.registration_names.get(take_triggered_id_ffi(state)) {
        Some(accelerator) => Some(accelerator)
        None => None
      }
  }
}

///|
/// Drains all currently triggered accelerators from the native queue.
pub fn GlobalHotkeyManager::drain_triggered(
  self : GlobalHotkeyManager,
) -> Array[String] {
  let accelerators : Array[String] = []
  while true {
    match self.take_triggered() {
      Some(accelerator) => accelerators.push(accelerator)
      None => break
    }
  }
  accelerators
}

///|
/// Destroys the native global hotkey manager and clears all tracked registrations.
pub fn GlobalHotkeyManager::destroy(self : GlobalHotkeyManager) -> Unit {
  if !self.destroyed {
    destroy_state_ffi(self.state)
    self.destroyed = true
    self.registrations.clear()
    self.registration_names.clear()
  }
}

///|
/// Parses a user-facing accelerator string into normalized native registration data.
fn parse_accelerator(raw : String) -> Result[ParsedGlobalHotkey, String] {
  let parts = raw.split("+").to_array()
  let mut control = false
  let mut shift = false
  let mut alt = false
  let mut meta = false
  let mut key_name : String? = None
  let mut key_code : Int? = None

  for part in parts {
    let token = part.to_string().trim().to_string()
    if token.is_empty() {
      return Err("globalHotkey accelerator contains an empty segment")
    }
    let normalized = normalize_keyword(token)
    match normalized {
      "ctrl" =>
        if control {
          return Err("globalHotkey accelerator repeats Ctrl")
        } else {
          control = true
        }
      "control" =>
        if control {
          return Err("globalHotkey accelerator repeats Ctrl")
        } else {
          control = true
        }
      "shift" =>
        if shift {
          return Err("globalHotkey accelerator repeats Shift")
        } else {
          shift = true
        }
      "alt" =>
        if alt {
          return Err("globalHotkey accelerator repeats Alt")
        } else {
          alt = true
        }
      "meta" =>
        if meta {
          return Err("globalHotkey accelerator repeats Meta")
        } else {
          meta = true
        }
      "win" =>
        if meta {
          return Err("globalHotkey accelerator repeats Meta")
        } else {
          meta = true
        }
      "super" =>
        if meta {
          return Err("globalHotkey accelerator repeats Meta")
        } else {
          meta = true
        }
      _ =>
        match key_name {
          Some(_) =>
            return Err("globalHotkey accelerator must contain exactly one key")
          None =>
            match decode_virtual_key(token) {
              Err(error) => return Err(error)
              Ok((canonical_name, canonical_code)) => {
                key_name = Some(canonical_name)
                key_code = Some(canonical_code)
              }
            }
        }
    }
  }

  match (key_name, key_code) {
    (Some(key_name), Some(key_code)) => {
      let modifiers = modifier_mask(control, shift, alt, meta)
      let normalized = normalize_accelerator_name(
        control, shift, alt, meta, key_name,
      )
      Ok(ParsedGlobalHotkey::{ normalized, modifiers, key: key_code })
    }
    _ => Err("globalHotkey accelerator must include a key")
  }
}

///|
/// Encodes the modifier booleans into the bitmask expected by the native backend.
fn modifier_mask(control : Bool, shift : Bool, alt : Bool, meta : Bool) -> Int {
  let mut mask = 0
  if alt {
    mask += 0x0001
  }
  if control {
    mask += 0x0002
  }
  if shift {
    mask += 0x0004
  }
  if meta {
    mask += 0x0008
  }
  mask
}

///|
/// Normalizes an accelerator back into the canonical display string.
fn normalize_accelerator_name(
  control : Bool,
  shift : Bool,
  alt : Bool,
  meta : Bool,
  key_name : String,
) -> String {
  let builder = StringBuilder::new()
  let mut wrote_modifier = false
  if control {
    builder.write_string("Ctrl")
    wrote_modifier = true
  }
  if shift {
    if wrote_modifier {
      builder.write_char('+')
    }
    builder.write_string("Shift")
    wrote_modifier = true
  }
  if alt {
    if wrote_modifier {
      builder.write_char('+')
    }
    builder.write_string("Alt")
    wrote_modifier = true
  }
  if meta {
    if wrote_modifier {
      builder.write_char('+')
    }
    builder.write_string("Meta")
    wrote_modifier = true
  }
  if wrote_modifier {
    builder.write_char('+')
  }
  builder.write_string(key_name)
  builder.to_string()
}

///|
/// Decodes a key token into its canonical name and native virtual-key code.
fn decode_virtual_key(raw : String) -> Result[(String, Int), String] {
  let upper = raw.trim().to_string().to_upper()
  if upper.length() == 1 {
    match upper.get_char(0) {
      Some(ch) =>
        if (ch >= 'A' && ch <= 'Z') || (ch >= '0' && ch <= '9') {
          Ok((upper, ch.to_int()))
        } else {
          Err("unsupported globalHotkey key: " + raw)
        }
      None => Err("unsupported globalHotkey key: " + raw)
    }
  } else {
    match upper {
      "SPACE" => Ok(("Space", 0x20))
      "ENTER" => Ok(("Enter", 0x0D))
      "RETURN" => Ok(("Enter", 0x0D))
      "ESC" => Ok(("Escape", 0x1B))
      "ESCAPE" => Ok(("Escape", 0x1B))
      "TAB" => Ok(("Tab", 0x09))
      "LEFT" => Ok(("Left", 0x25))
      "UP" => Ok(("Up", 0x26))
      "RIGHT" => Ok(("Right", 0x27))
      "DOWN" => Ok(("Down", 0x28))
      "F1" => Ok(("F1", 0x70))
      "F2" => Ok(("F2", 0x71))
      "F3" => Ok(("F3", 0x72))
      "F4" => Ok(("F4", 0x73))
      "F5" => Ok(("F5", 0x74))
      "F6" => Ok(("F6", 0x75))
      "F7" => Ok(("F7", 0x76))
      "F8" => Ok(("F8", 0x77))
      "F9" => Ok(("F9", 0x78))
      "F10" => Ok(("F10", 0x79))
      "F11" => Ok(("F11", 0x7A))
      "F12" => Ok(("F12", 0x7B))
      "F13" => Ok(("F13", 0x7C))
      "F14" => Ok(("F14", 0x7D))
      "F15" => Ok(("F15", 0x7E))
      "F16" => Ok(("F16", 0x7F))
      "F17" => Ok(("F17", 0x80))
      "F18" => Ok(("F18", 0x81))
      "F19" => Ok(("F19", 0x82))
      "F20" => Ok(("F20", 0x83))
      "F21" => Ok(("F21", 0x84))
      "F22" => Ok(("F22", 0x85))
      "F23" => Ok(("F23", 0x86))
      "F24" => Ok(("F24", 0x87))
      _ => Err("unsupported globalHotkey key: " + raw)
    }
  }
}

///|
/// Trims and lowercases accelerator tokens before comparison.
fn normalize_keyword(raw : String) -> String {
  raw.trim().to_string().to_lower()
}
