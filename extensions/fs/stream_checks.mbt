///|
test "fs extension native helpers can round-trip a file" {
  let path = "lepus-fs-extension-roundtrip.txt"
  let open_result = open_memory_file(path, "w+b")
  let handle = match open_result {
    Ok(handle) => handle
    Err(error) => abort(error)
  }

  match write_memory_file(handle, "hello from fs extension") {
    Ok(_) => ()
    Err(error) => abort(error)
  }
  match flush_memory_file(handle) {
    Ok(_) => ()
    Err(error) => abort(error)
  }
  match seek_memory_file(handle, 0, "set") {
    Ok(_) => ()
    Err(error) => abort(error)
  }
  let stat = stat_memory_file(handle, Some(path))
  let reply = match read_memory_file(handle, 64) {
    Ok(reply) => reply
    Err(error) => abort(error)
  }
  assert_eq(stat.size, 23)
  assert_eq(stat.position, 0)
  assert_true(stat.exists)
  assert_true(stat.is_file)
  assert_false(stat.is_dir)
  assert_eq(reply.content, "hello from fs extension")
  assert_true(reply.eof)
  match close_memory_file(handle) {
    Ok(_) => ()
    Err(error) => abort(error)
  }
  assert_true(native_path_exists(path))
  assert_eq(native_remove_file(path), Ok(true))
  assert_false(native_path_exists(path))
}

///|
test "fs extension can map openFile options to native modes" {
  assert_eq(
    build_open_mode_from_options(OpenFilePayload::{
      path: "demo.txt",
      flags: Some("rb"),
      read: None,
      write: None,
      append: None,
      create: None,
      truncate: None,
      create_new: None,
    }),
    Ok("rb"),
  )
  assert_eq(
    build_open_mode_from_options(OpenFilePayload::{
      path: "demo.txt",
      flags: None,
      read: Some(true),
      write: Some(true),
      append: None,
      create: Some(true),
      truncate: Some(true),
      create_new: None,
    }),
    Ok("w+b"),
  )
  assert_eq(
    build_open_mode_from_options(OpenFilePayload::{
      path: "demo.txt",
      flags: None,
      read: Some(true),
      write: None,
      append: Some(true),
      create: None,
      truncate: None,
      create_new: None,
    }),
    Ok("ab+"),
  )
}

///|
test "fs extension resolves relative paths into absolute paths" {
  let relative_path = "."
  let absolute_path = native_absolute_path(relative_path)
  assert_true(absolute_path != relative_path)
  assert_true(native_path_exists(absolute_path))
}

///|
test "fs extension native helpers can list a directory" {
  let file_name = "lepus-fs-extension-dir-test.txt"
  let path = file_name
  let handle = match open_memory_file(path, "wb") {
    Ok(handle) => handle
    Err(error) => abort(error)
  }
  match close_memory_file(handle) {
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

///|
test "fs extension append mode writes at the end after seek" {
  let path = "lepus-fs-extension-append.txt"
  let handle = match open_memory_file(path, "ab+") {
    Ok(handle) => handle
    Err(error) => abort(error)
  }
  match write_memory_file(handle, "first") {
    Ok(_) => ()
    Err(error) => abort(error)
  }
  match seek_memory_file(handle, 0, "set") {
    Ok(_) => ()
    Err(error) => abort(error)
  }
  match write_memory_file(handle, " second") {
    Ok(_) => ()
    Err(error) => abort(error)
  }
  match close_memory_file(handle) {
    Ok(_) => ()
    Err(error) => abort(error)
  }
  let reloaded = match read_path_bytes(path) {
    Ok(bytes) => bytes
    Err(error) => abort(error)
  }
  assert_eq(@utf8.decode_lossy(reloaded[:]), "first second")
  assert_eq(native_remove_file(path), Ok(true))
}

///|
test "fs extension flushes open handles during destroy cleanup" {
  let path = "lepus-fs-extension-destroy.txt"
  let handles : @core.ResourceTable[MemoryFileHandle] = @core.ResourceTable::new()
  let paths : Map[Int, String] = {}
  let handle = match open_memory_file(path, "w+b") {
    Ok(handle) => handle
    Err(error) => abort(error)
  }
  let rid = handles.add(handle)
  paths.set(rid, path)
  match write_memory_file(handle, "persist me") {
    Ok(_) => ()
    Err(error) => abort(error)
  }
  close_all_open_files(handles, paths)
  assert_false(handles.contains(rid))
  assert_eq(paths.get(rid), None)
  let reply = match read_text_file(path, None) {
    Ok(reply) => reply
    Err(error) => abort(error)
  }
  assert_eq(reply.content, "persist me")
  assert_eq(native_remove_file(path), Ok(true))
}
