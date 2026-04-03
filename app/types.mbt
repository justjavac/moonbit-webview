///|
pub struct AppExtension {
  name : String
  dependencies : Array[String]
  build : (AppExtensionContext) -> Result[@wvrt.Extension, String]
}

///|
pub struct AppExtensionContext {
  options : Json?
  base_dir : String?
}

///|
pub fn AppExtension::new(
  name : String,
  build : (AppExtensionContext) -> Result[@wvrt.Extension, String],
  dependencies? : Array[String] = [],
) -> AppExtension {
  AppExtension::{ name, dependencies, build }
}

///|
pub fn AppExtension::name(self : AppExtension) -> String {
  self.name
}

///|
pub fn AppExtension::dependencies(self : AppExtension) -> Array[String] {
  self.dependencies
}

///|
pub fn AppExtension::build_extension(
  self : AppExtension,
  context : AppExtensionContext,
) -> Result[@wvrt.Extension, String] {
  (self.build)(context)
}

///|
pub fn AppExtensionContext::new(
  options? : Json? = None,
  base_dir? : String? = None,
) -> AppExtensionContext {
  AppExtensionContext::{ options, base_dir }
}

///|
pub fn AppExtensionContext::options(self : AppExtensionContext) -> Json? {
  self.options
}

///|
pub fn AppExtensionContext::base_dir(self : AppExtensionContext) -> String? {
  self.base_dir
}
