///|
/// Registry of extension specs available to one application build.
struct ExtensionRegistry {
  specs : Map[String, @core.ExtensionSpec]
  registration_order : Array[String]
}

///|
/// One prepared extension installation captured by internal app creation state.
priv struct PreparedExtension {
  id : String
  spec : @core.ExtensionSpec
  options : Json?
}

///|
/// Internal application preparation state derived from a manifest and extension registry.
priv struct PreparedApp {
  runtime_config : @wvrt.AppConfig
  extensions : Array[PreparedExtension]
  base_dir : String?
}

///|
/// Creates an empty extension registry.
/// Registration order is preserved so later planning and generated registry
/// output stay deterministic.
pub fn ExtensionRegistry::new() -> ExtensionRegistry {
  ExtensionRegistry::{ specs: {}, registration_order: [] }
}

///|
/// Registers one extension spec and returns the same registry for chaining.
/// Duplicate or blank ids abort immediately because app composition depends on
/// each registered extension having one stable unique key.
pub fn ExtensionRegistry::register(
  self : ExtensionRegistry,
  spec : @core.ExtensionSpec,
) -> ExtensionRegistry {
  let id = spec.id()
  guard id.trim().to_string() != "" else {
    abort("ExtensionRegistry::register: extension id must not be empty")
  }
  guard self.specs.get(id) is None else {
    abort("ExtensionRegistry::register: duplicate extension id: " + id)
  }
  guard spec.js_namespace().trim().to_string() != "" else {
    abort("ExtensionRegistry::register: extension namespace must not be empty")
  }
  self.specs.set(id, spec)
  self.registration_order.push(id)
  self
}

///|
/// Returns one registered extension spec by id, if present.
/// This is useful for optional lookups before surfacing a higher-level app or
/// tooling error to the caller.
pub fn ExtensionRegistry::get(
  self : ExtensionRegistry,
  id : String,
) -> @core.ExtensionSpec? {
  self.specs.get(id)
}

///|
/// Returns the registered extension ids in deterministic registration order.
/// The returned array matches the order in which specs were registered on the
/// registry instance.
pub fn ExtensionRegistry::registered_ids(
  self : ExtensionRegistry,
) -> Array[String] {
  self.registration_order
}

///|
/// Returns the runtime configuration prepared for this app build.
fn PreparedApp::runtime_config(self : PreparedApp) -> @wvrt.AppConfig {
  self.runtime_config
}

///|
/// Returns the manifest base directory associated with this prepared app.
fn PreparedApp::base_dir(self : PreparedApp) -> String? {
  self.base_dir
}

///|
/// Creates one internal prepared extension entry.
fn PreparedExtension::new(
  id : String,
  spec : @core.ExtensionSpec,
  options : Json?,
) -> PreparedExtension {
  PreparedExtension::{ id, spec, options }
}

///|
/// Returns the prepared extension id.
fn PreparedExtension::id(self : PreparedExtension) -> String {
  self.id
}

///|
/// Returns the prepared extension JavaScript namespace.
fn PreparedExtension::js_namespace(self : PreparedExtension) -> String {
  self.spec.js_namespace()
}

///|
/// Builds the runtime extension using the prepared app base directory.
fn PreparedExtension::build(
  self : PreparedExtension,
  base_dir : String?,
) -> Result[@core.Extension, String] {
  self.spec.build_extension(
    @core.ExtensionBuildContext::new(options=self.options, base_dir~),
  )
}

///|
/// Creates one internal prepared app value.
fn PreparedApp::new(
  runtime_config : @wvrt.AppConfig,
  extensions : Array[PreparedExtension],
  base_dir? : String? = None,
) -> PreparedApp {
  PreparedApp::{ runtime_config, extensions, base_dir }
}

///|
/// Returns the internal prepared extension list.
fn PreparedApp::prepared_extensions(
  self : PreparedApp,
) -> Array[PreparedExtension] {
  self.extensions
}

///|
/// Returns the internal registry map.
fn ExtensionRegistry::spec_map(
  self : ExtensionRegistry,
) -> Map[String, @core.ExtensionSpec] {
  self.specs
}

///|
/// Returns the internal registry order.
fn ExtensionRegistry::ordered_names(self : ExtensionRegistry) -> Array[String] {
  self.registration_order
}
