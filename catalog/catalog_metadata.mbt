///|
/// TODO(justjavac): 重写 catalog 逻辑，不在区分内置扩展和自定义扩展，所有扩展都走同一套逻辑，不再硬编码内置扩展。
pub fn builtin_extensions() -> Array[BuiltinExtensionInfo] {
  [
    BuiltinExtensionInfo::new(
      "fs", "Filesystem", "Native filesystem access with Node-style path APIs and rid-based streaming APIs.",
      "extensions/fs", "ext_fs",
    ),
    BuiltinExtensionInfo::new(
      "path", "Path", "Portable path helpers exposed through window.__MoonBit__.path with Node-style wrappers.",
      "extensions/path", "ext_path",
    ),
    BuiltinExtensionInfo::new(
      "dialog", "Dialog", "Native dialog helpers for runtime apps.", "extensions/dialog",
      "ext_dialog",
    ),
    BuiltinExtensionInfo::new(
      "clipboard", "Clipboard", "Clipboard helpers for runtime apps.", "extensions/clipboard",
      "ext_clipboard",
    ),
    BuiltinExtensionInfo::new(
      "shell", "Shell", "Native shell helpers for opening and revealing files.",
      "extensions/shell", "ext_shell",
    ),
    BuiltinExtensionInfo::new(
      "notification",
      "Notification",
      "Windows-native notification helpers.",
      "extensions/notification",
      "ext_notification",
      support_modules=[
        BuiltinSupportModuleInfo::new("justjavac/notification", "notification"),
      ],
    ),
    BuiltinExtensionInfo::new(
      "tray",
      "Tray",
      "Windows-native tray icon helpers.",
      "extensions/tray",
      "ext_tray",
      support_modules=[BuiltinSupportModuleInfo::new("justjavac/tray", "tray")],
    ),
    BuiltinExtensionInfo::new(
      "globalHotkey",
      "Global Hotkey",
      "Windows-native global hotkey helpers.",
      "extensions/global_hotkey",
      "ext_global_hotkey",
      support_modules=[
        BuiltinSupportModuleInfo::new(
          "justjavac/global_hotkey", "global_hotkey",
        ),
      ],
    ),
  ]
}

///|
pub fn builtin_extension_info(id : String) -> BuiltinExtensionInfo? {
  for info in builtin_extensions() {
    if info.id() == id {
      return Some(info)
    }
  }
  None
}
