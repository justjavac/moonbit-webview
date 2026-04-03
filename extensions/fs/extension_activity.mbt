///|
struct FsActivity {
  operation : String
  path : String?
  rid : Int?
  bytes : Int?
} derive(ToJson, FromJson, Show, Eq)

///|
fn emit_activity(
  extension : @runtime.ExtensionContext,
  operation : String,
  path? : String? = None,
  rid? : Int? = None,
  bytes? : Int? = None,
) -> Unit {
  extension.emit("activity", FsActivity::{ operation, path, rid, bytes })
}
