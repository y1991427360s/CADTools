;;; simple test - write to file
(setq __f (open "E:/366256/vibecoding/CADTools/YS-Tools/test-result.txt" "w"))

(write-line "=== YS-Tools Load Test ===" __f)
(write-line (strcat "Date: " (rtos (getvar "CDATE") 2 6)) __f)
(write-line "" __f)

(if (and (boundp '*YS-Tools-Path*) *YS-Tools-Path*)
  (progn
    (write-line (strcat "OK: *YS-Tools-Path* = " *YS-Tools-Path*) __f)
    (write-line "" __f)
    (write-line "--- Module Files ---" __f)
    (foreach f '("config.lsp" "utils.lsp"
                 "modules\\color-tools.lsp" "modules\\move-tools.lsp"
                 "modules\\line-tools.lsp" "modules\\align-tools.lsp"
                 "modules\\draw-tools.lsp" "modules\\text-tools.lsp"
                 "modules\\cable-tools.lsp" "modules\\frame-tools.lsp"
                 "dcl\\toolbar.lsp" "dcl\\toolbar.dcl")
      (if (findfile (strcat *YS-Tools-Path* "\\" f))
        (write-line (strcat "  OK: " f) __f)
        (write-line (strcat "  FAIL: " f) __f)
      )
    )
    (write-line "" __f)
    (write-line "--- Commands ---" __f)
    (foreach sym '(c:YS c:YSOOLS c:YSTOOLS c:Y c:RR c:UU c:GG
                    c:SYI c:XYI c:ZYI c:YYI c:ZHONG c:ZUO c:YOU c:SHANG c:XIA
                    c:YAN c:SYAN c:XYAN c:XSUO c:SSUO c:SJ c:XJ c:LONG
                    c:EXCEL c:NU c:KUANG c:CONT c:TXT c:T c:YSDL c:HEI
                    c:QSTXT c:HE c:QW c:WI c:GTX c:GTY
                    c:BIAN c:LAN c:XIN c:XY c:PAI c:ZDML c:HAO c:DIAGFRAME)
      (if (and (boundp sym) (functionp (eval sym)))
        (write-line (strcat "  OK: " (vl-princ-to-string sym)) __f)
        (write-line (strcat "  FAIL: " (vl-princ-to-string sym)) __f)
      )
    )
    (write-line "" __f)
    (write-line "=== DCL Toolbar ===" __f)
    (if (and (boundp 'c:YSTOOLS) (functionp c:YSTOOLS))
      (write-line "OK: YSTOOLS command available" __f)
      (write-line "FAIL: YSTOOLS not defined!" __f)
    )
  )
  (write-line "FAIL: *YS-Tools-Path* is not set!" __f)
)

(close __f)
(princ)
