///|
/// A plugin definition that can be installed into a `PluginHost`.
///
/// A plugin is typically exposed from a MoonBit module:
///
/// ```moonbit nocheck
/// pub fn plugin() -> @webview.Plugin {
///   @webview.Plugin::new("math", fn(plugin) {
///     plugin.command("sum", fn(payload : SumPayload) {
///       SumReply::{ total: payload.left + payload.right }
///     })
///   })
/// }
/// ```
///
/// `on_install` runs after the plugin has finished registering commands and
/// JS helpers on the host. `on_destroy` runs when `PluginHost::destroy()` is
/// called, before the underlying `CommandBridge` is torn down.
struct Plugin {
  name : String
  register : (PluginContext) -> Unit
  on_install : (PluginContext) -> Unit
  on_destroy : (PluginContext) -> Unit
}

///|
/// Installs MoonBit plugins into a `Webview` and exposes them as JavaScript
/// APIs through the existing `CommandBridge`.
///
/// On the JavaScript side this exposes:
/// - `window[global_name]["@@call"](plugin_name, api_name, payload)`
/// - `window[global_name][plugin_name][api_name](payload)`
/// - `window[global_name][plugin_name]["@@on"](listener)`
/// - `window[global_name][plugin_name]["@@onEvent"](name, listener)`
///
/// These JS APIs forward to MoonBit through `CommandBridge::handle(...)`.
/// Plugin events are forwarded from MoonBit to JavaScript through the same
/// bridge and delivered as `PluginEvent`.
struct PluginHost {
  webview : Webview
  bridge : CommandBridge
  global_name : String
  plugins : Map[String, Bool]
  apis : Map[String, Bool]
  destroy_hooks : Map[String, () -> Unit]
}

///|
/// Registration context handed to a plugin while it installs its public APIs.
struct PluginContext {
  host : PluginHost
  plugin_name : String
}

///|
/// A plugin-scoped event sent from MoonBit to JavaScript.
pub struct PluginEvent {
  plugin : String
  name : String
  payload : Json
} derive(ToJson, FromJson, Show, Eq)

///|
/// Builds a plugin value that can later be installed on a `PluginHost`.
pub fn Plugin::new(
  name : String,
  register : (PluginContext) -> Unit,
  on_install? : (PluginContext) -> Unit = fn(_context) {  },
  on_destroy? : (PluginContext) -> Unit = fn(_context) {  },
) -> Plugin {
  Plugin::{ name, register, on_install, on_destroy }
}

///|
/// Creates a plugin host backed by a `CommandBridge`.
///
/// `global_name` controls the JavaScript namespace used for plugin APIs and
/// defaults to `window.MoonBitPlugins`.
///
/// `command_global_name`, `binding_name`, and `event_name` are passed through
/// to the underlying `CommandBridge`.
pub fn PluginHost::new(
  webview : Webview,
  global_name? : String = "MoonBitPlugins",
  command_global_name? : String = "MoonBitBridge",
  binding_name? : String = "__moonbit_command",
  event_name? : String = "moonbit:command",
) -> PluginHost {
  let host = PluginHost::{
    webview,
    bridge: CommandBridge::new(
      webview,
      global_name=command_global_name,
      binding_name~,
      event_name~,
    ),
    global_name,
    plugins: {},
    apis: {},
    destroy_hooks: {},
  }
  host.install_script(make_plugin_host_script(global_name, command_global_name))
  host
}

///|
/// Returns the JavaScript global object name used for plugin APIs.
pub fn PluginHost::global_name(self : PluginHost) -> String {
  self.global_name
}

///|
/// Returns the underlying command bridge used by the plugin host.
pub fn PluginHost::command_bridge(self : PluginHost) -> CommandBridge {
  self.bridge
}

///|
/// Installs a plugin into the host.
///
/// This aborts if another plugin with the same name has already been
/// installed on this host.
pub fn PluginHost::install(self : PluginHost, plugin : Plugin) -> Unit {
  guard !is_reserved_plugin_name(plugin.name) else {
    abort("PluginHost::install: reserved plugin name: " + plugin.name)
  }
  guard self.plugins.get(plugin.name) is None else {
    abort("PluginHost::install: plugin already installed: " + plugin.name)
  }
  let context = PluginContext::{ host: self, plugin_name: plugin.name }
  self.plugins.set(plugin.name, true)
  self.destroy_hooks.set(plugin.name, fn() { (plugin.on_destroy)(context) })
  self.install_script(
    make_plugin_namespace_script(self.global_name, plugin.name),
  )
  (plugin.register)(context)
  (plugin.on_install)(context)
}

///|
/// Drops all registered plugin metadata and destroys the underlying
/// `CommandBridge`.
pub fn PluginHost::destroy(self : PluginHost) -> Unit {
  for _, hook in self.destroy_hooks {
    hook()
  }
  self.plugins.clear()
  self.apis.clear()
  self.destroy_hooks.clear()
  self.bridge.destroy()
}

///|
/// Runs the underlying webview loop and then tears the plugin host down in the
/// correct order so destroy hooks run before the native webview is destroyed.
pub fn PluginHost::run(self : PluginHost) -> Unit {
  let _ = webview_run(self.webview.get_handle())
  self.destroy()
  self.webview.destroy()
}

///|
/// Returns the plugin name currently being installed.
pub fn PluginContext::name(self : PluginContext) -> String {
  self.plugin_name
}

///|
/// Emits a plugin-scoped event from the main program to JavaScript.
///
/// JavaScript receives these events through
/// `window.MoonBitPlugins[plugin_name]["@@on"](...)` and
/// `window.MoonBitPlugins[plugin_name]["@@onEvent"](...)`.
pub fn[Payload : ToJson] PluginHost::emit(
  self : PluginHost,
  plugin_name : String,
  event_name : String,
  payload : Payload,
) -> Unit {
  guard self.plugins.get(plugin_name) is Some(_) else {
    abort("PluginHost::emit: plugin is not installed: " + plugin_name)
  }
  self.bridge.send(plugin_event_command_name(), PluginEvent::{
    plugin: plugin_name,
    name: event_name,
    payload: ToJson::to_json(payload),
  })
}

///|
/// Emits a plugin-scoped event to JavaScript.
///
/// This is safe to call from command handlers or lifecycle hooks.
pub fn[Payload : ToJson] PluginContext::emit(
  self : PluginContext,
  event_name : String,
  payload : Payload,
) -> Unit {
  self.host.emit(self.plugin_name, event_name, payload)
}

///|
/// Registers a typed plugin command.
///
/// The command becomes callable from JavaScript through:
/// `window.MoonBitPlugins[plugin_name][api_name](payload)`.
pub fn[Payload : @json.FromJson, Reply : ToJson] PluginContext::command(
  self : PluginContext,
  api_name : String,
  callback : (Payload) -> Reply,
) -> Unit {
  let command_name = self.register_api(api_name)
  self.host.bridge.handle(command_name, callback)
  self.host.install_script(
    make_plugin_api_script(
      self.host.global_name,
      self.host.bridge.global_name(),
      self.plugin_name,
      api_name,
      command_name,
    ),
  )
}

///|
/// Registers a typed plugin command that can return explicit command errors.
pub fn[Payload : @json.FromJson, Reply : ToJson] PluginContext::command_result(
  self : PluginContext,
  api_name : String,
  callback : (Payload) -> Result[Reply, String],
) -> Unit {
  let command_name = self.register_api(api_name)
  self.host.bridge.handle_result(command_name, callback)
  self.host.install_script(
    make_plugin_api_script(
      self.host.global_name,
      self.host.bridge.global_name(),
      self.plugin_name,
      api_name,
      command_name,
    ),
  )
}

///|
fn PluginContext::register_api(
  self : PluginContext,
  api_name : String,
) -> String {
  guard !is_reserved_api_name(api_name) else {
    abort(
      "PluginContext::register_api: reserved API name: " +
      self.plugin_name +
      "." +
      api_name,
    )
  }
  let command_name = plugin_command_name(self.plugin_name, api_name)
  guard self.host.apis.get(command_name) is None else {
    abort(
      "PluginContext::register_api: API already registered: " +
      self.plugin_name +
      "." +
      api_name,
    )
  }
  self.host.apis.set(command_name, true)
  command_name
}

///|
fn PluginHost::install_script(self : PluginHost, script : String) -> Unit {
  self.webview.init(script)
  self.webview.dispatch(fn() { self.webview.eval(script) })
}

///|
fn plugin_command_name(plugin_name : String, api_name : String) -> String {
  "plugin:" +
  Json::string(plugin_name).stringify() +
  ":" +
  Json::string(api_name).stringify()
}

///|
fn plugin_event_command_name() -> String {
  "@@plugin:event"
}

///|
fn is_reserved_plugin_name(plugin_name : String) -> Bool {
  plugin_name.has_prefix("@@")
}

///|
fn is_reserved_api_name(api_name : String) -> Bool {
  api_name.has_prefix("@@")
}

///|
fn make_plugin_host_script(
  global_name : String,
  bridge_global_name : String,
) -> String {
  let global_name_js = Json::string(global_name).stringify()
  let bridge_global_name_js = Json::string(bridge_global_name).stringify()
  "(function() {" +
  "  const globalName = " +
  global_name_js +
  ";" +
  "  const bridgeName = " +
  bridge_global_name_js +
  ";" +
  "  const pluginEventCommand = '@@plugin:event';" +
  "  const existing = window[globalName];" +
  "  const root = existing && typeof existing === 'object' ? existing : Object.create(null);" +
  "  function getBridge() {" +
  "    const bridge = window[bridgeName];" +
  "    return bridge && typeof bridge.send === 'function' ? bridge : null;" +
  "  }" +
  "  function ensurePluginHelpers(plugin) {" +
  "    if (!Array.isArray(plugin['@@listeners'])) {" +
  "      plugin['@@listeners'] = [];" +
  "    }" +
  "    if (typeof plugin['@@on'] !== 'function') {" +
  "      plugin['@@on'] = function(listener) {" +
  "        root['@@ensureBridgeListener']();" +
  "        if (typeof listener !== 'function') {" +
  "          throw new TypeError('MoonBit plugin listener must be a function');" +
  "        }" +
  "        plugin['@@listeners'].push(listener);" +
  "        return function() {" +
  "          plugin['@@listeners'] = plugin['@@listeners'].filter(function(candidate) {" +
  "            return candidate !== listener;" +
  "          });" +
  "        };" +
  "      };" +
  "    }" +
  "    if (typeof plugin['@@onEvent'] !== 'function') {" +
  "      plugin['@@onEvent'] = function(eventName, listener) {" +
  "        return plugin['@@on'](function(event) {" +
  "          if (event.name === eventName) {" +
  "            listener(event);" +
  "          }" +
  "        });" +
  "      };" +
  "    }" +
  "    return plugin;" +
  "  }" +
  "  root['@@call'] = function(pluginName, apiName, payload) {" +
  "    root['@@ensureBridgeListener']();" +
  "    const bridge = getBridge();" +
  "    if (!bridge) {" +
  "      return Promise.reject(new Error('MoonBit command bridge is not available'));" +
  "    }" +
  "    return bridge.send('plugin:' + JSON.stringify(pluginName) + ':' + JSON.stringify(apiName), payload);" +
  "  };" +
  "  root['@@ensurePlugin'] = function(pluginName) {" +
  "    const plugin = root[pluginName];" +
  "    if (plugin && typeof plugin === 'object') {" +
  "      return ensurePluginHelpers(plugin);" +
  "    }" +
  "    const next = Object.create(null);" +
  "    root[pluginName] = next;" +
  "    return ensurePluginHelpers(next);" +
  "  };" +
  "  root['@@emit'] = function(pluginName, eventName, payload) {" +
  "    const plugin = root['@@ensurePlugin'](pluginName);" +
  "    const event = {" +
  "      plugin: pluginName," +
  "      name: eventName," +
  "      payload: payload === undefined ? null : payload" +
  "    };" +
  "    const listeners = plugin['@@listeners'].slice();" +
  "    for (const listener of listeners) {" +
  "      listener(event);" +
  "    }" +
  "    return event;" +
  "  };" +
  "  root['@@ensureBridgeListener'] = function() {" +
  "    if (root['@@bridgeListenerInstalled']) {" +
  "      return true;" +
  "    }" +
  "    const bridge = getBridge();" +
  "    if (!bridge || typeof bridge.onCommand !== 'function') {" +
  "      return false;" +
  "    }" +
  "    bridge.onCommand(function(command) {" +
  "      if (!command || command.name !== pluginEventCommand) {" +
  "        return;" +
  "      }" +
  "      const event = command.payload;" +
  "      if (!event || typeof event !== 'object') {" +
  "        return;" +
  "      }" +
  "      root['@@emit'](event.plugin, event.name, event.payload);" +
  "    });" +
  "    root['@@bridgeListenerInstalled'] = true;" +
  "    return true;" +
  "  };" +
  "  root['@@defineApi'] = function(pluginName, apiName, commandName) {" +
  "    const plugin = root['@@ensurePlugin'](pluginName);" +
  "    root['@@ensureBridgeListener']();" +
  "    plugin[apiName] = function(payload) {" +
  "      const bridge = getBridge();" +
  "      if (!bridge) {" +
  "        return Promise.reject(new Error('MoonBit command bridge is not available'));" +
  "      }" +
  "      return bridge.send(commandName, payload);" +
  "    };" +
  "    return plugin[apiName];" +
  "  };" +
  "  root['@@has'] = function(pluginName, apiName) {" +
  "    const plugin = root[pluginName];" +
  "    return !!(plugin && typeof plugin[apiName] === 'function');" +
  "  };" +
  "  root['@@ensureBridgeListener']();" +
  "  window[globalName] = root;" +
  "})();"
}

///|
fn make_plugin_namespace_script(
  global_name : String,
  plugin_name : String,
) -> String {
  let global_name_js = Json::string(global_name).stringify()
  let plugin_name_js = Json::string(plugin_name).stringify()
  "(function() {" +
  "  const globalName = " +
  global_name_js +
  ";" +
  "  const pluginName = " +
  plugin_name_js +
  ";" +
  "  const root = window[globalName] && typeof window[globalName] === 'object'" +
  "    ? window[globalName]" +
  "    : (window[globalName] = Object.create(null));" +
  "  if (typeof root['@@ensurePlugin'] === 'function') {" +
  "    root['@@ensurePlugin'](pluginName);" +
  "    return;" +
  "  }" +
  "  if (!root[pluginName] || typeof root[pluginName] !== 'object') {" +
  "    root[pluginName] = Object.create(null);" +
  "  }" +
  "})();"
}

///|
fn make_plugin_api_script(
  global_name : String,
  bridge_global_name : String,
  plugin_name : String,
  api_name : String,
  command_name : String,
) -> String {
  let global_name_js = Json::string(global_name).stringify()
  let bridge_global_name_js = Json::string(bridge_global_name).stringify()
  let plugin_name_js = Json::string(plugin_name).stringify()
  let api_name_js = Json::string(api_name).stringify()
  let command_name_js = Json::string(command_name).stringify()
  "(function() {" +
  "  const globalName = " +
  global_name_js +
  ";" +
  "  const bridgeName = " +
  bridge_global_name_js +
  ";" +
  "  const pluginName = " +
  plugin_name_js +
  ";" +
  "  const apiName = " +
  api_name_js +
  ";" +
  "  const commandName = " +
  command_name_js +
  ";" +
  "  const root = window[globalName] && typeof window[globalName] === 'object'" +
  "    ? window[globalName]" +
  "    : (window[globalName] = Object.create(null));" +
  "  if (typeof root['@@defineApi'] === 'function') {" +
  "    root['@@defineApi'](pluginName, apiName, commandName);" +
  "    return;" +
  "  }" +
  "  const plugin = root[pluginName] && typeof root[pluginName] === 'object'" +
  "    ? root[pluginName]" +
  "    : (root[pluginName] = Object.create(null));" +
  "  plugin[apiName] = function(payload) {" +
  "    const bridge = window[bridgeName];" +
  "    if (!bridge || typeof bridge.send !== 'function') {" +
  "      return Promise.reject(new Error('MoonBit command bridge is not available'));" +
  "    }" +
  "    return bridge.send(commandName, payload);" +
  "  };" +
  "})();"
}
