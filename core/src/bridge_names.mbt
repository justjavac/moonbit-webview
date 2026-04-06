///|
let moonbit_global_name_value = "__MoonBit__"

///|
let moonbit_op_binding_name_value = "__moonbit_op_dispatch"

///|
/// Returns the root JavaScript namespace used by Lepus runtime helpers.
/// JavaScript bridges and generated helper scripts should agree on this value
/// when exposing Lepus functionality on `window`.
pub fn moonbit_global_name() -> String {
  moonbit_global_name_value
}

///|
/// Returns the native/webview binding name used by the op bridge.
/// Native dispatch glue and injected runtime scripts both use this name to
/// route op calls through the same binding.
pub fn moonbit_op_binding_name() -> String {
  moonbit_op_binding_name_value
}
