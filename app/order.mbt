///|
/// Builds the ordered extension installation plan implied by one manifest.
fn plan_extensions(
  manifest : @manifest.AppManifest,
  registry : ExtensionRegistry,
) -> Result[Array[PreparedExtension], String] {
  let specs_by_id = registry.spec_map()
  match ensure_manifest_extensions_known(manifest, specs_by_id) {
    Ok(_) => ()
    Err(error) => return Err(error)
  }

  let visit_state : Map[String, Int] = {}
  let planned : Array[PreparedExtension] = []
  for id in registry.ordered_names() {
    if extension_is_enabled(manifest, id) {
      match
        visit_extension(id, None, manifest, specs_by_id, visit_state, planned) {
        Ok(_) => ()
        Err(error) => return Err(error)
      }
    }
  }
  Ok(planned)
}

///|
/// Rejects any manifest extension key that is not present in the registry.
fn ensure_manifest_extensions_known(
  manifest : @manifest.AppManifest,
  specs_by_id : Map[String, @core.ExtensionSpec],
) -> Result[Unit, String] {
  for entry in manifest.extension_settings() {
    let (id, _setting) = entry
    guard specs_by_id.get(id) is Some(_) else {
      return Err("unknown extension key: " + id)
    }
  }
  Ok(())
}

///|
/// Returns whether the manifest explicitly enables one extension id.
fn extension_is_enabled(manifest : @manifest.AppManifest, id : String) -> Bool {
  match manifest.extension_setting(id) {
    Some(setting) => setting.is_enabled()
    None => false
  }
}

///|
/// Visits one extension during dependency resolution and builds a deterministic install order.
fn visit_extension(
  id : String,
  requested_by_id : String?,
  manifest : @manifest.AppManifest,
  specs_by_id : Map[String, @core.ExtensionSpec],
  visit_state : Map[String, Int],
  planned : Array[PreparedExtension],
) -> Result[Unit, String] {
  match visit_state.get(id) {
    Some(2) => return Ok(())
    Some(1) => return Err("extension dependency cycle detected at: " + id)
    _ => ()
  }

  let spec = match require_extension_spec(id, requested_by_id, specs_by_id) {
    Ok(spec) => spec
    Err(error) => return Err(error)
  }
  let options = match resolve_extension_options(id, requested_by_id, manifest) {
    Ok(options) => options
    Err(error) => return Err(error)
  }

  visit_state.set(id, 1)
  match
    visit_extension_dependencies(
      id,
      spec.dependencies(),
      manifest,
      specs_by_id,
      visit_state,
      planned,
    ) {
    Ok(_) => ()
    Err(error) => return Err(error)
  }
  visit_state.set(id, 2)
  planned.push(PreparedExtension::new(id, spec, options))
  Ok(())
}

///|
/// Resolves one extension spec by id, surfacing dependency context in errors.
fn require_extension_spec(
  id : String,
  requested_by_id : String?,
  specs_by_id : Map[String, @core.ExtensionSpec],
) -> Result[@core.ExtensionSpec, String] {
  match specs_by_id.get(id) {
    Some(spec) => Ok(spec)
    None =>
      match requested_by_id {
        Some(requested_by_id) =>
          Err(
            "extension " +
            requested_by_id +
            " requires missing dependency " +
            id,
          )
        None => Err("unknown extension key: " + id)
      }
  }
}

///|
/// Resolves the manifest options for one extension and rejects disabled dependencies.
fn resolve_extension_options(
  id : String,
  requested_by_id : String?,
  manifest : @manifest.AppManifest,
) -> Result[Json?, String] {
  match manifest.extension_setting(id) {
    Some(Disabled) =>
      match requested_by_id {
        Some(requested_by_id) =>
          Err(
            "extension " +
            requested_by_id +
            " requires disabled dependency " +
            id,
          )
        None => Ok(None)
      }
    Some(setting) => Ok(setting.options())
    None => Ok(None)
  }
}

///|
/// Visits every dependency of one extension before it is installed.
fn visit_extension_dependencies(
  id : String,
  dependencies : Array[String],
  manifest : @manifest.AppManifest,
  specs_by_id : Map[String, @core.ExtensionSpec],
  visit_state : Map[String, Int],
  planned : Array[PreparedExtension],
) -> Result[Unit, String] {
  for dependency in dependencies {
    match
      visit_extension(
        dependency,
        Some(id),
        manifest,
        specs_by_id,
        visit_state,
        planned,
      ) {
      Ok(_) => ()
      Err(error) => return Err(error)
    }
  }
  Ok(())
}
