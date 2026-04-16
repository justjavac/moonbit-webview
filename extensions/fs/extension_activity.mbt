///|
struct FsActivity {
  operation : String
  path : String?
  rid : Int?
  bytes : Int?
} derive(ToJson, FromJson, Debug, Eq)

///|
/// Emits a filesystem activity event for JavaScript listeners.
fn emit_activity(
  extension : @core.ExtensionContext,
  operation : String,
  path? : String? = None,
  rid? : Int? = None,
  bytes? : Int? = None,
) -> Unit {
  extension.emit("activity", FsActivity::{ operation, path, rid, bytes })
}
