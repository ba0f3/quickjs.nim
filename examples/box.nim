import quickjs

type
  Box = object
    name: string
    width: int
    height: int
    x: float
    y: float
    hasItem: bool
    contains: seq[int]

var box = Box(
  name: "Magic box",
  width: 4,
  height: 3,
  x: 10.5,
  y: 3.1,
  hasItem: true,
  contains: @[1, 2, 3]
)

proc box_area(ctx: JSContext, this: JSValue, argc: cint, argv: ptr UncheckedArray[JSValue]): JSValue {.cdecl.} =
  assert this.tag == JS_TAG_OBJECT
  var width, height: int64
  discard JS_ToInt64(ctx, addr width, JS_GetPropertyStr(ctx, this, "width"))
  discard JS_ToInt64(ctx, addr height, JS_GetPropertyStr(ctx, this, "height"))
  result = JS_NewInt64(ctx, width * height)


let js_box_funcs = [
  JS_CFUNC_DEF("area", 0, box_area)
]

var e = newEngine()
let (box_class, _) = e.createClass(Box, js_box_funcs)
e.registerValue("Box", box_class)
e.registerValue("box", box)
let ret = e.evalFile("box.js")
quit(ret)
