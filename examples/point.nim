import quickjs, math

type
  JSPointData = object
    x: int32
    y: int32

var js_point_class_id: JSClassID

template fail() =
  js_free(ctx, s);
  JS_FreeValue(ctx, result);
  return JS_EXCEPTION;

proc js_point_ctor(ctx: JSContext, new_target: JSValueConst, argc: int32, argv: ptr UncheckedArray[JSValueConst]): JSValue {.cdecl.} =
  var
    s: ptr JSPointData
    proto: JSValue

  result = JS_UNDEFINED

  s = cast[ptr JSPointData](js_mallocz(ctx, sizeof(s[]).csize_t))
  if s == nil:
    return JS_EXCEPTION;
  if JS_ToInt32(ctx, addr s.x, argv[0]) != 0:
    fail()

  if JS_ToInt32(ctx, addr s.y, argv[1]) != 0:
    fail()

  proto = JS_GetPropertyStr(ctx, new_target, "prototype")
  if JS_IsException(proto):
    fail()
  result = JS_NewObjectProtoClass(ctx, proto, js_point_class_id)
  JS_FreeValue(ctx, proto)
  if JS_IsException(result):
    fail()
  JS_SetOpaque(result, s)

proc js_point_get_xy(ctx: JSContext, this: JSValueConst, magic: int32): JSValue {.cdecl.} =
  let s = cast[ptr JSPointData](JS_GetOpaque2(ctx, this, js_point_class_id))
  if s == nil:
    return JS_EXCEPTION
  if magic == 0:
    return JS_NewInt32(ctx, s.x)
  else:
    return JS_NewInt32(ctx, s.y)

proc js_point_set_xy(ctx: JSContext, this: JSValueConst, val: JSValue, magic: int32): JSValue {.cdecl.} =
  var s = cast[ptr JSPointData](JS_GetOpaque2(ctx, this, js_point_class_id))
  var v: int32
  if s == nil:
    return JS_EXCEPTION
  if JS_ToInt32(ctx, addr v, val) != 0:
    return JS_EXCEPTION
  if magic == 0:
    s.x = v
  else:
    s.y = v
  return JS_UNDEFINED

proc js_point_norm(ctx: JSContext, this: JSValueConst, argc: int32, argv: ptr UncheckedArray[JSValueConst]): JSValue {.cdecl.} =
  let s = cast[ptr JSPointData](JS_GetOpaque2(ctx, this, js_point_class_id))
  if s == nil:
    return JS_EXCEPTION
  return JS_NewFloat64(ctx, sqrt(s.x.float64 * s.x.float64 + s.y.float64 * s.y.float64))

var js_point_proto_funcs = [
  JS_CGETSET_MAGIC_DEF("x", js_point_get_xy, js_point_set_xy, 0),
  JS_CGETSET_MAGIC_DEF("y", js_point_get_xy, js_point_set_xy, 1),
  JS_CFUNC_DEF("norm", 0, js_point_norm),
]

proc js_point_finalizer(rt: JSRuntime, val: JSValue) {.cdecl.} =
  let s = cast[ptr JSPointData](JS_GetOpaque(val, js_point_class_id))
  if s != nil:
    js_free_rt(rt, s)

let js_point_class = JSClassDef(
  class_name: "Point",
  finalizer: js_point_finalizer
)

proc point_class_init(ctx: JSContext): JSValue =
  var point_proto = JS_NewObject(ctx)
  discard JS_NewClassID(addr js_point_class_id)
  discard JS_NewClass(JS_GetRuntime(ctx), js_point_class_id, js_point_class)
  JS_SetPropertyFunctionList(ctx, point_proto, addr js_point_proto_funcs[0], js_point_proto_funcs.len.int32);
  result = JS_NewCFunction2(ctx, js_point_ctor, "Point", 2, JS_CFUNC_constructor, 0)
  JS_SetConstructor(ctx, result, point_proto)
  JS_SetClassProto(ctx, js_point_class_id, point_proto)

proc js_point_init(ctx: JSContext, m: JSModuleDef): int32 {.cdecl.} =
  var point_class = point_class_init(ctx)
  discard JS_SetModuleExport(ctx, m, "Point", point_class)

proc js_init_module(ctx: JSContext, moduleName: cstring): JSModuleDef {.exportc, dynlib.} =
  result = JS_NewCModule(ctx, moduleName, js_point_init)
  if result != nil:
    discard JS_AddModuleExport(ctx, result, "Point")
