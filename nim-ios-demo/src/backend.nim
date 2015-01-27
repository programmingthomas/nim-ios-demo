proc hello*(name: cstring): cstring {.exportc.} =
    result = "Hello " & $name