///|
/// Loaded manifest plus the base directory used to resolve relative file paths.
struct LoadedAppManifest {
  manifest : @manifest.AppManifest
  base_dir : String?
}

///|
/// Creates a loaded manifest wrapper.
/// This is primarily used by bootstrap helpers that need to carry both the
/// typed manifest value and its optional base directory.
pub fn LoadedAppManifest::new(
  manifest : @manifest.AppManifest,
  base_dir? : String? = None,
) -> LoadedAppManifest {
  LoadedAppManifest::{ manifest, base_dir }
}

///|
/// Returns the loaded manifest value.
/// This is a cheap accessor over the normalized manifest captured at load time.
pub fn LoadedAppManifest::manifest(
  self : LoadedAppManifest,
) -> @manifest.AppManifest {
  self.manifest
}

///|
/// Returns the manifest base directory, if the manifest came from disk.
/// Relative file entries should be interpreted against this directory when it
/// is present.
pub fn LoadedAppManifest::base_dir(self : LoadedAppManifest) -> String? {
  self.base_dir
}
