import quickjs


proc hello_greating(ctx: JSContext, this_val: JSValue, argc: cint, argv: ptr UncheckedArray[JSValue]): JSValue {.cdecl.} =
  let name = JS_ToCString(ctx, argv[0])
  echo "Hello world, greating from ", name

let js_hello_funcs = [
  JS_CFUNC_DEF("greating", 1, hello_greating)
]

let e = newEngine()
e.registerObject("hello", js_hello_funcs)
let ret = e.evalString("hello.greating('Nim')")
quit(ret)
