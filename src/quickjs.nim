import os, quickjs/[core, libc]
export core, libc

type
  Engine*  = object
    ctx: ptr JSContext
    rt: ptr JSRuntime

proc `=destroy`*(e: var Engine) =
  JS_FreeContext(e.ctx)
  JS_FreeRuntime(e.rt)

proc JS_CFUNC_DEF*(name: string, paramCount: uint8, fn1: JSCFunction): JSCFunctionListEntry =
  result = JSCFunctionListEntry(
    name: name,
    prop_flags:  JS_PROP_WRITABLE or JS_PROP_CONFIGURABLE,
    def_type: JS_DEF_CFUNC,
    magic: 0,
    u: JSCDeclareUnion(
      `func`: JSCDeclareFuntion(
        length: paramCount,
        cproto: JS_CFUNC_generic,
        cfunc: JSCFunctionType(
          generic: fn1
        )
      )
    )
  )

proc initCustomContext(rt: ptr JSRuntime): ptr JSContext {.cdecl.} =
  result = JS_NewContextRaw(rt)
  if result != nil:
    JS_AddIntrinsicEval(result)
    JS_AddIntrinsicBaseObjects(result)
    js_std_add_helpers(result, 0, nil)
  else:
    raise newException(IOError, "failed to create new context")


proc initModule(ctx: ptr JSContext, moduleName: string, fn: JSModuleInitFunc): ptr JSModuleDef =
  result = JS_NewCModule(ctx, moduleName, fn)
  if result != nil:
    discard JS_AddModuleExport(ctx, result, moduleName)

proc newEngine*(): Engine =
  result.rt = JS_NewRuntime()
  js_std_set_worker_new_context_func(initCustomContext)
  js_std_init_handlers(result.rt)
  result.ctx = initCustomContext(result.rt)


proc evalString*(e: Engine, input: string, filename="<input>", flags = JS_EVAL_TYPE_GLOBAL): int  {.discardable.} =
  let inputLen = input.len.csize_t
  var val: JSValue

  if (flags and JS_EVAL_TYPE_MASK) == JS_EVAL_TYPE_MODULE:
    val = JS_Eval(e.ctx, input, inputLen, filename, (flags or JS_EVAL_FLAG_COMPILE_ONLY).cint)
    if JS_IsException(val) == 0:
      discard js_module_set_import_meta(e.ctx, val, TRUE, TRUE)
      val = JS_EvalFunction(e.ctx, val)
  else:
    val = JS_Eval(e.ctx, input, inputLen, filename, flags.cint)

  if JS_IsException(val) != 0:
    js_std_dump_error(e.ctx)
    result = -1
  else:
    result = 0
  js_std_loop(e.ctx)
  Js_FreeValue(e.ctx, val)

proc evalFile*(e: Engine, filename: string, flags = JS_EVAL_TYPE_GLOBAL): int {.discardable.} =
  if not filename.fileExists:
    raise newException(IOError, "file not found: " & filename)
  let input = readFile(filename)
  result = e.evalString(input, filename, flags)

proc registerModule*(e: Engine, moduleName: string, init: JSModuleInitFunc, functions: openArray[JSCFunctionListEntry]) =
  let m = initModule(e.ctx,  moduleName, init)
  discard JS_AddModuleExportList(e.ctx, m, unsafeAddr functions[0], functions.len.cint)


proc registerFunction*(e: Engine, name: string, paramCount: int, fn: JSCFunction) =
  var global_obj = JS_GetGlobalObject(e.ctx)
  discard JS_SetPropertyStr(e.ctx, global_obj, name, JS_NewCFunction(e.ctx, fn, name, paramCount.cint))
  JS_FreeValue(e.ctx, global_obj)