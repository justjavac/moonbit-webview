///|
fn register_file_text_ops(
  extension : @runtime.ExtensionContext,
) -> Unit {
  register_read_text_op(extension, "readFile")
  register_read_text_op(extension, "readTextFile")
  register_write_text_op(extension, "writeFile")
  register_write_text_op(extension, "writeTextFile")
  register_append_text_op(extension, "appendFile")
}

///|
fn register_read_text_op(
  extension : @runtime.ExtensionContext,
  api_name : String,
) -> Unit {
  extension.op_result(api_name, fn(payload : ReadFilePayload) {
    with_resolved_path(payload.path, resolve_read_path, fn(resolved_path) {
      match read_text_file(resolved_path, payload.encoding) {
        Err(error) => Err(error)
        Ok(reply) => {
          emit_activity(
            extension,
            api_name,
            path=Some(resolved_path),
            bytes=Some(reply.bytes_read),
          )
          Ok(reply)
        }
      }
    })
  })
}

///|
fn register_write_text_op(
  extension : @runtime.ExtensionContext,
  api_name : String,
) -> Unit {
  extension.op_result(api_name, fn(payload : WriteFilePayload) {
    ignore(option_bool(payload.flush, false))
    with_resolved_path(payload.path, resolve_write_path, fn(resolved_path) {
      match write_text_file(resolved_path, payload.content, payload.encoding) {
        Err(error) => Err(error)
        Ok(reply) => {
          emit_activity(
            extension,
            api_name,
            path=Some(resolved_path),
            bytes=Some(reply.bytes_written),
          )
          Ok(reply)
        }
      }
    })
  })
}

///|
fn register_append_text_op(
  extension : @runtime.ExtensionContext,
  api_name : String,
) -> Unit {
  extension.op_result(api_name, fn(payload : AppendFilePayload) {
    ignore(option_bool(payload.flush, false))
    with_resolved_path(payload.path, resolve_write_path, fn(resolved_path) {
      match append_text_file(resolved_path, payload.content, payload.encoding) {
        Err(error) => Err(error)
        Ok(reply) => {
          emit_activity(
            extension,
            api_name,
            path=Some(resolved_path),
            bytes=Some(reply.bytes_written),
          )
          Ok(reply)
        }
      }
    })
  })
}
