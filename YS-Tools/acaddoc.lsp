;;; acaddoc.lsp - AutoCAD/ZWCAD document startup loader
;;; Encoding: GBK/ANSI, CRLF

(defun YS-Tools-Autoload (/ root file)
  (setq root (getenv "YS_TOOLS_PATH"))
  (setq file
    (cond
      ((and root (findfile (strcat root "\\YS-Tools.lsp")))
       (strcat root "\\YS-Tools.lsp"))
      ((findfile "YS-Tools\\YS-Tools.lsp")
       (findfile "YS-Tools\\YS-Tools.lsp"))
      ((findfile "YS-Tools.lsp")
       (findfile "YS-Tools.lsp"))
      ((findfile "E:/366256/vibecoding/CADTools/YS-Tools/YS-Tools.lsp")
       "E:/366256/vibecoding/CADTools/YS-Tools/YS-Tools.lsp")
    )
  )
  (if file (load file nil))
  (princ)
)

(YS-Tools-Autoload)
