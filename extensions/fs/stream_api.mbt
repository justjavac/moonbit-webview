///|
priv struct FileOpenMode {
  can_read : Bool
  can_write : Bool
  create_if_missing : Bool
  truncate_on_open : Bool
  append_on_write : Bool
}

///|
priv struct MemoryFileHandle {
  path : String
  mode : FileOpenMode
  mut content : Bytes
  mut cursor : Int
  mut dirty : Bool
}

///|
struct OpenPayload {
  path : String
  mode : String
} derive(ToJson, FromJson, Show, Eq)

///|
priv struct OpenFilePayload {
  path : String
  flags : String?
  read : Bool?
  write : Bool?
  append : Bool?
  create : Bool?
  truncate : Bool?
  create_new : Bool?
} derive(FromJson)

///|
struct OpenReply {
  rid : Int
} derive(ToJson, FromJson, Show, Eq)

///|
struct ReadPayload {
  rid : Int
  size : Int
} derive(ToJson, FromJson, Show, Eq)

///|
struct ReadReply {
  content : String
  bytes_read : Int
  eof : Bool
} derive(ToJson, FromJson, Show, Eq)

///|
struct WritePayload {
  rid : Int
  content : String
} derive(ToJson, FromJson, Show, Eq)

///|
struct WriteReply {
  bytes_written : Int
} derive(ToJson, FromJson, Show, Eq)

///|
struct ClosePayload {
  rid : Int
} derive(ToJson, FromJson, Show, Eq)

///|
struct CloseReply {
  closed : Bool
} derive(ToJson, FromJson, Show, Eq)

///|
struct FlushPayload {
  rid : Int
} derive(ToJson, FromJson, Show, Eq)

///|
struct FlushReply {
  flushed : Bool
} derive(ToJson, FromJson, Show, Eq)

///|
struct SeekPayload {
  rid : Int
  offset : Int
  whence : String
} derive(ToJson, FromJson, Show, Eq)

///|
struct SeekReply {
  position : Int
} derive(ToJson, FromJson, Show, Eq)

///|
struct FstatPayload {
  rid : Int
} derive(ToJson, FromJson, Show, Eq)

///|
struct FstatReply {
  path : String?
  size : Int
  position : Int
  eof : Bool
  exists : Bool
  is_file : Bool
  is_dir : Bool
} derive(ToJson, FromJson, Show, Eq)

///|
struct ExistsPayload {
  path : String
} derive(ToJson, FromJson, Show, Eq)

///|
struct ExistsReply {
  exists : Bool
} derive(ToJson, FromJson, Show, Eq)

///|
struct RemoveFilePayload {
  path : String
} derive(ToJson, FromJson, Show, Eq)

///|
struct RemoveFileReply {
  removed : Bool
} derive(ToJson, FromJson, Show, Eq)

///|
struct ReadDirPayload {
  path : String
} derive(ToJson, FromJson, Show, Eq)

///|
struct ReadDirReply {
  entries : Array[String]
} derive(ToJson, FromJson, Show, Eq)

///|
struct ResolvePathPayload {
  path : String
} derive(ToJson, FromJson, Show, Eq)

///|
struct ResolvePathReply {
  path : String
} derive(ToJson, FromJson, Show, Eq)

///|
fn normalize_native_separators(path : String) -> String {
  let builder = StringBuilder::new(size_hint=path.length())
  for _, ch in path {
    builder.write_char(if ch == '\\' { '/' } else { ch })
  }
  builder.to_string()
}

///|
fn is_absolute_native_path(path : String) -> Bool {
  let normalized = normalize_native_separators(path)
  normalized.has_prefix("/") ||
  (normalized.length() >= 3 && normalized[1] == ':' && normalized[2] == '/')
}

///|
fn lexical_normalize_native_path(path : String) -> String {
  let normalized = normalize_native_separators(path)
  let (prefix, remainder) = if normalized.length() >= 3 &&
    normalized[1] == ':' &&
    normalized[2] == '/' {
    (normalized[:3].to_string(), normalized[3:].to_string())
  } else if normalized.has_prefix("//") {
    ("//", normalized[2:].to_string())
  } else if normalized.has_prefix("/") {
    ("/", normalized[1:].to_string())
  } else {
    ("", normalized)
  }
  let absolute = prefix != ""
  let mut segments : Array[String] = []

  for part in remainder.split("/") {
    let segment = part.to_string()
    if segment == "" || segment == "." {
      ()
    } else if segment == ".." {
      if segments.length() > 0 && segments[segments.length() - 1] != ".." {
        segments = segments[:segments.length() - 1].to_array()
      } else if !absolute {
        segments.push(segment)
      }
    } else {
      segments.push(segment)
    }
  }

  let builder = StringBuilder::new(size_hint=normalized.length())
  builder.write_string(prefix)
  if segments.length() == 0 {
    if prefix == "" {
      builder.write_char('.')
    }
  } else {
    builder.write_string(segments[0])
    for index in 1..<segments.length() {
      builder.write_char('/')
      builder.write_string(segments[index])
    }
  }
  builder.to_string()
}

///|
fn native_absolute_path(path : String) -> String {
  if is_absolute_native_path(path) {
    lexical_normalize_native_path(path)
  } else {
    let absolute_path : @path.Path = path
    lexical_normalize_native_path(absolute_path.resolve().to_string())
  }
}

///|
fn native_path_exists(path : String) -> Bool {
  @xfs.path_exists(path)
}

///|
fn int_min(left : Int, right : Int) -> Int {
  if left < right {
    left
  } else {
    right
  }
}

///|
fn int_max(left : Int, right : Int) -> Int {
  if left > right {
    left
  } else {
    right
  }
}

///|
fn empty_bytes() -> Bytes {
  Bytes::default()
}

///|
fn encode_string_bytes(content : String) -> Bytes {
  @utf8.encode(content)
}

///|
fn decode_read_bytes(bytes : BytesView) -> String {
  @utf8.decode_lossy(bytes)
}

///|
fn overwrite_bytes(original : Bytes, position : Int, patch : Bytes) -> Bytes {
  let original_len = original.length()
  let prefix = if position <= original_len {
    original[:position].to_bytes()
  } else {
    original + Bytes::make(position - original_len, b'\x00')
  }
  let suffix_start = position + patch.length()
  let suffix = if suffix_start < original_len {
    original[suffix_start:].to_bytes()
  } else {
    empty_bytes()
  }
  prefix + patch + suffix
}

///|
fn parse_open_mode(mode : String) -> Result[FileOpenMode, String] {
  let mut primary : Char? = None
  let mut can_read = false
  let mut can_write = false
  let mut create_if_missing = false
  let mut truncate_on_open = false
  let mut append_on_write = false

  for _, ch in mode {
    match primary {
      None => {
        primary = Some(ch)
        match ch {
          'r' => can_read = true
          'w' => {
            can_write = true
            create_if_missing = true
            truncate_on_open = true
          }
          'a' => {
            can_write = true
            create_if_missing = true
            append_on_write = true
          }
          _ => return Err("Unsupported open mode: " + mode)
        }
      }
      Some(_) =>
        if ch == '+' {
          can_read = true
          can_write = true
        } else if ch == 'b' || ch == 't' {
          ()
        } else {
          return Err("Unsupported open mode: " + mode)
        }
    }
  }

  match primary {
    None => Err("fs open mode is required")
    Some(_) =>
      Ok(FileOpenMode::{
        can_read,
        can_write,
        create_if_missing,
        truncate_on_open,
        append_on_write,
      })
  }
}

///|
fn build_open_mode_from_options(
  payload : OpenFilePayload,
) -> Result[String, String] {
  match payload.flags {
    Some(flags) =>
      if flags == "" {
        Err("fs openFile flags must not be empty")
      } else {
        Ok(flags)
      }
    None => {
      let read = option_bool(payload.read, false)
      let write = option_bool(payload.write, false)
      let append = option_bool(payload.append, false)
      let create = option_bool(payload.create, false)
      let truncate = option_bool(payload.truncate, false)
      let create_new = option_bool(payload.create_new, false)

      guard !create_new else {
        return Err("fs openFile create_new is not supported yet")
      }
      guard !append || !truncate else {
        return Err("fs openFile append and truncate cannot both be true")
      }

      if append {
        Ok(if read { "ab+" } else { "ab" })
      } else if write && (truncate || create) {
        Ok(if read { "w+b" } else { "wb" })
      } else if write {
        Ok("r+b")
      } else if read {
        Ok("rb")
      } else {
        Err("fs openFile requires flags or at least one of read/write/append")
      }
    }
  }
}

///|
fn read_path_bytes(path : String) -> Result[Bytes, String] {
  let bytes : Result[Bytes, _] = try? @xfs.read_file_to_bytes(path)
  match bytes {
    Ok(bytes) => Ok(bytes)
    Err(error) => Err("Failed to read file: " + error.to_string())
  }
}

///|
fn write_path_bytes(path : String, content : Bytes) -> Result[Unit, String] {
  let write_result : Result[Unit, _] = try? @xfs.write_bytes_to_file(
    path, content,
  )
  match write_result {
    Ok(_) => Ok(())
    Err(error) => Err("Failed to write file: " + error.to_string())
  }
}

///|
fn is_path_file(path : String) -> Bool {
  let result : Result[Bool, _] = try? @xfs.is_file(path)
  match result {
    Ok(value) => value
    Err(_) => false
  }
}

///|
fn is_path_dir(path : String) -> Bool {
  let result : Result[Bool, _] = try? @xfs.is_dir(path)
  match result {
    Ok(value) => value
    Err(_) => false
  }
}

///|
fn open_memory_file(
  path : String,
  mode : String,
) -> Result[MemoryFileHandle, String] {
  let parsed_mode = match parse_open_mode(mode) {
    Ok(parsed_mode) => parsed_mode
    Err(error) => return Err(error)
  }
  let existed_on_open = native_path_exists(path)

  let content = if parsed_mode.truncate_on_open {
    match write_path_bytes(path, empty_bytes()) {
      Ok(_) => empty_bytes()
      Err(error) => return Err(error)
    }
  } else if existed_on_open {
    match read_path_bytes(path) {
      Ok(bytes) => bytes
      Err(error) => return Err(error)
    }
  } else if parsed_mode.create_if_missing {
    match write_path_bytes(path, empty_bytes()) {
      Ok(_) => empty_bytes()
      Err(error) => return Err(error)
    }
  } else {
    return Err("Failed to open file: path does not exist")
  }

  let cursor = if parsed_mode.append_on_write { content.length() } else { 0 }
  Ok(MemoryFileHandle::{
    path,
    mode: parsed_mode,
    content,
    cursor,
    dirty: parsed_mode.truncate_on_open ||
    (!existed_on_open && parsed_mode.create_if_missing),
  })
}

///|
fn read_memory_file(
  handle : MemoryFileHandle,
  size : Int,
) -> Result[ReadReply, String] {
  guard size >= 0 else { return Err("Read size must be non-negative") }
  guard handle.mode.can_read else {
    return Err("Failed to read file: handle is not open for reading")
  }

  let content_len = handle.content.length()
  let start = int_min(handle.cursor, content_len)
  let end = int_min(start + size, content_len)
  let bytes_read = end - start
  let content = if bytes_read == 0 {
    ""
  } else {
    decode_read_bytes(handle.content[start:end])
  }
  handle.cursor += bytes_read
  Ok(ReadReply::{ content, bytes_read, eof: handle.cursor >= content_len })
}

///|
fn write_memory_file(
  handle : MemoryFileHandle,
  content : String,
) -> Result[Int, String] {
  guard handle.mode.can_write else {
    return Err("Failed to write file: handle is not open for writing")
  }

  let write_bytes = encode_string_bytes(content)
  let write_position = if handle.mode.append_on_write {
    handle.content.length()
  } else {
    int_max(handle.cursor, 0)
  }
  handle.content = overwrite_bytes(handle.content, write_position, write_bytes)
  handle.cursor = write_position + write_bytes.length()
  handle.dirty = true
  Ok(write_bytes.length())
}

///|
fn sync_memory_file(handle : MemoryFileHandle) -> Result[Unit, String] {
  if !handle.dirty {
    return Ok(())
  }
  match write_path_bytes(handle.path, handle.content) {
    Ok(_) => {
      handle.dirty = false
      Ok(())
    }
    Err(error) => Err(error)
  }
}

///|
fn flush_memory_file(handle : MemoryFileHandle) -> Result[Unit, String] {
  sync_memory_file(handle)
}

///|
fn seek_target_position(
  handle : MemoryFileHandle,
  offset : Int,
  whence : String,
) -> Result[Int, String] {
  let base = match whence {
    "set" => 0
    "current" => handle.cursor
    "end" => handle.content.length()
    _ => return Err("Unsupported whence: " + whence)
  }
  let position = base + offset
  guard position >= 0 else {
    return Err("Failed to seek file: resulting position is negative")
  }
  Ok(position)
}

///|
fn seek_memory_file(
  handle : MemoryFileHandle,
  offset : Int,
  whence : String,
) -> Result[Int, String] {
  match seek_target_position(handle, offset, whence) {
    Ok(position) => {
      handle.cursor = position
      Ok(position)
    }
    Err(error) => Err(error)
  }
}

///|
fn stat_path_flags(path : String?) -> (Bool, Bool, Bool) {
  match path {
    None => (false, false, false)
    Some(path) => {
      let exists = native_path_exists(path)
      (exists, exists && is_path_file(path), exists && is_path_dir(path))
    }
  }
}

///|
fn stat_memory_file(handle : MemoryFileHandle, path : String?) -> FstatReply {
  let (exists, is_file, is_dir) = stat_path_flags(path)
  let size = handle.content.length()
  FstatReply::{
    path,
    size,
    position: handle.cursor,
    eof: handle.cursor >= size,
    exists,
    is_file,
    is_dir,
  }
}

///|
fn close_memory_file(handle : MemoryFileHandle) -> Result[Unit, String] {
  sync_memory_file(handle)
}

///|
fn native_remove_file(path : String) -> Result[Bool, String] {
  if !native_path_exists(path) {
    return Ok(false)
  }
  let removed : Result[Unit, _] = try? @xfs.remove_file(path)
  match removed {
    Ok(_) => Ok(true)
    Err(error) => Err("Failed to remove file: " + error.to_string())
  }
}

///|
fn native_read_dir(path : String) -> Result[Array[String], String] {
  let entries : Result[Array[String], _] = try? @xfs.read_dir(path)
  match entries {
    Ok(entries) => Ok(entries)
    Err(error) => Err("Failed to read directory: " + error.to_string())
  }
}

///|
fn get_open_handle(
  handles : @runtime.ResourceTable[MemoryFileHandle],
  rid : Int,
) -> Result[MemoryFileHandle, String] {
  match handles.get(rid) {
    Some(handle) => Ok(handle)
    None => Err("Unknown fs rid: " + rid.to_string())
  }
}

///|
fn close_all_open_files(
  handles : @runtime.ResourceTable[MemoryFileHandle],
  paths : Map[Int, String],
) -> Unit {
  for rid in handles.rids() {
    match handles.get(rid) {
      Some(handle) => {
        ignore(sync_memory_file(handle))
        ignore(handles.remove(rid))
        paths.remove(rid)
      }
      None => ()
    }
  }
}

///|
fn resolve_read_path(path : String) -> Result[String, String] {
  Ok(native_absolute_path(path))
}

///|
fn resolve_write_path(path : String) -> Result[String, String] {
  Ok(native_absolute_path(path))
}

///|
fn resolve_remove_path(path : String) -> Result[String, String] {
  Ok(native_absolute_path(path))
}

///|
fn resolve_open_path(path : String, _mode : String) -> Result[String, String] {
  Ok(native_absolute_path(path))
}
