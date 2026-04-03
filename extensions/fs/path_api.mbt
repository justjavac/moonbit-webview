///|
priv struct ReadFilePayload {
  path : String
  encoding : String?
} derive(FromJson)

///|
priv struct ReadFileReply {
  path : String
  content : String
  bytes_read : Int
} derive(ToJson)

///|
priv struct WriteFilePayload {
  path : String
  content : String
  encoding : String?
  flush : Bool?
} derive(FromJson)

///|
priv struct WriteFileReply {
  path : String
  written : Bool
  bytes_written : Int
} derive(ToJson)

///|
priv struct AppendFilePayload {
  path : String
  content : String
  encoding : String?
  flush : Bool?
} derive(FromJson)

///|
priv struct AppendFileReply {
  path : String
  written : Bool
  bytes_written : Int
} derive(ToJson)

///|
priv struct StatPayload {
  path : String
  throw_if_no_entry : Bool?
} derive(FromJson)

///|
priv struct StatReply {
  path : String
  exists : Bool
  size : Int
  is_file : Bool
  is_dir : Bool
  is_readonly : Bool
} derive(ToJson)

///|
priv struct ReaddirPayload {
  path : String
  recursive : Bool?
} derive(FromJson)

///|
priv struct ReaddirReply {
  path : String
  entries : Array[String]
} derive(ToJson)

///|
priv struct MkdirPayload {
  path : String
  recursive : Bool?
} derive(FromJson)

///|
priv struct MkdirReply {
  path : String
  created : Bool
} derive(ToJson)

///|
priv struct RemovePathPayload {
  path : String
  recursive : Bool?
  force : Bool?
} derive(FromJson)

///|
priv struct RemovePathReply {
  path : String
  removed : Bool
} derive(ToJson)

///|
priv struct RenamePayload {
  old_path : String
  new_path : String
} derive(FromJson)

///|
priv struct RenameReply {
  old_path : String
  new_path : String
  renamed : Bool
} derive(ToJson)

///|
priv struct CopyFilePayload {
  src : String
  dest : String
  overwrite : Bool?
} derive(FromJson)

///|
priv struct CopyFileReply {
  src : String
  dest : String
  copied : Bool
  bytes_copied : Int
} derive(ToJson)

///|
priv struct TruncatePayload {
  path : String
  len : Int?
} derive(FromJson)

///|
priv struct TruncateReply {
  path : String
  size : Int
  truncated : Bool
} derive(ToJson)

///|
priv struct SizePayload {
  path : String
} derive(FromJson)

///|
priv struct SizeReply {
  path : String
  size : Int
} derive(ToJson)

///|
priv struct NativeStatData {
  exists : Bool
  size : Int
  is_file : Bool
  is_dir : Bool
  is_readonly : Bool
} derive(FromJson)

///|
#borrow(path)
extern "C" fn native_stat_json_ffi(path : Bytes) -> Bytes = "extensions_fs_stat_json_ffi"

///|
extern "C" fn native_last_error_message_ffi() -> Bytes = "extensions_fs_last_error_message"

///|
#borrow(old_path, new_path)
extern "C" fn native_rename_path_ffi(old_path : Bytes, new_path : Bytes) -> Int = "extensions_fs_rename_ffi"

///|
#borrow(src, dest)
extern "C" fn native_copy_file_ffi(
  src : Bytes,
  dest : Bytes,
  overwrite : Int,
) -> Int = "extensions_fs_copy_file_ffi"

///|
#borrow(path, content)
extern "C" fn native_append_bytes_ffi(
  path : Bytes,
  content : Bytes,
  content_len : Int,
) -> Int = "extensions_fs_append_bytes_ffi"

///|
#borrow(path)
extern "C" fn native_realpath_ffi(path : Bytes) -> Bytes = "extensions_fs_realpath_ffi"

///|
#borrow(path)
extern "C" fn native_truncate_file_ffi(path : Bytes, len : Int) -> Int = "extensions_fs_truncate_file_ffi"

///|
fn option_bool(value : Bool?, default_value : Bool) -> Bool {
  match value {
    Some(value) => value
    None => default_value
  }
}

///|
fn encode_native_path_bytes(path : String) -> Bytes {
  @ffi.to_cstr(path)
}

///|
fn decode_native_text(bytes : Bytes) -> String {
  @ffi.from_cstr(bytes)
}

///|
fn native_last_error_message() -> String {
  let message = decode_native_text(native_last_error_message_ffi())
  if message == "" {
    "unknown OS error"
  } else {
    message
  }
}

///|
fn resolve_text_encoding(encoding : String?) -> Result[String, String] {
  match encoding {
    None => Ok("utf8")
    Some(encoding) => {
      let normalized = encoding.to_lower()
      if normalized == "utf8" || normalized == "utf-8" {
        Ok("utf8")
      } else {
        Err("Unsupported encoding: " + encoding + ", only utf8 is supported")
      }
    }
  }
}

///|
fn bytes_written_for_text(content : String) -> Int {
  encode_string_bytes(content).length()
}

///|
fn[Reply] with_supported_text_encoding(
  encoding : String?,
  callback : () -> Result[Reply, String],
) -> Result[Reply, String] {
  match resolve_text_encoding(encoding) {
    Err(error) => Err(error)
    Ok(_) => callback()
  }
}

///|
fn read_text_file(
  path : String,
  encoding : String?,
) -> Result[ReadFileReply, String] {
  with_supported_text_encoding(encoding, fn() {
    let content : Result[String, _] = try? @xfs.read_file_to_string(path)
    match content {
      Ok(content) =>
        Ok(ReadFileReply::{
          path,
          content,
          bytes_read: bytes_written_for_text(content),
        })
      Err(error) => Err("Failed to read file: " + error.to_string())
    }
  })
}

///|
fn write_text_file(
  path : String,
  content : String,
  encoding : String?,
) -> Result[WriteFileReply, String] {
  with_supported_text_encoding(encoding, fn() {
    let write_result : Result[Unit, _] = try? @xfs.write_string_to_file(
      path, content,
    )
    match write_result {
      Ok(_) =>
        Ok(WriteFileReply::{
          path,
          written: true,
          bytes_written: bytes_written_for_text(content),
        })
      Err(error) => Err("Failed to write file: " + error.to_string())
    }
  })
}

///|
fn append_text_file(
  path : String,
  content : String,
  encoding : String?,
) -> Result[AppendFileReply, String] {
  with_supported_text_encoding(encoding, fn() {
    let bytes = encode_string_bytes(content)
    let written = native_append_bytes_ffi(
      encode_native_path_bytes(path),
      bytes,
      bytes.length(),
    )
    guard written >= 0 else {
      return Err("Failed to append file: " + native_last_error_message())
    }
    Ok(AppendFileReply::{ path, written: true, bytes_written: written })
  })
}

///|
fn native_stat_info(path : String) -> Result[StatReply, String] {
  let stat_json = decode_native_text(
    native_stat_json_ffi(encode_native_path_bytes(path)),
  )
  let parsed_json : Result[Json, _] = try? @json.parse(stat_json)
  match parsed_json {
    Err(error) => Err("Failed to stat path: " + error.to_string())
    Ok(parsed_json) => {
      let decoded : Result[NativeStatData, _] = try? @json.from_json(
        parsed_json,
      )
      match decoded {
        Err(error) => Err("Failed to decode path stat: " + error.to_string())
        Ok(decoded) =>
          Ok(StatReply::{
            path,
            exists: decoded.exists,
            size: decoded.size,
            is_file: decoded.is_file,
            is_dir: decoded.is_dir,
            is_readonly: decoded.is_readonly,
          })
      }
    }
  }
}

///|
fn stat_path(
  path : String,
  throw_if_no_entry : Bool,
) -> Result[StatReply, String] {
  match native_stat_info(path) {
    Err(error) => Err(error)
    Ok(stat) =>
      if !stat.exists && throw_if_no_entry {
        Err("Failed to stat path: path does not exist")
      } else {
        Ok(stat)
      }
  }
}

///|
fn last_native_separator_index(path : String) -> Int {
  let mut index = path.length() - 1
  while index >= 0 {
    if path[index] == '/' {
      return index
    }
    index -= 1
  }
  -1
}

///|
fn trim_trailing_slash(path : String) -> String {
  if path.length() <= 1 {
    return path
  }
  if path.length() == 3 && path[1] == ':' && path[2] == '/' {
    return path
  }
  let mut end = path.length()
  while end > 1 && path[end - 1] == '/' {
    end -= 1
  }
  path[:end].to_string()
}

///|
fn native_parent_path(path : String) -> String {
  let normalized = trim_trailing_slash(lexical_normalize_native_path(path))
  if normalized == "." || normalized == "/" {
    return normalized
  }
  if normalized.length() == 3 && normalized[1] == ':' && normalized[2] == '/' {
    return normalized
  }
  let separator = last_native_separator_index(normalized)
  if separator < 0 {
    "."
  } else if separator == 0 {
    "/"
  } else if separator == 2 && normalized[1] == ':' {
    normalized[:3].to_string()
  } else {
    normalized[:separator].to_string()
  }
}

///|
fn join_native_child_path(path : String, child : String) -> String {
  let base = trim_trailing_slash(lexical_normalize_native_path(path))
  if base == "." {
    lexical_normalize_native_path(child)
  } else if base == "/" ||
    (base.length() == 3 && base[1] == ':' && base[2] == '/') {
    lexical_normalize_native_path(base + child)
  } else {
    lexical_normalize_native_path(base + "/" + child)
  }
}

///|
fn join_relative_entry(prefix : String, child : String) -> String {
  if prefix == "" {
    child
  } else {
    prefix + "/" + child
  }
}

///|
fn for_each_dir_entry(
  path : String,
  callback : (String) -> Result[Unit, String],
) -> Result[Unit, String] {
  match native_read_dir(path) {
    Err(error) => Err(error)
    Ok(entries) => {
      for entry in entries {
        match callback(entry) {
          Ok(_) => ()
          Err(error) => return Err(error)
        }
      }
      Ok(())
    }
  }
}

///|
fn collect_readdir_entries(
  path : String,
  prefix : String,
  recursive : Bool,
  output : Array[String],
) -> Result[Unit, String] {
  for_each_dir_entry(path, fn(entry) {
    let relative = join_relative_entry(prefix, entry)
    output.push(relative)
    if recursive {
      let child_path = join_native_child_path(path, entry)
      if is_path_dir(child_path) {
        match collect_readdir_entries(child_path, relative, recursive, output) {
          Ok(_) => ()
          Err(error) => return Err(error)
        }
      } else {
        ()
      }
    }
    Ok(())
  })
}

///|
fn readdir_entries(
  path : String,
  recursive : Bool,
) -> Result[Array[String], String] {
  let entries : Array[String] = []
  match collect_readdir_entries(path, "", recursive, entries) {
    Ok(_) => Ok(entries)
    Err(error) => Err(error)
  }
}

///|
fn native_create_dir(path : String) -> Result[Bool, String] {
  if native_path_exists(path) {
    if is_path_dir(path) {
      Ok(false)
    } else {
      Err(
        "Failed to create directory: path already exists and is not a directory",
      )
    }
  } else {
    let result : Result[Unit, _] = try? @xfs.create_dir(path)
    match result {
      Ok(_) => Ok(true)
      Err(error) => Err("Failed to create directory: " + error.to_string())
    }
  }
}

///|
fn mkdir_path(path : String, recursive : Bool) -> Result[Bool, String] {
  if native_path_exists(path) {
    if is_path_dir(path) {
      return Ok(false)
    } else {
      return Err(
        "Failed to create directory: path already exists and is not a directory",
      )
    }
  }

  let parent = native_parent_path(path)
  if recursive && parent != path && parent != "." && !native_path_exists(parent) {
    match mkdir_path(parent, true) {
      Ok(_) => ()
      Err(error) => return Err(error)
    }
  }

  native_create_dir(path)
}

///|
fn native_remove_dir(path : String) -> Result[Bool, String] {
  if !native_path_exists(path) {
    return Ok(false)
  }
  let removed : Result[Unit, _] = try? @xfs.remove_dir(path)
  match removed {
    Ok(_) => Ok(true)
    Err(error) => Err("Failed to remove directory: " + error.to_string())
  }
}

///|
fn remove_path_recursive(path : String) -> Result[Bool, String] {
  match native_stat_info(path) {
    Err(error) => Err(error)
    Ok(stat) =>
      if !stat.exists {
        Ok(false)
      } else if stat.is_file {
        native_remove_file(path)
      } else if stat.is_dir {
        match
          for_each_dir_entry(path, fn(entry) {
            let child_path = join_native_child_path(path, entry)
            match remove_path_recursive(child_path) {
              Ok(_) => Ok(())
              Err(error) => Err(error)
            }
          }) {
          Ok(_) => native_remove_dir(path)
          Err(error) => Err(error)
        }
      } else {
        Err("Failed to remove path: unsupported filesystem entry")
      }
  }
}

///|
fn remove_path(
  path : String,
  recursive : Bool,
  force : Bool,
) -> Result[Bool, String] {
  match native_stat_info(path) {
    Err(error) => Err(error)
    Ok(stat) =>
      if !stat.exists {
        if force {
          Ok(false)
        } else {
          Err("Failed to remove path: path does not exist")
        }
      } else if stat.is_file {
        native_remove_file(path)
      } else if stat.is_dir {
        if recursive {
          remove_path_recursive(path)
        } else {
          native_remove_dir(path)
        }
      } else {
        Err("Failed to remove path: unsupported filesystem entry")
      }
  }
}

///|
fn recursive_path_size(path : String) -> Result[Int, String] {
  match native_stat_info(path) {
    Err(error) => Err(error)
    Ok(stat) =>
      if !stat.exists {
        Err("Failed to read path size: path does not exist")
      } else if stat.is_file {
        Ok(stat.size)
      } else if stat.is_dir {
        let mut total = 0
        match
          for_each_dir_entry(path, fn(entry) {
            match recursive_path_size(join_native_child_path(path, entry)) {
              Ok(size) => {
                total += size
                Ok(())
              }
              Err(error) => Err(error)
            }
          }) {
          Ok(_) => Ok(total)
          Err(error) => Err(error)
        }
      } else {
        Err("Failed to read path size: unsupported filesystem entry")
      }
  }
}

///|
fn rename_path(old_path : String, new_path : String) -> Result[Unit, String] {
  guard native_rename_path_ffi(
      encode_native_path_bytes(old_path),
      encode_native_path_bytes(new_path),
    ) ==
    0 else {
    return Err("Failed to rename path: " + native_last_error_message())
  }
  Ok(())
}

///|
fn copy_file_path(
  src : String,
  dest : String,
  overwrite : Bool,
) -> Result[Int, String] {
  let copied = native_copy_file_ffi(
    encode_native_path_bytes(src),
    encode_native_path_bytes(dest),
    if overwrite {
      1
    } else {
      0
    },
  )
  guard copied >= 0 else {
    return Err("Failed to copy file: " + native_last_error_message())
  }
  Ok(copied)
}

///|
fn realpath_path(path : String) -> Result[String, String] {
  let resolved = decode_native_text(
    native_realpath_ffi(encode_native_path_bytes(path)),
  )
  guard resolved != "" else {
    return Err("Failed to resolve real path: " + native_last_error_message())
  }
  Ok(lexical_normalize_native_path(resolved))
}

///|
fn truncate_path(path : String, len : Int) -> Result[Int, String] {
  guard len >= 0 else {
    return Err("Failed to truncate path: len must be non-negative")
  }
  guard native_truncate_file_ffi(encode_native_path_bytes(path), len) == 0 else {
    return Err("Failed to truncate path: " + native_last_error_message())
  }
  Ok(len)
}

///|
test "fs path api can read write and append text files" {
  let path = "moonbit-webview-fs-path-api.txt"
  match write_text_file(path, "hello", None) {
    Ok(reply) => {
      assert_true(reply.written)
      assert_eq(reply.bytes_written, 5)
    }
    Err(error) => abort(error)
  }
  match append_text_file(path, " world", None) {
    Ok(reply) => {
      assert_true(reply.written)
      assert_eq(reply.bytes_written, 6)
    }
    Err(error) => abort(error)
  }
  match read_text_file(path, None) {
    Ok(reply) => {
      assert_eq(reply.content, "hello world")
      assert_eq(reply.bytes_read, 11)
    }
    Err(error) => abort(error)
  }
  assert_eq(native_remove_file(path), Ok(true))
}

///|
test "fs path api can stat rename and copy files" {
  let path = "moonbit-webview-fs-stat-source.txt"
  let renamed = "moonbit-webview-fs-stat-renamed.txt"
  let copied = "moonbit-webview-fs-stat-copy.txt"
  ignore(write_text_file(path, "abc123", None))

  match stat_path(path, true) {
    Ok(stat) => {
      assert_true(stat.exists)
      assert_true(stat.is_file)
      assert_false(stat.is_dir)
      assert_eq(stat.size, 6)
    }
    Err(error) => abort(error)
  }

  match copy_file_path(path, copied, true) {
    Ok(bytes_copied) => assert_eq(bytes_copied, 6)
    Err(error) => abort(error)
  }
  match rename_path(path, renamed) {
    Ok(_) => ()
    Err(error) => abort(error)
  }
  assert_false(native_path_exists(path))
  assert_true(native_path_exists(renamed))
  assert_true(native_path_exists(copied))
  assert_eq(native_remove_file(renamed), Ok(true))
  assert_eq(native_remove_file(copied), Ok(true))
}

///|
test "fs path api can create directories recursively" {
  let root = "moonbit-webview-fs-dir-api"
  let child = join_native_child_path(root, "nested")

  if native_path_exists(root) {
    ignore(remove_path(root, true, true))
  }

  match mkdir_path(child, true) {
    Ok(created) => assert_true(created)
    Err(error) => abort(error)
  }

  assert_true(native_path_exists(root))
  assert_true(is_path_dir(root))
  assert_true(native_path_exists(child))
  assert_true(is_path_dir(child))

  assert_eq(native_remove_dir(child), Ok(true))
  assert_eq(native_remove_dir(root), Ok(true))
}

///|
test "fs path api can list directories recursively" {
  let root = "moonbit-webview-fs-list-api"
  let child = join_native_child_path(root, "nested")
  let file = join_native_child_path(child, "demo.txt")

  if native_path_exists(root) {
    ignore(remove_path(root, true, true))
  }

  match mkdir_path(child, true) {
    Ok(_) => ()
    Err(error) => abort(error)
  }
  ignore(write_text_file(file, "demo", None))

  match readdir_entries(root, true) {
    Ok(entries) => {
      assert_true(entries.contains("nested"))
      assert_true(entries.contains("nested/demo.txt"))
    }
    Err(error) => abort(error)
  }

  assert_eq(native_remove_file(file), Ok(true))
  assert_eq(native_remove_dir(child), Ok(true))
  assert_eq(native_remove_dir(root), Ok(true))
}

///|
test "fs path api can remove directories recursively" {
  let root = "moonbit-webview-fs-remove-api"
  let child = join_native_child_path(root, "nested")
  let file = join_native_child_path(child, "demo.txt")

  if native_path_exists(root) {
    ignore(remove_path(root, true, true))
  }

  match mkdir_path(child, true) {
    Ok(_) => ()
    Err(error) => abort(error)
  }
  ignore(write_text_file(file, "demo", None))

  match remove_path(root, true, false) {
    Ok(removed) => assert_true(removed)
    Err(error) => abort(error)
  }
  match stat_path(root, false) {
    Ok(stat) => assert_false(stat.exists)
    Err(error) => abort(error)
  }
}

///|
test "fs path api can truncate files and measure size" {
  let path = "moonbit-webview-fs-truncate.txt"
  ignore(write_text_file(path, "abcdef", None))

  match truncate_path(path, 3) {
    Ok(size) => assert_eq(size, 3)
    Err(error) => abort(error)
  }
  match read_text_file(path, None) {
    Ok(reply) => assert_eq(reply.content, "abc")
    Err(error) => abort(error)
  }
  match recursive_path_size(path) {
    Ok(size) => assert_eq(size, 3)
    Err(error) => abort(error)
  }
  assert_eq(native_remove_file(path), Ok(true))
}
