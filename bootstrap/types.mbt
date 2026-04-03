///|
/// Bootstrap-level app config that combines runtime core settings with
/// runtime-core settings loaded from declarative configuration.
pub struct BootstrapAppConfig {
  window : @wvrt.WindowConfig
  entry : @wvrt.AppEntry
  windows : Array[@wvrt.AppWindowConfig]
  debug : Int
  base_dir : String?
}

///|
pub fn BootstrapAppConfig::new(
  window : @wvrt.WindowConfig,
  entry : @wvrt.AppEntry,
  debug? : Int = 0,
  windows? : Array[@wvrt.AppWindowConfig] = [],
  base_dir? : String? = None,
) -> BootstrapAppConfig {
  BootstrapAppConfig::{ window, entry, windows, debug, base_dir }
}
