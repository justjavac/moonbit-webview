///|
/// Parsed open-mode flags for the in-memory `fs` stream implementation.
priv struct FileOpenMode {
  can_read : Bool
  can_write : Bool
  create_if_missing : Bool
  truncate_on_open : Bool
  append_on_write : Bool
}

///|
/// Tracks one open in-memory file handle plus its current cursor and dirty state.
priv struct MemoryFileHandle {
  path : String
  mode : FileOpenMode
  mut content : Bytes
  mut cursor : Int
  mut dirty : Bool
}

///|
struct OpenPayload {
  path : String
  mode : String
} derive(ToJson, FromJson, Debug, Eq)

///|
priv struct OpenFilePayload {
  path : String
  flags : String?
  read : Bool?
  write : Bool?
  append : Bool?
  create : Bool?
  truncate : Bool?
  create_new : Bool?
} derive(FromJson)

///|
struct OpenReply {
  rid : Int
} derive(ToJson, FromJson, Debug, Eq)

///|
struct ReadPayload {
  rid : Int
  size : Int
} derive(ToJson, FromJson, Debug, Eq)

///|
struct ReadReply {
  content : String
  bytes_read : Int
  eof : Bool
} derive(ToJson, FromJson, Debug, Eq)

///|
struct WritePayload {
  rid : Int
  content : String
} derive(ToJson, FromJson, Debug, Eq)

///|
struct WriteReply {
  bytes_written : Int
} derive(ToJson, FromJson, Debug, Eq)

///|
struct ClosePayload {
  rid : Int
} derive(ToJson, FromJson, Debug, Eq)

///|
struct CloseReply {
  closed : Bool
} derive(ToJson, FromJson, Debug, Eq)

///|
struct FlushPayload {
  rid : Int
} derive(ToJson, FromJson, Debug, Eq)

///|
struct FlushReply {
  flushed : Bool
} derive(ToJson, FromJson, Debug, Eq)

///|
struct SeekPayload {
  rid : Int
  offset : Int
  whence : String
} derive(ToJson, FromJson, Debug, Eq)

///|
struct SeekReply {
  position : Int
} derive(ToJson, FromJson, Debug, Eq)

///|
struct FstatPayload {
  rid : Int
} derive(ToJson, FromJson, Debug, Eq)

///|
struct FstatReply {
  path : String?
  size : Int
  position : Int
  eof : Bool
  exists : Bool
  is_file : Bool
  is_dir : Bool
} derive(ToJson, FromJson, Debug, Eq)

///|
struct ExistsPayload {
  path : String
} derive(ToJson, FromJson, Debug, Eq)

///|
struct ExistsReply {
  exists : Bool
} derive(ToJson, FromJson, Debug, Eq)

///|
struct RemoveFilePayload {
  path : String
} derive(ToJson, FromJson, Debug, Eq)

///|
struct RemoveFileReply {
  removed : Bool
} derive(ToJson, FromJson, Debug, Eq)

///|
struct ReadDirPayload {
  path : String
} derive(ToJson, FromJson, Debug, Eq)

///|
struct ReadDirReply {
  entries : Array[String]
} derive(ToJson, FromJson, Debug, Eq)

///|
struct ResolvePathPayload {
  path : String
} derive(ToJson, FromJson, Debug, Eq)

///|
struct ResolvePathReply {
  path : String
} derive(ToJson, FromJson, Debug, Eq)
