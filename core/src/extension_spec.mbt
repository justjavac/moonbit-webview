///|
/// Build-time context passed to an extension spec when constructing one runtime extension.
struct ExtensionBuildContext {
  options : Json?
  base_dir : String?
}

///|
/// Declarative extension spec registered in application code.
struct ExtensionSpec {
  id : String
  js_namespace : String
  dependencies : Array[String]
  build : (ExtensionBuildContext) -> Result[Extension, String]
}

///|
/// Creates an extension build context.
/// Specs receive this value when they need manifest-provided options or a base
/// directory while constructing one runtime extension instance.
pub fn ExtensionBuildContext::new(
  options? : Json? = None,
  base_dir? : String? = None,
) -> ExtensionBuildContext {
  ExtensionBuildContext::{ options, base_dir }
}

///|
/// Returns the JSON options configured for this extension.
/// Specs can read this to interpret manifest-time configuration before
/// constructing their runtime behavior.
pub fn ExtensionBuildContext::options(self : ExtensionBuildContext) -> Json? {
  self.options
}

///|
/// Returns the manifest base directory, when app creation came from a file.
/// Extensions typically use this to resolve relative file paths from declarative
/// configuration.
pub fn ExtensionBuildContext::base_dir(self : ExtensionBuildContext) -> String? {
  self.base_dir
}

///|
/// Creates a declarative extension spec.
/// Application code registers specs up front so app composition can stay
/// explicit and build-time link plans remain reviewable.
pub fn ExtensionSpec::new(
  id : String,
  js_namespace : String,
  build : (ExtensionBuildContext) -> Result[Extension, String],
  dependencies? : Array[String] = [],
) -> ExtensionSpec {
  ExtensionSpec::{ id, js_namespace, dependencies, build }
}

///|
/// Returns the extension spec id.
/// This id is the stable manifest and tooling key used to select the extension.
pub fn ExtensionSpec::id(self : ExtensionSpec) -> String {
  self.id
}

///|
/// Returns the JavaScript namespace exposed by the built runtime extension.
/// This namespace is independent from the stable manifest/catalog id.
pub fn ExtensionSpec::js_namespace(self : ExtensionSpec) -> String {
  self.js_namespace
}

///|
/// Returns the extension ids that must be resolved before this spec.
/// App planning and tooling use this metadata to expand transitive dependencies
/// deterministically.
pub fn ExtensionSpec::dependencies(self : ExtensionSpec) -> Array[String] {
  self.dependencies
}

///|
/// Builds the runtime extension using the provided build context.
/// This is the low-level execution step behind app planning, generated
/// registries, and declarative extension composition.
pub fn ExtensionSpec::build_extension(
  self : ExtensionSpec,
  context : ExtensionBuildContext,
) -> Result[Extension, String] {
  (self.build)(context)
}

///|
/// Builds the runtime extension with default options and no base directory.
/// It is useful for direct installation paths that do not need manifest-derived
/// context.
pub fn ExtensionSpec::build_default(
  self : ExtensionSpec,
) -> Result[Extension, String] {
  self.build_extension(ExtensionBuildContext::new())
}
