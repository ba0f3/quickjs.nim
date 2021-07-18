import quickjs

let
  e = newEngine()
  ret = e.evalFile("./hello.js")

quit(ret)