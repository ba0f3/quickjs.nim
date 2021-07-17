import os, quickjs/[core, helpers, libc]
export core, helpers, libc

type
  Engine*  = object
    ctx*: JSContext
    rt*: JSRuntime

proc `=destroy`*(e: var Engine) =
  JS_FreeContext(e.ctx)
  JS_FreeRuntime(e.rt)


proc initCustomContext(rt: JSRuntime): JSContext {.cdecl.} =
  result = JS_NewContextRaw(rt)
  if result != nil:
    JS_AddIntrinsicEval(result)
    JS_AddIntrinsicBaseObjects(result)
    JS_AddIntrinsicDate(result)
    JS_AddIntrinsicJSON(result)

    js_std_add_helpers(result, 0, nil)
    discard js_init_module_std(result, "std")
    discard js_init_module_os(result, "os")

    JS_SetModuleLoaderFunc(rt, nil, js_module_loader, nil)
  else:
    raise newException(IOError, "failed to create new context")


proc newEngine*(): Engine =
  ## Create new Javascript Engine
  result.rt = JS_NewRuntime()
  js_std_set_worker_new_context_func(initCustomContext)
  js_std_init_handlers(result.rt)
  result.ctx = initCustomContext(result.rt)

proc evalString*(e: Engine, input: string, filename="<input>", flags: int32 = JS_EVAL_TYPE_MODULE): int  {.discardable.} =
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

  if JS_IsException(val):
    js_std_dump_error(e.ctx)
    result = -1
  else:
    result = 0
  js_std_loop(e.ctx)
  Js_FreeValue(e.ctx, val)

proc evalFile*(e: Engine, filename: string, flags: int32 = JS_EVAL_TYPE_MODULE): int {.discardable.} =
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
  let global_obj = JS_GetGlobalObject(e.ctx);
  discard JS_SetPropertyStr(e.ctx, global_obj, objectName, result)
  JS_FreeValue(e.ctx, global_obj)

proc createValue*[T](e: Engine, value: T, flags: int32 = JS_PROP_C_W_E): JSValue {.discardable.} =
  ## Create Javascript value from Nim types
  when T is object:
    result = JS_NewObject(e.ctx)
    for k, v in value.fieldPairs():
      let val = e.createValue(v)
      discard JS_DefinePropertyValueStr(e.ctx, result, k, val, flags)
  elif T is array or T is seq:
    result = JS_NewArray(e.ctx)
    for i in 0..<value.len:
      let val = e.createValue(value[i])
      discard JS_DefinePropertyValueUint32(e.ctx, result, i.uint32, val, flags)
  elif T is SomeSignedInt:
    if sizeof(value) == sizeof(int64):
      result = JS_NewInt64(e.ctx, value)
    else:
      result = JS_NewInt32(e.ctx, value.int32)
  elif T is SomeUnsignedInt:
    if sizeof(value) == sizeof(uint64):
      result = JS_NewUInt64(e.ctx, value)
    else:
      result = JS_NewUInt32(e.ctx, value.uint32)
  elif T is SomeFloat:
    result = JS_NewFloat64(e.ctx, value)
  elif T is bool:
    result = JS_NewBool(e.ctx, value.int32)
  elif T is string or T is cstring:
    result = JS_NewString(e.ctx, value.cstring)
  else:
    {.error: "createValue error: type not supported".}

proc registerValue*(e: Engine, parent: JSValue, name: string, val: JSValue, flags: int32 = JS_PROP_C_W_E): int {.discardable.} =
  ## Register a Javascript value as child of `parent`
  result = JS_DefinePropertyValueStr(e.ctx, parent, name, val, flags).int

proc registerValue*(e: Engine, name: string, val: JSValue, flags: int32 = JS_PROP_C_W_E): int {.discardable.} =
  ## Register a global Javascript value
  let global_obj = JS_GetGlobalObject(e.ctx)
  result = e.registerValue(global_obj, name, val, flags)
  JS_FreeValue(e.ctx, global_obj)

proc registerFunction*(e: Engine, parent: JSValue, name: string, paramCount: int, fn: JSCFunction) =
  ## Register a Nim fuction with `name` so Javascript can calls it
  let fn = JS_NewCFunction(e.ctx, fn, name, paramCount.int32)
  discard JS_SetPropertyStr(e.ctx, parent, name, fn)

proc registerFunction*(e: Engine, name: string, paramCount: int, fn: JSCFunction) =
  ## Register a Nim fuction with `name` as global function
  let global_obj = JS_GetGlobalObject(e.ctx)
  e.registerFunction(global_obj, name, paramCount, fn)
  JS_FreeValue(e.ctx, global_obj)

