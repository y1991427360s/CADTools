;;; YS-Tools v1.5.0 module
;;; Encoding: GBK/ANSI, CRLF

(if (and (boundp '*ys-module-draw_tools-loaded*)
         *ys-module-draw_tools-loaded*)
  (princ)
  (progn
    (vl-catch-all-apply 'vl-load-com '())

    (defun c:EXCEL (/ rows cols totalWidth totalHeight startPoint
                     cellWidth cellHeight i j x1 y1 x2 y2)
      (princ "\n*** 表格绘制工具 (快捷键: EXCEL) ***")
      (initget 7) (setq rows (getint "\n请输入表格的行数: "))
      (initget 7) (setq cols (getint "\n请输入表格的列数: "))
      (initget 7) (setq totalWidth (getreal "\n请输入表格的总宽度: "))
      (initget 7) (setq totalHeight (getreal "\n请输入表格的总高度: "))
      (setq startPoint (getpoint "\n请选择表格的插入点: "))

      (setq cellWidth (/ totalWidth cols))
      (setq cellHeight (/ totalHeight rows))

      (command "_.layer" "_m" *EXCEL_LayerName* "_c" *EXCEL_LayerColor* "" "")

      (command "_.line"
               startPoint
               (list (+ (car startPoint) totalWidth) (cadr startPoint))
               (list (+ (car startPoint) totalWidth) (+ (cadr startPoint) totalHeight))
               (list (car startPoint) (+ (cadr startPoint) totalHeight))
               "_close")

      (setq i 1)
      (while (< i rows)
        (setq y1 (+ (cadr startPoint) (* i cellHeight)))
        (setq x1 (car startPoint))
        (setq x2 (+ x1 totalWidth))
        (command "_.line" (list x1 y1) (list x2 y1) "")
        (setq i (1+ i))
      )

      (setq j 1)
      (while (< j cols)
        (setq x1 (+ (car startPoint) (* j cellWidth)))
        (setq y1 (cadr startPoint))
        (setq y2 (+ y1 totalHeight))
        (command "_.line" (list x1 y1) (list x1 y2) "")
        (setq j (1+ j))
      )

      (princ (strcat "\n表格绘制完成! "
                     "行数: " (itoa rows)
                     ", 列数: " (itoa cols)))
      (princ)
    )

    (defun aa:digit-char-p (ch / code)
      (and ch
           (= (type ch) 'STR)
           (= (strlen ch) 1)
           (setq code (ascii ch))
           (<= 48 code 57))
    )

    (defun aa:nu-number-token-at (str start / len idx digit-found end)
      (setq len (strlen str)
            idx start
            digit-found nil
            end nil)
      (if (<= start len)
        (progn
          (if (member (substr str idx 1) '("+" "-"))
            (setq idx (1+ idx)))
          (while (and (<= idx len)
                      (aa:digit-char-p (substr str idx 1)))
            (setq digit-found T
                  end idx
                  idx (1+ idx)))
          (if (and (<= idx len)
                   (= (substr str idx 1) ".")
                   (< idx len)
                   (aa:digit-char-p (substr str (1+ idx) 1)))
            (progn
              (setq idx (1+ idx))
              (while (and (<= idx len)
                          (aa:digit-char-p (substr str idx 1)))
                (setq digit-found T
                      end idx
                      idx (1+ idx)))))
          (if digit-found
            (list start
                  end
                  (substr str start (1+ (- end start)))))
        )
      )
    )

    (defun aa:nu-find-first-number (str / len idx token ch)
      (setq len (strlen str)
            idx 1
            token nil)
      (while (and (<= idx len) (null token))
        (setq ch (substr str idx 1))
        (if (or (aa:digit-char-p ch)
                (and (= ch ".")
                     (< idx len)
                     (aa:digit-char-p (substr str (1+ idx) 1)))
                (and (member ch '("+" "-"))
                     (< idx len)
                     (or (aa:digit-char-p (substr str (1+ idx) 1))
                         (and (< (1+ idx) len)
                              (= (substr str (1+ idx) 1) ".")
                              (aa:digit-char-p (substr str (+ idx 2) 1))))))
          (setq token (aa:nu-number-token-at str idx))
        )
        (if (null token)
          (setq idx (1+ idx))))
      token
    )

    (defun aa:nu-trim-number-string (str)
      (if (vl-string-search "." str)
        (progn
          (while (and (> (strlen str) 0)
                      (= (substr str (strlen str) 1) "0"))
            (setq str (substr str 1 (1- (strlen str)))))
          (if (and (> (strlen str) 0)
                   (= (substr str (strlen str) 1) "."))
            (setq str (substr str 1 (1- (strlen str))))))
      )
      (if (or (= str "") (= str "-0") (= str "+0"))
        "0"
        str)
    )

    (defun aa:nu-string-all-digits-p (str / idx ok)
      (setq idx 1
            ok (> (strlen str) 0))
      (while (and ok (<= idx (strlen str)))
        (if (not (aa:digit-char-p (substr str idx 1)))
          (setq ok nil))
        (setq idx (1+ idx)))
      ok
    )

    (defun aa:nu-format-number (value old-token / raw body keep-plus pad-width abs-str)
      (setq raw (aa:nu-trim-number-string (rtos value 2 8))
            body old-token
            keep-plus nil
            pad-width 0)
      (if (> (strlen body) 0)
        (cond
          ((= (substr body 1 1) "+")
           (setq keep-plus T
                 body (substr body 2)))
          ((= (substr body 1 1) "-")
           (setq body (substr body 2)))
        )
      )
      (if (and (= value (fix value))
               (> (strlen body) 1)
               (= (substr body 1 1) "0")
               (aa:nu-string-all-digits-p body))
        (progn
          (setq pad-width (strlen body)
                abs-str (itoa (abs (fix value))))
          (while (< (strlen abs-str) pad-width)
            (setq abs-str (strcat "0" abs-str)))
          (setq raw
                 (strcat
                   (cond
                     ((< value 0) "-")
                     ((and keep-plus (>= value 0)) "+")
                     (T ""))
                   abs-str)))
        (if (and keep-plus
                 (>= value 0)
                 (/= raw ""))
          (setq raw (strcat "+" raw))))
      raw
    )

    (defun aa:nu-rewrite-text (str delta / token start end old-val new-str)
      (if (setq token (aa:nu-find-first-number str))
        (progn
          (setq start   (car token)
                end     (cadr token)
                old-val (distof (caddr token)))
          (if (numberp old-val)
            (progn
              (setq new-str (aa:nu-format-number (- old-val delta) (caddr token)))
              (strcat
                (if (> start 1)
                  (substr str 1 (1- start))
                  "")
                new-str
                (if (< end (strlen str))
                  (substr str (1+ end))
                  "")))
          )
        )
      )
    )

    (defun c:NU (/ *error* doc undo-open ss a i en ed str new-str changed)
      (vl-load-com)
      (setq doc (vla-get-ActiveDocument (vlax-get-acad-object))
            undo-open nil)

      (defun *error* (msg)
        (if undo-open
          (vl-catch-all-apply 'vla-EndUndoMark (list doc)))
        (if (and msg
                 (not (wcmatch (strcase msg) "*BREAK*,*CANCEL*,*EXIT*,*QUIT*")))
          (princ (strcat "\n[NU] Error: " msg)))
        (princ)
      )

      (if (null (setq a (getreal "\n[NU] Enter value to subtract: ")))
        (princ "\n[NU] No value entered.")
        (progn
          (princ "\n[NU] Select TEXT/MTEXT objects: ")
          (if (setq ss (ssget '((0 . "TEXT,MTEXT"))))
            (progn
              (setq i 0
                    changed 0)
              (vla-StartUndoMark doc)
              (setq undo-open T)
              (repeat (sslength ss)
                (setq en (ssname ss i)
                      ed (entget en)
                      str (cdr (assoc 1 ed))
                      new-str (if str (aa:nu-rewrite-text str a)))
                (if (and new-str (/= new-str str))
                  (progn
                    (setq ed (subst (cons 1 new-str) (assoc 1 ed) ed))
                    (if (entmod ed)
                      (setq changed (1+ changed)))))
                (setq i (1+ i)))
              (vla-EndUndoMark doc)
              (setq undo-open nil)
              (princ (strcat "\n[NU] Updated " (itoa changed) " text object(s)."))
            )
            (princ "\n[NU] No text objects selected.")
          )
        )
      )
      (princ)
    )

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
      (setq pt (getpoint "\nPick upper-left point for L frame: "))
      (if pt
        (progn
          (setq pts (ys:make-eff-poly pt))
          (command "_.PLINE"
                   (nth 0 pts) "_non"
                   (nth 1 pts) "_non"
                   (nth 2 pts) "_non"
                   (nth 3 pts) "_non"
                   (nth 4 pts) "_non"
                   (nth 5 pts) "_close")
          (princ "\nL frame created. Size: 390x237 + 210x50.")
        )
        (princ "\nCanceled.")
      )
      (princ)
    )

    (setq *ys-module-draw_tools-loaded* T)
    (princ "\n[YS-Tools] draw-tools.lsp loaded.")
  )
)
(princ)
