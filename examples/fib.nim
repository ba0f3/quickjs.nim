import quickjs

proc fib(n: int32): int32 =
  if n <= 0:
    result = 0
  elif n == 1:
    result = 1
  else:
    result = fib(n - 1) + fib(n - 2);



proc js_fib(ctx: JSContext, this_val: JSValue, argc: cint, argv: ptr UncheckedArray[JSValue]): JSValue {.cdecl.} =
  var n: int32

  if JS_ToInt32(ctx, addr n, argv[0]) != 0:
    return JS_EXCEPTION
  result = JS_NewInt32(ctx, fib(n))

let js_fib_funcs = [
  JS_CFUNC_DEF("fib", 1, js_fib)
]

proc js_fib_init(ctx: JSContext, m: JSModuleDef): cint {.cdecl.} =
  JS_SetModuleExportList(ctx, m, unsafeAddr js_fib_funcs[0], js_fib_funcs.len.cint)


proc js_init_module*(ctx: JSContext, moduleName: cstring): JSModuleDef {.exportc, dynlib.} =
  result = JS_NewCModule(ctx, module_name, js_fib_init);
  if result != nil:
    discard JS_AddModuleExportList(ctx, result, unsafeAddr js_fib_funcs[0], js_fib_funcs.len.cint);

