///|
/// Structured diagnostic emitted while reading extension metadata or planning links.
pub(all) enum CatalogDiagnosticKind {
  MissingFile
  InvalidSearchRoot
  DirectoryReadFailed
  InvalidJson
  InvalidMetadata
  DuplicateExtensionId
  UnknownExtensionId
  DependencyCycle
} derive(Eq, Debug)

///|
/// One catalog-level diagnostic with a machine-readable kind and location hint.
pub struct CatalogDiagnostic {
  kind : CatalogDiagnosticKind
  path : String
  message : String
} derive(Eq, Debug)

///|
/// Builds one catalog diagnostic entry.
/// Callers typically convert the result with `to_error_string()` before
/// surfacing it through CLIs, editors, or agent tooling.
pub fn CatalogDiagnostic::new(
  kind : CatalogDiagnosticKind,
  path : String,
  message : String,
) -> CatalogDiagnostic {
  CatalogDiagnostic::{ kind, path, message }
}

///|
/// Formats one catalog diagnostic as a single human-readable error string.
/// The result keeps the stored path prefix so users can trace the failure back
/// to one descriptor, schema, or search root.
pub fn CatalogDiagnostic::to_error_string(self : CatalogDiagnostic) -> String {
  self.path + ": " + self.message
}
