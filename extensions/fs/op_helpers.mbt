///|
/// Resolves one path before running the supplied callback.
fn[Reply] with_resolved_path(
  path : String,
  resolver : (String) -> Result[String, String],
  callback : (String) -> Result[Reply, String],
) -> Result[Reply, String] {
  resolver(path).bind(callback)
}

///|
/// Resolves two paths before running the supplied callback.
fn[Reply] with_resolved_paths(
  left_path : String,
  left_resolver : (String) -> Result[String, String],
  right_path : String,
  right_resolver : (String) -> Result[String, String],
  callback : (String, String) -> Result[Reply, String],
) -> Result[Reply, String] {
  left_resolver(left_path).bind(fn(left) {
    right_resolver(right_path).bind(fn(right) { callback(left, right) })
  })
}

///|
/// Looks up an open file handle and forwards it to the supplied callback.
fn[Reply] with_open_handle(
  handles : @core.ResourceTable[MemoryFileHandle],
  rid : Int,
  callback : (MemoryFileHandle) -> Result[Reply, String],
) -> Result[Reply, String] {
  get_open_handle(handles, rid).bind(callback)
}
