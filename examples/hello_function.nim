import quickjs


proc hello(ctx: JSContext, this_val: JSValue, argc: cint, argv: ptr UncheckedArray[JSValue]): JSValue {.cdecl.} =
  echo "Hello world, greating from Nim!"


var e = newEngine()
e.registerFunction("hello", 0, hello)

let ret = e.evalString("hello()")
quit(ret)