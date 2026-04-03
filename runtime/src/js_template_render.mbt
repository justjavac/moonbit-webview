///|
pub struct TemplateReplacement {
  token : String
  value : String
}

///|
fn replace_template_token(
  template : String,
  replacement : TemplateReplacement,
) -> String {
  if replacement.token == "" {
    return template
  }
  template
  .split(replacement.token)
  .map(part => part.to_string())
  .to_array()
  .join(replacement.value)
}

///|
pub fn render_js_template(
  template : String,
  replacements : Array[TemplateReplacement],
) -> String {
  let mut rendered = template
  for replacement in replacements {
    rendered = replace_template_token(rendered, replacement)
  }
  rendered
}

///|
pub fn replacement(token : String, value : String) -> TemplateReplacement {
  TemplateReplacement::{ token, value }
}

///|
test "js template renderer replaces repeated tokens" {
  let rendered = render_js_template("before __TOKEN__ middle __TOKEN__ after", [
    replacement("__TOKEN__", "value"),
  ])
  assert_eq(rendered, "before value middle value after")
}
