;;; YS-Tools v1.5.0 module
;;; Encoding: GBK/ANSI, CRLF

(if (and (boundp '*ys-module-utils-loaded*)
         *ys-module-utils-loaded*)
  (princ)
  (progn
    (vl-catch-all-apply 'vl-load-com '())

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

    (setq *ys-module-utils-loaded* T)
    (princ "\n[YS-Tools] utils.lsp loaded.")
  )
)
(princ)
