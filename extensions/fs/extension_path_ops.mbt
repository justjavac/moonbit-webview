///|
fn register_path_ops(
  extension : @runtime.ExtensionContext,
) -> Unit {
  extension.op_result("stat", fn(payload : StatPayload) {
    with_resolved_path(payload.path, resolve_read_path, fn(resolved_path) {
      match stat_path(resolved_path, option_bool(payload.throw_if_no_entry, true)) {
        Err(error) => Err(error)
        Ok(reply) => {
          emit_activity(
            extension,
            "stat",
            path=Some(resolved_path),
            bytes=Some(reply.size),
          )
          Ok(reply)
        }
      }
    })
  })

  extension.op_result("readdir", fn(payload : ReaddirPayload) {
    with_resolved_path(payload.path, resolve_read_path, fn(resolved_path) {
      match readdir_entries(resolved_path, option_bool(payload.recursive, false)) {
        Err(error) => Err(error)
        Ok(entries) => {
          emit_activity(extension, "readdir", path=Some(resolved_path))
          Ok(ReaddirReply::{ path: resolved_path, entries })
        }
      }
    })
  })

  extension.op_result("mkdir", fn(payload : MkdirPayload) {
    with_resolved_path(payload.path, resolve_write_path, fn(resolved_path) {
      match mkdir_path(resolved_path, option_bool(payload.recursive, false)) {
        Err(error) => Err(error)
        Ok(created) => {
          emit_activity(extension, "mkdir", path=Some(resolved_path))
          Ok(MkdirReply::{ path: resolved_path, created })
        }
      }
    })
  })

  extension.op_result("unlink", fn(payload : RemoveFilePayload) {
    with_resolved_path(payload.path, resolve_remove_path, fn(resolved_path) {
      if !native_path_exists(resolved_path) {
        Err("Failed to unlink path: path does not exist")
      } else {
        match native_remove_file(resolved_path) {
          Err(error) => Err(error)
          Ok(removed) => {
            emit_activity(extension, "unlink", path=Some(resolved_path))
            Ok(RemoveFileReply::{ removed, })
          }
        }
      }
    })
  })

  register_remove_path_op(extension, "rm")
  register_remove_path_op(extension, "remove")

  extension.op_result("rename", fn(payload : RenamePayload) {
    with_resolved_paths(
      payload.old_path,
      resolve_remove_path,
      payload.new_path,
      resolve_write_path,
      fn(old_path, new_path) {
        match rename_path(old_path, new_path) {
          Err(error) => Err(error)
          Ok(_) => {
            emit_activity(extension, "rename", path=Some(new_path))
            Ok(RenameReply::{ old_path, new_path, renamed: true })
          }
        }
      }
    )
  })

  extension.op_result("copyFile", fn(payload : CopyFilePayload) {
    with_resolved_paths(
      payload.src,
      resolve_read_path,
      payload.dest,
      resolve_write_path,
      fn(src, dest) {
        match copy_file_path(src, dest, option_bool(payload.overwrite, true)) {
          Err(error) => Err(error)
          Ok(bytes_copied) => {
            emit_activity(
              extension,
              "copyFile",
              path=Some(dest),
              bytes=Some(bytes_copied),
            )
            Ok(CopyFileReply::{ src, dest, copied: true, bytes_copied })
          }
        }
      }
    )
  })

  extension.op_result("realpath", fn(payload : ResolvePathPayload) {
    with_resolved_path(payload.path, resolve_read_path, fn(resolved_path) {
      match realpath_path(resolved_path) {
        Err(error) => Err(error)
        Ok(real_path) => {
          emit_activity(extension, "realpath", path=Some(real_path))
          Ok(ResolvePathReply::{ path: real_path })
        }
      }
    })
  })

  extension.op_result("truncate", fn(payload : TruncatePayload) {
    with_resolved_path(payload.path, resolve_write_path, fn(resolved_path) {
      let len = match payload.len {
        Some(len) => len
        None => 0
      }
      match truncate_path(resolved_path, len) {
        Err(error) => Err(error)
        Ok(size) => {
          emit_activity(
            extension,
            "truncate",
            path=Some(resolved_path),
            bytes=Some(size),
          )
          Ok(TruncateReply::{ path: resolved_path, size, truncated: true })
        }
      }
    })
  })

  extension.op_result("size", fn(payload : SizePayload) {
    with_resolved_path(payload.path, resolve_read_path, fn(resolved_path) {
      match recursive_path_size(resolved_path) {
        Err(error) => Err(error)
        Ok(size) => {
          emit_activity(
            extension,
            "size",
            path=Some(resolved_path),
            bytes=Some(size),
          )
          Ok(SizeReply::{ path: resolved_path, size })
        }
      }
    })
  })

  extension.op_result("exists", fn(payload : ExistsPayload) {
    with_resolved_path(payload.path, resolve_read_path, fn(resolved_path) {
      Ok(ExistsReply::{ exists: native_path_exists(resolved_path) })
    })
  })

  extension.op_result("removeFile", fn(payload : RemoveFilePayload) {
    with_resolved_path(payload.path, resolve_remove_path, fn(resolved_path) {
      match native_remove_file(resolved_path) {
        Err(error) => Err(error)
        Ok(removed) => {
          emit_activity(extension, "removeFile", path=Some(resolved_path))
          Ok(RemoveFileReply::{ removed, })
        }
      }
    })
  })

  extension.op_result("readDir", fn(payload : ReadDirPayload) {
    with_resolved_path(payload.path, resolve_read_path, fn(resolved_path) {
      match native_read_dir(resolved_path) {
        Err(error) => Err(error)
        Ok(entries) => {
          emit_activity(extension, "readDir", path=Some(resolved_path))
          Ok(ReadDirReply::{ entries, })
        }
      }
    })
  })

  extension.op_result("resolvePath", fn(payload : ResolvePathPayload) {
    with_resolved_path(payload.path, resolve_read_path, fn(resolved_path) {
      Ok(ResolvePathReply::{ path: resolved_path })
    })
  })
}

///|
fn register_remove_path_op(
  extension : @runtime.ExtensionContext,
  api_name : String,
) -> Unit {
  extension.op_result(api_name, fn(payload : RemovePathPayload) {
    with_resolved_path(payload.path, resolve_remove_path, fn(resolved_path) {
      match
        remove_path(
          resolved_path,
          option_bool(payload.recursive, false),
          option_bool(payload.force, false),
        ) {
        Err(error) => Err(error)
        Ok(removed) => {
          emit_activity(extension, api_name, path=Some(resolved_path))
          Ok(RemovePathReply::{ path: resolved_path, removed })
        }
      }
    })
  })
}
