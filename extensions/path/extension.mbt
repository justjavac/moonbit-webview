///|
let extension_id = "justjavac/lepus-path"

///|
let extension_namespace = "path"

///|
struct PathPayload {
  path : String
} derive(ToJson, FromJson, Debug, Eq)

///|
struct BasenamePayload {
  path : String
  suffix : String?
} derive(FromJson)

///|
struct JoinPayload {
  left : String
  right : String
} derive(ToJson, FromJson, Debug, Eq)

///|
struct PathsPayload {
  paths : Array[String]
} derive(FromJson)

///|
struct RelativePayload {
  path : String
  base : String
} derive(ToJson, FromJson, Debug, Eq)

///|
struct FormatPayload {
  root : String?
  dir : String?
  base : String?
  name : String?
  ext : String?
} derive(FromJson)

///|
struct PathReply {
  path : String
} derive(ToJson, FromJson, Debug, Eq)

///|
struct BasenameReply {
  name : String
} derive(ToJson, FromJson, Debug, Eq)

///|
struct ExtnameReply {
  ext : String
} derive(ToJson, FromJson, Debug, Eq)

///|
struct IsAbsoluteReply {
  is_absolute : Bool
} derive(ToJson, FromJson, Debug, Eq)

///|
struct ParseReply {
  root : String
  dir : String
  base : String
  ext : String
  name : String
} derive(ToJson)

///|
/// Registers a path API that returns a single `path` string field.
fn register_path_reply_op(
  extension : @core.ExtensionContext,
  name : String,
  callback : (String) -> String,
) -> Unit {
  extension.op(name, fn(payload : PathPayload) {
    PathReply::{ path: callback(payload.path) }
  })
}

///|
/// Registers a path API that consumes many paths and returns one `path` string field.
fn register_paths_reply_op(
  extension : @core.ExtensionContext,
  name : String,
  callback : (Array[String]) -> String,
) -> Unit {
  extension.op(name, fn(payload : PathsPayload) {
    PathReply::{ path: callback(payload.paths) }
  })
}

///|
/// Builds the `path` extension for direct installation.
///
/// Install it with `@core.install_extension(webview, @path.extension())` to expose
/// `window.__MoonBit__.path` for common path operations such as `resolve`,
/// `join`, `dirname`, `basename`, `parse`, and `format`.
pub fn extension() -> @core.Extension {
  @core.Extension::new(
    extension_id,
    extension_namespace,
    fn(extension) {
      extension.op("basename", fn(payload : BasenamePayload) {
        BasenameReply::{
          name: basename_path(payload.path, suffix=payload.suffix),
        }
      })
      register_path_reply_op(extension, "dirname", dirname_path)
      extension.op("extname", fn(payload : PathPayload) {
        ExtnameReply::{ ext: extname_path(payload.path) }
      })
      extension.op("isAbsolute", fn(payload : PathPayload) {
        IsAbsoluteReply::{ is_absolute: is_absolute_path(payload.path) }
      })
      extension.op("join", fn(payload : JoinPayload) {
        PathReply::{ path: join_paths(payload.left, payload.right) }
      })
      register_paths_reply_op(extension, "joinAll", join_many_paths)
      register_path_reply_op(extension, "normalize", normalize_path)
      extension.op("relative", fn(payload : RelativePayload) {
        PathReply::{ path: relative_path(payload.path, payload.base) }
      })
      register_path_reply_op(extension, "resolve", resolve_path)
      register_paths_reply_op(extension, "resolveAll", resolve_many_paths)
      extension.op("parse", fn(payload : PathPayload) {
        parse_path(payload.path)
      })
      extension.op("format", fn(payload : FormatPayload) {
        PathReply::{ path: format_path(payload) }
      })
    },
    scripts=[path_helper_script()],
  )
}

///|
/// Builds the declarative `path` extension spec.
/// Register this when common path operations should be linked declaratively
/// through app composition.
pub fn spec() -> @core.ExtensionSpec {
  @core.ExtensionSpec::new(extension_id, extension_namespace, fn(_context) {
    Ok(extension())
  })
}
