///|
fn extension_map(
  extensions : Array[AppExtension],
) -> Result[Map[String, AppExtension], String] {
  let by_name : Map[String, AppExtension] = {}
  for extension in extensions {
    let extension_name = extension.name()
    guard extension_name.trim().to_string() != "" else {
      return Err("app extension name must not be empty")
    }
    guard by_name.get(extension_name) is None else {
      return Err("duplicate app extension name: " + extension_name)
    }
    by_name.set(extension_name, extension)
  }
  Ok(by_name)
}

///|
fn ordered_extensions(
  extensions : Array[AppExtension],
) -> Result[Array[AppExtension], String] {
  let by_name = match extension_map(extensions) {
    Ok(by_name) => by_name
    Err(error) => return Err(error)
  }
  let visit_state : Map[String, Int] = {}
  let ordered : Array[AppExtension] = []
  for extension in extensions {
    match visit_extension(extension.name(), by_name, visit_state, ordered) {
      Ok(_) => ()
      Err(error) => return Err(error)
    }
  }
  Ok(ordered)
}

///|
fn visit_extension(
  extension_name : String,
  by_name : Map[String, AppExtension],
  visit_state : Map[String, Int],
  ordered : Array[AppExtension],
) -> Result[Unit, String] {
  match visit_state.get(extension_name) {
    Some(2) => return Ok(())
    Some(1) =>
      return Err(
        "app extension dependency cycle detected at: " + extension_name,
      )
    _ => ()
  }
  let extension = match by_name.get(extension_name) {
    Some(extension) => extension
    None => return Err("unknown declared app extension: " + extension_name)
  }
  visit_state.set(extension_name, 1)
  for dependency in extension.dependencies() {
    guard by_name.get(dependency) is Some(_) else {
      return Err(
        "app extension " +
        extension_name +
        " requires missing dependency " +
        dependency,
      )
    }
    match visit_extension(dependency, by_name, visit_state, ordered) {
      Ok(_) => ()
      Err(error) => return Err(error)
    }
  }
  visit_state.set(extension_name, 2)
  ordered.push(extension)
  Ok(())
}
