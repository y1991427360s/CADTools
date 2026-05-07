;;; YS-Tools shared utility functions
;;; Encoding: GBK/ANSI, CRLF

(defun ys:ss->list (ss / i out)
  (setq out '())
  (if ss
    (progn
      (setq i 0)
      (while (< i (sslength ss))
        (setq out (cons (ssname ss i) out))
        (setq i (1+ i))
      )
    )
  )
  (reverse out)
)

(defun ys:safe-getvar (name / result)
  (setq result (vl-catch-all-apply 'getvar (list name)))
  (if (vl-catch-all-error-p result) nil result)
)

(defun ys:try-get-bbox (obj / minPt maxPt result)
  (setq result (vl-catch-all-apply 'vla-getBoundingBox (list obj 'minPt 'maxPt)))
  (if (vl-catch-all-error-p result)
    nil
    (list (vlax-safearray->list minPt) (vlax-safearray->list maxPt))
  )
)

(defun ys:dxf (code ed default / pair)
  (setq pair (assoc code ed))
  (if pair (cdr pair) default)
)

(defun ys:ensure-vl ()
  (vl-load-com)
  T
)

(princ "\n[YS-Tools] utils.lsp loaded.")
(princ)
