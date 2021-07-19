# Package
version     = "0.1.0"
author      = "ba0f3"
description = "High level QuickJS wrapper for Nim"
license     = "MIT"
srcDir      = "src"
skipDirs    = @["examples"]

# Dependencies
requires "nim >= 0.19.2"

task examples, "Compile and run examples":
  withDir "examples":
    exec "nim c -r hello.nim"
    exec "nim c -r hello_eval.nim"
    exec "nim c -r hello_function.nim"
    exec "nim c -r hello_object.nim"
    exec "nim c -r point_nimgen.nim"
    exec "nim c --app:lib fib.nim"
    exec "nim c --app:lib point.nim"
    exec "nim c -r run_test.nim test_fib.js"
    exec "nim c -r run_test.nim test_point.js"
