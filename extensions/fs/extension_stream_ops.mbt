///|
fn register_stream_ops(
  extension : @runtime.ExtensionContext,
  handles : @runtime.ResourceTable[MemoryFileHandle],
  paths : Map[Int, String],
) -> Unit {
  extension.op_result("open", fn(payload : OpenPayload) {
    open_path_handle(
      extension,
      "open",
      handles,
      paths,
      payload.path,
      payload.mode,
    )
  })

  extension.op_result("openFile", fn(payload : OpenFilePayload) {
    let mode = match build_open_mode_from_options(payload) {
      Ok(mode) => mode
      Err(error) => return Err(error)
    }
    open_path_handle(extension, "openFile", handles, paths, payload.path, mode)
  })

  extension.op_result("read", fn(payload : ReadPayload) {
    let rid = payload.rid
    with_open_handle(handles, rid, fn(file) {
      match read_memory_file(file, payload.size) {
        Err(error) => Err(error)
        Ok(reply) => {
          emit_activity(
            extension,
            "read",
            path=paths.get(rid),
            rid=Some(rid),
            bytes=Some(reply.bytes_read),
          )
          Ok(reply)
        }
      }
    })
  })

  extension.op_result("write", fn(payload : WritePayload) {
    let rid = payload.rid
    with_open_handle(handles, rid, fn(file) {
      match write_memory_file(file, payload.content) {
        Err(error) => Err(error)
        Ok(bytes_written) => {
          emit_activity(
            extension,
            "write",
            path=paths.get(rid),
            rid=Some(rid),
            bytes=Some(bytes_written),
          )
          Ok(WriteReply::{ bytes_written, })
        }
      }
    })
  })

  extension.op_result("seek", fn(payload : SeekPayload) {
    let rid = payload.rid
    with_open_handle(handles, rid, fn(file) {
      match seek_memory_file(file, payload.offset, payload.whence) {
        Err(error) => Err(error)
        Ok(position) => {
          emit_activity(extension, "seek", path=paths.get(rid), rid=Some(rid))
          Ok(SeekReply::{ position, })
        }
      }
    })
  })

  extension.op_result("fstat", fn(payload : FstatPayload) {
    let rid = payload.rid
    with_open_handle(handles, rid, fn(file) {
      let reply = stat_memory_file(file, paths.get(rid))
      emit_activity(
        extension,
        "fstat",
        path=reply.path,
        rid=Some(rid),
        bytes=Some(reply.size),
      )
      Ok(reply)
    })
  })

  extension.op_result("flush", fn(payload : FlushPayload) {
    let rid = payload.rid
    with_open_handle(handles, rid, fn(file) {
      match flush_memory_file(file) {
        Err(error) => Err(error)
        Ok(_) => {
          emit_activity(extension, "flush", path=paths.get(rid), rid=Some(rid))
          Ok(FlushReply::{ flushed: true })
        }
      }
    })
  })

  extension.op_result("close", fn(payload : ClosePayload) {
    let rid = payload.rid
    with_open_handle(handles, rid, fn(file) {
      let path = paths.get(rid)
      match close_memory_file(file) {
        Err(error) => Err(error)
        Ok(_) => {
          ignore(handles.remove(rid))
          paths.remove(rid)
          emit_activity(extension, "close", path~, rid=Some(rid))
          Ok(CloseReply::{ closed: true })
        }
      }
    })
  })
}

///|
fn open_path_handle(
  extension : @runtime.ExtensionContext,
  api_name : String,
  handles : @runtime.ResourceTable[MemoryFileHandle],
  paths : Map[Int, String],
  path : String,
  mode : String,
) -> Result[OpenReply, String] {
  with_resolved_path(path, fn(path) { resolve_open_path(path, mode) }, fn(
    resolved_path,
  ) {
    match open_memory_file(resolved_path, mode) {
      Err(error) => Err(error)
      Ok(file) => {
        let rid = handles.add(file)
        paths.set(rid, resolved_path)
        emit_activity(
          extension,
          api_name,
          path=Some(resolved_path),
          rid=Some(rid),
        )
        Ok(OpenReply::{ rid, })
      }
    }
  })
}
