///|
test "fs spec rejects unsupported options" {
  match
    spec().build_extension(
      @core.ExtensionBuildContext::new(
        options=Some(Json::object({ "deprecated": Json::boolean(true) })),
      ),
    ) {
    Ok(_) => abort("expected fs extension options rejection")
    Err(error) => assert_eq(error, "fs extension options are not supported")
  }
}

///|
test "fs helper script stays with fs extension assets" {
  let script = fs_helper_script()
  assert_true(script.contains("const rootName = \"__MoonBit__\";"))
  assert_true(script.contains("const extensionName = \"fs\";"))
  assert_true(script.contains("@@nodeStyleFs"))
}

///|
test "fs path api can read write and append text files" {
  let path = "lepus-fs-path-api.txt"
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
  let path = "lepus-fs-stat-source.txt"
  let renamed = "lepus-fs-stat-renamed.txt"
  let copied = "lepus-fs-stat-copy.txt"
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
  let root = "lepus-fs-dir-api"
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
  let root = "lepus-fs-list-api"
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
  let root = "lepus-fs-remove-api"
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
  let path = "lepus-fs-truncate.txt"
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
