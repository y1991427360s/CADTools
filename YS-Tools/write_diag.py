import os

content = (
    ";;; acaddoc.lsp - diagnostic version\r\n"
    '(alert "acaddoc.lsp loaded - running diagnostic")\r\n'
    "\r\n"
    "(defun AA-load-local-file (file-name / file-path)\r\n"
    "  (setq file-path (findfile file-name))\r\n"
    "  (if file-path (load file-path nil))\r\n"
    ")\r\n"
    '(AA-load-local-file "AA_main.lsp")\r\n'
    "\r\n"
    ";;; YS-Tools Auto-Load\r\n"
    '(if (findfile "YS-Tools\\\\YS-Tools.lsp")\r\n'
    "  (progn\r\n"
    '    (load "YS-Tools\\\\YS-Tools.lsp")\r\n'
    "    (princ)\r\n"
    "  )\r\n"
    ")\r\n"
    "\r\n"
    ";;; DIAGNOSTIC\r\n"
    '(setq __d (open (strcat (getenv "USERPROFILE") "\\\\Desktop\\\\ys-diag.txt") "w"))\r\n'
    '(write-line "=== YS-Tools Diagnostic ===" __d)\r\n'
    "(if (and (boundp (quote *YS-Tools-Path*)) *YS-Tools-Path*)\r\n"
    '  (write-line (strcat "GOOD: *YS-Tools-Path* = " *YS-Tools-Path*) __d)\r\n'
    '  (write-line "FAIL: *YS-Tools-Path* is not set" __d)\r\n'
    ")\r\n"
    "(if (and (boundp (quote c:YS)) (functionp c:YS))\r\n"
    '  (write-line "GOOD: C:YS is defined" __d)\r\n'
    '  (write-line "FAIL: C:YS is not defined" __d)\r\n'
    ")\r\n"
    "(if (and (boundp (quote c:YSTOOLS)) (functionp c:YSTOOLS))\r\n"
    '  (write-line "GOOD: C:YSTOOLS is defined" __d)\r\n'
    '  (write-line "FAIL: C:YSTOOLS is not defined" __d)\r\n'
    ")\r\n"
    "(if (and (boundp (quote c:Y)) (functionp c:Y))\r\n"
    '  (write-line "GOOD: C:Y (color) is defined" __d)\r\n'
    '  (write-line "FAIL: C:Y (color) is not defined" __d)\r\n'
    ")\r\n"
    "(close __d)\r\n"
    "(setq __d nil)\r\n"
    "(princ)\r\n"
)

path = r"D:\Autodesk\CAD2018\AutoCAD 2018\Support\acaddoc.lsp"
with open(path, "w", newline="") as f:
    f.write(content)

# verify backslashes
with open(path, "rb") as f:
    raw = f.read()
    import re
    bs = len(re.findall(rb'\\\\', raw))
    crlf = raw.count(b"\r\n")
    print(f"Written: {path}")
    print(f"Double backslashes found: {bs}")
    print(f"CRLF pairs: {crlf}")
    print(f"Total size: {len(raw)} bytes")
