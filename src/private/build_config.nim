import os

const LIB_DIR = currentSourcePath().splitPath.head
const headerquickjs* = LIB_DIR & "/quickjs/quickjs.h"

{.passC: "-D_GNU_SOURCE -DCONFIG_BIGNUM -DCONFIG_VERSION=\"\"".}
{.passL: "-lm -lpthread".}
{.compile: LIB_DIR & "/quickjs/quickjs.c".}
{.compile: LIB_DIR & "/quickjs/cutils.c".}
{.compile: LIB_DIR & "/quickjs/libregexp.c".}
{.compile: LIB_DIR & "/quickjs/libunicode.c".}
{.compile: LIB_DIR & "/quickjs/libbf.c".}
{.compile: LIB_DIR & "/quickjs/quickjs-libc.c".}