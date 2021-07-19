import quickjs

var e = newEngine()

e.evalString("1 + 2")
assert e.retval == JS_MKVAL(JS_TAG_INT, 3)

let ret = e.evalFile("./hello.js")
quit(ret)