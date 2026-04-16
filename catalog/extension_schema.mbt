///|
/// Parsed schema document associated with one extension descriptor.
pub struct ExtensionSchema {
  descriptor_id : String
  path : String
  json : Json
}

///|
/// Loads the schema document referenced by one extension descriptor.
/// Callers usually use this after loading or requiring a descriptor from an
/// `ExtensionCatalog`.
pub fn load_extension_schema(
  descriptor : ExtensionDescriptor,
) -> Result[ExtensionSchema, String] {
  let path = descriptor.options_schema_file()
  match read_json_file(path) {
    Err(error) => Err(error)
    Ok(json) =>
      Ok(ExtensionSchema::{ descriptor_id: descriptor.id(), path, json })
  }
}

///|
/// Returns the extension id that owns this schema.
/// Tooling can use this to keep schema diagnostics attached to the owning
/// extension id.
pub fn ExtensionSchema::descriptor_id(self : ExtensionSchema) -> String {
  self.descriptor_id
}

///|
/// Returns the resolved schema path on disk.
/// This is the exact file location that was read to build the schema wrapper.
pub fn ExtensionSchema::path(self : ExtensionSchema) -> String {
  self.path
}

///|
/// Returns a detached copy of the parsed schema JSON.
/// Callers may mutate the returned value without affecting shared catalog state.
pub fn ExtensionSchema::json(self : ExtensionSchema) -> Json {
  clone_json(self.json)
}

///|
/// Deep-clones a JSON value so schema callers cannot mutate shared state.
fn clone_json(json : Json) -> Json {
  match json {
    Array(items) => Json::array(items.map(item => clone_json(item)))
    Object(object) => Json::object(clone_json_object(object))
    _ => json
  }
}

///|
/// Deep-clones a JSON object map entry by entry.
fn clone_json_object(object : Map[String, Json]) -> Map[String, Json] {
  let cloned : Map[String, Json] = {}
  for key, value in object {
    cloned.set(key, clone_json(value))
  }
  cloned
}
