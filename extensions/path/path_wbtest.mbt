///|
test "path helper script stays with path extension assets" {
  let script = path_helper_script()
  assert_true(script.contains("const rootName = \"__MoonBit__\";"))
  assert_true(script.contains("const extensionName = \"path\";"))
  assert_true(script.contains("@@nodeStylePath"))
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
