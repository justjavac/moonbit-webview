struct ReadPayload {
  path : String
} derive(ToJson, FromJson, Eq, Show)

struct ReadReply {
  content : String
} derive(ToJson, FromJson, Eq, Show)

pub fn plugin() -> @webview.Plugin {
  @webview.Plugin::new("fs", fn(plugin) {
    plugin.command("read", fn(payload : ReadPayload) {
      let content = if payload.path == "/README.md" {
        "MoonBit Plugin FS Demo"
      } else if payload.path == "/hello.txt" {
        "Hello MoonBit"
      } else {
        "File not found"
      }
      let reply = ReadReply::{ content: content.to_string() }
      reply
    })
  })
}
