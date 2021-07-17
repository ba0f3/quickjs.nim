import core

proc JS_CFUNC_DEF*(name: string, length: uint8, fn1: JSCFunction): JSCFunctionListEntry {.inline.} =
  result = JSCFunctionListEntry(
    name: name,
    prop_flags: JS_PROP_WRITABLE or JS_PROP_CONFIGURABLE,
    def_type: JS_DEF_CFUNC,
    u: JSCDeclareUnion(
      fn: JSCDeclareFuntion(
        length: length,
        cproto: JS_CFUNC_generic,
        cfunc: JSCFunctionType(generic: fn1)
  )))

proc JS_CFUNC_MAGIC_DEF*(name: string, length: uint8, fn1:  proc (ctx: ptr JSContext; this_val: JSValue; argc: cint; argv: ptr UncheckedArray[JSValue]; magic: cint): JSValue {.cdecl.}, magic: int16): JSCFunctionListEntry {.inline.} =
  result = JSCFunctionListEntry(
    name: name,
    prop_flags: JS_PROP_WRITABLE or JS_PROP_CONFIGURABLE,
    def_type: JS_DEF_CFUNC,
    magic: magic,
    u: JSCDeclareUnion(
      fn: JSCDeclareFuntion(
        length: length,
        cproto: JS_CFUNC_generic_magic,
        cfunc: JSCFunctionType(generic_magic: fn1)
    )))

#proc JS_CFUNC_SPECIAL_DEF*(name: string, length: uint8, cproto, func1) { name, JS_PROP_WRITABLE | JS_PROP_CONFIGURABLE, JS_DEF_CFUNC, 0, .u = { .func = { length, JS_CFUNC_ ## cproto, { .cproto = func1 } } } }

proc JS_ITERATOR_NEXT_DEF*(name: string, length: uint8, fn1: proc (ctx: ptr JSContext; this_val: JSValue; argc: cint; argv: ptr UncheckedArray[JSValue]; pdone: ptr cint; magic: cint): JSValue {.cdecl.}, magic: int16): JSCFunctionListEntry {.inline.} =
  result = JSCFunctionListEntry(
    name: name,
    prop_flags: JS_PROP_WRITABLE or JS_PROP_CONFIGURABLE,
    def_type: JS_DEF_CFUNC,
    magic: magic,
    u: JSCDeclareUnion(
      fn: JSCDeclareFuntion(
        length: length,
        cproto: JS_CFUNC_iterator_next,
        cfunc: JSCFunctionType(
          iterator_next: fn1)
    )))

proc JS_CGETSET_DEF*(name: string, fgetter: proc (ctx: ptr JSContext; this_val: JSValue): JSValue {.cdecl.}, fsetter: proc (ctx: ptr JSContext; this_val: JSValue; val: JSValue): JSValue {.cdecl.}): JSCFunctionListEntry {.inline.} =
  result = JSCFunctionListEntry(
    name: name,
    prop_flags: JS_PROP_CONFIGURABLE,
    def_type: JS_DEF_CGETSET
  )
  result.u.getset.fget.getter = fgetter
  result.u.getset.fset.setter = fsetter

proc JS_CGETSET_MAGIC_DEF*(name: string, fgetter: proc (ctx: ptr JSContext; this_val: JSValue, magic: cint): JSValue {.cdecl.}, fsetter: proc (ctx: ptr JSContext; this_val: JSValue; val: JSValue, magic: cint): JSValue {.cdecl.}, magic: int16): JSCFunctionListEntry {.inline.} =
  result = JSCFunctionListEntry(
    name: name,
    prop_flags: JS_PROP_CONFIGURABLE,
    def_type: JS_DEF_CGETSET_MAGIC,
    magic: magic
  )
  result.u.getset.fget.getter_magic = fgetter
  result.u.getset.fset.setter_magic = fsetter


proc JS_PROP_STRING_DEF*(name: string, cstr: cstring, prop_flags: uint8): JSCFunctionListEntry {.inline.} =
  result = JSCFunctionListEntry(
    name: name,
    prop_flags: prop_flags,
    def_type: JS_DEF_PROP_STRING,
    magic: 0,
    u: JSCDeclareUnion(str: cstr)
  )

proc JS_PROP_INT32_DEF*(name: string, val: int32, prop_flags: uint8): JSCFunctionListEntry {.inline.} =
  result = JSCFunctionListEntry(
    name: name,
    prop_flags: prop_flags,
    def_type: JS_DEF_PROP_INT32,
    magic: 0,
    u: JSCDeclareUnion(i32: val)
  )

proc JS_PROP_INT64_DEF*(name: string, val: int64, prop_flags: uint8): JSCFunctionListEntry {.inline.} =
  result = JSCFunctionListEntry(
    name: name,
    prop_flags: prop_flags,
    def_type: JS_DEF_PROP_INT64,
    magic: 0,
    u: JSCDeclareUnion(i64: val)
  )

proc JS_PROP_DOUBLE_DEF*(name: string, val: float64, prop_flags: uint8): JSCFunctionListEntry {.inline.} =
  result = JSCFunctionListEntry(
    name: name,
    prop_flags: prop_flags,
    def_type: JS_DEF_PROP_DOUBLE,
    magic: 0,
    u: JSCDeclareUnion(f64: val)
  )

proc JS_PROP_UNDEFINED_DEF*(name: string, prop_flags: uint8): JSCFunctionListEntry {.inline.} =
  result = JSCFunctionListEntry(
    name: name,
    prop_flags: prop_flags,
    def_type: JS_DEF_PROP_INT32,
    magic: 0,
    u: JSCDeclareUnion(i32: 0)
  )

proc JS_OBJECT_DEF*(name: string, tab: ptr JSCFunctionListEntry, len: cint, prop_flags: uint8): JSCFunctionListEntry {.inline.} =
  result = JSCFunctionListEntry(
    name: name,
    prop_flags: prop_flags,
    def_type: JS_DEF_OBJECT,
    magic: 0,
    u: JSCDeclareUnion(
      prop_list: JSCDeclarePropList(
        tab: tab,
        len: len
      ))
  )

proc JS_ALIAS_DEF*(name: string, `from`: cstring): JSCFunctionListEntry {.inline.} =
  result = JSCFunctionListEntry(
    name: name,
    prop_flags: JS_PROP_WRITABLE or JS_PROP_CONFIGURABLE,
    def_type: JS_DEF_ALIAS,
    magic: 0,
    u: JSCDeclareUnion(
      alias: JSCDeclareAlias(
        name: `from`,
        base: -1
      ))
  )

proc JS_ALIAS_BASE_DEF*(name: string, `from`: cstring, base: cint): JSCFunctionListEntry {.inline.} =
  result = JSCFunctionListEntry(
    name: name,
    prop_flags: JS_PROP_WRITABLE or JS_PROP_CONFIGURABLE,
    def_type: JS_DEF_ALIAS,
    magic: 0,
    u: JSCDeclareUnion(
      alias: JSCDeclareAlias(
        name: `from`,
        base: base
      ))
  )
