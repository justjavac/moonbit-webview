///|
/// Registers the text-oriented filesystem APIs.
fn register_file_text_ops(extension : @core.ExtensionContext) -> Unit {
  register_read_text_op(extension, "readFile")
  register_read_text_op(extension, "readTextFile")
  register_write_text_op(extension, "writeFile")
  register_write_text_op(extension, "writeTextFile")
  register_append_text_op(extension, "appendFile")
}

///|
/// Registers one text-reading API and reports activity after successful reads.
fn register_read_text_op(
  extension : @core.ExtensionContext,
  api_name : String,
) -> Unit {
  extension.op_result(api_name, fn(payload : ReadFilePayload) {
    with_resolved_path(payload.path, resolve_read_path, fn(resolved_path) {
      read_text_file(resolved_path, payload.encoding).map(fn(reply) {
        emit_activity(
          extension,
          api_name,
          path=Some(resolved_path),
          bytes=Some(reply.bytes_read),
        )
        reply
      })
    })
  })
}

///|
/// Registers one text-writing API and reports activity after successful writes.
fn register_write_text_op(
  extension : @core.ExtensionContext,
  api_name : String,
) -> Unit {
  extension.op_result(api_name, fn(payload : WriteFilePayload) {
    ignore(option_bool(payload.flush, false))
    with_resolved_path(payload.path, resolve_write_path, fn(resolved_path) {
      write_text_file(resolved_path, payload.content, payload.encoding).map(fn(
        reply,
      ) {
        emit_activity(
          extension,
          api_name,
          path=Some(resolved_path),
          bytes=Some(reply.bytes_written),
        )
        reply
      })
    })
  })
}

///|
/// Registers one text-appending API and reports activity after successful appends.
fn register_append_text_op(
  extension : @core.ExtensionContext,
  api_name : String,
) -> Unit {
  extension.op_result(api_name, fn(payload : AppendFilePayload) {
    ignore(option_bool(payload.flush, false))
    with_resolved_path(payload.path, resolve_write_path, fn(resolved_path) {
      append_text_file(resolved_path, payload.content, payload.encoding).map(fn(
        reply,
      ) {
        emit_activity(
          extension,
          api_name,
          path=Some(resolved_path),
          bytes=Some(reply.bytes_written),
        )
        reply
      })
    })
  })
}
