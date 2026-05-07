# Write a minimal test acaddoc.lsp - test FIRST, then load everything else
import os

content = ";;; acaddoc.lsp - TEST FIRST\r\n"
content += "(alert \"acaddoc.lsp is being loaded!\")\r\n"
content += "\r\n"
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

path = r"D:\Autodesk\CAD2018\AutoCAD 2018\Support\acaddoc.lsp"
with open(path, 'w', newline='') as f:
    f.write(content)
print(f"Written: {path}")
print(f"Size: {len(content)} bytes")
