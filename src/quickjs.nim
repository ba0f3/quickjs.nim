import os, quickjs/[core, libc]
export core, libc

type
  Engine*  = object
    ctx: ptr JSContext
    rt: ptr JSRuntime

proc `=destroy`*(e: var Engine) =
  JS_FreeContext(e.ctx)
  JS_FreeRuntime(e.rt)

proc newCustomContext(rt: ptr JSRuntime): ptr JSContext {.cdecl.} =
  result = JS_NewContextRaw(rt)
  if result != nil:
    JS_AddIntrinsicEval(result)
    JS_AddIntrinsicBaseObjects(result)
    js_std_add_helpers(result, 0, nil)
  else:
    raise newException(IOError, "failed to create new context")


proc newEngine*(): Engine =
  result.rt = JS_NewRuntime()
  js_std_set_worker_new_context_func(newCustomContext)
  js_std_init_handlers(result.rt)
  result.ctx = newCustomContext(result.rt)


proc evalString*(e: Engine, input: string, filename="<input>", flags = JS_EVAL_TYPE_GLOBAL): int  {.discardable.} =
  let inputLen = input.len.csize_t
  var val: JSValue

  if (flags and JS_EVAL_TYPE_MASK) == JS_EVAL_TYPE_MODULE:
    val = JS_Eval(e.ctx, input.cstring, inputLen, filename.cstring, (flags or JS_EVAL_FLAG_COMPILE_ONLY).cint)
    if JS_IsException(val) == 0:
      discard js_module_set_import_meta(e.ctx, val, TRUE, TRUE)
      val = JS_EvalFunction(e.ctx, val)
  else:
    val = JS_Eval(e.ctx, input.cstring, inputLen, filename.cstring, flags.cint)

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