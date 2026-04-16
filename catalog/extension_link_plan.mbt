///|
/// One explicit import-time input needed to link an extension into an app project.
pub struct ExtensionLinkInput {
  id : String
  package_path : String
  spec_symbol : String
} derive(Eq, Debug)

///|
/// Deterministic set of link inputs for a selected extension subset.
pub struct ExtensionLinkPlan {
  ordered_inputs : Array[ExtensionLinkInput]
} derive(Eq, Debug)

///|
/// Returns the ordered link inputs that should become explicit project edits.
/// Each input corresponds to one package import plus one registry registration
/// call in generated code.
pub fn ExtensionLinkPlan::inputs(
  self : ExtensionLinkPlan,
) -> Array[ExtensionLinkInput] {
  self.ordered_inputs
}

///|
/// Returns the extension ids in link order.
/// Transitive dependencies appear before the extensions that require them.
pub fn ExtensionLinkPlan::extension_ids(
  self : ExtensionLinkPlan,
) -> Array[String] {
  let ids : Array[String] = []
  for input in self.ordered_inputs {
    ids.push(input.id)
  }
  ids
}

///|
/// Returns the import path needed to link this extension.
/// Tooling writes this path into generated `moon.pkg` import blocks.
pub fn ExtensionLinkInput::package_path(self : ExtensionLinkInput) -> String {
  self.package_path
}

///|
/// Returns the extension id represented by this input.
/// This is the same id used by manifests and catalogs during planning.
pub fn ExtensionLinkInput::id(self : ExtensionLinkInput) -> String {
  self.id
}

///|
/// Returns the exported spec symbol that should be registered.
/// Generated registries invoke this symbol on the imported package.
pub fn ExtensionLinkInput::spec_symbol(self : ExtensionLinkInput) -> String {
  self.spec_symbol
}

///|
/// Builds a deterministic link plan from selected extension ids and metadata deps.
/// The plan expands transitive dependencies and rejects missing ids or cycles
/// with catalog-style diagnostics.
pub fn build_extension_link_plan(
  catalog : ExtensionCatalog,
  selected_ids : Array[String],
) -> Result[ExtensionLinkPlan, String] {
  let visit_state : Map[String, Int] = {}
  let inputs : Array[ExtensionLinkInput] = []
  for id in selected_ids {
    let normalized = match normalize_selected_extension_id(id) {
      Ok(normalized) => normalized
      Err(error) => return Err(error)
    }
    match
      visit_linked_extension(normalized, None, catalog, visit_state, inputs) {
      Ok(_) => ()
      Err(error) => return Err(error)
    }
  }
  Ok(ExtensionLinkPlan::{ ordered_inputs: inputs })
}

///|
/// Visits one extension id and appends it after all metadata dependencies.
fn visit_linked_extension(
  id : String,
  requested_by : String?,
  catalog : ExtensionCatalog,
  visit_state : Map[String, Int],
  inputs : Array[ExtensionLinkInput],
) -> Result[Unit, String] {
  match visit_state.get(id) {
    Some(2) => return Ok(())
    Some(1) =>
      return Err(
        CatalogDiagnostic::new(
          DependencyCycle,
          id,
          "extension dependency cycle detected at: " + id,
        ).to_error_string(),
      )
    _ => ()
  }

  let descriptor = match require_linked_descriptor(id, requested_by, catalog) {
    Ok(descriptor) => descriptor
    Err(error) => return Err(error)
  }

  visit_state.set(id, 1)
  match
    visit_linked_dependencies(
      id,
      descriptor.dependencies(),
      catalog,
      visit_state,
      inputs,
    ) {
    Ok(_) => ()
    Err(error) => return Err(error)
  }
  visit_state.set(id, 2)
  inputs.push(ExtensionLinkInput::{
    id,
    package_path: descriptor.package_path(),
    spec_symbol: descriptor.spec_symbol(),
  })
  Ok(())
}

///|
/// Rejects blank selected extension ids before dependency resolution starts.
fn normalize_selected_extension_id(id : String) -> Result[String, String] {
  let normalized = id.trim().to_string()
  if normalized == "" {
    Err(
      CatalogDiagnostic::new(
        InvalidMetadata,
        id,
        "selected extension id must not be empty",
      ).to_error_string(),
    )
  } else {
    Ok(normalized)
  }
}

///|
/// Resolves one descriptor by id while preserving dependency context in errors.
fn require_linked_descriptor(
  id : String,
  requested_by : String?,
  catalog : ExtensionCatalog,
) -> Result[ExtensionDescriptor, String] {
  match catalog.get(id) {
    Some(descriptor) => Ok(descriptor)
    None =>
      match requested_by {
        Some(requested_by) =>
          Err(
            CatalogDiagnostic::new(
              UnknownExtensionId,
              id,
              "extension " + requested_by + " requires missing dependency " + id,
            ).to_error_string(),
          )
        None =>
          Err(
            CatalogDiagnostic::new(
              UnknownExtensionId,
              id,
              "unknown extension id: " + id,
            ).to_error_string(),
          )
      }
  }
}

///|
/// Visits every dependency of one linked descriptor before recording it.
fn visit_linked_dependencies(
  id : String,
  dependencies : Array[String],
  catalog : ExtensionCatalog,
  visit_state : Map[String, Int],
  inputs : Array[ExtensionLinkInput],
) -> Result[Unit, String] {
  for dependency in dependencies {
    match
      visit_linked_extension(dependency, Some(id), catalog, visit_state, inputs) {
      Ok(_) => ()
      Err(error) => return Err(error)
    }
  }
  Ok(())
}
