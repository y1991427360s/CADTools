;;; 自动目录 ZDML - Extract title-block attributes into a drawing list.
;;; Encoding: GBK/ANSI, CRLF

(vl-load-com)

(if (not (boundp '*TKTJ-COL-OFFSETS*))      (setq *TKTJ-COL-OFFSETS* '(0.0 7.5 57.5)))
(if (not (boundp '*TKTJ-ROW-GAP*))          (setq *TKTJ-ROW-GAP* 9.0))
(if (not (boundp '*TKTJ-TEXT-HEIGHT*))      (setq *TKTJ-TEXT-HEIGHT* 4.0))
(if (not (boundp '*TKTJ-TEXT-STYLE*))       (setq *TKTJ-TEXT-STYLE* "宋体"))
(if (not (boundp '*TKTJ-TEXT-FONTFILE*))    (setq *TKTJ-TEXT-FONTFILE* "simsun.ttc"))
(if (not (boundp '*TKTJ-TEXT-WIDTH-FACTOR*)) (setq *TKTJ-TEXT-WIDTH-FACTOR* 0.8))
(if (not (boundp '*TKTJ-OUTPUT-HEADER*))    (setq *TKTJ-OUTPUT-HEADER* T))
(if (not (boundp '*TKTJ-SORT-BY-POSITION*)) (setq *TKTJ-SORT-BY-POSITION* T))
(if (not (boundp '*TKTJ-ROW-SORT-TOL*))     (setq *TKTJ-ROW-SORT-TOL* 5.0))
(if (not (boundp '*TKTJ-SORT-BY-PAGE*))     (setq *TKTJ-SORT-BY-PAGE* nil))
(if (not (boundp '*TKTJ-SHEETNO-TAGS*))     (setq *TKTJ-SHEETNO-TAGS* '("图号" "图纸编号" "DRAWINGNO" "DWGNO")))
(if (not (boundp '*TKTJ-SHEETNAME-TAGS*))   (setq *TKTJ-SHEETNAME-TAGS* '("图名" "图纸名称" "SHEETNAME" "DRAWINGNAME")))
(if (not (boundp '*TKTJ-PAGE-TAGS*))        (setq *TKTJ-PAGE-TAGS* '("页码" "页号" "PAGE" "SHEET")))
(if (not (boundp '*TKTJ-ARCHIVE-TAGS*))     (setq *TKTJ-ARCHIVE-TAGS* '("档案号" "工程号" "设计号" "DWGNO" "DRAWINGNO")))

(defun tktj:trim (s)
  (if s
    (vl-string-trim " \t\r\n" (vl-princ-to-string s))
    ""
  )
)

(defun tktj:norm-tag (s)
  (strcase (tktj:trim s))
)

(defun tktj:current-space (/ doc)
  (setq doc (vla-get-ActiveDocument (vlax-get-acad-object)))
  (cond
    ((= 1 (getvar "TILEMODE")) (vla-get-ModelSpace doc))
    ((= 1 (getvar "CVPORT")) (vla-get-PaperSpace doc))
    (T (vla-get-ModelSpace doc))
  )
)

(defun tktj:ensure-text-style (/ doc styles style)
  (setq doc (vla-get-ActiveDocument (vlax-get-acad-object)))
  (setq styles (vla-get-TextStyles doc))
  (setq style (vl-catch-all-apply 'vla-Item (list styles *TKTJ-TEXT-STYLE*)))
  (if (vl-catch-all-error-p style)
    (setq style (vl-catch-all-apply 'vla-Add (list styles *TKTJ-TEXT-STYLE*)))
  )
  (if (not (vl-catch-all-error-p style))
    (progn
      (vl-catch-all-apply 'vla-put-FontFile (list style *TKTJ-TEXT-FONTFILE*))
      (vl-catch-all-apply 'vla-put-Width (list style *TKTJ-TEXT-WIDTH-FACTOR*))
      *TKTJ-TEXT-STYLE*
    )
    (getvar "TEXTSTYLE")
  )
)

(defun tktj:safe-getattributes (blk / r)
  (setq r (vl-catch-all-apply 'vlax-invoke (list blk 'GetAttributes)))
  (if (vl-catch-all-error-p r) nil r)
)

(defun tktj:assoc-data (key data)
  (cdr (assoc key data))
)

(defun tktj:block-point (blockObj / p)
  (setq p (vlax-safearray->list (vlax-variant-value (vla-get-InsertionPoint blockObj))))
  (list (car p) (cadr p) (if (caddr p) (caddr p) 0.0))
)

(defun tktj:all-digits-p (s)
  (and (> (strlen s) 0)
       (not (wcmatch s "*[~0-9]*")))
)

(defun tktj:page-number (s / n)
  (setq s (tktj:trim s))
  (if (tktj:all-digits-p s)
    (atoi s)
    2147483647
  )
)

(defun tktj:get-attributes (blockObj / atts att tag val result)
  (setq result nil)
  (if (= :vlax-true (vla-get-HasAttributes blockObj))
    (progn
      (setq atts (tktj:safe-getattributes blockObj))
      (foreach att atts
        (setq tag (tktj:trim (vla-get-TagString att)))
        (setq val (tktj:trim (vla-get-TextString att)))
        (if (> (strlen tag) 0)
          (setq result (append result (list (cons tag val))))
        )
      )
    )
  )
  result
)

(defun tktj:get-first-pair (attrs candidates skipTags / cand found pair tag val)
  (setq found nil)
  (foreach cand candidates
    (if (not found)
      (foreach pair attrs
        (if (not found)
          (progn
            (setq tag (car pair))
            (setq val (tktj:trim (cdr pair)))
            (if (and (> (strlen val) 0)
                     (= (tktj:norm-tag tag) (tktj:norm-tag cand))
                     (not (member (tktj:norm-tag tag) skipTags)))
              (setq found (cons tag val))
            )
          )
        )
      )
    )
  )
  found
)

(defun tktj:get-first-value (attrs candidates / pair)
  (setq pair (tktj:get-first-pair attrs candidates nil))
  (if pair (cdr pair) "")
)

(defun tktj:collect-one-block (blockObj / attrs namePair noPair page archive insPt)
  (setq attrs (tktj:get-attributes blockObj))
  (if attrs
    (progn
      (setq insPt (tktj:block-point blockObj))
      (setq namePair (tktj:get-first-pair attrs *TKTJ-SHEETNAME-TAGS* nil))
      (setq noPair (tktj:get-first-pair attrs *TKTJ-SHEETNO-TAGS* nil))
      (setq page (tktj:get-first-value attrs *TKTJ-PAGE-TAGS*))
      (setq archive (tktj:get-first-value attrs *TKTJ-ARCHIVE-TAGS*))
      (if (and noPair namePair)
        (list
          (cons 'sheetNo (cdr noPair))
          (cons 'sheetName (cdr namePair))
          (cons 'page page)
          (cons 'archive archive)
          (cons 'x (car insPt))
          (cons 'y (cadr insPt))
        )
        nil
      )
    )
    nil
  )
)

(defun tktj:add-text (pt txt / obj)
  (setq obj
        (vla-AddText
          (tktj:current-space)
          (if txt (vl-princ-to-string txt) "")
          (vlax-3d-point pt)
          *TKTJ-TEXT-HEIGHT*
        )
  )
  (vla-put-Layer obj (getvar "CLAYER"))
  (vla-put-StyleName obj (tktj:ensure-text-style))
  (vl-catch-all-apply 'vla-put-Alignment (list obj 0))
  (vl-catch-all-apply 'vla-put-ScaleFactor (list obj *TKTJ-TEXT-WIDTH-FACTOR*))
  obj
)

(defun tktj:nth-offset (n offsets / rest)
  (setq rest offsets)
  (while (and (> n 0) rest)
    (setq rest (cdr rest))
    (setq n (1- n))
  )
  (if rest (car rest) 0.0)
)

(defun tktj:draw-row (base rowIndex values / x y col pt)
  (setq y (- (cadr base) (* rowIndex *TKTJ-ROW-GAP*)))
  (setq col 0)
  (foreach txt values
    (setq x (+ (car base) (tktj:nth-offset col *TKTJ-COL-OFFSETS*)))
    (setq pt (list x y (if (caddr base) (caddr base) 0.0)))
    (tktj:add-text pt txt)
    (setq col (1+ col))
  )
)

(defun tktj:draw-table (dataList basePt / rowIndex item values)
  (setq rowIndex 0)
  (if *TKTJ-OUTPUT-HEADER*
    (progn
      (tktj:draw-row basePt rowIndex '("序号" "图号" "图名"))
      (setq rowIndex (1+ rowIndex))
    )
  )
  (foreach item dataList
    (setq values
           (list
             (itoa (1+ (- rowIndex (if *TKTJ-OUTPUT-HEADER* 1 0))))
             (tktj:assoc-data 'sheetNo item)
             (tktj:assoc-data 'sheetName item)
           )
    )
    (tktj:draw-row basePt rowIndex values)
    (setq rowIndex (1+ rowIndex))
  )
  dataList
)

(defun tktj:sort-by-page (dataList)
  (vl-sort dataList
    '(lambda (a b)
       (< (tktj:page-number (tktj:assoc-data 'page a))
          (tktj:page-number (tktj:assoc-data 'page b)))
     )
  )
)

(defun tktj:sort-by-position (dataList)
  (vl-sort dataList
    '(lambda (a b / ax ay bx by)
       (setq ax (tktj:assoc-data 'x a))
       (setq ay (tktj:assoc-data 'y a))
       (setq bx (tktj:assoc-data 'x b))
       (setq by (tktj:assoc-data 'y b))
       (if (<= (abs (- ay by)) *TKTJ-ROW-SORT-TOL*)
         (< ax bx)
         (> ay by)
       )
     )
  )
)

(defun C:ZDML (/ ss i ent obj one data basePt)
  (vl-load-com)
  (princ "\n请选择要统计的图框块: ")
  (setq ss (ssget '((0 . "INSERT"))))
  (cond
    ((not ss)
     (princ "\n未选择对象。"))
    (T
     (setq i 0)
     (setq data nil)
     (while (< i (sslength ss))
       (setq ent (ssname ss i))
       (setq obj (vlax-ename->vla-object ent))
       (setq one (tktj:collect-one-block obj))
       (if one
         (setq data (append data (list one)))
       )
       (setq i (1+ i))
     )
     (if (not data)
       (princ "\n未找到有效的图号/图名属性。")
       (progn
         (cond
           (*TKTJ-SORT-BY-PAGE*
            (setq data (tktj:sort-by-page data)))
           (*TKTJ-SORT-BY-POSITION*
            (setq data (tktj:sort-by-position data)))
         )
         (setq basePt (getpoint "\n请选择目录插入点: "))
         (if basePt
           (progn
             (tktj:draw-table data basePt)
             (princ (strcat "\n已生成 " (itoa (length data)) " 条目录记录。"))
           )
           (princ "\n已取消。")
         )
       )
     )
    )
  )
  (princ)
)

(defun C:ZDMLDEBUG (/ ent obj attrs pair)
  (vl-load-com)
  (setq ent (car (entsel "\n请选择一个图框块: ")))
  (cond
    ((not ent)
     (princ "\n未选择对象。"))
    ((/= "INSERT" (cdr (assoc 0 (entget ent))))
     (princ "\n选择的对象不是块。"))
    (T
     (setq obj (vlax-ename->vla-object ent))
     (setq attrs (tktj:get-attributes obj))
     (if attrs
       (progn
         (princ "\n块属性如下:")
         (foreach pair attrs
           (princ (strcat "\n标记: " (car pair) "  值: " (cdr pair)))
         )
       )
       (princ "\n没有找到块属性。")
     )
    )
  )
  (princ)
)

(princ "\nZDML loaded. Commands: ZDML, ZDMLDEBUG.")
(princ)
