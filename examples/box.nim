import quickjs

type
  Box = object
    name: string
    width: int
    height: int
    x: float
    y: float
    hasItem: bool
    contains: array[3, int]

var box = Box(
  name: "Magic box",
  width: 4,
  height: 3,
  x: 10.5,
  y: 3.1,
  hasItem: true,
  contains: [1, 2, 3]
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

let e = newEngine()

let jsBox = e.createValue(box)
e.registerFunctionList(jsBox, js_box_funcs)

e.registerValue("box", jsBox)
let ret = e.evalString("""
console.log("box", JSON.stringify(box));
console.log("width", box.width, "height", box.height);
console.log("box area is: ", box.area());
""")
quit(ret)
