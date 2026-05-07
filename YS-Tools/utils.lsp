;;; ====================================================================
;;; YS-Tools - ?????????????
;;; ??????ûs???????????? aa:* ???????
;;; ====================================================================

;;; --- Bbox ???? ---

(defun aa:try-get-bbox (vla_obj / min_pt max_pt result)
  (setq result
         (vl-catch-all-apply
           'vla-getboundingbox
           (list vla_obj 'min_pt 'max_pt)))
  (if (not (vl-catch-all-error-p result))
    (list (vlax-safearray->list min_pt)
          (vlax-safearray->list max_pt))
  )
)

(defun aa:safe-get-bbox (doc ename / vla_obj bbox)
  (if (and ename
           (setq vla_obj (vlax-ename->vla-object ename)))
    (progn
      (setq bbox (aa:try-get-bbox vla_obj))
      (if (null bbox)
        (progn
          (vl-catch-all-apply 'vla-update (list vla_obj))
          (entupd ename)
          (setq bbox (aa:try-get-bbox vla_obj))
        )
      )
      (if (and (null bbox) doc)
        (progn
          (vl-catch-all-apply 'vla-regen (list doc 0))
          (setq bbox (aa:try-get-bbox vla_obj))
        )
      )
      bbox
    )
  )
)

(defun aa:bbox-center-x (bbox)
  (/ (+ (car (car bbox))
        (car (cadr bbox)))
     2.0)
)

(defun aa:bbox-left-x (bbox)
  (car (car bbox))
)

(defun aa:bbox-right-x (bbox)
  (car (cadr bbox))
)

(defun aa:bbox-top-y (bbox)
  (cadr (cadr bbox))
)

(defun aa:bbox-bottom-y (bbox)
  (cadr (car bbox))
)

;;; --- ?????? ---

(defun aa:safe-move-entity (ename move_vec / vla_obj result)
  (if (and ename
           move_vec
           (setq vla_obj (vlax-ename->vla-object ename)))
    (progn
      (setq result
             (vl-catch-all-apply
               'vla-move
               (list vla_obj
                     (vlax-3d-point '(0.0 0.0 0.0))
                     move_vec)))
      (if (not (vl-catch-all-error-p result))
        (progn
          (entupd ename)
          T
        )
        nil
      )
    )
  )
)

(defun aa:find-ref-by-left-bbox (doc ss / i ename bbox ref-ename ref-bbox)
  (setq i         0
        ref-ename nil
        ref-bbox  nil)
  (repeat (sslength ss)
    (setq ename (ssname ss i)
          bbox  (aa:safe-get-bbox doc ename))
    (if bbox
      (if (or (null ref-bbox)
              (< (aa:bbox-left-x bbox)
                 (aa:bbox-left-x ref-bbox)))
        (setq ref-ename ename
              ref-bbox  bbox))
    )
    (setq i (1+ i))
  )
  (if ref-bbox
    (list ref-ename ref-bbox))
)

(defun aa:find-ref-by-top-bbox (doc ss / i ename bbox ref-ename ref-bbox)
  (setq i         0
        ref-ename nil
        ref-bbox  nil)
  (repeat (sslength ss)
    (setq ename (ssname ss i)
          bbox  (aa:safe-get-bbox doc ename))
    (if bbox
      (if (or (null ref-bbox)
              (> (aa:bbox-top-y bbox)
                 (aa:bbox-top-y ref-bbox)))
        (setq ref-ename ename
              ref-bbox  bbox))
    )
    (setq i (1+ i))
  )
  (if ref-bbox
    (list ref-ename ref-bbox))
)

(defun aa:align-text-horizontal-by-bbox (doc ename base-x mode / bbox current-x delta-x)
  (if (setq bbox (aa:safe-get-bbox doc ename))
    (progn
      (setq current-x (if (= mode 3)
                        (aa:bbox-right-x bbox)
                        (aa:bbox-left-x bbox))
            delta-x   (- base-x current-x))
      (if (equal delta-x 0.0 1e-8)
        T
        (aa:safe-move-entity ename (vlax-3d-point (list delta-x 0.0 0.0)))))
  )
)

(defun aa:align-text-vertical-by-bbox (doc ename base-y mode / bbox current-y delta-y)
  (if (setq bbox (aa:safe-get-bbox doc ename))
    (progn
      (setq current-y (if (= mode 1)
                        (aa:bbox-top-y bbox)
                        (aa:bbox-bottom-y bbox))
            delta-y   (- base-y current-y))
      (if (equal delta-y 0.0 1e-8)
        T
        (aa:safe-move-entity ename (vlax-3d-point (list 0.0 delta-y 0.0)))))
  )
)

;;; --- ????????? ---

(defun aa:str-replace-all (old new str / start pos result old-len)
  (setq str     (if str str "")
        start   0
        result  ""
        old-len (strlen old))
  (if (= old-len 0)
    str
    (progn
      (while (setq pos (vl-string-search old str start))
        (setq result
               (strcat
                 result
                 (if (> pos start)
                   (substr str (1+ start) (- pos start))
                   "")
                 new)
              start (+ pos old-len))
      )
      (strcat result (substr str (1+ start)))
    )
  )
)

;;; --- DXF/????¨º????? ---

(defun aa:get-dxf-point (ed code / v y z)
  (setq v (if (assoc code ed) (cdr (assoc code ed)) nil)
        y (if (assoc (+ code 10) ed) (cdr (assoc (+ code 10) ed)) 0.0)
        z (if (assoc (+ code 20) ed) (cdr (assoc (+ code 20) ed)) 0.0))
  (cond
    ((listp v)
     (list (float (car v))
           (float (cadr v))
           (float (if (caddr v) (caddr v) 0.0))))
    ((numberp v)
     (list (float v)
           (float y)
           (float z)))
  )
)

(defun aa:set-dxf-int (ed code value / row)
  (setq row (assoc code ed))
  (if row
    (subst (cons code value) row ed)
    (append ed (list (cons code value))))
)

(defun aa:set-dxf-point (ed code pt / row)
  (setq row (assoc code ed))
  (if row
    (subst (list code (car pt) (cadr pt) (caddr pt)) row ed)
    (append ed (list (list code (car pt) (cadr pt) (caddr pt)))))
)

(defun aa:text-anchor-point (ed / typ h v)
  (setq typ (cdr (assoc 0 ed)))
  (cond
    ((= typ "TEXT")
     (setq h (if (assoc 72 ed) (cdr (assoc 72 ed)) 0)
           v (if (assoc 73 ed) (cdr (assoc 73 ed)) 0))
     (if (or (/= h 0) (/= v 0))
       (or (aa:get-dxf-point ed 11)
           (aa:get-dxf-point ed 10))
       (aa:get-dxf-point ed 10)))
    ((= typ "MTEXT")
     (aa:get-dxf-point ed 10))
  )
)

(defun aa:mtext-center-attachment (ap)
  (cond
    ((member ap '(1 2 3)) 2)
    ((member ap '(4 5 6)) 5)
    ((member ap '(7 8 9)) 8)
    (T 5))
)

(defun aa:center-text-by-anchor (ename base-x / ed typ pt v ap new-pt ok)
  (setq ed  (entget ename)
        typ (if ed (cdr (assoc 0 ed)) nil)
        pt  (aa:text-anchor-point ed))
  (if (and ed pt)
    (progn
      (setq new-pt (list base-x (cadr pt) (caddr pt)))
      (cond
        ((= typ "TEXT")
         (setq v  (if (assoc 73 ed) (cdr (assoc 73 ed)) 0)
               ed (aa:set-dxf-int ed 72 1)
               ed (aa:set-dxf-int ed 73 v)
               ed (aa:set-dxf-point ed 10 new-pt)
               ed (aa:set-dxf-point ed 11 new-pt)))
        ((= typ "MTEXT")
         (setq ap (if (assoc 71 ed) (cdr (assoc 71 ed)) 1)
               ed (aa:set-dxf-int ed 71 (aa:mtext-center-attachment ap))
               ed (aa:set-dxf-point ed 10 new-pt)))
      )
      (setq ok (entmod ed))
      (if ok
        (progn
          (entupd ename)
          T)
        nil))
    nil)
)

(defun aa:text-raw-v (ed)
  (if (assoc 73 ed) (cdr (assoc 73 ed)) 0)
)

(defun aa:text-normalized-h (ed / h)
  (setq h (if (assoc 72 ed) (cdr (assoc 72 ed)) 0))
  (cond
    ((= h 2) 2)
    ((member h '(1 4)) 1)
    (T 0))
)

(defun aa:mtext-h-tier (ap)
  (+ 1 (rem (max 0 (1- ap)) 3))
)

(defun aa:mtext-v-tier (ap)
  (+ 1 (fix (/ (max 0 (1- ap)) 3)))
)

(defun aa:mtext-attachment (h-tier v-tier)
  (+ h-tier (* (1- v-tier) 3))
)

(defun aa:set-text-horizontal-align (ename base-x mode / ed typ pt v ap vtier new-pt ok)
  (setq ed  (entget ename)
        typ (if ed (cdr (assoc 0 ed)) nil)
        pt  (aa:text-anchor-point ed))
  (if (and ed pt)
    (progn
      (setq new-pt (list base-x (cadr pt) (caddr pt)))
      (cond
        ((= typ "TEXT")
         (setq v  (aa:text-raw-v ed)
               ed (aa:set-dxf-int ed 72
                                  (cond
                                    ((= mode 3) 2)
                                    ((= mode 2) 1)
                                    (T 0)))
               ed (aa:set-dxf-int ed 73 v)
               ed (aa:set-dxf-point ed 10 new-pt)
               ed (aa:set-dxf-point ed 11 new-pt)))
        ((= typ "MTEXT")
         (setq ap    (if (assoc 71 ed) (cdr (assoc 71 ed)) 1)
               vtier (aa:mtext-v-tier ap)
               ed    (aa:set-dxf-int ed 71 (aa:mtext-attachment mode vtier))
               ed    (aa:set-dxf-point ed 10 new-pt)))
      )
      (setq ok (entmod ed))
      (if ok
        (progn
          (entupd ename)
          T)
        nil))
    nil)
)

(defun aa:set-text-vertical-align (ename base-y mode / ed typ pt h ap htier new-pt ok)
  (setq ed  (entget ename)
        typ (if ed (cdr (assoc 0 ed)) nil)
        pt  (aa:text-anchor-point ed))
  (if (and ed pt)
    (progn
      (setq new-pt (list (car pt) base-y (caddr pt)))
      (cond
        ((= typ "TEXT")
         (setq h  (aa:text-normalized-h ed)
               ed (aa:set-dxf-int ed 72 h)
               ed (aa:set-dxf-int ed 73
                                  (cond
                                    ((= mode 1) 3)
                                    ((= mode 2) 2)
                                    (T 1)))
               ed (aa:set-dxf-point ed 10 new-pt)
               ed (aa:set-dxf-point ed 11 new-pt)))
        ((= typ "MTEXT")
         (setq ap    (if (assoc 71 ed) (cdr (assoc 71 ed)) 1)
               htier (aa:mtext-h-tier ap)
               ed    (aa:set-dxf-int ed 71 (aa:mtext-attachment htier mode))
               ed    (aa:set-dxf-point ed 10 new-pt)))
      )
      (setq ok (entmod ed))
      (if ok
        (progn
          (entupd ename)
          T)
        nil))
    nil)
)

(defun aa:find-ref-by-top-anchor (ss / i ename ed pt ref-ename ref-pt)
  (setq i 0
        ref-ename nil
        ref-pt nil)
  (repeat (sslength ss)
    (setq ename (ssname ss i)
          ed    (entget ename)
          pt    (aa:text-anchor-point ed))
    (if pt
      (if (or (null ref-pt)
              (> (cadr pt) (cadr ref-pt)))
        (setq ref-ename ename
              ref-pt    pt))
    )
    (setq i (1+ i))
  )
  (if ref-pt
    (list ref-ename ref-pt))
)

(defun aa:find-ref-by-left-anchor (ss / i ename ed pt ref-ename ref-pt)
  (setq i 0
        ref-ename nil
        ref-pt nil)
  (repeat (sslength ss)
    (setq ename (ssname ss i)
          ed    (entget ename)
          pt    (aa:text-anchor-point ed))
    (if pt
      (if (or (null ref-pt)
              (< (car pt) (car ref-pt)))
        (setq ref-ename ename
              ref-pt    pt))
    )
    (setq i (1+ i))
  )
  (if ref-pt
    (list ref-ename ref-pt))
)

(princ "\n[YS-Tools] utils.lsp loaded.")
(princ)
