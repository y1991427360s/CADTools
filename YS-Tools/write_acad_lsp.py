import os, shutil

# Create acad.lsp - this is loaded once at AutoCAD startup
# AutoCAD loads acad.lsp from the executable directory and support paths
content = b""";;; acad.lsp - loads YS-Tools on AutoCAD startup
(setq *YS-TOOLS-AUTO-LOAD* nil)

(defun ys:auto-load (/ p)
  (setq p (findfile "YS-Tools\\\\YS-Tools.lsp"))
  (if p
    (progn
      (load p)
      (setq *YS-TOOLS-AUTO-LOAD* T)
    )
  )
)

(ys:auto-load)
(princ)
"""

# Write to multiple locations
paths = [
    r"D:\Autodesk\CAD2018\AutoCAD 2018\acad.lsp",
    r"D:\Autodesk\CAD2018\AutoCAD 2018\Support\acad.lsp",
    r"D:\Autodesk\CAD2018\AutoCAD 2018\UserDataCache\acad.lsp",
    r"D:\Autodesk\CAD2018\AutoCAD 2018\UserDataCache\Support\acad.lsp",
    r"C:\Users\ys199\AppData\Roaming\Autodesk\AutoCAD 2018\R22.0\chs\Support\acad.lsp",
]

for p in paths:
    try:
        os.makedirs(os.path.dirname(p), exist_ok=True)
        with open(p, "wb") as f:
            f.write(content)
        print(f"Written: {p}")
    except Exception as e:
        print(f"Failed: {p} - {e}")

# Verify backslashes
with open(paths[0], "rb") as f:
    raw = f.read()
    bs = raw.count(b"\\\\\\\\")
    print(f"\\nVerification:")
    print(f"  Double backslashes: {bs}")
    print(f"  Content: {raw.decode('ascii')}")
