///|
pub fn AppConfigDocument::set_extension_options(
  self : AppConfigDocument,
  name : String,
  options : Json,
) -> Result[AppConfigDocument, String] {
  guard normalize_keyword(name) != "" else {
    return Err("extension options key must not be empty")
  }
  guard options is Object(_) else {
    return Err("extension options for " + name + " must be an object")
  }
  self.updated(object => {
    set_extension_option_entry(object, name, options)
    Ok(())
  })
}

///|
pub fn AppConfigDocument::remove_extension_options(
  self : AppConfigDocument,
  name : String,
) -> Result[AppConfigDocument, String] {
  self.updated(object => {
    clear_extension_option_entry(object, name)
    Ok(())
  })
}

///|
fn set_extension_option_entry(
  object : Map[String, Json],
  name : String,
  options : Json,
) -> Unit {
  let extension_object = ensure_extension_options_object(object)
  extension_object[name] = clone_json(options)
}

///|
fn clear_extension_option_entry(
  object : Map[String, Json],
  name : String,
) -> Unit {
  match object.get("extensions") {
    Some(Object(extension_object)) => {
      extension_object.remove(name)
      if extension_object.is_empty() {
        object.remove("extensions")
      }
    }
    _ => ()
  }
}

///|
fn ensure_extension_options_object(
  object : Map[String, Json],
) -> Map[String, Json] {
  match object.get("extensions") {
    Some(Object(extension_object)) => extension_object
    _ => {
      let extension_object : Map[String, Json] = {}
      object["extensions"] = Json::object(extension_object)
      extension_object
    }
  }
}
