// TODO(justjavac): 重构整个 config 模块，重写 config 逻辑。

///|
fn[Value, Next] and_then(
  result : Result[Value, String],
  next : (Value) -> Result[Next, String],
) -> Result[Next, String] {
  match result {
    Ok(value) => next(value)
    Err(error) => Err(error)
  }
}

///|
fn[Value, Next] map_ok(
  result : Result[Value, String],
  f : (Value) -> Next,
) -> Result[Next, String] {
  match result {
    Ok(value) => Ok(f(value))
    Err(error) => Err(error)
  }
}

///|
fn[Value] required_built_field(
  object : Map[String, Json],
  key : String,
  label : String,
  build : (Json) -> Result[Value, String],
) -> Result[Value, String] {
  and_then(required_field(object, key, label), build)
}

///|
fn build_app_config_from_json(
  json : Json,
  base_dir : String?,
) -> Result[BootstrapAppConfig, String] {
  and_then(expect_object(json, "app config"), fn(object) {
    and_then(
      required_built_field(
        object, "window", "app config.window", build_window_config_from_json,
      ),
      fn(window) {
        and_then(
          required_built_field(object, "entry", "app config.entry", fn(
            entry_json,
          ) {
            build_app_entry_from_json(entry_json, base_dir)
          }),
          fn(entry) {
            and_then(
              build_app_windows_from_json(
                optional_field(object, "windows"),
                base_dir,
              ),
              fn(windows) {
                and_then(
                  reject_unsupported_permissions(
                    optional_field(object, "permissions"),
                  ),
                  fn(_) {
                    and_then(
                      validate_extension_options_shape(
                        optional_field(object, "extensions"),
                      ),
                      fn(_) {
                        map_ok(
                          decode_optional_int(
                            optional_field(object, "debug"),
                            "app config.debug",
                          ),
                          fn(debug) {
                            BootstrapAppConfig::new(
                              window,
                              entry,
                              debug=int_or_default(debug, 0),
                              windows~,
                              base_dir~,
                            )
                          },
                        )
                      },
                    )
                  },
                )
              },
            )
          },
        )
      },
    )
  })
}

///|
fn build_window_config_from_json(
  json : Json,
) -> Result[@wvrt.WindowConfig, String] {
  and_then(expect_object(json, "window config"), fn(object) {
    and_then(required_string_field(object, "title", "window.title"), fn(title) {
      and_then(required_int_field(object, "width", "window.width"), fn(width) {
        and_then(required_int_field(object, "height", "window.height"), fn(
          height,
        ) {
          and_then(
            decode_optional_string(
              optional_field(object, "size_hint"),
              "window.size_hint",
            ),
            fn(size_hint) {
              map_ok(parse_size_hint(size_hint), fn(size_hint) {
                @wvrt.WindowConfig::new(title, width, height, size_hint~)
              })
            },
          )
        })
      })
    })
  })
}

///|
fn build_app_entry_from_json(
  json : Json,
  base_dir : String?,
) -> Result[@wvrt.AppEntry, String] {
  and_then(expect_object(json, "app entry"), fn(object) {
    and_then(required_string_field(object, "kind", "entry.kind"), fn(kind) {
      and_then(required_string_field(object, "value", "entry.value"), fn(
        value,
      ) {
        let normalized_kind = normalize_keyword(kind)
        let rebased_value = match normalized_kind {
          "file" => rebase_relative_path(value, base_dir)
          _ => value
        }
        match normalized_kind {
          "html" => Ok(@wvrt.AppEntry::Html(rebased_value))
          "url" => Ok(@wvrt.AppEntry::Url(rebased_value))
          "file" => Ok(@wvrt.AppEntry::File(rebased_value))
          _ => Err("unsupported app entry kind: " + kind)
        }
      })
    })
  })
}

///|
fn build_app_windows_from_json(
  json : Json?,
  base_dir : String?,
) -> Result[Array[@wvrt.AppWindowConfig], String] {
  match json {
    None => Ok([])
    Some(Array(items)) => {
      let windows : Array[@wvrt.AppWindowConfig] = []
      for index, item in items {
        match build_app_window_from_json(item, base_dir, index) {
          Ok(window) => windows.push(window)
          Err(error) => return Err(error)
        }
      }
      Ok(windows)
    }
    Some(_) => Err("expected array for app config.windows")
  }
}

///|
fn build_app_window_from_json(
  json : Json,
  base_dir : String?,
  index : Int,
) -> Result[@wvrt.AppWindowConfig, String] {
  let label = "windows[" + index.to_string() + "]"
  and_then(expect_object(json, label), fn(object) {
    and_then(required_string_field(object, "id", label + ".id"), fn(id) {
      and_then(
        required_built_field(
          object,
          "window",
          label + ".window",
          build_window_config_from_json,
        ),
        fn(window) {
          map_ok(
            required_built_field(object, "entry", label + ".entry", fn(
              entry_json,
            ) {
              build_app_entry_from_json(entry_json, base_dir)
            }),
            fn(entry) { @wvrt.AppWindowConfig::new(id, window, entry) },
          )
        },
      )
    })
  })
}

///|
fn reject_unsupported_permissions(json : Json?) -> Result[Unit, String] {
  match json {
    None => Ok(())
    Some(_) => Err("app config.permissions is no longer supported; remove it")
  }
}

///|
fn validate_extension_options_shape(json : Json?) -> Result[Unit, String] {
  match json {
    None => Ok(())
    Some(Object(object)) => {
      for name, value in object {
        guard normalize_keyword(name) != "" else {
          return Err("app config.extensions contains an empty key")
        }
        guard value is Object(_) else {
          return Err("expected object for app config.extensions." + name)
        }
      }
      Ok(())
    }
    Some(_) => Err("expected object for app config.extensions")
  }
}
