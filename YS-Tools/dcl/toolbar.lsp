;;; ====================================================================
;;; YS-Tools - DCL ????????????
;;; ???? toolbar.dcl ??????????
;;; ====================================================================

;;; --- DCL ???¡¤?? ---
(setq *YS-Tools-DCL-Path*
  (if *YS-Tools-Path*
    (strcat *YS-Tools-Path* "\\dcl\\toolbar.dcl")
    nil
  )
)

;;; --- ????????? ---
(defun ys:handle-button (key)
  (cond
    ;; ???????
    ((= key "btn_cont")   (done_dialog 1) (vl-cmdf "_.CONT"))
    ((= key "btn_txt")    (done_dialog 1) (vl-cmdf "_.TXT"))
    ((= key "btn_ysdl")   (done_dialog 1) (vl-cmdf "_.YSDL"))
    ((= key "btn_hei")    (done_dialog 1) (vl-cmdf "_.HEI"))
    ((= key "btn_qstxt")  (done_dialog 1) (vl-cmdf "_.QSTXT"))
    ((= key "btn_he")     (done_dialog 1) (vl-cmdf "_.HE"))
    ((= key "btn_qw")     (done_dialog 1) (vl-cmdf "_.QW"))
    ((= key "btn_wi")     (done_dialog 1) (vl-cmdf "_.WI"))
    ((= key "btn_gtx")    (done_dialog 1) (vl-cmdf "_.GTX"))
    ((= key "btn_gty")    (done_dialog 1) (vl-cmdf "_.GTY"))

    ;; ??????
    ((= key "btn_zhong")  (done_dialog 1) (vl-cmdf "_.ZHONG"))
    ((= key "btn_zuo")    (done_dialog 1) (vl-cmdf "_.ZUO"))
    ((= key "btn_you")    (done_dialog 1) (vl-cmdf "_.YOU"))
    ((= key "btn_shang")  (done_dialog 1) (vl-cmdf "_.SHANG"))
    ((= key "btn_xia")    (done_dialog 1) (vl-cmdf "_.XIA"))

    ;; ???
    ((= key "btn_y")      (done_dialog 1) (vl-cmdf "_.Y"))
    ((= key "btn_rr")     (done_dialog 1) (vl-cmdf "_.RR"))
    ((= key "btn_uu")     (done_dialog 1) (vl-cmdf "_.UU"))
    ((= key "btn_gg")     (done_dialog 1) (vl-cmdf "_.GG"))

    ;; ???
    ((= key "btn_syi")    (done_dialog 1) (vl-cmdf "_.SYI"))
    ((= key "btn_xyi")    (done_dialog 1) (vl-cmdf "_.XYI"))
    ((= key "btn_zyy")    (done_dialog 1) (vl-cmdf "_.ZYI"))
    ((= key "btn_yyi")    (done_dialog 1) (vl-cmdf "_.YYI"))

    ;; ??¦É???
    ((= key "btn_yan")    (done_dialog 1) (vl-cmdf "_.YAN"))
    ((= key "btn_syan")   (done_dialog 1) (vl-cmdf "_.SYAN"))
    ((= key "btn_xyan")   (done_dialog 1) (vl-cmdf "_.XYAN"))
    ((= key "btn_xSUO")   (done_dialog 1) (vl-cmdf "_.XSUO"))
    ((= key "btn_sSUO")   (done_dialog 1) (vl-cmdf "_.SSUO"))
    ((= key "btn_sj")     (done_dialog 1) (vl-cmdf "_.SJ"))
    ((= key "btn_xj")     (done_dialog 1) (vl-cmdf "_.XJ"))
    ((= key "btn_long")   (done_dialog 1) (vl-cmdf "_.LONG"))

    ;; ???/????
    ((= key "btn_excel")  (done_dialog 1) (vl-cmdf "_.EXCEL"))
    ((= key "btn_nu")     (done_dialog 1) (vl-cmdf "_.NU"))
    ((= key "btn_kuang")  (done_dialog 1) (vl-cmdf "_.KUANG"))
    ((= key "btn_bian")   (done_dialog 1) (vl-cmdf "_.BIAN"))
    ((= key "btn_lan")    (done_dialog 1) (vl-cmdf "_.LAN"))
    ((= key "btn_xin")    (done_dialog 1) (vl-cmdf "_.XIN"))
    ((= key "btn_xy")     (done_dialog 1) (vl-cmdf "_.XY"))

    ;; ?????
    ((= key "btn_pai")    (done_dialog 1) (vl-cmdf "_.PAI"))
    ((= key "btn_zdml")   (done_dialog 1) (vl-cmdf "_.ZDML"))
    ((= key "btn_hao")    (done_dialog 1) (vl-cmdf "_.HAO"))
    ((= key "btn_diag")   (done_dialog 1) (vl-cmdf "_.DIAGFRAME"))

    ;; ???
    ((= key "close_btn")  (done_dialog 0))

    (T nil)
  )
)

;;; --- ????????? ---
(defun ys:show-toolbar (/ dcl_id result)
  (if (null *YS-Tools-DCL-Path*)
    (progn
      (princ "\n[YS-Tools] DCL¡¤??¦Ä???ÈÉ?????YS-Tools????????")
      nil
    )
    (if (not (findfile *YS-Tools-DCL-Path*))
      (progn
        (princ (strcat "\n[YS-Tools] DCL???¦Ä???: " *YS-Tools-DCL-Path*))
        nil
      )
      (progn
        (setq dcl_id (load_dialog *YS-Tools-DCL-Path*))
        (if (< dcl_id 0)
          (progn
            (princ "\n[YS-Tools] ????DCL???????")
            nil
          )
          (progn
            (if (not (new_dialog "ys_tools_toolbar" dcl_id))
              (progn
                (princ "\n[YS-Tools] ????????????")
                (unload_dialog dcl_id)
                nil
              )
              (progn
                ;; ?????§Ñ??
                (action_tile "btn_cont"   "(ys:handle-button \"btn_cont\")")
                (action_tile "btn_txt"    "(ys:handle-button \"btn_txt\")")
                (action_tile "btn_ysdl"   "(ys:handle-button \"btn_ysdl\")")
                (action_tile "btn_hei"    "(ys:handle-button \"btn_hei\")")
                (action_tile "btn_qstxt"  "(ys:handle-button \"btn_qstxt\")")
                (action_tile "btn_he"     "(ys:handle-button \"btn_he\")")
                (action_tile "btn_qw"     "(ys:handle-button \"btn_qw\")")
                (action_tile "btn_wi"     "(ys:handle-button \"btn_wi\")")
                (action_tile "btn_gtx"    "(ys:handle-button \"btn_gtx\")")
                (action_tile "btn_gty"    "(ys:handle-button \"btn_gty\")")
                (action_tile "btn_zhong"  "(ys:handle-button \"btn_zhong\")")
                (action_tile "btn_zuo"    "(ys:handle-button \"btn_zuo\")")
                (action_tile "btn_you"    "(ys:handle-button \"btn_you\")")
                (action_tile "btn_shang"  "(ys:handle-button \"btn_shang\")")
                (action_tile "btn_xia"    "(ys:handle-button \"btn_xia\")")
                (action_tile "btn_y"      "(ys:handle-button \"btn_y\")")
                (action_tile "btn_rr"     "(ys:handle-button \"btn_rr\")")
                (action_tile "btn_uu"     "(ys:handle-button \"btn_uu\")")
                (action_tile "btn_gg"     "(ys:handle-button \"btn_gg\")")
                (action_tile "btn_syi"    "(ys:handle-button \"btn_syi\")")
                (action_tile "btn_xyi"    "(ys:handle-button \"btn_xyi\")")
                (action_tile "btn_zyy"    "(ys:handle-button \"btn_zyy\")")
                (action_tile "btn_yyi"    "(ys:handle-button \"btn_yyi\")")
                (action_tile "btn_yan"    "(ys:handle-button \"btn_yan\")")
                (action_tile "btn_syan"   "(ys:handle-button \"btn_syan\")")
                (action_tile "btn_xyan"   "(ys:handle-button \"btn_xyan\")")
                (action_tile "btn_xSUO"   "(ys:handle-button \"btn_xSUO\")")
                (action_tile "btn_sSUO"   "(ys:handle-button \"btn_sSUO\")")
                (action_tile "btn_sj"     "(ys:handle-button \"btn_sj\")")
                (action_tile "btn_xj"     "(ys:handle-button \"btn_xj\")")
                (action_tile "btn_long"   "(ys:handle-button \"btn_long\")")
                (action_tile "btn_excel"  "(ys:handle-button \"btn_excel\")")
                (action_tile "btn_nu"     "(ys:handle-button \"btn_nu\")")
                (action_tile "btn_kuang"  "(ys:handle-button \"btn_kuang\")")
                (action_tile "btn_bian"   "(ys:handle-button \"btn_bian\")")
                (action_tile "btn_lan"    "(ys:handle-button \"btn_lan\")")
                (action_tile "btn_xin"    "(ys:handle-button \"btn_xin\")")
                (action_tile "btn_xy"     "(ys:handle-button \"btn_xy\")")
                (action_tile "btn_pai"    "(ys:handle-button \"btn_pai\")")
                (action_tile "btn_zdml"   "(ys:handle-button \"btn_zdml\")")
                (action_tile "btn_hao"    "(ys:handle-button \"btn_hao\")")
                (action_tile "btn_diag"   "(ys:handle-button \"btn_diag\")")
                (action_tile "close_btn"  "(ys:handle-button \"close_btn\")")

                (start_dialog)
                (unload_dialog dcl_id)
                T
              )
            )
          )
        )
      )
    )
  )
)

;;; --- YSTOOLS ???? ---
(defun C:YSTOOLS ()
  (vl-load-com)
  (ys:show-toolbar)
)

(princ "\n[YS-Tools] toolbar.lsp loaded.")
(princ)
