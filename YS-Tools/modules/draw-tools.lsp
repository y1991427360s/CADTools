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
(defun ys:make-eff-poly (p / x y p1 p2 p3 p4 p5 p6)
  (setq x (car p))
  (setq y (cadr p))
  (setq p1 (list x y 0.0))
  (setq p2 (list (+ x 390.0) y 0.0))
  (setq p3 (list (+ x 390.0) (- y 237.0) 0.0))
  (setq p4 (list (+ x 210.0) (- y 237.0) 0.0))
  (setq p5 (list (+ x 210.0) (- y 287.0) 0.0))
  (setq p6 (list x (- y 287.0) 0.0))
  (list p1 p2 p3 p4 p5 p6)
)
(defun C:KUANG (/ pt pts)
  (vl-load-com)
  (setq pt (getpoint "\n请选择 L 形框左上角点: "))
  (if pt
    (progn
      (setq pts (ys:make-eff-poly pt))
      (command "_.PLINE" (nth 0 pts) "_non" (nth 1 pts) "_non" (nth 2 pts) "_non" (nth 3 pts) "_non" (nth 4 pts) "_non" (nth 5 pts) "_close")
      (princ "\nL 形框已绘制，尺寸为 390x237 + 210x50。")
    )
    (princ "\n已取消。")
  )
  (princ)
)
(princ "\n[YS-Tools] draw-tools loaded from AA整合版本.lsp. Commands: EXCEL, NU, KUANG.")
(princ)
