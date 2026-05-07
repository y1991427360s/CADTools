import os

content = ";;; acaddoc.lsp - with YS-Tools test (desktop)\r\n"
content += "(defun AA-load-local-file (file-name / file-path)\r\n"
content += "  (setq file-path (findfile file-name))\r\n"
content += "  (if file-path\r\n"
content += "    (load file-path nil)\r\n"
content += "  )\r\n"
content += ")\r\n"
content += "(AA-load-local-file \"AA_main.lsp\")\r\n"
content += "\r\n"
content += ";;; YS-Tools Auto-Load\r\n"
content += "(if (findfile \"YS-Tools\\\\YS-Tools.lsp\")\r\n"
content += "  (progn\r\n"
content += "    (load \"YS-Tools\\\\YS-Tools.lsp\")\r\n"
content += "    (princ)\r\n"
content += "  )\r\n"
content += ")\r\n"
content += "\r\n"
content += ";;; TEST: write to desktop\r\n"
content += '(setq __jtf (open (strcat (getenv \"USERPROFILE\") \"\\\\Desktop\\\\ys-tools-test.txt\") \"w\"))\r\n'
content += '(write-line \"=== YS-Tools Test ===\" __jtf)\r\n'
content += '(write-line (strcat \"ACADVER: \" (getvar \"ACADVER\")) __jtf)\r\n'
content += "(if (and (boundp '*YS-Tools-Path*) *YS-Tools-Path*)\r\n"
content += "  (progn\r\n"
content += '    (write-line (strcat "ROOT: " *YS-Tools-Path*) __jtf)\r\n'
content += '    (write-line (strcat "config.lsp: " (if (findfile (strcat *YS-Tools-Path* "\\\\config.lsp")) "EXISTS" "MISSING")) __jtf)\r\n'
content += "    (write-line \"\" __jtf)\r\n"
content += "    (write-line \"--- Commands ---\" __jtf)\r\n"
content += "    (foreach sym '(c:YS c:YSTOOLS c:Y c:ZUO c:LONG c:HEI c:QW c:BIAN c:XY c:PAI c:ZDML c:HAO)\r\n"
content += "      (if (and (boundp sym) (functionp (eval sym)))\r\n"
content += '        (write-line (strcat "OK: " (vl-princ-to-string sym)) __jtf)\r\n'
content += '        (write-line (strcat "MISSING: " (vl-princ-to-string sym)) __jtf)\r\n'
content += "      )\r\n"
content += "    )\r\n"
content += "  )\r\n"
content += "  (write-line \"FAIL: *YS-Tools-Path* is NOT SET!\" __jtf)\r\n"
content += ")\r\n"
content += "(close __jtf)\r\n"
content += "(setq __jtf nil)\r\n"
content += "(princ)\r\n"

paths = [
    r"D:\Autodesk\CAD2018\AutoCAD 2018\Support\acaddoc.lsp",
    r"C:\Users\ys199\AppData\Roaming\Autodesk\AutoCAD 2018\R22.0\chs\Support\acaddoc.lsp"
]
for path in paths:
    with open(path, 'w', newline='') as f:
        f.write(content)
    print(f"Written: {path}")

# Verify
with open(paths[0], 'rb') as f:
    raw = f.read()
    bs = raw.count(b'\\\\')
    crlf = raw.count(b'\r\n')
    print(f"Double backslashes: {bs}")
    print(f"CRLF pairs: {crlf}")
