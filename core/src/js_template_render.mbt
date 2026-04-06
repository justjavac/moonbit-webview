///|
struct TemplateReplacement {
  token : String
  value : String
}

///|
/// Replaces every occurrence of one template token in a string.
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
/// Applies a sequence of token replacements to a JavaScript template string.
/// Replacements are processed in order, which allows later entries to build on
/// earlier substitutions when generating runtime helper scripts.
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
/// Creates a single token replacement entry for `render_js_template`.
/// This keeps call sites readable when several template tokens need to be
/// substituted together.
pub fn replacement(token : String, value : String) -> TemplateReplacement {
  TemplateReplacement::{ token, value }
}
