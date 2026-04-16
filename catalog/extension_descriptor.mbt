///|
/// Typed metadata descriptor loaded from one extension's `extension.json`.
pub struct ExtensionDescriptor {
  schema_version : Int
  id : String
  version : String
  display_name : String
  description : String
  js_namespace : String
  manifest_key : String
  package_path : String
  spec_symbol : String
  platforms : Array[String]
  dependencies : Array[String]
  capabilities : Array[String]
  options_schema_path : String
  root_dir : String
} derive(Eq, Debug)

///|
/// Builds one typed extension metadata descriptor.
/// Most callers load descriptors from disk, but this constructor keeps tests and
/// tooling code simple when fixtures are assembled in memory.
pub fn ExtensionDescriptor::new(
  schema_version : Int,
  id : String,
  version : String,
  display_name : String,
  description : String,
  js_namespace : String,
  manifest_key : String,
  package_path : String,
  spec_symbol : String,
  platforms : Array[String],
  dependencies : Array[String],
  capabilities : Array[String],
  options_schema_path : String,
  root_dir : String,
) -> ExtensionDescriptor {
  ExtensionDescriptor::{
    schema_version,
    id,
    version,
    display_name,
    description,
    js_namespace,
    manifest_key,
    package_path,
    spec_symbol,
    platforms,
    dependencies,
    capabilities,
    options_schema_path,
    root_dir,
  }
}

///|
/// Returns the schema version declared by the metadata file.
/// Tooling can branch on this value when supporting future schema migrations.
pub fn ExtensionDescriptor::schema_version(self : ExtensionDescriptor) -> Int {
  self.schema_version
}

///|
/// Returns the stable extension id used for manifest configuration and linking.
/// This is the key shared by manifests, catalogs, and generated registry code.
pub fn ExtensionDescriptor::id(self : ExtensionDescriptor) -> String {
  self.id
}

///|
/// Returns the semantic version string declared by the metadata file.
/// Discovery UIs can surface this directly without reparsing the original JSON.
pub fn ExtensionDescriptor::version(self : ExtensionDescriptor) -> String {
  self.version
}

///|
/// Returns the human-facing display name.
/// This value is intended for user-facing tooling rather than stable programmatic lookup.
pub fn ExtensionDescriptor::display_name(self : ExtensionDescriptor) -> String {
  self.display_name
}

///|
/// Returns the human-facing description text.
/// Tooling can present it alongside the display name when helping users choose
/// an extension.
pub fn ExtensionDescriptor::description(self : ExtensionDescriptor) -> String {
  self.description
}

///|
/// Returns the JavaScript namespace exposed by the extension.
/// Generated runtime helpers expose the extension under this namespace on
/// `window.__MoonBit__`.
pub fn ExtensionDescriptor::js_namespace(self : ExtensionDescriptor) -> String {
  self.js_namespace
}

///|
/// Returns the manifest key that should be edited in `app.json`.
/// The documented v2 metadata model keeps this aligned with the stable
/// extension id so tooling does not need a second identity mapping.
pub fn ExtensionDescriptor::manifest_key(self : ExtensionDescriptor) -> String {
  self.manifest_key
}

///|
/// Returns the import path that application code uses to link this extension.
/// Generated registry modules write this value into explicit `moon.pkg` import
/// blocks.
pub fn ExtensionDescriptor::package_path(self : ExtensionDescriptor) -> String {
  self.package_path
}

///|
/// Returns the exported function name that produces the extension spec.
/// Registry code calls this symbol on the imported package to obtain the
/// declarative extension spec.
pub fn ExtensionDescriptor::spec_symbol(self : ExtensionDescriptor) -> String {
  self.spec_symbol
}

///|
/// Returns the supported platform identifiers from metadata.
/// Tooling can use this list to filter unsupported extensions before link or
/// install steps.
pub fn ExtensionDescriptor::platforms(
  self : ExtensionDescriptor,
) -> Array[String] {
  self.platforms
}

///|
/// Returns the declared metadata dependency ids.
/// These ids feed directly into dependency expansion when building link plans.
pub fn ExtensionDescriptor::dependencies(
  self : ExtensionDescriptor,
) -> Array[String] {
  self.dependencies
}

///|
/// Returns the declared capability identifiers.
/// Capability tags are intended for discovery, search, and AI-assisted
/// recommendations.
pub fn ExtensionDescriptor::capabilities(
  self : ExtensionDescriptor,
) -> Array[String] {
  self.capabilities
}

///|
/// Returns the extension directory from which this descriptor was loaded.
/// Relative metadata assets such as `options.schema.json` are resolved from this
/// directory.
pub fn ExtensionDescriptor::root_dir(self : ExtensionDescriptor) -> String {
  self.root_dir
}

///|
/// Returns the resolved `extension.json` path for this descriptor.
/// Use this when diagnostics or tooling output need to point back to the source
/// metadata file.
pub fn ExtensionDescriptor::metadata_path(self : ExtensionDescriptor) -> String {
  path_join(self.root_dir, "extension.json")
}

///|
/// Returns the resolved `options.schema.json` path for this descriptor.
/// The path is normalized relative to the extension root stored in the
/// descriptor.
pub fn ExtensionDescriptor::options_schema_file(
  self : ExtensionDescriptor,
) -> String {
  path_join(self.root_dir, self.options_schema_path)
}

///|
/// Reads and decodes one extension descriptor from an `extension.json` file.
/// The returned descriptor stores normalized filesystem paths so later tooling
/// can compare and render them consistently.
pub fn load_extension_descriptor_from_file(
  path : String,
) -> Result[ExtensionDescriptor, String] {
  let normalized_path = normalize_path_string(path)
  read_json_file(normalized_path).bind(fn(json) {
    decode_extension_descriptor(json, normalized_path)
  })
}

///|
/// Reads and parses one JSON file for catalog metadata use.
fn read_json_file(path : String) -> Result[Json, String] {
  let text : Result[String, _] = try? @mbfs.read_file_to_string(path)
  text
  .map_err(fn(error) {
    CatalogDiagnostic::new(
      MissingFile,
      path,
      "failed to read JSON file: " + error.to_string(),
    ).to_error_string()
  })
  .bind(fn(text) {
    let parsed : Result[Json, _] = try? @json.parse(text)
    parsed.map_err(fn(error) {
      CatalogDiagnostic::new(
        InvalidJson,
        path,
        "failed to parse JSON: " + error.to_string(),
      ).to_error_string()
    })
  })
}

///|
/// Converts one parsed metadata JSON value into the typed descriptor.
fn decode_extension_descriptor(
  json : Json,
  path : String,
) -> Result[ExtensionDescriptor, String] {
  match json {
    Object(object) =>
      decode_descriptor_object(object, path).map_err(fn(error) {
        CatalogDiagnostic::new(InvalidMetadata, path, error).to_error_string()
      })
    _ =>
      Err(
        CatalogDiagnostic::new(
          InvalidMetadata,
          path,
          "expected object for extension metadata",
        ).to_error_string(),
      )
  }
}

///|
/// Decodes the metadata object fields into the typed descriptor.
fn decode_descriptor_object(
  object : Map[String, Json],
  path : String,
) -> Result[ExtensionDescriptor, String] {
  zip3(
    decode_descriptor_identity_fields(object),
    decode_descriptor_runtime_fields(object),
    decode_descriptor_collection_fields(object),
  ).bind(fn(values) {
    let (identity, runtime, collections) = values
    let (schema_version, id, version, display_name, description) = identity
    let (
      js_namespace,
      manifest_key,
      package_path,
      spec_symbol,
      options_schema_path,
    ) = runtime
    let (platforms, dependencies, capabilities) = collections
    guard schema_version == 2 else {
      return Err(
        "unsupported extension metadata schema_version: " +
        schema_version.to_string(),
      )
    }
    guard manifest_key == id else {
      return Err("metadata manifest_key must match id: " + id)
    }
    Ok(
      ExtensionDescriptor::new(
        schema_version,
        id,
        version,
        display_name,
        description,
        js_namespace,
        manifest_key,
        package_path,
        spec_symbol,
        platforms,
        dependencies,
        capabilities,
        options_schema_path,
        path_dirname(path),
      ),
    )
  })
}

///|
/// Decodes the required identity and display fields for one descriptor.
fn decode_descriptor_identity_fields(
  object : Map[String, Json],
) -> Result[(Int, String, String, String, String), String] {
  zip5(
    descriptor_required_int(object, "schema_version"),
    descriptor_required_string(object, "id"),
    descriptor_required_string(object, "version"),
    descriptor_required_string(object, "display_name"),
    descriptor_required_string(object, "description"),
  )
}

///|
/// Decodes the required runtime linking fields for one descriptor.
fn decode_descriptor_runtime_fields(
  object : Map[String, Json],
) -> Result[(String, String, String, String, String), String] {
  zip5(
    descriptor_required_string(object, "namespace"),
    descriptor_required_string(object, "manifest_key"),
    descriptor_required_string(object, "package"),
    descriptor_required_string(object, "spec_symbol"),
    descriptor_required_string(object, "options_schema"),
  )
}

///|
/// Decodes the required list-valued metadata fields for one descriptor.
fn decode_descriptor_collection_fields(
  object : Map[String, Json],
) -> Result[(Array[String], Array[String], Array[String]), String] {
  zip3(
    descriptor_required_string_array(object, "platforms"),
    descriptor_required_string_array(object, "dependencies"),
    descriptor_required_string_array(object, "capabilities"),
  )
}

///|
/// Reads a required raw JSON field from one metadata object.
fn descriptor_required_field(
  object : Map[String, Json],
  key : String,
) -> Result[Json, String] {
  match object.get(key) {
    Some(value) => Ok(value)
    None => Err("missing required metadata field: " + key)
  }
}

///|
/// Reads and decodes a required string metadata field.
fn descriptor_required_string(
  object : Map[String, Json],
  key : String,
) -> Result[String, String] {
  descriptor_required_field(object, key).bind(fn(value) {
    match value {
      String(value) => Ok(value)
      _ => Err("expected string for metadata field: " + key)
    }
  })
}

///|
/// Reads and decodes a required integer metadata field.
fn descriptor_required_int(
  object : Map[String, Json],
  key : String,
) -> Result[Int, String] {
  descriptor_required_field(object, key).bind(fn(json) {
    let decoded : Result[Int, _] = try? @json.from_json(json)
    decoded.map_err(fn(error) {
      "invalid int for metadata field " + key + ": " + error.to_string()
    })
  })
}

///|
/// Reads and decodes a required string array metadata field.
fn descriptor_required_string_array(
  object : Map[String, Json],
  key : String,
) -> Result[Array[String], String] {
  descriptor_required_field(object, key).bind(fn(value) {
    match value {
      Array(items) => {
        let values : Array[String] = []
        for item in items {
          match item {
            String(value) => values.push(value)
            _ => return Err("expected string array for metadata field: " + key)
          }
        }
        Ok(values)
      }
      _ => Err("expected array for metadata field: " + key)
    }
  })
}

///|
/// Normalizes a path string through MoonBit's native path abstraction.
fn normalize_path_string(path : String) -> String {
  let value : @mbpath.Path = path
  value.normalize().to_string()
}

///|
/// Joins two path segments and normalizes the result.
fn path_join(base : String, child : String) -> String {
  let value : @mbpath.Path = base
  value.join(child).normalize().to_string()
}

///|
/// Returns the normalized parent directory of one filesystem path.
fn path_dirname(path : String) -> String {
  let value : @mbpath.Path = path
  value.dirname().normalize().to_string()
}
