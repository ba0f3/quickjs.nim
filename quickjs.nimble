# Package
version     = "0.0.2"
author      = "ba0f3"
description = "High level QuickJS wrapper for Nim"
license     = "MIT"
srcDir        = "src"

# Dependencies
requires "nim >= 0.19.2"

task examples, "Compile and run examples":
  withDir "examples":
    exec "nim c -d:release --app:lib fib.nim"
    exec "nim c -d:release --app:lib point.nim"
    exec "nim c -d:release run_test.nim"
    exec "./run_test test_fib.js"
    exec "./run_test test_point.js"