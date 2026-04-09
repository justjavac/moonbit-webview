///|
/// Deep-clones a JSON value so document edits do not alias the original tree.
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
