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
/// Returns the optional boolean or a default fallback value.
fn option_bool(value : Bool?, default_value : Bool) -> Bool {
  match value {
    Some(value) => value
    None => default_value
  }
}

///|
/// Encodes a filesystem path for the native C helpers.
fn encode_native_path_bytes(path : String) -> Bytes {
  @ffi.to_cstr(path)
}

///|
/// Decodes a C string returned by the native filesystem helpers.
fn decode_native_text(bytes : Bytes) -> String {
  @ffi.from_cstr(bytes)
}

///|
/// Returns the most recent native filesystem error message.
fn native_last_error_message() -> String {
  let message = decode_native_text(native_last_error_message_ffi())
  if message == "" {
    "unknown OS error"
  } else {
    message
  }
}

///|
/// Validates that the requested text encoding is supported.
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
/// Returns the UTF-8 byte count for a string payload.
fn bytes_written_for_text(content : String) -> Int {
  encode_string_bytes(content).length()
}

///|
/// Runs a text-file operation only when the requested encoding is supported.
fn[Reply] with_supported_text_encoding(
  encoding : String?,
  callback : () -> Result[Reply, String],
) -> Result[Reply, String] {
  resolve_text_encoding(encoding).bind(fn(_) { callback() })
}

///|
/// Reads a text file and returns its content plus byte length metadata.
fn read_text_file(
  path : String,
  encoding : String?,
) -> Result[ReadFileReply, String] {
  with_supported_text_encoding(encoding, fn() {
    let content : Result[String, _] = try? @xfs.read_file_to_string(path)
    content
    .map_err(fn(error) { "Failed to read file: " + error.to_string() })
    .map(fn(content) {
      ReadFileReply::{
        path,
        content,
        bytes_read: bytes_written_for_text(content),
      }
    })
  })
}

///|
/// Writes a full text file and returns its byte length metadata.
fn write_text_file(
  path : String,
  content : String,
  encoding : String?,
) -> Result[WriteFileReply, String] {
  with_supported_text_encoding(encoding, fn() {
    let write_result : Result[Unit, _] = try? @xfs.write_string_to_file(
      path, content,
    )
    write_result
    .map_err(fn(error) { "Failed to write file: " + error.to_string() })
    .map(fn(_) {
      WriteFileReply::{
        path,
        written: true,
        bytes_written: bytes_written_for_text(content),
      }
    })
  })
}

///|
/// Appends UTF-8 text to an existing file through the native append helper.
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
/// Reads native stat information and decodes it into the public reply shape.
fn native_stat_info(path : String) -> Result[StatReply, String] {
  let stat_json = decode_native_text(
    native_stat_json_ffi(encode_native_path_bytes(path)),
  )
  let parsed_json : Result[Json, _] = try? @json.parse(stat_json)
  parsed_json
  .map_err(fn(error) { "Failed to stat path: " + error.to_string() })
  .bind(fn(parsed_json) {
    let decoded : Result[NativeStatData, _] = try? @json.from_json(parsed_json)
    decoded
    .map_err(fn(error) { "Failed to decode path stat: " + error.to_string() })
    .map(fn(decoded) {
      StatReply::{
        path,
        exists: decoded.exists,
        size: decoded.size,
        is_file: decoded.is_file,
        is_dir: decoded.is_dir,
        is_readonly: decoded.is_readonly,
      }
    })
  })
}

///|
/// Returns stat information and optionally errors when the path does not exist.
fn stat_path(
  path : String,
  throw_if_no_entry : Bool,
) -> Result[StatReply, String] {
  native_stat_info(path).bind(fn(stat) {
    if !stat.exists && throw_if_no_entry {
      Err("Failed to stat path: path does not exist")
    } else {
      Ok(stat)
    }
  })
}

///|
/// Returns the last forward-slash position in a normalized native path.
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
/// Removes trailing slashes while preserving filesystem roots.
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
/// Returns the parent directory of a normalized native path.
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
/// Joins a child entry name onto a normalized native directory path.
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
/// Builds a relative child entry path used by recursive directory traversal.
fn join_relative_entry(prefix : String, child : String) -> String {
  if prefix == "" {
    child
  } else {
    prefix + "/" + child
  }
}

///|
/// Iterates the entries of one directory and forwards them to a callback.
fn for_each_dir_entry(
  path : String,
  callback : (String) -> Result[Unit, String],
) -> Result[Unit, String] {
  native_read_dir(path).bind(fn(entries) {
    for entry in entries {
      match callback(entry) {
        Ok(_) => ()
        Err(error) => return Err(error)
      }
    }
    Ok(())
  })
}

///|
/// Collects directory entries recursively into the supplied output array.
fn collect_readdir_entries(
  path : String,
  prefix : String,
  recursive : Bool,
  output : Array[String],
) -> Result[Unit, String] {
  for_each_dir_entry(path, fn(entry) {
    let relative = join_relative_entry(prefix, entry)
    output.push(relative)
    let child_path = join_native_child_path(path, entry)
    if recursive && is_path_dir(child_path) {
      collect_readdir_entries(child_path, relative, recursive, output)
    } else {
      Ok(())
    }
  })
}

///|
/// Returns the directory entries of a path, optionally traversing recursively.
fn readdir_entries(
  path : String,
  recursive : Bool,
) -> Result[Array[String], String] {
  let entries : Array[String] = []
  collect_readdir_entries(path, "", recursive, entries).map(fn(_) { entries })
}

///|
/// Creates one directory when it does not already exist.
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
/// Creates a directory and, when requested, any missing parent directories.
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

  ensure_mkdir_parent(path, recursive).bind(fn(_) { native_create_dir(path) })
}

///|
/// Removes an empty directory if it exists.
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
/// Recursively removes a filesystem path and all of its children.
fn remove_path_recursive(path : String) -> Result[Bool, String] {
  native_stat_info(path).bind(fn(stat) {
    remove_path_recursive_from_stat(path, stat)
  })
}

///|
/// Removes a file or directory while honoring the `recursive` and `force` flags.
fn remove_path(
  path : String,
  recursive : Bool,
  force : Bool,
) -> Result[Bool, String] {
  native_stat_info(path).bind(fn(stat) {
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
        remove_path_recursive_from_stat(path, stat)
      } else {
        native_remove_dir(path)
      }
    } else {
      Err("Failed to remove path: unsupported filesystem entry")
    }
  })
}

///|
/// Computes the total size of a file or recursively traversed directory.
fn recursive_path_size(path : String) -> Result[Int, String] {
  native_stat_info(path).bind(fn(stat) {
    if !stat.exists {
      Err("Failed to read path size: path does not exist")
    } else if stat.is_file {
      Ok(stat.size)
    } else if stat.is_dir {
      sum_directory_path_size(path)
    } else {
      Err("Failed to read path size: unsupported filesystem entry")
    }
  })
}

///|
/// Ensures a recursive mkdir request has created any missing parent directories first.
fn ensure_mkdir_parent(path : String, recursive : Bool) -> Result[Unit, String] {
  let parent = native_parent_path(path)
  if recursive && parent != path && parent != "." && !native_path_exists(parent) {
    mkdir_path(parent, true).map(fn(_) { () })
  } else {
    Ok(())
  }
}

///|
/// Removes a known filesystem entry, recursing into directories when required.
fn remove_path_recursive_from_stat(
  path : String,
  stat : StatReply,
) -> Result[Bool, String] {
  if !stat.exists {
    Ok(false)
  } else if stat.is_file {
    native_remove_file(path)
  } else if stat.is_dir {
    for_each_dir_entry(path, fn(entry) {
      remove_path_recursive(join_native_child_path(path, entry)).map(fn(_) {
        ()
      })
    }).bind(fn(_) { native_remove_dir(path) })
  } else {
    Err("Failed to remove path: unsupported filesystem entry")
  }
}

///|
/// Sums the size of every entry beneath one directory path.
fn sum_directory_path_size(path : String) -> Result[Int, String] {
  let mut total = 0
  for_each_dir_entry(path, fn(entry) {
    recursive_path_size(join_native_child_path(path, entry)).map(fn(size) {
      total += size
      ()
    })
  }).map(fn(_) { total })
}

///|
/// Renames or moves a filesystem path through the native helper.
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
/// Copies one file through the native helper and returns the copied byte count.
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
/// Resolves a path to its canonical real path through the native helper.
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
/// Truncates a file to the requested byte length.
fn truncate_path(path : String, len : Int) -> Result[Int, String] {
  guard len >= 0 else {
    return Err("Failed to truncate path: len must be non-negative")
  }
  guard native_truncate_file_ffi(encode_native_path_bytes(path), len) == 0 else {
    return Err("Failed to truncate path: " + native_last_error_message())
  }
  Ok(len)
}
