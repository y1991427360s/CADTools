import os, re

path = r"D:\Autodesk\CAD2018\AutoCAD 2018\Support\AA_main.lsp"

with open(path, "rb") as f:
    content = f.read()

# Find the YS-Tools loading line and replace with correct version
old = b'(load "YS-Tools\\YS-Tools.lsp")'
new = b'(if (findfile "YS-Tools\\\\YS-Tools.lsp") (load "YS-Tools\\\\YS-Tools.lsp"))'

if old in content:
    content = content.replace(old, new)
    with open(path, "wb") as f:
        f.write(content)
    print("Fixed AA_main.lsp - replaced single backslash with double backslash + findfile check")
else:
    print("Old pattern not found, checking current state...")

# Verify
with open(path, "rb") as f:
    verify = f.read()
    # Find the YS-Tools lines
    lines = verify.split(b"\n")
    for i, line in enumerate(lines):
        if b"YS-Tools" in line:
            # Count backslashes
            bs = line.count(b"\\")
            print(f"Line {i}: {line.decode('ascii', errors='replace')} (backslashes: {bs})")

# Also ensure the YS-Tools files have correct paths
ys_path = r"D:\Autodesk\CAD2018\AutoCAD 2018\Support\YS-Tools\YS-Tools.lsp"
if os.path.exists(ys_path):
    with open(ys_path, "rb") as f:
        ys_content = f.read()
    bs = ys_content.count(b"\\\\")
    print(f"YS-Tools.lsp has {bs} double backslash sequences")
