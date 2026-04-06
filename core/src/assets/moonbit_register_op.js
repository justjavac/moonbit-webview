(function() {
  const moonbit = window[__MOONBIT_NAME_JS__];
  const opName = __OP_NAME_JS__;
  if (moonbit && moonbit.core && typeof moonbit.core.registerOp === 'function') {
    moonbit.core.registerOp(opName);
  }
})();
