import os, quickjs


if paramCount() != 1:
  quit("Usage: " & paramStr(0) & " file.js")


if not paramStr(0).fileExists:
  quit("File not found: " & paramStr(1))

let
  e = newEngine()
  ret = e.evalFile(paramStr(1))

quit(ret)
