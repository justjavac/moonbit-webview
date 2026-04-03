///|
fn native_path(path : String) -> @mbpath.Path {
  path
}

///|
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
fn dirname_path(path : String) -> String {
  let normalized = normalize_path(path)
  native_path(normalized).dirname().to_string()
}

///|
fn extname_path(path : String) -> String {
  let normalized = normalize_path(path)
  native_path(normalized).extname().to_string()
}

///|
fn is_absolute_path(path : String) -> Bool {
  native_path(prepare_native_path(path)).is_absolute()
}

///|
fn join_paths(left : String, right : String) -> String {
  native_path(prepare_native_path(left))
  .join(prepare_native_path(right))
  .to_string()
}

///|
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
fn normalize_path(path : String) -> String {
  native_path(prepare_native_path(path)).normalize().to_string()
}

///|
fn relative_path(path : String, base : String) -> String {
  native_path(prepare_native_path(path))
  .relative(base=prepare_native_path(base))
  .to_string()
}

///|
fn resolve_path(path : String) -> String {
  native_path(prepare_native_path(path)).resolve().to_string()
}

///|
fn resolve_many_paths(paths : Array[String]) -> String {
  if paths.length() == 0 {
    return resolve_path(".")
  }
  let joined = join_many_paths(paths)
  resolve_path(joined)
}

///|
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
fn option_string(value : String?) -> String {
  match value {
    Some(value) => value
    None => ""
  }
}

///|
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

///|
test "path extension helpers expose basename dirname and extname" {
  let path = join_paths(join_paths("extensions", "path"), "example.txt")
  assert_eq(basename_path(path), "example.txt")
  assert_eq(basename_path(path, suffix=Some(".txt")), "example")
  assert_eq(extname_path(path), ".txt")
  assert_eq(basename_path(dirname_path(path)), "path")
}

///|
test "path extension helpers resolve absolute and relative paths" {
  let base = resolve_path("extensions")
  let child = join_paths(base, "path")
  assert_true(is_absolute_path(base))
  let relative = join_paths("extensions", "path")
  assert_false(is_absolute_path(relative))
  assert_eq(relative_path(child, base), "path")
  assert_eq(resolve_many_paths(["extensions", "path"]), child)
}

///|
test "path extension helpers normalize mixed segments" {
  let mixed = join_paths(join_paths(".", "path"), "..")
  let mixed = join_paths(mixed, "path")
  let normalized = normalize_path(mixed)
  assert_eq(basename_path(normalized), "path")
  assert_eq(join_many_paths([".", "path", "..", "path"]), normalized)
}

///|
test "path extension can parse and format node style path objects" {
  let parsed = parse_path("extensions/path/example.txt")
  assert_eq(parsed.base, "example.txt")
  assert_eq(parsed.ext, ".txt")
  assert_eq(parsed.name, "example")
  assert_eq(
    format_path(FormatPayload::{
      root: None,
      dir: Some(join_paths("extensions", "path")),
      base: Some("example.txt"),
      name: None,
      ext: None,
    }),
    join_paths("extensions", "path/example.txt"),
  )
}
