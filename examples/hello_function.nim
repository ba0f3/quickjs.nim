import quickjs


proc hello(ctx: ptr JSContext, this_val: JSValue, argc: cint, argv: ptr JSValue): JSValue {.cdecl.} =
  echo "Hello world, greating from Nim!"


let e = newEngine()
e.registerFunction("hello", 0, hello)

let ret = e.evalString("hello()")
quit(ret)