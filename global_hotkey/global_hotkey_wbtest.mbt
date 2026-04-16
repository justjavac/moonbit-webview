///|
test "globalHotkey parses modifier shortcuts" {
  inspect(
    parse_accelerator("ctrl+shift+k"),
    content="Ok({normalized: \"Ctrl+Shift+K\", modifiers: 6, key: 75})",
  )
}

///|
test "globalHotkey parses function keys" {
  inspect(
    parse_accelerator("Alt+F12"),
    content="Ok({normalized: \"Alt+F12\", modifiers: 1, key: 123})",
  )
}
