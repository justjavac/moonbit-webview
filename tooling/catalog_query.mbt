///|
/// Read-only summary of one discovered extension for tooling UIs and agents.
pub struct ExtensionCatalogSummary {
  id : String
  version : String
  display_name : String
  description : String
  js_namespace : String
  package_path : String
  spec_symbol : String
  platforms : Array[String]
  dependencies : Array[String]
  capabilities : Array[String]
} derive(Eq, Debug, ToJson)

///|
/// Loads extension summaries from explicit search roots.
/// The result is designed for UIs, CLIs, and agents that need discovery-friendly
/// metadata without the full descriptor internals.
pub fn query_extension_catalog(
  search_roots : Array[String],
) -> Result[Array[ExtensionCatalogSummary], String] {
  match @catalog.load_extension_catalog_from_search_roots(search_roots) {
    Err(error) => Err(error)
    Ok(catalog) => {
      let summaries : Array[ExtensionCatalogSummary] = []
      for descriptor in catalog.descriptors() {
        summaries.push(summary_from_descriptor(descriptor))
      }
      Ok(summaries)
    }
  }
}

///|
/// Returns catalog query results in JSON form for scripts or AI workflows.
/// This avoids a second encoding step in environments that already operate on
/// raw JSON values.
pub fn query_extension_catalog_json(
  search_roots : Array[String],
) -> Result[Json, String] {
  match query_extension_catalog(search_roots) {
    Err(error) => Err(error)
    Ok(summaries) => Ok(ToJson::to_json(summaries))
  }
}

///|
/// Converts one catalog descriptor into a tooling-friendly summary.
fn summary_from_descriptor(
  descriptor : @catalog.ExtensionDescriptor,
) -> ExtensionCatalogSummary {
  ExtensionCatalogSummary::{
    id: descriptor.id(),
    version: descriptor.version(),
    display_name: descriptor.display_name(),
    description: descriptor.description(),
    js_namespace: descriptor.js_namespace(),
    package_path: descriptor.package_path(),
    spec_symbol: descriptor.spec_symbol(),
    platforms: descriptor.platforms(),
    dependencies: descriptor.dependencies(),
    capabilities: descriptor.capabilities(),
  }
}
