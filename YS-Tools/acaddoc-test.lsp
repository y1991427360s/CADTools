;;; acaddoc.lsp - with build-in YS-Tools test
(defun AA-load-local-file (file-name / file-path)
  (setq file-path (findfile file-name))
  (if file-path
    (load file-path nil)
  )
)
(AA-load-local-file "AA_main.lsp")

;;; YS-Tools Auto-Load
(if (findfile "YS-Tools\\YS-Tools.lsp")
  (progn
    (load "YS-Tools\\YS-Tools.lsp")
    (princ)
  )
)

;;; AUTOMATIC TEST
(setq __jtf (open "E:/366256/vibecoding/CADTools/YS-Tools/test-result.txt" "w"))
(write-line "=== YS-Tools Test ===" __jtf)
(write-line (strcat "ACADVER: " (getvar "ACADVER")) __jtf)
(if (and (boundp '*YS-Tools-Path*) *YS-Tools-Path*)
  (write-line (strcat "ROOT: " *YS-Tools-Path*) __jtf)
  (write-line "ROOT: NOT SET!" __jtf)
)
(foreach sym '(c:YS c:YSTOOLS c:Y c:RR c:ZUO c:YOU c:YAN c:LONG c:EXCEL c:HEI c:HE c:QW c:GTX c:GTY c:BIAN c:LAN c:XIN c:XY c:PAI c:ZDML c:HAO)
  (if (and (boundp sym) (functionp (eval sym)))
    (write-line (strcat "OK: " (vl-princ-to-string sym)) __jtf)
    (write-line (strcat "MISSING: " (vl-princ-to-string sym)) __jtf)
  )
)
(close __jtf)
(setq __jtf nil)
(princ)
