///|
fn parse_size_hint(size_hint : String?) -> Result[@webview.SizeHint, String] {
  match size_hint {
    None => Ok(@webview.SizeHint::None)
    Some(size_hint) =>
      match normalize_keyword(size_hint) {
        "none" => Ok(@webview.SizeHint::None)
        "min" => Ok(@webview.SizeHint::Min)
        "max" => Ok(@webview.SizeHint::Max)
        "fixed" => Ok(@webview.SizeHint::Fixed)
        _ => Err("unsupported window size_hint: " + size_hint)
      }
  }
}

///|
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
fn config_base_dir(path : String) -> String {
  let raw_dirname = dirname_string(path)
  let config_dir : @mbpath.Path = raw_dirname
  config_dir.resolve().to_string()
}

///|
fn normalize_keyword(raw : String) -> String {
  raw.trim().to_string().to_lower()
}

///|
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
fn int_or_default(value : Int?, fallback : Int) -> Int {
  match value {
    Some(value) => value
    None => fallback
  }
}
