///|
/// TODO(justjavac): 扩展相关的功能移动到独立的 extension 模块中。
pub struct BuiltinSupportModuleInfo {
  dependency_name : String
  module_dir : String
} derive(Show, Eq)

///|
pub struct BuiltinExtensionInfo {
  id : String
  name : String
  description : String
  import_path : String
  import_alias : String
  support_modules : Array[BuiltinSupportModuleInfo]
} derive(Show, Eq)

///|
pub fn BuiltinExtensionInfo::new(
  id : String,
  name : String,
  description : String,
  import_path : String,
  import_alias : String,
  support_modules? : Array[BuiltinSupportModuleInfo] = [],
) -> BuiltinExtensionInfo {
  BuiltinExtensionInfo::{
    id,
    name,
    description,
    import_path,
    import_alias,
    support_modules,
  }
}

///|
pub fn BuiltinExtensionInfo::id(self : BuiltinExtensionInfo) -> String {
  self.id
}

///|
pub fn BuiltinExtensionInfo::name(self : BuiltinExtensionInfo) -> String {
  self.name
}

///|
pub fn BuiltinExtensionInfo::description(self : BuiltinExtensionInfo) -> String {
  self.description
}

///|
pub fn BuiltinExtensionInfo::import_path(self : BuiltinExtensionInfo) -> String {
  self.import_path
}

///|
pub fn BuiltinExtensionInfo::import_alias(
  self : BuiltinExtensionInfo,
) -> String {
  self.import_alias
}

///|
pub fn BuiltinExtensionInfo::support_modules(
  self : BuiltinExtensionInfo,
) -> Array[BuiltinSupportModuleInfo] {
  self.support_modules
}

///|
pub fn BuiltinSupportModuleInfo::new(
  dependency_name : String,
  module_dir : String,
) -> BuiltinSupportModuleInfo {
  BuiltinSupportModuleInfo::{ dependency_name, module_dir }
}

///|
pub fn BuiltinSupportModuleInfo::dependency_name(
  self : BuiltinSupportModuleInfo,
) -> String {
  self.dependency_name
}

///|
pub fn BuiltinSupportModuleInfo::module_dir(
  self : BuiltinSupportModuleInfo,
) -> String {
  self.module_dir
}
