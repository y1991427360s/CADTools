;;; ====================================================================
;;; YS-Tools - ??????????
;;; ????: EXCEL(????) NU(?????) KUANG(???)
;;; ====================================================================

;;; --- EXCEL ???? ---
(defun c:EXCEL (/ *error* oldCmdEcho oldOsMode rows cols totalWidth totalHeight startPoint
                 cellWidth cellHeight i j x1 y1 x2 y2)
  (defun *error* (msg)
    (if oldCmdEcho (setvar "CMDECHO" oldCmdEcho))
    (if oldOsMode (setvar "OSMODE" oldOsMode))
    (if (and msg
             (not (wcmatch (strcase msg) "*BREAK*,*CANCEL*,*EXIT*,*QUIT*")))
      (princ (strcat "\n[EXCEL] Error: " msg))
    )
    (princ)
  )
  (setq oldCmdEcho (getvar "CMDECHO")
        oldOsMode (getvar "OSMODE"))
  (setvar "CMDECHO" 0)
  (setvar "OSMODE" 0)
  (princ "\n*** ?????????? (????: EXCEL) ***")
  (initget 7) (setq rows (getint "\n??????????????: "))
  (initget 7) (setq cols (getint "\n??????????????: "))
  (initget 7) (setq totalWidth (getreal "\n???????????????: "))
  (initget 7) (setq totalHeight (getreal "\n??????????????: "))
  (setq startPoint (getpoint "\n?????????????: "))
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
  (setvar "CMDECHO" oldCmdEcho)
  (setvar "OSMODE" oldOsMode)
  (princ (strcat "\n???????! ????: "
                 (itoa rows)
                 ", ????: " (itoa cols)))
  (princ)
)

;;; --- NU ????? (??undo????·Ú) ---
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
  (if (null (setq a (getreal "\n[NU] ???????????????: ")))
    (princ "\n[NU] ¦Ä?????????")
    (progn
      (princ "\n[NU] ??????????????????: ")
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
          (princ (strcat "\n[NU] ????? " (itoa changed) " ?????????"))
        )
        (princ "\n[NU] ¦Ä????¦Ê????????")
      )
    )
  )
  (princ)
)

;;; --- KUANG ??? (L????????) ---
(defun ys:pt (x y)
  (list x y 0.0)
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

;;; Local utility: convert selection set to list of entity names
(defun ys-ss->list (ss / i lst)
  (setq lst '())
  (if ss
    (progn
      (setq i 0)
      (while (< i (sslength ss))
        (setq lst (cons (ssname ss i) lst))
        (setq i (1+ i))
      )
    )
  )
  lst
)

(defun c:KUANG (/ pt pts)
  (vl-load-com)
  (setq pt (getpoint "\n?????L???????????????: "))
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
      (princ "\nL??????????? (390x237+210x50)??")
    )
    (princ "\n???????")
  )
  (princ)
)

(princ "\n[YS-Tools] draw-tools.lsp loaded.")
(princ)
