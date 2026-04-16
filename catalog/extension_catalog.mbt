///|
/// Metadata catalog for Lepus extensions discovered from explicit search roots.
pub struct ExtensionCatalog {
  descriptors : Map[String, ExtensionDescriptor]
  discovery_order : Array[String]
}

///|
/// Creates an empty extension catalog.
/// Discovery order is tracked alongside descriptor lookup so later tooling and
/// generated output stay deterministic.
pub fn ExtensionCatalog::new() -> ExtensionCatalog {
  ExtensionCatalog::{ descriptors: {}, discovery_order: [] }
}

///|
/// Builds a catalog from already decoded descriptors while checking duplicate ids.
/// Input order is preserved after validation so descriptor iteration matches the
/// original discovery order.
pub fn ExtensionCatalog::from_descriptors(
  descriptors : Array[ExtensionDescriptor],
) -> Result[ExtensionCatalog, String] {
  let catalog = ExtensionCatalog::new()
  for descriptor in descriptors {
    let id = descriptor.id()
    guard id.trim().to_string() != "" else {
      return Err(
        CatalogDiagnostic::new(
          InvalidMetadata,
          descriptor.metadata_path(),
          "extension id must not be empty",
        ).to_error_string(),
      )
    }
    guard catalog.descriptors.get(id) is None else {
      return Err(
        CatalogDiagnostic::new(
          DuplicateExtensionId,
          descriptor.metadata_path(),
          "duplicate extension id: " + id,
        ).to_error_string(),
      )
    }
    catalog.descriptors.set(id, descriptor)
    catalog.discovery_order.push(id)
  }
  Ok(catalog)
}

///|
/// Returns one descriptor by id, if present.
/// Use `require()` when missing entries should become a formatted catalog error.
pub fn ExtensionCatalog::get(
  self : ExtensionCatalog,
  id : String,
) -> ExtensionDescriptor? {
  self.descriptors.get(id)
}

///|
/// Returns one descriptor or an explicit unknown-id error.
/// This keeps unknown-extension failures formatted consistently with other
/// catalog diagnostics.
pub fn ExtensionCatalog::require(
  self : ExtensionCatalog,
  id : String,
) -> Result[ExtensionDescriptor, String] {
  match self.descriptors.get(id) {
    Some(descriptor) => Ok(descriptor)
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

///|
/// Returns the known extension ids in deterministic discovery order.
/// The returned order matches descriptor discovery and later link-planning
/// output.
pub fn ExtensionCatalog::descriptor_ids(
  self : ExtensionCatalog,
) -> Array[String] {
  self.discovery_order
}

///|
/// Returns every descriptor in deterministic discovery order.
/// Each descriptor appears in the same order as its corresponding id from
/// `descriptor_ids()`.
pub fn ExtensionCatalog::descriptors(
  self : ExtensionCatalog,
) -> Array[ExtensionDescriptor] {
  let descriptors : Array[ExtensionDescriptor] = []
  for id in self.discovery_order {
    match self.descriptors.get(id) {
      Some(descriptor) => descriptors.push(descriptor)
      None => ()
    }
  }
  descriptors
}

///|
/// Loads the schema referenced by one known descriptor id.
/// The descriptor id is validated against the catalog before the schema file is
/// read from disk.
pub fn ExtensionCatalog::load_schema(
  self : ExtensionCatalog,
  id : String,
) -> Result[ExtensionSchema, String] {
  self.require(id).bind(load_extension_schema)
}

///|
/// Loads a catalog from many explicit `extension.json` file paths.
/// Each descriptor is decoded independently so the first metadata error can be
/// reported with its exact file path.
pub fn load_extension_catalog_from_descriptor_files(
  paths : Array[String],
) -> Result[ExtensionCatalog, String] {
  let descriptors : Array[ExtensionDescriptor] = []
  for path in paths {
    match load_extension_descriptor_from_file(path) {
      Err(error) => return Err(error)
      Ok(descriptor) => descriptors.push(descriptor)
    }
  }
  ExtensionCatalog::from_descriptors(descriptors)
}

///|
/// Discovers `extension.json` files from one or more explicit search roots.
///
/// Each search root may be:
/// - one directory that contains many extension package directories
/// - one specific extension package directory
/// - one explicit `extension.json` file path
pub fn discover_extension_descriptor_files(
  search_roots : Array[String],
) -> Result[Array[String], String] {
  let descriptor_paths : Array[String] = []
  for root in search_roots {
    match collect_extension_descriptor_files(root, descriptor_paths) {
      Ok(_) => ()
      Err(error) => return Err(error)
    }
  }
  descriptor_paths.sort()
  Ok(deduplicate_sorted_paths(descriptor_paths))
}

///|
/// Loads a catalog by scanning one or more explicit extension search roots.
/// Search roots may point at extension package directories, explicit
/// `extension.json` files, or directories that contain many extensions.
pub fn load_extension_catalog_from_search_roots(
  search_roots : Array[String],
) -> Result[ExtensionCatalog, String] {
  discover_extension_descriptor_files(search_roots).bind(
    load_extension_catalog_from_descriptor_files,
  )
}

///|
/// Collects every descriptor file reachable from one search root.
fn collect_extension_descriptor_files(
  raw_root : String,
  descriptor_paths : Array[String],
) -> Result[Unit, String] {
  let root = normalize_path_string(raw_root)
  guard @mbfs.path_exists(root) else {
    return Err(
      CatalogDiagnostic::new(
        MissingFile,
        root,
        "extension search root does not exist: " + root,
      ).to_error_string(),
    )
  }

  let is_dir_result : Result[Bool, _] = try? @mbfs.is_dir(root)
  is_dir_result
  .map_err(fn(error) {
    CatalogDiagnostic::new(
      InvalidSearchRoot,
      root,
      "failed to inspect extension search root: " + error.to_string(),
    ).to_error_string()
  })
  .bind(fn(is_dir) {
    if is_dir {
      collect_extension_descriptor_files_from_directory(root, descriptor_paths)
    } else if root.has_suffix("extension.json") {
      descriptor_paths.push(root)
      Ok(())
    } else {
      Err(
        CatalogDiagnostic::new(
          InvalidSearchRoot,
          root,
          "extension search root must be a directory or extension.json file",
        ).to_error_string(),
      )
    }
  })
}

///|
/// Walks one directory root until it reaches extension package directories.
fn collect_extension_descriptor_files_from_directory(
  directory : String,
  descriptor_paths : Array[String],
) -> Result[Unit, String] {
  let entries = match read_extension_search_directory(directory) {
    Ok(entries) => entries
    Err(error) => return Err(error)
  }
  entries.sort()

  if entries.contains("extension.json") {
    descriptor_paths.push(path_join(directory, "extension.json"))
    return Ok(())
  }

  for entry in entries {
    if should_skip_extension_search_entry(entry) {
      continue
    }
    let child = path_join(directory, entry)
    match is_extension_search_directory(child) {
      Err(error) => return Err(error)
      Ok(true) =>
        match
          collect_extension_descriptor_files_from_directory(
            child, descriptor_paths,
          ) {
          Ok(_) => ()
          Err(error) => return Err(error)
        }
      Ok(false) => ()
    }
  }

  Ok(())
}

///|
/// Reads one directory while preserving catalog-specific error context.
fn read_extension_search_directory(
  directory : String,
) -> Result[Array[String], String] {
  let entries_result : Result[Array[String], _] = try? @mbfs.read_dir(directory)
  entries_result.map_err(fn(error) {
    CatalogDiagnostic::new(
      DirectoryReadFailed,
      directory,
      "failed to read extension search root: " + error.to_string(),
    ).to_error_string()
  })
}

///|
/// Returns whether one candidate search entry is a directory.
fn is_extension_search_directory(path : String) -> Result[Bool, String] {
  let child_is_dir_result : Result[Bool, _] = try? @mbfs.is_dir(path)
  child_is_dir_result.map_err(fn(error) {
    CatalogDiagnostic::new(
      InvalidSearchRoot,
      path,
      "failed to inspect extension search entry: " + error.to_string(),
    ).to_error_string()
  })
}

///|
/// Skips generated or hidden directories while scanning extension roots.
fn should_skip_extension_search_entry(entry : String) -> Bool {
  entry.has_prefix(".") ||
  entry == "_build" ||
  entry == "build" ||
  entry == "target"
}

///|
/// Removes duplicate paths from one already sorted descriptor list.
fn deduplicate_sorted_paths(paths : Array[String]) -> Array[String] {
  let deduplicated : Array[String] = []
  let mut previous : String? = None
  for path in paths {
    if previous != Some(path) {
      deduplicated.push(path)
      previous = Some(path)
    }
  }
  deduplicated
}
