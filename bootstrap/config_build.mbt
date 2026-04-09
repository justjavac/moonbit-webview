///|
/// Converts the root JSON object into a typed loaded manifest.
fn build_loaded_manifest_from_json(
  json : Json,
  base_dir : String?,
) -> Result[LoadedAppManifest, String] {
  expect_object(json, "app manifest").bind(fn(object) {
    reject_unsupported_permissions_field(object).bind(fn(_) {
      build_app_manifest_from_object(object, base_dir).map(fn(manifest) {
        LoadedAppManifest::new(manifest, base_dir~)
      })
    })
  })
}

///|
/// Builds a manifest window config from a JSON object.
fn build_window_manifest_from_json(
  json : Json,
) -> Result[@manifest.WindowManifest, String] {
  expect_object(json, "window manifest").bind(build_window_manifest_from_object)
}

///|
/// Builds a typed manifest from the root manifest object fields.
fn build_app_manifest_from_object(
  object : Map[String, Json],
  base_dir : String?,
) -> Result[@manifest.AppManifest, String] {
  zip5(
    build_required_window_from_object(object),
    build_required_entry_from_object(object, base_dir),
    build_optional_windows_from_object(object, base_dir),
    build_declared_extension_settings_from_object(object),
    build_debug_value_from_object(object),
  ).map(fn(values) {
    let (window, entry, windows, extensions, debug) = values
    @manifest.AppManifest::new(
      window,
      entry,
      debug=int_or_default(debug, 0),
      windows~,
      extensions~,
    )
  })
}

///|
/// Builds the required primary window field from the root manifest object.
fn build_required_window_from_object(
  object : Map[String, Json],
) -> Result[@manifest.WindowManifest, String] {
  required_built_field(
    object, "window", "app manifest.window", build_window_manifest_from_json,
  )
}

///|
/// Builds the required primary entry field from the root manifest object.
fn build_required_entry_from_object(
  object : Map[String, Json],
  base_dir : String?,
) -> Result[@manifest.AppEntry, String] {
  required_built_field(object, "entry", "app manifest.entry", fn(entry_json) {
    build_app_entry_from_json(entry_json, base_dir)
  })
}

///|
/// Builds the optional secondary windows field from the root manifest object.
fn build_optional_windows_from_object(
  object : Map[String, Json],
  base_dir : String?,
) -> Result[Array[@manifest.AppWindowManifest], String] {
  build_app_windows_from_json(optional_field(object, "windows"), base_dir)
}

///|
/// Builds the normalized extension settings field from the root manifest object.
fn build_declared_extension_settings_from_object(
  object : Map[String, Json],
) -> Result[Map[String, @manifest.ExtensionSetting], String] {
  build_extension_settings(optional_field(object, "extensions"))
}

///|
/// Builds the optional debug field from the root manifest object.
fn build_debug_value_from_object(
  object : Map[String, Json],
) -> Result[Int?, String] {
  decode_optional_int(optional_field(object, "debug"), "app manifest.debug")
}

///|
/// Rejects legacy permissions fields on the root manifest object.
fn reject_unsupported_permissions_field(
  object : Map[String, Json],
) -> Result[Unit, String] {
  reject_unsupported_permissions(optional_field(object, "permissions"))
}

///|
/// Builds a manifest window config from an already validated object.
fn build_window_manifest_from_object(
  object : Map[String, Json],
) -> Result[@manifest.WindowManifest, String] {
  zip4(
    required_string_field(object, "title", "window.title"),
    required_int_field(object, "width", "window.width"),
    required_int_field(object, "height", "window.height"),
    decode_optional_string(
      optional_field(object, "size_hint"),
      "window.size_hint",
    ).bind(parse_size_hint),
  ).map(fn(values) {
    let (title, width, height, size_hint) = values
    @manifest.WindowManifest::new(title, width, height, size_hint~)
  })
}

///|
/// Builds an app entry value and rebases relative file-backed entries against the config directory.
fn build_app_entry_from_json(
  json : Json,
  base_dir : String?,
) -> Result[@manifest.AppEntry, String] {
  expect_object(json, "app entry").bind(fn(object) {
    zip2(
      required_string_field(object, "kind", "entry.kind"),
      required_string_field(object, "value", "entry.value"),
    ).bind(fn(values) {
      let (kind, value) = values
      build_app_entry_from_parts(kind, value, base_dir)
    })
  })
}

///|
/// Builds an app entry from decoded `kind` and `value` fields.
fn build_app_entry_from_parts(
  kind : String,
  value : String,
  base_dir : String?,
) -> Result[@manifest.AppEntry, String] {
  let normalized_kind = normalize_keyword(kind)
  let rebased_value = match normalized_kind {
    "file" => rebase_relative_path(value, base_dir)
    "asset" => rebase_relative_path(value, base_dir)
    _ => value
  }
  match normalized_kind {
    "html" => Ok(@manifest.AppEntry::Html(rebased_value))
    "url" => Ok(@manifest.AppEntry::Url(rebased_value))
    "file" => Ok(@manifest.AppEntry::File(rebased_value))
    "asset" => Ok(@manifest.AppEntry::Asset(rebased_value))
    _ => Err("unsupported app entry kind: " + kind)
  }
}

///|
/// Builds the optional secondary window list from JSON.
fn build_app_windows_from_json(
  json : Json?,
  base_dir : String?,
) -> Result[Array[@manifest.AppWindowManifest], String] {
  match json {
    None => Ok([])
    Some(Array(items)) => build_app_windows_from_array(items, base_dir)
    Some(_) => Err("expected array for app manifest.windows")
  }
}

///|
/// Builds every secondary window from the decoded `windows` array.
fn build_app_windows_from_array(
  items : Array[Json],
  base_dir : String?,
) -> Result[Array[@manifest.AppWindowManifest], String] {
  let windows : Array[@manifest.AppWindowManifest] = []
  for index, item in items {
    match build_app_window_from_json(item, base_dir, index) {
      Ok(window) => windows.push(window)
      Err(error) => return Err(error)
    }
  }
  Ok(windows)
}

///|
/// Builds one secondary window config entry from the `windows` array.
fn build_app_window_from_json(
  json : Json,
  base_dir : String?,
  index : Int,
) -> Result[@manifest.AppWindowManifest, String] {
  let label = "windows[" + index.to_string() + "]"
  expect_object(json, label).bind(fn(object) {
    build_app_window_from_object(object, base_dir, label)
  })
}

///|
/// Builds one secondary window config entry from an already validated object.
fn build_app_window_from_object(
  object : Map[String, Json],
  base_dir : String?,
  label : String,
) -> Result[@manifest.AppWindowManifest, String] {
  zip3(
    required_string_field(object, "id", label + ".id"),
    required_built_field(
      object,
      "window",
      label + ".window",
      build_window_manifest_from_json,
    ),
    required_built_field(object, "entry", label + ".entry", fn(entry_json) {
      build_app_entry_from_json(entry_json, base_dir)
    }),
  ).map(fn(values) {
    let (id, window, entry) = values
    @manifest.AppWindowManifest::new(id, window, entry)
  })
}

///|
/// Builds the normalized extension settings map from the `extensions` object.
fn build_extension_settings(
  json : Json?,
) -> Result[Map[String, @manifest.ExtensionSetting], String] {
  match json {
    None => Ok({})
    Some(Object(object)) => build_extension_settings_from_object(object)
    Some(_) => Err("expected object for app manifest.extensions")
  }
}

///|
/// Builds the normalized extension settings map from an already validated object.
fn build_extension_settings_from_object(
  object : Map[String, Json],
) -> Result[Map[String, @manifest.ExtensionSetting], String] {
  let settings : Map[String, @manifest.ExtensionSetting] = {}
  for name, value in object {
    guard normalize_keyword(name) != "" else {
      return Err("app manifest.extensions contains an empty key")
    }
    match build_extension_setting_from_json(name, value) {
      Ok(setting) => settings.set(name, setting)
      Err(error) => return Err(error)
    }
  }
  Ok(settings)
}

///|
/// Builds one normalized extension setting from the raw JSON value.
fn build_extension_setting_from_json(
  name : String,
  value : Json,
) -> Result[@manifest.ExtensionSetting, String] {
  match value {
    True => Ok(@manifest.ExtensionSetting::enabled())
    False => Ok(@manifest.ExtensionSetting::disabled())
    Object(options) =>
      Ok(
        @manifest.ExtensionSetting::enabled(
          options=Some(Json::object(clone_json_object(options))),
        ),
      )
    _ => Err("expected boolean or object for app manifest.extensions." + name)
  }
}

///|
/// Rejects legacy `permissions` config that is no longer supported.
fn reject_unsupported_permissions(json : Json?) -> Result[Unit, String] {
  match json {
    None => Ok(())
    Some(_) => Err("app manifest.permissions is no longer supported; remove it")
  }
}
