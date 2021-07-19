import os, tables, quickjs/[core, helpers, libc]
export core, helpers

type
  Engine*  = object
    rt*: JSRuntime
    ctx: JSContext
    retval*: JSValue

proc `=destroy`*(e: var Engine) =
  JS_FreeValue(e.ctx, e.retval)
  JS_FreeContext(e.ctx)
  JS_FreeRuntime(e.rt)

var tblClassIds = initTable[string, JSClassID]()
var js_nim_object_class_id: JSClassID


proc initCustomContext(rt: JSRuntime): JSContext =
  result = JS_NewContext(rt)
  if result != nil:
    js_std_add_helpers(result, 0, nil)
    discard js_init_module_std(result, "std")
    discard js_init_module_os(result, "os")

    js_std_init_handlers(rt)
    JS_SetModuleLoaderFunc(rt, nil, js_module_loader, nil)

  else:
    raise newException(IOError, "failed to create new context")

proc newEngine*(): Engine =
  ## Create new Javascript Engine
  result.rt = JS_NewRuntime()
  js_std_set_worker_new_context_func(initCustomContext)
  result.ctx = initCustomContext(result.rt)

proc evalString*(e: var Engine, input: string, filename="<input>", flags: int32 = JS_EVAL_TYPE_GLOBAL): int  {.discardable.} =
  ## Evaluates Javascript code represented as a string
  let inputLen = input.len.csize_t
  var val: JSValue

  if (flags and JS_EVAL_TYPE_MASK) == JS_EVAL_TYPE_MODULE:
    val = JS_Eval(e.ctx, input, inputLen, filename, flags or JS_EVAL_FLAG_COMPILE_ONLY)
    if not JS_IsException(val):
      discard js_module_set_import_meta(e.ctx, val, true, true)
      val = JS_EvalFunction(e.ctx, val)
  else:
    val = JS_Eval(e.ctx, input, inputLen, filename, flags)

  e.retval = JS_DupValue(e.ctx, val)

  if JS_IsException(val):
    js_std_dump_error(e.ctx)
    result = -1
  else:
    result = 0
  js_std_loop(e.ctx)
  Js_FreeValue(e.ctx, val)

proc evalFile*(e: var Engine, filename: string, flags: int32 = JS_EVAL_TYPE_MODULE): int {.discardable.} =
  ## Reads `filename` and then evaluates Javascript code represented as a string
  if not filename.fileExists:
    raise newException(IOError, "file not found: " & filename)
  let input = readFile(filename)
  result = e.evalString(input, filename, flags)

proc registerFunctionList*(e: Engine, val: JSValue, functions: openArray[JSCFunctionListEntry]) =
  ## Register function list for a Javascript value
  JS_SetPropertyFunctionList(e.ctx, val, unsafeAddr functions[0], functions.len.int32)

proc registerObject*(e: Engine, objectName: string, functions: openArray[JSCFunctionListEntry]): JSValue {.discardable.} =
  ## Register global object with function list
  result = JS_NewObject(e.ctx)
  e.registerFunctionList(result, functions)
  let global_obj = JS_GetGlobalObject(e.ctx)
  discard JS_SetPropertyStr(e.ctx, global_obj, objectName, result)
  JS_FreeValue(e.ctx, global_obj)

proc makeValue[T](ctx: JSContext, value: T, flags: int32 = JS_PROP_C_W_E): JSValue {.discardable.} =
  ## Create Javascript value from Nim types
  when T is object:
    if tblClassIds.hasKey($T):
      result = JS_NewObjectClass(ctx, tblClassIds[$T])
      JS_SetOpaque(result, unsafeAddr value)
    else:
      result = JS_NewObject(ctx)
      for k, v in value.fieldPairs():
        let val = makeValue(ctx, v)
        discard JS_DefinePropertyValueStr(ctx, result, k, val, flags)
  elif T is seq: # T is array or
    result = JS_NewArray(ctx)
    for i in 0..<value.len:
      let val = makeValue(ctx, value[i])
      discard JS_DefinePropertyValueUint32(ctx, result, i.uint32, val, flags)
  elif T is SomeSignedInt:
    if sizeof(value) == sizeof(int64):
      result = JS_NewInt64(ctx, value)
    else:
      result = JS_NewInt32(ctx, value.int32)
  elif T is SomeUnsignedInt:
    if sizeof(value) == sizeof(uint64):
      result = JS_NewUInt64(ctx, value)
    else:
      result = JS_NewUInt32(ctx, value.uint32)
  elif T is SomeFloat:
    result = JS_NewFloat64(ctx, value)
  elif T is bool:
    result = JS_NewBool(ctx, value.int32)
  elif T is string or T is cstring:
    result = JS_NewString(ctx, value.cstring)
  else:
    JS_ThrowTypeError(ctx, $T & " not supported")

proc getValue[T](ctx: JSContext, val: JSValue, v: ptr T): bool =
  when T is object:
    if tblClassIds.hasKey($T):
      v = cast[ptr T](JS_GetOpaque(val, tblClassIds[$T]))
  elif T is seq: # T is array or
    v[] = @[]
    var tmp = JS_GetPropertyStr(ctx, val, "length")
    if JS_IsException(tmp):
        return false
    var length: uint32
    discard JS_ToUint32(ctx, addr length, tmp)
    for i in 0..<length:
      tmp = JS_GetPropertyUint32(ctx, val, i)
      var v1: v[0].type
      discard getValue(ctx, tmp, addr v1)
      v[].add v1
    return true
  elif T is SomeSignedInt:
    when sizeof(T) == sizeof(int64):
      return JS_ToInt64(ctx, cast[ptr int64](v), val) == 0
    else:
      return JS_ToInt32(ctx, v, val) == 0
  elif T is SomeUnsignedInt:
    when sizeof(T) == sizeof(int64):
      return JS_ToUInt64(ctx, v, val) == 0
    else:
      return JS_ToUInt32(ctx, v, val) == 0
  elif T is SomeFloat:
    return JS_ToFloat64(ctx, v, val) == 0
  elif T is bool:
    v[] = JS_ToBool(ctx, val) != 0
    return true
  elif T is string:
    v[] = $JS_ToCString(ctx, val)
    return true
  elif T is cstring:
    return JS_ToCString(ctx, v, val) == 0
  else:
    JS_ThrowTypeError(ctx, $T & " not supported")

proc registerValue*(e: Engine, parent: JSValue, name: string, val: JSValue, flags: int32 = JS_PROP_C_W_E): int {.discardable.} =
  ## Register a Javascript value as child of `parent`
  result = JS_DefinePropertyValueStr(e.ctx, parent, name, val, flags).int

proc registerValue*(e: Engine, name: string, val: JSValue, flags: int32 = JS_PROP_C_W_E): int {.discardable.} =
  ## Register a global Javascript value
  let global_obj = JS_GetGlobalObject(e.ctx)
  result = e.registerValue(global_obj, name, val, flags)
  JS_FreeValue(e.ctx, global_obj)

proc registerValue*(e: Engine, name: string, val: auto, flags: int32 = JS_PROP_C_W_E): int {.discardable.} =
  ## Register a Nim variable as global Javascript value
  let jsVal = makeValue(e.ctx, val)
  result = e.registerValue(name, jsVal, flags)

proc registerFunction*(e: Engine, parent: JSValue, name: string, paramCount: int, fn: JSCFunction) =
  ## Register a Nim fuction with `name` so Javascript can calls it
  let fn = JS_NewCFunction(e.ctx, fn, name, paramCount.int32)
  discard JS_SetPropertyStr(e.ctx, parent, name, fn)

proc registerFunction*(e: Engine, name: string, paramCount: int, fn: JSCFunction) =
  ## Register a Nim fuction with `name` as global function
  let global_obj = JS_GetGlobalObject(e.ctx)
  e.registerFunction(global_obj, name, paramCount, fn)
  JS_FreeValue(e.ctx, global_obj)

#[ Class ]#
template fail() =
  js_free(ctx, s)
  JS_FreeValue(ctx, result)
  return JS_EXCEPTION

proc createClass*(e: Engine, classDef: JSClassDef, classId: var JSClassID, ctor: JSCFunction, functions: openArray[JSCFunctionListEntry] = []): JSValue =
  ## Create new Javascript class
  var proto = JS_NewObject(e.ctx)
  discard JS_NewClassID(addr classId)
  discard JS_NewClass(e.rt, classId, classDef)
  result = JS_NewCFunction2(e.ctx, ctor, classDef.class_name, 2, JS_CFUNC_constructor, 0)
  JS_SetConstructor(e.ctx, result, proto)
  JS_SetClassProto(e.ctx, classId, proto)
  if functions.len > 0:
    JS_SetPropertyFunctionList(e.ctx, proto, unsafeAddr functions[0], functions.len.int32)

proc createClass*(e: Engine, T: typedesc, functions: openArray[JSCFunctionListEntry] = []): (JSValue, JSClassID) {.cdecl.} =
  ## Create new Javascript class from Nim object
  proc js_default_finalizer(rt: JSRuntime, val: JSValue) {.cdecl.} =
    let s = JS_GetOpaque(val, tblClassIds[$T])
    if s != nil:
      js_free_rt(rt, s)

  proc js_default_ctor(ctx: JSContext, new_target: JSValueConst, argc: int32, argv: ptr UncheckedArray[JSValueConst]): JSValue {.cdecl.} =
    result = JS_UNDEFINED
    var s = cast[ptr T](js_mallocz(ctx, sizeof(T).csize_t))
    if s == nil:
      return JS_EXCEPTION

    var i = 0
    for k, v in s[].fieldPairs():
      if not getValue(ctx, argv[i], addr v):
        fail()
      inc(i)

    let proto = JS_GetPropertyStr(ctx, new_target, "prototype")
    if JS_IsException(proto):
      fail()
    result = JS_NewObjectProtoClass(ctx, proto, tblClassIds[$T])
    JS_FreeValue(ctx, proto)
    if JS_IsException(result):
      fail()
    JS_SetOpaque(result, s)

  proc js_default_getter(ctx: JSContext, this: JSValueConst, magic: int32): JSValue {.cdecl.} =
    let s = cast[ptr T](JS_GetOpaque2(ctx, this, tblClassIds[$T]))
    if s == nil:
      return JS_EXCEPTION

    var i = 0
    for k, v in s[].fieldPairs():
      if i == magic:
        return makeValue(ctx, v)
      inc(i)

  proc js_default_setter(ctx: JSContext, this: JSValueConst, val: JSValue, magic: int32): JSValue {.cdecl.} =
    result = JS_UNDEFINED
    let s = cast[ptr T](JS_GetOpaque2(ctx, this, tblClassIds[$T]))
    if s == nil:
      return JS_EXCEPTION
    var i = 0
    for k, v in s[].fieldPairs():
      if i == magic:
        if not getValue(ctx, val, addr v):
          return JS_EXCEPTION
        break
      inc(i)

  if tblClassIds.hasKey($T):
    return

  let classDef = JSClassDef(
    class_name: $T,
    finalizer: js_default_finalizer
  )

  var
    js_proto_functions: seq[JSCFunctionListEntry]
    i = 0'i16
    t: T

  for k, v in t.fieldPairs():
    js_proto_functions.add(JS_CGETSET_MAGIC_DEF(k, js_default_getter, js_default_setter, i))
    inc(i)

  for i in 0..<functions.len:
    js_proto_functions.add(functions[i])

  var classId: JSClassID
  result = (e.createClass(classDef, classId, js_default_ctor, js_proto_functions), classId)
  tblClassIds[$T] = classId