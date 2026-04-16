///|
/// Wraps a string as the native path abstraction used by this package.
fn native_path(path : String) -> @mbpath.Path {
  path
}

///|
/// Rewrites separators when the current platform expects backslashes.
fn prepare_native_path(path : String) -> String {
  if @mbpath.sep != '\\' {
    return path
  }
  let builder = StringBuilder::new(size_hint=path.length())
  for _, ch in path {
    builder.write_char(if ch == '/' { '\\' } else { ch })
  }
  builder.to_string()
}

///|
/// Returns the last path segment, optionally trimming a matching suffix.
fn basename_path(path : String, suffix? : String? = None) -> String {
  let normalized = normalize_path(path)
  let name = native_path(normalized).basename().to_string()
  match suffix {
    Some(suffix) =>
      if suffix != "" &&
        name.length() >= suffix.length() &&
        name.has_suffix(suffix) {
        name[:name.length() - suffix.length()].to_string()
      } else {
        name
      }
    None => name
  }
}

///|
/// Returns the parent directory portion of a path.
fn dirname_path(path : String) -> String {
  let normalized = normalize_path(path)
  native_path(normalized).dirname().to_string()
}

///|
/// Returns the file extension portion of a path.
fn extname_path(path : String) -> String {
  let normalized = normalize_path(path)
  native_path(normalized).extname().to_string()
}

///|
/// Returns whether a path is absolute on the current platform.
fn is_absolute_path(path : String) -> Bool {
  native_path(prepare_native_path(path)).is_absolute()
}

///|
/// Joins two path segments using the platform-native path rules.
fn join_paths(left : String, right : String) -> String {
  native_path(prepare_native_path(left))
  .join(prepare_native_path(right))
  .to_string()
}

///|
/// Joins many path segments while skipping empty entries.
fn join_many_paths(paths : Array[String]) -> String {
  let mut result = ""
  let mut found = false
  for path in paths {
    if path != "" {
      if found {
        result = join_paths(result, path)
      } else {
        result = path
        found = true
      }
    }
  }
  if found {
    normalize_path(result)
  } else {
    "."
  }
}

///|
/// Normalizes redundant path separators and dot segments.
fn normalize_path(path : String) -> String {
  native_path(prepare_native_path(path)).normalize().to_string()
}

///|
/// Computes the relative path from `base` to `path`.
fn relative_path(path : String, base : String) -> String {
  native_path(prepare_native_path(path))
  .relative(base=prepare_native_path(base))
  .to_string()
}

///|
/// Resolves a path against the current working directory.
fn resolve_path(path : String) -> String {
  native_path(prepare_native_path(path)).resolve().to_string()
}

///|
/// Joins many path segments and resolves the result to an absolute path.
fn resolve_many_paths(paths : Array[String]) -> String {
  if paths.length() == 0 {
    return resolve_path(".")
  }
  let joined = join_many_paths(paths)
  resolve_path(joined)
}

///|
/// Extracts the root component of a path, including Windows drive and UNC roots.
fn root_path(path : String) -> String {
  let normalized = normalize_path(path)
  if normalized == "." && !is_absolute_path(path) {
    return ""
  }
  if normalized.length() >= 3 &&
    normalized[1] == ':' &&
    (normalized[2] == '/' || normalized[2] == '\\') {
    return normalized[:3].to_string()
  }
  if normalized.has_prefix("//") || normalized.has_prefix("\\\\") {
    let mut slash_count = 0
    for index in 2..<normalized.length() {
      if normalized[index] == '/' || normalized[index] == '\\' {
        slash_count += 1
        if slash_count == 2 {
          return normalized[:index + 1].to_string()
        }
      }
    }
    return normalized[:2].to_string()
  }
  if normalized.has_prefix("/") || normalized.has_prefix("\\") {
    normalized[:1].to_string()
  } else {
    ""
  }
}

///|
/// Splits a path into the node-style `root`, `dir`, `base`, `ext`, and `name` parts.
fn parse_path(path : String) -> ParseReply {
  let base = basename_path(path)
  let ext = extname_path(path)
  let name = if ext != "" &&
    base.length() >= ext.length() &&
    base.has_suffix(ext) {
    base[:base.length() - ext.length()].to_string()
  } else {
    base
  }
  ParseReply::{
    root: root_path(path),
    dir: dirname_path(path),
    base,
    ext,
    name,
  }
}

///|
/// Converts an optional string into the empty-string fallback used by `format_path`.
fn option_string(value : String?) -> String {
  match value {
    Some(value) => value
    None => ""
  }
}

///|
/// Reassembles a path from node-style parsed path fields.
fn format_path(payload : FormatPayload) -> String {
  let root = option_string(payload.root)
  let dir = option_string(payload.dir)
  let base = match payload.base {
    Some(base) => base
    None => option_string(payload.name) + option_string(payload.ext)
  }
  if dir != "" {
    if base == "" {
      dir
    } else if dir == root {
      dir + base
    } else {
      join_paths(dir, base)
    }
  } else if root != "" {
    if base == "" {
      root
    } else if root.has_suffix("/") || root.has_suffix("\\") {
      root + base
    } else {
      root + "\{@mbpath.sep}" + base
    }
  } else {
    base
  }
}
