///|
/// Replaces or creates the manifest setting for one extension entry.
/// The edited raw JSON is revalidated by rebuilding the typed document before
/// the new value is returned.
pub fn AppManifestDocument::set_extension_setting(
  self : AppManifestDocument,
  name : String,
  setting : @manifest.ExtensionSetting,
) -> Result[AppManifestDocument, String] {
  guard normalize_keyword(name) != "" else {
    return Err("extension key must not be empty")
  }
  self.updated(object => {
    set_extension_setting_entry(object, name, setting)
    Ok(())
  })
}

///|
/// Enables one extension with optional JSON options.
/// Pass `options` when you need to persist extension-specific configuration in
/// the editable manifest document.
pub fn AppManifestDocument::enable_extension(
  self : AppManifestDocument,
  name : String,
  options? : Json? = None,
) -> Result[AppManifestDocument, String] {
  self.set_extension_setting(
    name,
    @manifest.ExtensionSetting::enabled(options~),
  )
}

///|
/// Disables one extension explicitly.
/// The extension key remains present in the document so tooling can tell the
/// difference between a disabled setting and a missing one.
pub fn AppManifestDocument::disable_extension(
  self : AppManifestDocument,
  name : String,
) -> Result[AppManifestDocument, String] {
  self.set_extension_setting(name, @manifest.ExtensionSetting::disabled())
}

///|
/// Removes one extension setting entry if it exists.
/// When the last extension is removed, the parent `extensions` object is also
/// cleaned up from the raw JSON document.
pub fn AppManifestDocument::remove_extension_setting(
  self : AppManifestDocument,
  name : String,
) -> Result[AppManifestDocument, String] {
  self.updated(object => {
    clear_extension_setting_entry(object, name)
    Ok(())
  })
}

///|
/// Stores a cloned extension setting under the requested extension name.
fn set_extension_setting_entry(
  object : Map[String, Json],
  name : String,
  setting : @manifest.ExtensionSetting,
) -> Unit {
  let extension_object = ensure_extension_settings_object(object)
  extension_object[name] = extension_setting_to_json(setting)
}

///|
/// Removes one extension setting entry and drops the parent object when it becomes empty.
fn clear_extension_setting_entry(
  object : Map[String, Json],
  name : String,
) -> Unit {
  match object.get("extensions") {
    Some(Object(extension_object)) => {
      extension_object.remove(name)
      if extension_object.is_empty() {
        object.remove("extensions")
      }
    }
    _ => ()
  }
}

///|
/// Returns the mutable `extensions` object, creating it when necessary.
fn ensure_extension_settings_object(
  object : Map[String, Json],
) -> Map[String, Json] {
  match object.get("extensions") {
    Some(Object(extension_object)) => extension_object
    _ => {
      let extension_object : Map[String, Json] = {}
      object["extensions"] = Json::object(extension_object)
      extension_object
    }
  }
}

///|
/// Converts one normalized extension setting back into its JSON representation.
fn extension_setting_to_json(setting : @manifest.ExtensionSetting) -> Json {
  match setting {
    Disabled => Json::boolean(false)
    Enabled(None) => Json::boolean(true)
    Enabled(Some(options)) => clone_json(options)
  }
}

///|
/// Converts one manifest window into its persisted JSON object form.
fn window_manifest_to_json(window : @manifest.WindowManifest) -> Json {
  let object : Map[String, Json] = {
    "title": Json::string(window.title),
    "width": ToJson::to_json(window.width),
    "height": ToJson::to_json(window.height),
  }
  match window.size_hint {
    @manifest.WindowSizeHint::None => ()
    @manifest.WindowSizeHint::Fixed =>
      object["size_hint"] = Json::string("fixed")
    @manifest.WindowSizeHint::Min => object["size_hint"] = Json::string("min")
    @manifest.WindowSizeHint::Max => object["size_hint"] = Json::string("max")
  }
  Json::object(object)
}

///|
/// Converts one manifest entry into its persisted JSON object form.
fn app_entry_to_json(entry : @manifest.AppEntry) -> Json {
  let object : Map[String, Json] = {}
  match entry {
    Html(value) => {
      object["kind"] = Json::string("html")
      object["value"] = Json::string(value)
    }
    Url(value) => {
      object["kind"] = Json::string("url")
      object["value"] = Json::string(value)
    }
    File(value) => {
      object["kind"] = Json::string("file")
      object["value"] = Json::string(value)
    }
    Asset(value) => {
      object["kind"] = Json::string("asset")
      object["value"] = Json::string(value)
    }
  }
  Json::object(object)
}

///|
/// Converts one secondary window manifest into its persisted JSON form.
fn app_window_manifest_to_json(window : @manifest.AppWindowManifest) -> Json {
  Json::object({
    "id": Json::string(window.id),
    "window": window_manifest_to_json(window.window),
    "entry": app_entry_to_json(window.entry),
  })
}

///|
/// Returns the mutable `windows` array, creating it when necessary.
fn ensure_windows_json_array(object : Map[String, Json]) -> Array[Json] {
  match object.get("windows") {
    Some(Array(windows)) => windows
    _ => {
      let windows : Array[Json] = []
      object["windows"] = Json::array(windows)
      windows
    }
  }
}

///|
/// Extracts a secondary window id from raw JSON when present.
fn window_id_from_json(json : Json) -> String? {
  match json {
    Object(object) =>
      match object.get("id") {
        Some(String(id)) => Some(id)
        _ => None
      }
    _ => None
  }
}
