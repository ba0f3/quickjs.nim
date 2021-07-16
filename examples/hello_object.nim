import quickjs


proc hello_greating(ctx: ptr JSContext, this_val: JSValue, argc: cint, argv: ptr JSValue): JSValue {.cdecl.} =
  echo "greating from Nim"

let js_hello_funcs = [
  JS_CFUNC_DEF("greating", 0, hello_greating)
]

let e = newEngine()
e.registerObject("hello", js_hello_funcs)
let ret = e.evalString("hello.greating()")
quit(ret)
