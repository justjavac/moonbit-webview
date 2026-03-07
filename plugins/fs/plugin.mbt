///|
#external
priv type NativeFileHandle

///|
#external
priv type DirectoryEntriesHandle

///|
struct OpenPayload {
  path : String
  mode : String
} derive(ToJson, FromJson, Show, Eq)

///|
struct OpenReply {
  handle : Int
} derive(ToJson, FromJson, Show, Eq)

///|
struct ReadPayload {
  handle : Int
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
  handle : Int
  content : String
} derive(ToJson, FromJson, Show, Eq)

///|
struct WriteReply {
  bytes_written : Int
} derive(ToJson, FromJson, Show, Eq)

///|
struct ClosePayload {
  handle : Int
} derive(ToJson, FromJson, Show, Eq)

///|
struct CloseReply {
  closed : Bool
} derive(ToJson, FromJson, Show, Eq)

///|
struct FlushPayload {
  handle : Int
} derive(ToJson, FromJson, Show, Eq)

///|
struct FlushReply {
  flushed : Bool
} derive(ToJson, FromJson, Show, Eq)

///|
struct SeekPayload {
  handle : Int
  offset : Int
  whence : String
} derive(ToJson, FromJson, Show, Eq)

///|
struct SeekReply {
  position : Int
} derive(ToJson, FromJson, Show, Eq)

///|
struct FstatPayload {
  handle : Int
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
struct FsActivity {
  operation : String
  path : String?
  handle : Int?
  bytes : Int?
} derive(ToJson, FromJson, Show, Eq)

///|
#borrow(path, mode)
extern "C" fn open_file_ffi(path : Bytes, mode : Bytes) -> NativeFileHandle = "plugins_fs_fopen"

///|
extern "C" fn file_handle_is_null(handle : NativeFileHandle) -> Bool = "moonbit_is_null"

///|
#borrow(bytes)
extern "C" fn read_file_ffi(
  bytes : Bytes,
  size : Int,
  item_count : Int,
  handle : NativeFileHandle,
) -> Int = "plugins_fs_fread"

///|
#borrow(bytes)
extern "C" fn write_file_ffi(
  bytes : Bytes,
  size : Int,
  item_count : Int,
  handle : NativeFileHandle,
) -> Int = "plugins_fs_fwrite"

///|
extern "C" fn seek_file_ffi(
  handle : NativeFileHandle,
  offset : Int,
  whence : Int,
) -> Int = "plugins_fs_fseek"

///|
extern "C" fn tell_file_ffi(handle : NativeFileHandle) -> Int = "plugins_fs_ftell"

///|
extern "C" fn flush_file_ffi(handle : NativeFileHandle) -> Int = "plugins_fs_fflush"

///|
extern "C" fn close_file_ffi(handle : NativeFileHandle) -> Int = "plugins_fs_fclose"

///|
extern "C" fn end_of_file_ffi(handle : NativeFileHandle) -> Int = "plugins_fs_feof"

///|
extern "C" fn file_error_ffi(handle : NativeFileHandle) -> Int = "plugins_fs_ferror"

///|
extern "C" fn clear_file_error_ffi(handle : NativeFileHandle) -> Unit = "plugins_fs_clearerr"

///|
extern "C" fn get_error_message_ffi() -> Bytes = "plugins_fs_get_error_message"

///|
#borrow(path)
extern "C" fn path_exists_ffi(path : Bytes) -> Int = "plugins_fs_path_exists"

///|
#borrow(path)
extern "C" fn path_is_file_ffi(path : Bytes) -> Int = "plugins_fs_is_file"

///|
#borrow(path)
extern "C" fn path_is_dir_ffi(path : Bytes) -> Int = "plugins_fs_is_dir"

///|
#borrow(path)
extern "C" fn remove_file_ffi(path : Bytes) -> Int = "plugins_fs_remove_file"

///|
#borrow(path)
extern "C" fn read_dir_ffi(path : Bytes) -> DirectoryEntriesHandle = "plugins_fs_read_dir"

///|
#borrow(path)
extern "C" fn absolute_path_ffi(path : Bytes) -> Bytes = "plugins_fs_absolute_path"

///|
extern "C" fn entries_handle_is_null(handle : DirectoryEntriesHandle) -> Bool = "moonbit_is_null"

///|
fn directory_entries_to_fixed_array(
  handle : DirectoryEntriesHandle,
) -> FixedArray[Bytes] = "%identity"

///|
fn get_error_message() -> String {
  @utf8.decode_lossy(get_error_message_ffi()[:])
}

///|
fn path_to_cstr(path : String) -> Bytes {
  @ffi.to_cstr(path)
}

///|
fn mode_to_cstr(mode : String) -> Bytes {
  @ffi.to_cstr(mode)
}

///|
fn read_string_bytes(content : String) -> Bytes {
  @utf8.encode(content)
}

///|
fn decode_read_bytes(bytes : Bytes, length : Int) -> String {
  @utf8.decode_lossy(bytes[:length])
}

///|
fn whence_to_int(whence : String) -> Result[Int, String] {
  match whence {
    "set" => Ok(0)
    "current" => Ok(1)
    "end" => Ok(2)
    _ => Err("Unsupported whence: " + whence)
  }
}

///|
fn open_native_file(
  path : String,
  mode : String,
) -> Result[NativeFileHandle, String] {
  let handle = open_file_ffi(path_to_cstr(path), mode_to_cstr(mode))
  if file_handle_is_null(handle) {
    Err("Failed to open file: " + get_error_message())
  } else {
    Ok(handle)
  }
}

///|
fn read_native_file(
  handle : NativeFileHandle,
  size : Int,
) -> Result[ReadReply, String] {
  guard size >= 0 else { return Err("Read size must be non-negative") }
  clear_file_error_ffi(handle)
  let bytes = Bytes::make(size, b'\x00')
  let bytes_read = read_file_ffi(bytes, 1, size, handle)
  guard file_error_ffi(handle) == 0 else {
    clear_file_error_ffi(handle)
    return Err("Failed to read file: " + get_error_message())
  }
  Ok(ReadReply::{
    content: decode_read_bytes(bytes, bytes_read),
    bytes_read,
    eof: end_of_file_ffi(handle) != 0,
  })
}

///|
fn write_native_file(
  handle : NativeFileHandle,
  content : String,
) -> Result[Int, String] {
  let bytes = read_string_bytes(content)
  let bytes_written = write_file_ffi(bytes, 1, bytes.length(), handle)
  guard bytes_written == bytes.length() else {
    return Err("Failed to write file: " + get_error_message())
  }
  Ok(bytes_written)
}

///|
fn flush_native_file(handle : NativeFileHandle) -> Result[Unit, String] {
  guard flush_file_ffi(handle) == 0 else {
    return Err("Failed to flush file: " + get_error_message())
  }
  Ok(())
}

///|
fn seek_native_file(
  handle : NativeFileHandle,
  offset : Int,
  whence : String,
) -> Result[Int, String] {
  match whence_to_int(whence) {
    Err(error) => Err(error)
    Ok(whence) => {
      guard seek_file_ffi(handle, offset, whence) == 0 else {
        return Err("Failed to seek file: " + get_error_message())
      }
      let position = tell_file_ffi(handle)
      guard position >= 0 else {
        return Err("Failed to query file position: " + get_error_message())
      }
      Ok(position)
    }
  }
}

///|
fn close_native_file(handle : NativeFileHandle) -> Result[Unit, String] {
  guard close_file_ffi(handle) == 0 else {
    return Err("Failed to close file: " + get_error_message())
  }
  Ok(())
}

///|
fn stat_path_flags(path : String?) -> (Bool, Bool, Bool) {
  match path {
    None => (false, false, false)
    Some(path) => {
      let exists = native_path_exists(path)
      (
        exists,
        exists && path_is_file_ffi(path_to_cstr(path)) != 0,
        exists && path_is_dir_ffi(path_to_cstr(path)) != 0,
      )
    }
  }
}

///|
fn stat_native_file(
  handle : NativeFileHandle,
  path : String?,
) -> Result[FstatReply, String] {
  let position = tell_file_ffi(handle)
  guard position >= 0 else {
    return Err("Failed to query file position: " + get_error_message())
  }
  guard seek_file_ffi(handle, 0, 2) == 0 else {
    return Err("Failed to seek file: " + get_error_message())
  }
  let size = tell_file_ffi(handle)
  guard size >= 0 else {
    return Err("Failed to query file size: " + get_error_message())
  }
  guard seek_file_ffi(handle, position, 0) == 0 else {
    return Err("Failed to restore file position: " + get_error_message())
  }
  let (exists, is_file, is_dir) = stat_path_flags(path)
  Ok(FstatReply::{
    path,
    size,
    position,
    eof: end_of_file_ffi(handle) != 0,
    exists,
    is_file,
    is_dir,
  })
}

///|
fn native_path_exists(path : String) -> Bool {
  path_exists_ffi(path_to_cstr(path)) != 0
}

///|
fn native_remove_file(path : String) -> Result[Bool, String] {
  if !native_path_exists(path) {
    Ok(false)
  } else if remove_file_ffi(path_to_cstr(path)) == 0 {
    Ok(true)
  } else {
    Err("Failed to remove file: " + get_error_message())
  }
}

///|
fn native_read_dir(path : String) -> Result[Array[String], String] {
  let entries = read_dir_ffi(path_to_cstr(path))
  if entries_handle_is_null(entries) {
    Err("Failed to read directory: " + get_error_message())
  } else {
    Ok(
      Array::from_fixed_array(directory_entries_to_fixed_array(entries)).map(fn(
        entry,
      ) {
        @utf8.decode_lossy(entry[:])
      }),
    )
  }
}

///|
/// Resolves a user-provided path string into a native absolute path.
///
/// This is useful for UIs that accept portable relative paths but still want to
/// display or reuse the backend's canonical absolute location.

///|
fn native_absolute_path(path : String) -> String {
  @utf8.decode_lossy(absolute_path_ffi(path_to_cstr(path))[:])
}

///|
fn get_open_handle(
  handles : Map[Int, NativeFileHandle],
  handle : Int,
) -> Result[NativeFileHandle, String] {
  match handles.get(handle) {
    Some(handle) => Ok(handle)
    None => Err("Unknown fs handle: " + handle.to_string())
  }
}

///|
fn emit_activity(
  plugin : @webview.PluginContext,
  operation : String,
  path? : String? = None,
  handle? : Int? = None,
  bytes? : Int? = None,
) -> Unit {
  plugin.emit("activity", FsActivity::{ operation, path, handle, bytes })
}

///|
/// Builds the `fs` plugin.
///
/// Install it with `webview.install_plugin(@fs.plugin())` to expose
/// `window.MoonBitPlugins.fs` in JavaScript. Opened handles remember their
/// resolved absolute path, and `resolvePath` is also exposed as a standalone
/// plugin command for JS callers that need it before opening files.
///
/// This plugin intentionally exposes host filesystem access. Only install it in
/// webviews that load trusted/local content; do not combine it with untrusted
/// or remote HTML/JavaScript.
pub fn plugin() -> @webview.Plugin {
  let handles : Map[Int, NativeFileHandle] = {}
  let paths : Map[Int, String] = {}
  let mut next_handle = 1

  @webview.Plugin::new("fs", fn(plugin) {
    plugin.command_result("open", fn(payload : OpenPayload) {
      match open_native_file(payload.path, payload.mode) {
        Err(error) => Err(error)
        Ok(file) => {
          let handle = next_handle
          // Remember the resolved path once so handle-scoped APIs can report a
          // stable absolute location even when JS opened the file with a
          // relative path.
          let resolved_path = native_absolute_path(payload.path)
          next_handle += 1
          handles.set(handle, file)
          paths.set(handle, resolved_path)
          emit_activity(
            plugin,
            "open",
            path=Some(resolved_path),
            handle=Some(handle),
          )
          Ok(OpenReply::{ handle, })
        }
      }
    })

    plugin.command_result("read", fn(payload : ReadPayload) {
      match get_open_handle(handles, payload.handle) {
        Err(error) => Err(error)
        Ok(file) =>
          match read_native_file(file, payload.size) {
            Err(error) => Err(error)
            Ok(reply) => {
              emit_activity(
                plugin,
                "read",
                path=paths.get(payload.handle),
                handle=Some(payload.handle),
                bytes=Some(reply.bytes_read),
              )
              Ok(reply)
            }
          }
      }
    })

    plugin.command_result("write", fn(payload : WritePayload) {
      match get_open_handle(handles, payload.handle) {
        Err(error) => Err(error)
        Ok(file) =>
          match write_native_file(file, payload.content) {
            Err(error) => Err(error)
            Ok(bytes_written) => {
              emit_activity(
                plugin,
                "write",
                path=paths.get(payload.handle),
                handle=Some(payload.handle),
                bytes=Some(bytes_written),
              )
              Ok(WriteReply::{ bytes_written, })
            }
          }
      }
    })

    plugin.command_result("seek", fn(payload : SeekPayload) {
      match get_open_handle(handles, payload.handle) {
        Err(error) => Err(error)
        Ok(file) =>
          match seek_native_file(file, payload.offset, payload.whence) {
            Err(error) => Err(error)
            Ok(position) => {
              emit_activity(
                plugin,
                "seek",
                path=paths.get(payload.handle),
                handle=Some(payload.handle),
              )
              Ok(SeekReply::{ position, })
            }
          }
      }
    })

    plugin.command_result("fstat", fn(payload : FstatPayload) {
      match get_open_handle(handles, payload.handle) {
        Err(error) => Err(error)
        Ok(file) =>
          match stat_native_file(file, paths.get(payload.handle)) {
            Err(error) => Err(error)
            Ok(reply) => {
              emit_activity(
                plugin,
                "fstat",
                path=reply.path,
                handle=Some(payload.handle),
                bytes=Some(reply.size),
              )
              Ok(reply)
            }
          }
      }
    })

    plugin.command_result("flush", fn(payload : FlushPayload) {
      match get_open_handle(handles, payload.handle) {
        Err(error) => Err(error)
        Ok(file) =>
          match flush_native_file(file) {
            Err(error) => Err(error)
            Ok(_) => {
              emit_activity(
                plugin,
                "flush",
                path=paths.get(payload.handle),
                handle=Some(payload.handle),
              )
              Ok(FlushReply::{ flushed: true })
            }
          }
      }
    })

    plugin.command_result("close", fn(payload : ClosePayload) {
      match get_open_handle(handles, payload.handle) {
        Err(error) => Err(error)
        Ok(file) => {
          let path = paths.get(payload.handle)
          match close_native_file(file) {
            Err(error) => Err(error)
            Ok(_) => {
              handles.remove(payload.handle)
              paths.remove(payload.handle)
              emit_activity(plugin, "close", path~, handle=Some(payload.handle))
              Ok(CloseReply::{ closed: true })
            }
          }
        }
      }
    })

    plugin.command_result("exists", fn(payload : ExistsPayload) {
      Ok(ExistsReply::{ exists: native_path_exists(payload.path) })
    })

    plugin.command_result("removeFile", fn(payload : RemoveFilePayload) {
      match native_remove_file(payload.path) {
        Err(error) => Err(error)
        Ok(removed) => {
          emit_activity(plugin, "removeFile", path=Some(payload.path))
          Ok(RemoveFileReply::{ removed, })
        }
      }
    })

    plugin.command_result("readDir", fn(payload : ReadDirPayload) {
      match native_read_dir(payload.path) {
        Err(error) => Err(error)
        Ok(entries) => {
          emit_activity(plugin, "readDir", path=Some(payload.path))
          Ok(ReadDirReply::{ entries, })
        }
      }
    })

    plugin.command_result("resolvePath", fn(payload : ResolvePathPayload) {
      Ok(ResolvePathReply::{ path: native_absolute_path(payload.path) })
    })
  })
}

///|
test "fs plugin native helpers can round-trip a file" {
  let path = "moonbit-webview-fs-plugin-roundtrip.txt"
  let open_result = open_native_file(path, "w+b")
  let handle = match open_result {
    Ok(handle) => handle
    Err(error) => abort(error)
  }

  match write_native_file(handle, "hello from fs plugin") {
    Ok(_) => ()
    Err(error) => abort(error)
  }
  match flush_native_file(handle) {
    Ok(_) => ()
    Err(error) => abort(error)
  }
  match seek_native_file(handle, 0, "set") {
    Ok(_) => ()
    Err(error) => abort(error)
  }
  let stat = match stat_native_file(handle, Some(path)) {
    Ok(stat) => stat
    Err(error) => abort(error)
  }
  let reply = match read_native_file(handle, 64) {
    Ok(reply) => reply
    Err(error) => abort(error)
  }
  assert_eq(stat.size, 20)
  assert_eq(stat.position, 0)
  assert_true(stat.exists)
  assert_true(stat.is_file)
  assert_false(stat.is_dir)
  assert_eq(reply.content, "hello from fs plugin")
  assert_true(reply.eof)
  match close_native_file(handle) {
    Ok(_) => ()
    Err(error) => abort(error)
  }
  assert_true(native_path_exists(path))
  assert_eq(native_remove_file(path), Ok(true))
  assert_false(native_path_exists(path))
}

///|
test "fs plugin resolves relative paths into absolute paths" {
  let relative_path = "."
  let absolute_path = native_absolute_path(relative_path)
  assert_true(absolute_path != relative_path)
  assert_true(native_path_exists(absolute_path))
}

///|
test "fs plugin native helpers can list a directory" {
  let file_name = "moonbit-webview-fs-plugin-dir-test.txt"
  let path = file_name
  let handle = match open_native_file(path, "wb") {
    Ok(handle) => handle
    Err(error) => abort(error)
  }
  match close_native_file(handle) {
    Ok(_) => ()
    Err(error) => abort(error)
  }
  let entries = match native_read_dir(".") {
    Ok(entries) => entries
    Err(error) => abort(error)
  }
  assert_true(entries.contains(file_name))
  assert_eq(native_remove_file(path), Ok(true))
}
