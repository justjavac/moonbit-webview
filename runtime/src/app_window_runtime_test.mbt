///|
test "App registers additional windows before run" {
  let config = @lepus_runtime.AppConfig::new(
    @lepus_runtime.WindowConfig::new("runtime-main", 800, 600),
    @lepus_runtime.AppEntry::Html("<html>Main</html>"),
    windows=[
      @lepus_runtime.AppWindowConfig::new(
        "docs",
        @lepus_runtime.WindowConfig::new("Docs", 640, 480),
        @lepus_runtime.AppEntry::Html("<html>Docs</html>"),
      ),
    ],
  )
  let app = @lepus_runtime.App::new(config)
  assert_eq(app.main_window().id(), "main")
  assert_eq(app.windows().length(), 2)
  match app.window("docs") {
    Some(window) => {
      assert_eq(window.id(), "docs")
      assert_eq(window.config().title, "Docs")
    }
    None => abort("expected docs window")
  }
  app.destroy()
}

///|
test "panic App::install_extension applies to registered windows" {
  let config = @lepus_runtime.AppConfig::new(
    @lepus_runtime.WindowConfig::new("runtime-main", 800, 600),
    @lepus_runtime.AppEntry::Html("<html>Main</html>"),
    windows=[
      @lepus_runtime.AppWindowConfig::new(
        "docs",
        @lepus_runtime.WindowConfig::new("Docs", 640, 480),
        @lepus_runtime.AppEntry::Html("<html>Docs</html>"),
      ),
    ],
  )
  let app = @lepus_runtime.App::new(config)
  app.install_extension(
    @core.Extension::new("tests/math", "math", fn(_extension) {  }),
  )
  match app.window("docs") {
    Some(window) =>
      @core.install_extension(
        window.webview(),
        @core.Extension::new("tests/math", "math", fn(_extension) {  }),
      )
    None => abort("expected docs window")
  }
}
