import private/build_config, core

proc js_init_module_std*(ctx: JSContext,
    module_name: cstring): JSModuleDef {.importc: "js_init_module_std",
    header: headerquickjs.}
proc js_init_module_os*(ctx: JSContext,
    module_name: cstring): JSModuleDef {.importc: "js_init_module_os",
    header: headerquickjs.}
proc js_std_add_helpers*(ctx: JSContext, argc: int32, argv: ptr cstring) {.
    importc: "js_std_add_helpers", header: headerquickjs.}
proc js_std_loop*(ctx: JSContext) {.importc: "js_std_loop",
    header: headerquickjs.}
proc js_std_init_handlers*(tr: JSRunTime) {.importc: "js_std_init_handlers",
    header: headerquickjs.}
proc js_std_free_handlers*(rt: JSRuntime) {.importc: "js_std_free_handlers",
    header: headerquickjs.}
proc js_std_dump_error*(ctx: JSContext) {.importc: "js_std_dump_error",
    header: headerquickjs.}
proc js_load_file*(ctx: JSContext, pbuf_len: ptr uint32,
    filename: cstring): ptr uint8 {.importc: "js_load_file",
    header: headerquickjs.}
proc js_module_set_import_meta*(ctx: JSContext, func_val: JSValueConst,
    use_realpath: bool, is_main: bool): int {.importc: "js_module_set_import_meta",
    header: headerquickjs.}
proc js_module_loader*(ctx: JSContext, module_name: cstring,
    opaque: pointer): JSModuleDef {.importc, cdecl.}
proc js_std_eval_binary*(ctx: JSContext, buf: ptr uint8, buf_len: uint32,
    flags: int32) {.importc: "js_std_eval_binary", header: headerquickjs.}
proc js_std_promise_rejection_tracker*(ctx: JSContext, promise: JSValueConst,
    reason: JSValueConst, is_handled: bool, opaque: pointer) {.importc: "js_std_promise_rejection_tracker",
    header: headerquickjs.}
proc js_std_set_worker_new_context_func*(fn: proc(rt: JSRuntime): JSContext {.cdecl.}) {.importc: "js_std_set_worker_new_context_func",
    header: headerquickjs.}