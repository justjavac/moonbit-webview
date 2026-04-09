///|
/// Converts the optional textual `size_hint` into the manifest enum value.
fn parse_size_hint(
  size_hint : String?,
) -> Result[@manifest.WindowSizeHint, String] {
  match size_hint {
    None => Ok(@manifest.WindowSizeHint::None)
    Some(size_hint) =>
      match normalize_keyword(size_hint) {
        "none" => Ok(@manifest.WindowSizeHint::None)
        "min" => Ok(@manifest.WindowSizeHint::Min)
        "max" => Ok(@manifest.WindowSizeHint::Max)
        "fixed" => Ok(@manifest.WindowSizeHint::Fixed)
        _ => Err("unsupported window size_hint: " + size_hint)
      }
  }
}

///|
/// Resolves a relative config path against the config file base directory.
fn rebase_relative_path(path : String, base_dir : String?) -> String {
  match base_dir {
    None => path
    Some(base_dir) => {
      let candidate : @mbpath.Path = path
      if candidate.is_absolute() {
        path
      } else {
        let base : @mbpath.Path = base_dir
        base.join(path).normalize().to_string()
      }
    }
  }
}

///|
/// Resolves the absolute directory that contains a config file path.
fn config_base_dir(path : String) -> String {
  let raw_dirname = dirname_string(path)
  let config_dir : @mbpath.Path = raw_dirname
  config_dir.resolve().to_string()
}

///|
/// Trims and lowercases config keywords before comparison.
fn normalize_keyword(raw : String) -> String {
  raw.trim().to_string().to_lower()
}

///|
/// Returns the directory portion of a path using both slash styles.
fn dirname_string(path : String) -> String {
  let mut separator_index : Int? = None
  for i, ch in path {
    if ch == '/' || ch == '\\' {
      separator_index = Some(i)
    }
  }
  match separator_index {
    None => "."
    Some(separator_index) => prefix_string(path, separator_index)
  }
}

///|
/// Copies the path prefix that ends just before `end_exclusive`.
fn prefix_string(path : String, end_exclusive : Int) -> String {
  let builder = StringBuilder::new(size_hint=end_exclusive)
  for i, ch in path {
    if i >= end_exclusive {
      break
    }
    builder.write_char(ch)
  }
  builder.to_string()
}

///|
/// Returns the optional integer or a fallback default.
fn int_or_default(value : Int?, fallback : Int) -> Int {
  match value {
    Some(value) => value
    None => fallback
  }
}
