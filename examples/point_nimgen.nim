import quickjs, math

type
  Point = object
    x: int32
    y: int32

var
  js_point_class_id: JSClassID
  point_class: JSValue

proc js_point_norm(ctx: JSContext, this: JSValueConst, argc: int32, argv: ptr UncheckedArray[JSValueConst]): JSValue {.cdecl.} =
  let s = cast[ptr Point](JS_GetOpaque2(ctx, this, js_point_class_id))
  if s == nil:
    return JS_EXCEPTION
  return JS_NewFloat64(ctx, sqrt(s.x.float64 * s.x.float64 + s.y.float64 * s.y.float64))

var js_point_funcs = [
  JS_CFUNC_DEF("norm", 0, js_point_norm),
]

let e = newEngine()
(point_class, js_point_class_id) = e.createClass(Point, js_point_funcs)
e.registerValue("Point", point_class)
let ret = e.evalString("""
function assert(b, str) {
  if (b) {
      return;
  } else {
      throw Error("assertion failed: " + str);
  }
}
var pt = new Point(2, 3);
assert(pt.x === 2);
assert(pt.y === 3);
pt.x = 4;
assert(pt.x === 4);
assert(pt.norm() == 5);
""")
quit(ret)
