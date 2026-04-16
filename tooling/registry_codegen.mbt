///|
/// One explicit `moon.pkg` import needed by a generated registry module.
pub struct GeneratedRegistryBinding {
  extension_id : String
  package_path : String
  import_alias : String
  spec_symbol : String
} derive(Eq, Debug, ToJson)

///|
/// One generated registry module plus the import snippet it requires.
pub struct GeneratedRegistryModule {
  function_name : String
  recommended_file_name : String
  moon_pkg_import_block : String
  source : String
  bindings : Array[GeneratedRegistryBinding]
} derive(Eq, Debug, ToJson)

///|
/// Returns the generated function name.
/// This is the symbol callers should invoke to reconstruct the explicit
/// extension registry.
pub fn GeneratedRegistryModule::function_name(
  self : GeneratedRegistryModule,
) -> String {
  self.function_name
}

///|
/// Returns the recommended `.mbt` file name for the generated source.
/// Tooling can use this as a default output path when materializing generated
/// registry code on disk.
pub fn GeneratedRegistryModule::recommended_file_name(
  self : GeneratedRegistryModule,
) -> String {
  self.recommended_file_name
}

///|
/// Returns the `moon.pkg` import block that should be applied explicitly.
/// The block keeps every extension dependency visible and reviewable at build
/// time.
pub fn GeneratedRegistryModule::moon_pkg_import_block(
  self : GeneratedRegistryModule,
) -> String {
  self.moon_pkg_import_block
}

///|
/// Returns the generated MoonBit source file content.
/// Writing this source alongside the import block is enough to reconstruct the
/// selected extension registry.
pub fn GeneratedRegistryModule::source(
  self : GeneratedRegistryModule,
) -> String {
  self.source
}

///|
/// Returns the generated registry bindings in deterministic link order.
/// The order already reflects dependency expansion from the source link plan.
pub fn GeneratedRegistryModule::bindings(
  self : GeneratedRegistryModule,
) -> Array[GeneratedRegistryBinding] {
  self.bindings
}

///|
/// Returns the resolved extension ids that will be linked by this module.
/// This includes transitive dependencies that were pulled in during planning.
pub fn GeneratedRegistryModule::extension_ids(
  self : GeneratedRegistryModule,
) -> Array[String] {
  let ids : Array[String] = []
  for binding in self.bindings {
    ids.push(binding.extension_id)
  }
  ids
}

///|
/// Builds a generated registry module from one existing link plan.
/// The result includes both the MoonBit source and the explicit `moon.pkg`
/// import snippet required to compile it.
pub fn build_generated_registry_module(
  plan : @catalog.ExtensionLinkPlan,
  function_name? : String = "generated_extension_registry",
) -> Result[GeneratedRegistryModule, String] {
  let normalized_function_name = validate_generated_function_name(function_name)
  match normalized_function_name {
    Err(error) => Err(error)
    Ok(function_name) => {
      let bindings = build_generated_registry_bindings(plan)
      Ok(GeneratedRegistryModule::{
        function_name,
        recommended_file_name: function_name + ".mbt",
        moon_pkg_import_block: render_moon_pkg_import_block(bindings),
        source: render_generated_registry_source(bindings, function_name),
        bindings,
      })
    }
  }
}

///|
/// Resolves selected ids against one catalog and renders explicit registry edits.
/// This is the main entry point when a caller already has a loaded
/// `ExtensionCatalog`.
pub fn generate_registry_module_from_catalog(
  catalog : @catalog.ExtensionCatalog,
  selected_ids : Array[String],
  function_name? : String = "generated_extension_registry",
) -> Result[GeneratedRegistryModule, String] {
  match @catalog.build_extension_link_plan(catalog, selected_ids) {
    Err(error) => Err(error)
    Ok(plan) => build_generated_registry_module(plan, function_name~)
  }
}

///|
/// Discovers extensions from search roots and renders explicit registry edits.
/// Use this when extension metadata has not been loaded yet and search roots are
/// the only available input.
pub fn generate_registry_module_from_search_roots(
  search_roots : Array[String],
  selected_ids : Array[String],
  function_name? : String = "generated_extension_registry",
) -> Result[GeneratedRegistryModule, String] {
  match @catalog.load_extension_catalog_from_search_roots(search_roots) {
    Err(error) => Err(error)
    Ok(catalog) =>
      generate_registry_module_from_catalog(
        catalog,
        selected_ids,
        function_name~,
      )
  }
}

///|
/// Reads declared extension ids from one manifest document and renders registry edits.
/// Disabled entries can be included or filtered before metadata resolution
/// depending on `enabled_only`.
pub fn generate_registry_module_from_document(
  document : @bootstrap.AppManifestDocument,
  search_roots : Array[String],
  enabled_only? : Bool = true,
  function_name? : String = "generated_extension_registry",
) -> Result[GeneratedRegistryModule, String] {
  generate_registry_module_from_search_roots(
    search_roots,
    declared_extension_ids(document, enabled_only~),
    function_name~,
  )
}

///|
/// Builds deterministic registry bindings from one link plan.
fn build_generated_registry_bindings(
  plan : @catalog.ExtensionLinkPlan,
) -> Array[GeneratedRegistryBinding] {
  let bindings : Array[GeneratedRegistryBinding] = []
  let alias_counts : Map[String, Int] = {}
  for input in plan.inputs() {
    let base_alias = generated_alias_base(input.package_path())
    let import_alias = unique_generated_alias(base_alias, alias_counts)
    bindings.push(GeneratedRegistryBinding::{
      extension_id: input.id(),
      package_path: input.package_path(),
      import_alias,
      spec_symbol: input.spec_symbol(),
    })
  }
  bindings
}

///|
/// Validates that the generated function name is a non-empty snake_case identifier.
fn validate_generated_function_name(name : String) -> Result[String, String] {
  let normalized = name.trim().to_string()
  guard normalized != "" else {
    return Err("generated registry function name must not be empty")
  }

  for index, ch in normalized {
    if index == 0 {
      guard is_identifier_start(ch) else {
        return Err(
          "generated registry function name must start with a lowercase letter or _",
        )
      }
    } else {
      guard is_identifier_continue(ch) else {
        return Err(
          "generated registry function name must use only lowercase letters, digits, or _",
        )
      }
    }
  }

  Ok(normalized)
}

///|
/// Renders the `moon.pkg` import block needed by one generated registry module.
fn render_moon_pkg_import_block(
  bindings : Array[GeneratedRegistryBinding],
) -> String {
  let builder = StringBuilder::new()
  builder.write_string("import {\n")
  builder.write_string("  \"justjavac/lepus_app\" @app,\n")
  for binding in bindings {
    builder.write_string("  \"")
    builder.write_string(binding.package_path)
    builder.write_string("\" @")
    builder.write_string(binding.import_alias)
    builder.write_string(",\n")
  }
  builder.write_string("}\n")
  builder.to_string()
}

///|
/// Renders one `.mbt` source file that constructs the explicit registry.
fn render_generated_registry_source(
  bindings : Array[GeneratedRegistryBinding],
  function_name : String,
) -> String {
  let builder = StringBuilder::new()
  builder.write_string("///|\n")
  builder.write_string(
    "/// Generated by justjavac/lepus_tooling from extension metadata.\n",
  )
  builder.write_string(
    "/// Keep the corresponding moon.pkg imports explicit and reviewable.\n",
  )
  builder.write_string("pub fn ")
  builder.write_string(function_name)
  builder.write_string("() -> @app.ExtensionRegistry {\n")
  builder.write_string("  let registry = @app.ExtensionRegistry::new()\n")
  for binding in bindings {
    builder.write_string("  let _ = registry.register(@")
    builder.write_string(binding.import_alias)
    builder.write_char('.')
    builder.write_string(binding.spec_symbol)
    builder.write_string("())\n")
  }
  builder.write_string("  registry\n")
  builder.write_string("}\n")
  builder.to_string()
}

///|
/// Builds a deterministic package alias base from one package path.
fn generated_alias_base(package_path : String) -> String {
  let builder = StringBuilder::new(size_hint=package_path.length() + 4)
  builder.write_string("ext_")
  for _, ch in package_path {
    if is_identifier_continue(ch) {
      builder.write_char(ch)
    } else {
      builder.write_char('_')
    }
  }
  builder.to_string()
}

///|
/// Ensures each generated alias stays unique even if package paths sanitize the same way.
fn unique_generated_alias(
  base_alias : String,
  alias_counts : Map[String, Int],
) -> String {
  match alias_counts.get(base_alias) {
    Some(count) => {
      let next = count + 1
      alias_counts.set(base_alias, next)
      base_alias + "_" + next.to_string()
    }
    None => {
      alias_counts.set(base_alias, 1)
      base_alias
    }
  }
}

///|
/// Returns whether one character is valid at the start of a snake_case identifier.
fn is_identifier_start(ch : Char) -> Bool {
  ('a' <= ch && ch <= 'z') || ch == '_'
}

///|
/// Returns whether one character is valid after the first position in a snake_case identifier.
fn is_identifier_continue(ch : Char) -> Bool {
  is_identifier_start(ch) || ('0' <= ch && ch <= '9')
}
