///|
fn[Reply] with_resolved_path(
  path : String,
  resolver : (String) -> Result[String, String],
  callback : (String) -> Result[Reply, String],
) -> Result[Reply, String] {
  match resolver(path) {
    Err(error) => Err(error)
    Ok(resolved_path) => callback(resolved_path)
  }
}

///|
fn[Reply] with_resolved_paths(
  left_path : String,
  left_resolver : (String) -> Result[String, String],
  right_path : String,
  right_resolver : (String) -> Result[String, String],
  callback : (String, String) -> Result[Reply, String],
) -> Result[Reply, String] {
  let left = match left_resolver(left_path) {
    Err(error) => return Err(error)
    Ok(left) => left
  }
  let right = match right_resolver(right_path) {
    Err(error) => return Err(error)
    Ok(right) => right
  }
  callback(left, right)
}

///|
fn[Reply] with_open_handle(
  handles : @runtime.ResourceTable[MemoryFileHandle],
  rid : Int,
  callback : (MemoryFileHandle) -> Result[Reply, String],
) -> Result[Reply, String] {
  match get_open_handle(handles, rid) {
    Err(error) => Err(error)
    Ok(handle) => callback(handle)
  }
}
