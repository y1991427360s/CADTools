;;; YS-Tools module compatibility loader
;;; Encoding: GBK/ANSI, CRLF

(defun ysmod:root (/ p)
  (cond
    ((and (boundp '*YS-Tools-Path*) *YS-Tools-Path*) *YS-Tools-Path*)
    ((findfile "YS-Tools\\YS-Tools.lsp") (vl-filename-directory (findfile "YS-Tools\\YS-Tools.lsp")))
    ((findfile "YS-Tools.lsp") (vl-filename-directory (findfile "YS-Tools.lsp")))
    (T nil)
  )
)

(defun ysmod:project-root (/ r)
  (setq r (ysmod:root))
  (if r (vl-filename-directory r) nil)
)

(defun ysmod:load-first (files / done f)
  (setq done nil)
  (foreach f files
    (if (and (null done) f (> (strlen f) 0) (findfile f))
      (progn
        (load (findfile f) nil)
        (setq done T)
      )
    )
  )
  done
)

(defun ysmod:load-aa (/ p)
  (setq p (ysmod:project-root))
  (ysmod:load-first
    (list
      (if p (strcat p "\\AA整合版本.lsp") "")
      "E:/366256/vibecoding/CADTools/AA整合版本.lsp"
      "AA整合版本.lsp"
    )
  )
)

(defun ysmod:load-small (name / p)
  (setq p (ysmod:project-root))
  (ysmod:load-first
    (list
      (if p (strcat p "\\小命令\\" name) "")
      (strcat "E:/366256/vibecoding/CADTools/小命令/" name)
      (strcat "小命令\\" name)
      name
    )
  )
)

(ysmod:load-aa)
(princ "\n[YS-Tools] line-tools loaded from AA整合版本.lsp. Commands: YAN, SYAN, XYAN, XSUO, SSUO, SJ, XJ, LONG.")
(princ)
