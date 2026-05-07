import os

# Path to AA_main.lsp
path = r"D:\Autodesk\CAD2018\AutoCAD 2018\Support\AA_main.lsp"

# Read existing content
with open(path, "rb") as f:
    content = f.read()

# Check if already patched
if b"YS-Tools" in content:
    print("AA_main.lsp already has YS-Tools loading code")
else:
    # Append YS-Tools loading code to the end
    append = b"\r\n\r\n;;; YS-Tools Auto-Load (added by fix)\r\n"
    append += b'(if (findfile "YS-Tools\\\\YS-Tools.lsp")\r\n'
    append += b"  (progn\r\n"
    append += b'    (load "YS-Tools\\\\YS-Tools.lsp")\r\n'
    append += b"    (princ)\r\n"
    append += b"  )\r\n"
    append += b")\r\n"
    append += b"(princ)\r\n"

    with open(path, "wb") as f:
        f.write(content + append)
    print("Patched AA_main.lsp with YS-Tools loading")

# Verify
with open(path, "rb") as f:
    check = f.read()
    bs = check.count(b"\\\\\\\\")
    print(f"File size: {len(check)} bytes")
    print(f"Double backslashes in path: {bs}")

# Also copy acaddoc.lsp back to clean version (without alert)
# And also add YS loading to it
acad_path = r"D:\Autodesk\CAD2018\AutoCAD 2018\Support\acaddoc.lsp"
acad_content = b";;; acaddoc.lsp - clean version with YS-Tools loading\r\n"
acad_content += b"(defun AA-load-local-file (file-name / file-path)\r\n"
acad_content += b"  (setq file-path (findfile file-name))\r\n"
acad_content += b"  (if file-path (load file-path nil))\r\n"
acad_content += b")\r\n"
acad_content += b'(AA-load-local-file "AA_main.lsp")\r\n'
acad_content += b"\r\n"
acad_content += b";;; YS-Tools Auto-Load\r\n"
acad_content += b'(if (findfile "YS-Tools\\\\YS-Tools.lsp")\r\n'
acad_content += b"  (progn\r\n"
acad_content += b'    (load "YS-Tools\\\\YS-Tools.lsp")\r\n'
acad_content += b"    (princ)\r\n"
acad_content += b"  )\r\n"
acad_content += b")\r\n"
acad_content += b"(princ)\r\n"

with open(acad_path, "wb") as f:
    f.write(acad_content)
print("acaddoc.lsp rewritten (clean)")

# Copy to other locations
import shutil
destinations = [
    r"D:\Autodesk\CAD2018\AutoCAD 2018\acaddoc.lsp",
    r"D:\Autodesk\CAD2018\AutoCAD 2018\UserDataCache\acaddoc.lsp",
    r"D:\Autodesk\CAD2018\AutoCAD 2018\UserDataCache\Support\acaddoc.lsp",
    r"C:\Users\ys199\AppData\Roaming\Autodesk\AutoCAD 2018\R22.0\chs\Support\acaddoc.lsp",
]
for d in destinations:
    try:
        shutil.copy2(acad_path, d)
        print(f"Copied to: {d}")
    except:
        print(f"Failed to copy to: {d}")
