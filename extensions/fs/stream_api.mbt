///|
/// Rewrites path separators into the normalized forward-slash form used internally.
fn normalize_native_separators(path : String) -> String {
  let builder = StringBuilder::new(size_hint=path.length())
  for _, ch in path {
    builder.write_char(if ch == '\\' { '/' } else { ch })
  }
  builder.to_string()
}

///|
/// Returns whether a normalized path is absolute for the current platform.
fn is_absolute_native_path(path : String) -> Bool {
  let normalized = normalize_native_separators(path)
  normalized.has_prefix("/") ||
  (normalized.length() >= 3 && normalized[1] == ':' && normalized[2] == '/')
}

///|
/// Lexically normalizes separators plus `.` and `..` path segments.
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
/// Resolves a path against the current working directory when it is not already absolute.
fn native_absolute_path(path : String) -> String {
  if is_absolute_native_path(path) {
    lexical_normalize_native_path(path)
  } else {
    let absolute_path : @path.Path = path
    lexical_normalize_native_path(absolute_path.resolve().to_string())
  }
}

///|
/// Returns whether a filesystem path currently exists.
fn native_path_exists(path : String) -> Bool {
  @xfs.path_exists(path)
}

///|
/// Returns the smaller of two integers.
fn int_min(left : Int, right : Int) -> Int {
  if left < right {
    left
  } else {
    right
  }
}

///|
/// Returns the larger of two integers.
fn int_max(left : Int, right : Int) -> Int {
  if left > right {
    left
  } else {
    right
  }
}

///|
/// Returns an empty byte buffer.
fn empty_bytes() -> Bytes {
  Bytes::default()
}

///|
/// Encodes a string as UTF-8 bytes.
fn encode_string_bytes(content : String) -> Bytes {
  @utf8.encode(content)
}

///|
/// Decodes a byte slice as UTF-8 while replacing invalid sequences.
fn decode_read_bytes(bytes : BytesView) -> String {
  @utf8.decode_lossy(bytes)
}

///|
/// Overwrites a byte range at `position`, extending the buffer with zeros when needed.
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
/// Parses the compact mode string used by `fs.open`.
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
/// Converts the `openFile` option object into a compact native mode string.
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
/// Reads a file into a byte buffer.
fn read_path_bytes(path : String) -> Result[Bytes, String] {
  let bytes : Result[Bytes, _] = try? @xfs.read_file_to_bytes(path)
  match bytes {
    Ok(bytes) => Ok(bytes)
    Err(error) => Err("Failed to read file: " + error.to_string())
  }
}

///|
/// Writes a byte buffer to a file, replacing any existing content.
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
/// Returns whether a path currently points to a file.
fn is_path_file(path : String) -> Bool {
  let result : Result[Bool, _] = try? @xfs.is_file(path)
  match result {
    Ok(value) => value
    Err(_) => false
  }
}

///|
/// Returns whether a path currently points to a directory.
fn is_path_dir(path : String) -> Bool {
  let result : Result[Bool, _] = try? @xfs.is_dir(path)
  match result {
    Ok(value) => value
    Err(_) => false
  }
}

///|
/// Opens a file into the in-memory handle representation used by the streaming APIs.
fn open_memory_file(
  path : String,
  mode : String,
) -> Result[MemoryFileHandle, String] {
  parse_open_mode(mode).bind(fn(parsed_mode) {
    let existed_on_open = native_path_exists(path)
    load_open_file_content(path, parsed_mode, existed_on_open).map(fn(content) {
      let cursor = if parsed_mode.append_on_write {
        content.length()
      } else {
        0
      }
      MemoryFileHandle::{
        path,
        mode: parsed_mode,
        content,
        cursor,
        dirty: parsed_mode.truncate_on_open ||
        (!existed_on_open && parsed_mode.create_if_missing),
      }
    })
  })
}

///|
/// Reads bytes from an in-memory file handle and advances its cursor.
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
/// Writes bytes into an in-memory file handle and advances its cursor.
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
/// Flushes dirty in-memory file content back to disk.
fn sync_memory_file(handle : MemoryFileHandle) -> Result[Unit, String] {
  if !handle.dirty {
    return Ok(())
  }
  write_path_bytes(handle.path, handle.content).map(fn(_) {
    handle.dirty = false
    ()
  })
}

///|
/// Flushes an in-memory file handle to disk.
fn flush_memory_file(handle : MemoryFileHandle) -> Result[Unit, String] {
  sync_memory_file(handle)
}

///|
/// Computes the target cursor position for a seek request.
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
/// Moves the in-memory file cursor according to the requested seek operation.
fn seek_memory_file(
  handle : MemoryFileHandle,
  offset : Int,
  whence : String,
) -> Result[Int, String] {
  seek_target_position(handle, offset, whence).map(fn(position) {
    handle.cursor = position
    position
  })
}

///|
/// Writes an empty file and returns the resulting empty content buffer.
fn create_empty_file_content(path : String) -> Result[Bytes, String] {
  write_path_bytes(path, empty_bytes()).map(fn(_) { empty_bytes() })
}

///|
/// Loads the initial in-memory content for one newly opened file handle.
fn load_open_file_content(
  path : String,
  parsed_mode : FileOpenMode,
  existed_on_open : Bool,
) -> Result[Bytes, String] {
  if parsed_mode.truncate_on_open {
    create_empty_file_content(path)
  } else if existed_on_open {
    read_path_bytes(path)
  } else if parsed_mode.create_if_missing {
    create_empty_file_content(path)
  } else {
    Err("Failed to open file: path does not exist")
  }
}

///|
/// Returns `exists`, `is_file`, and `is_dir` flags for an optional path.
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
/// Builds the `fstat` reply for an in-memory file handle.
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
/// Flushes and closes an in-memory file handle.
fn close_memory_file(handle : MemoryFileHandle) -> Result[Unit, String] {
  sync_memory_file(handle)
}

///|
/// Removes a file if it exists.
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
/// Reads the direct entries of a directory.
fn native_read_dir(path : String) -> Result[Array[String], String] {
  let entries : Result[Array[String], _] = try? @xfs.read_dir(path)
  match entries {
    Ok(entries) => Ok(entries)
    Err(error) => Err("Failed to read directory: " + error.to_string())
  }
}

///|
/// Returns an open file handle by resource id.
fn get_open_handle(
  handles : @core.ResourceTable[MemoryFileHandle],
  rid : Int,
) -> Result[MemoryFileHandle, String] {
  match handles.get(rid) {
    Some(handle) => Ok(handle)
    None => Err("Unknown fs rid: " + rid.to_string())
  }
}

///|
/// Flushes and forgets every tracked open file handle.
fn close_all_open_files(
  handles : @core.ResourceTable[MemoryFileHandle],
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
/// Resolves a path for a read-only filesystem operation.
fn resolve_read_path(path : String) -> Result[String, String] {
  Ok(native_absolute_path(path))
}

///|
/// Resolves a path for a write filesystem operation.
fn resolve_write_path(path : String) -> Result[String, String] {
  Ok(native_absolute_path(path))
}

///|
/// Resolves a path for a remove filesystem operation.
fn resolve_remove_path(path : String) -> Result[String, String] {
  Ok(native_absolute_path(path))
}

///|
/// Resolves a path for an open filesystem operation.
fn resolve_open_path(path : String, _mode : String) -> Result[String, String] {
  Ok(native_absolute_path(path))
}
