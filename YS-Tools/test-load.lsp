;;; YS-Tools ??????? (????????)
(setq __tf (open "E:/366256/vibecoding/CADTools/YS-Tools/test-result.txt" "w"))

(write-line "==========================================" __tf)
(write-line "  YS-Tools Load Test" __tf)
(write-line "==========================================" __tf)

;; ????1: ???¡¤??
(if (and (boundp '*YS-Tools-Path*) *YS-Tools-Path*)
  (progn
    (write-line (strcat "OK  *YS-Tools-Path* = " *YS-Tools-Path*) __tf)
    ;; ????2: ???????????????
    (foreach f '("config.lsp" "utils.lsp"
                 "modules\\color-tools.lsp" "modules\\move-tools.lsp"
                 "modules\\line-tools.lsp" "modules\\align-tools.lsp"
                 "modules\\draw-tools.lsp" "modules\\text-tools.lsp"
                 "modules\\cable-tools.lsp" "modules\\frame-tools.lsp"
                 "dcl\\toolbar.lsp" "dcl\\toolbar.dcl")
      (if (findfile (strcat *YS-Tools-Path* "\\" f))
        (write-line (strcat "OK  File found: " f) __tf)
        (write-line (strcat "FAIL File NOT found: " f) __tf)
      )
    )
  )
  (write-line "FAIL *YS-Tools-Path* is not set!" __tf)
)

;; ????3: ???????????
(write-line "" __tf)
(write-line "--- Command Availability ---" __tf)
(foreach sym '(c:Y c:RR c:UU c:GG
                c:SYI c:XYI c:ZYI c:YYI
                c:YAN c:SYAN c:XYAN c:XSUO c:SSUO c:SJ c:XJ c:LONG
                c:ZHONG c:ZUO c:YOU c:SHANG c:XIA
                c:EXCEL c:NU c:KUANG
                c:CONT c:TXT c:T c:YSDL c:HEI c:QSTXT c:HE c:QW c:WI c:GTX c:GTY
                c:BIAN c:LAN c:XIN c:XY
                c:PAI c:ZDML c:HAO c:DIAGFRAME c:SHOWBB
                c:YSTOOLS c:YS c:YSOOLS)
  (if (and (boundp sym) (functionp (eval sym)))
    (write-line (strcat "OK  " (vl-princ-to-string sym)) __tf)
    (write-line (strcat "MISSING " (vl-princ-to-string sym)) __tf)
  )
)

(write-line "" __tf)
(write-line "==========================================" __tf)
(write-line "  Test Complete" __tf)
(write-line "==========================================" __tf)
(close __tf)

;; ???????????
(load "YS-Tools/dcl/toolbar.lsp")
(if (and (boundp 'c:YSTOOLS) (functionp c:YSTOOLS))
  (progn
    (setq __f2 (open "E:/366256/vibecoding/CADTools/YS-Tools/test-result.txt" "a"))
    (write-line "OK  YSTOOLS toolbar command defined" __f2)
    (close __f2)
  )
)

(setq __tf nil)
(princ)
