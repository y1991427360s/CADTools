;;; YS-Tools load test
;;; Encoding: GBK/ANSI, CRLF

(setq __tf (open "E:/366256/vibecoding/CADTools/YS-Tools/test-result.txt" "w"))
(write-line "=== YS-Tools Load Test ===" __tf)

(if (and (boundp '*YS-Tools-Path*) *YS-Tools-Path*)
  (progn
    (write-line (strcat "OK  *YS-Tools-Path* = " *YS-Tools-Path*) __tf)
    (foreach f '("YS-Tools.lsp" "config.lsp" "utils.lsp" "dcl\\toolbar.lsp" "dcl\\toolbar.dcl")
      (write-line
        (strcat f ": " (if (findfile (strcat *YS-Tools-Path* "\\" f)) "EXISTS" "MISSING"))
        __tf
      )
    )
  )
  (write-line "FAIL *YS-Tools-Path* is not set." __tf)
)

(write-line "Checking command symbols..." __tf)
(foreach sym '(c:YS c:YSTOOLS c:Y c:RR c:ZUO c:LONG c:EXCEL c:HEI c:HE c:QW c:BIAN c:LAN c:XIN c:XY c:PAI c:ZDML c:HAO)
  (write-line (strcat (vl-princ-to-string sym) ": " (if (member (strcase (vl-princ-to-string sym)) (atoms-family 1)) "OK" "MISSING")) __tf)
)

(close __tf)
(princ "\nYS-Tools load test finished. See test-result.txt.")
(princ)
