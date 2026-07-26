;;; YS-Tools v1.5.0 module
;;; Encoding: GBK/ANSI, CRLF

(if (and (boundp '*ys-module-align_tools-loaded*)
         *ys-module-align_tools-loaded*)
  (princ)
  (progn
    (vl-catch-all-apply 'vl-load-com '())

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

    (defun c:ZHONG (/ *error* ss doc undo-open i ename ed pt top-ename top-pt base-x changed skipped)
      (vl-load-com)
      (setq doc       (vla-get-activedocument (vlax-get-acad-object))
            undo-open nil
            top-ename nil
            top-pt    nil
            changed   0
            skipped   0)

      (defun *error* (msg)
        (if undo-open
          (vl-catch-all-apply 'vla-endundomark (list doc))
        )
        (if (and msg
                 (/= msg "Function cancelled")
                 (/= msg "quit / exit abort"))
          (princ (strcat "\n[ZHONG] Error: " msg))
        )
        (princ)
      )

      (princ "\n[ZHONG] Select text objects to center align...")
      (if (setq ss (ssget '((0 . "TEXT,MTEXT"))))
        (progn
          (setq i 0)
          (repeat (sslength ss)
            (setq ename (ssname ss i)
                  ed    (entget ename)
                  pt    (aa:text-anchor-point ed))
            (if pt
              (if (or (null top-pt)
                      (> (cadr pt) (cadr top-pt)))
                (setq top-ename ename
                      top-pt    pt))
              (setq skipped (1+ skipped))
            )
            (setq i (1+ i))
          )

          (if top-pt
            (progn
              (setq base-x (car top-pt))
              (vla-startundomark doc)
              (setq undo-open T
                    i         0)
              (repeat (sslength ss)
                (setq ename (ssname ss i))
                (if (eq ename top-ename)
                  nil
                  (if (aa:center-text-by-anchor ename base-x)
                    (setq changed (1+ changed))
                    (setq skipped (1+ skipped))
                  )
                )
                (setq i (1+ i))
              )
              (vla-endundomark doc)
              (setq undo-open nil)
              (princ
                (strcat
                  "\n[ZHONG] Done. Base X: "
                  (rtos base-x 2 4)
                  ", changed: "
                  (itoa changed)
                  ", skipped: "
                  (itoa skipped)
                  "."))
            )
            (princ "\n[ZHONG] No valid text anchor found in selection.")
          )
        )
        (princ "\n[ZHONG] No text objects selected.")
      )
      (princ)
    )

    (defun c:ZUO (/ *error* ss doc undo-open ref i ename base-x changed skipped)
      (vl-load-com)
      (setq doc       (vla-get-activedocument (vlax-get-acad-object))
            undo-open nil
            changed   0
            skipped   0)

      (defun *error* (msg)
        (if undo-open
          (vl-catch-all-apply 'vla-endundomark (list doc))
        )
        (if (and msg
                 (/= msg "Function cancelled")
                 (/= msg "quit / exit abort"))
          (princ (strcat "\n[ZUO] Error: " msg))
        )
        (princ)
      )

      (princ "\n[ZUO] Select text objects to left align...")
      (if (setq ss (ssget '((0 . "TEXT,MTEXT"))))
        (if (setq ref (aa:find-ref-by-top-bbox doc ss))
          (progn
            (setq base-x (aa:bbox-left-x (cadr ref)))
            (vla-startundomark doc)
            (setq undo-open T
                  i         0)
            (repeat (sslength ss)
              (setq ename (ssname ss i))
              (if (eq ename (car ref))
                nil
                (if (aa:align-text-horizontal-by-bbox doc ename base-x 1)
                  (setq changed (1+ changed))
                  (setq skipped (1+ skipped))
                )
              )
              (setq i (1+ i))
            )
            (vla-endundomark doc)
            (setq undo-open nil)
            (princ
              (strcat
                "\n[ZUO] Done. Base X: "
                (rtos base-x 2 4)
                ", changed: "
                (itoa changed)
                ", skipped: "
                (itoa skipped)
                "."))
          )
          (princ "\n[ZUO] No valid text extents found in selection.")
        )
        (princ "\n[ZUO] No text objects selected.")
      )
      (princ)
    )

    (defun c:YOU (/ *error* ss doc undo-open ref i ename base-x changed skipped)
      (vl-load-com)
      (setq doc       (vla-get-activedocument (vlax-get-acad-object))
            undo-open nil
            changed   0
            skipped   0)

      (defun *error* (msg)
        (if undo-open
          (vl-catch-all-apply 'vla-endundomark (list doc))
        )
        (if (and msg
                 (/= msg "Function cancelled")
                 (/= msg "quit / exit abort"))
          (princ (strcat "\n[YOU] Error: " msg))
        )
        (princ)
      )

      (princ "\n[YOU] Select text objects to right align...")
      (if (setq ss (ssget '((0 . "TEXT,MTEXT"))))
        (if (setq ref (aa:find-ref-by-top-bbox doc ss))
          (progn
            (setq base-x (aa:bbox-right-x (cadr ref)))
            (vla-startundomark doc)
            (setq undo-open T
                  i         0)
            (repeat (sslength ss)
              (setq ename (ssname ss i))
              (if (eq ename (car ref))
                nil
                (if (aa:align-text-horizontal-by-bbox doc ename base-x 3)
                  (setq changed (1+ changed))
                  (setq skipped (1+ skipped))
                )
              )
              (setq i (1+ i))
            )
            (vla-endundomark doc)
            (setq undo-open nil)
            (princ
              (strcat
                "\n[YOU] Done. Base X: "
                (rtos base-x 2 4)
                ", changed: "
                (itoa changed)
                ", skipped: "
                (itoa skipped)
                "."))
          )
          (princ "\n[YOU] No valid text extents found in selection.")
        )
        (princ "\n[YOU] No text objects selected.")
      )
      (princ)
    )

    (defun c:SHANG (/ *error* ss doc undo-open ref i ename base-y changed skipped)
      (vl-load-com)
      (setq doc       (vla-get-activedocument (vlax-get-acad-object))
            undo-open nil
            changed   0
            skipped   0)

      (defun *error* (msg)
        (if undo-open
          (vl-catch-all-apply 'vla-endundomark (list doc))
        )
        (if (and msg
                 (/= msg "Function cancelled")
                 (/= msg "quit / exit abort"))
          (princ (strcat "\n[SHANG] Error: " msg))
        )
        (princ)
      )

      (princ "\n[SHANG] Select text objects to top align...")
      (if (setq ss (ssget '((0 . "TEXT,MTEXT"))))
        (if (setq ref (aa:find-ref-by-left-bbox doc ss))
          (progn
            (setq base-y (aa:bbox-top-y (cadr ref)))
            (vla-startundomark doc)
            (setq undo-open T
                  i         0)
            (repeat (sslength ss)
              (setq ename (ssname ss i))
              (if (eq ename (car ref))
                nil
                (if (aa:align-text-vertical-by-bbox doc ename base-y 1)
                  (setq changed (1+ changed))
                  (setq skipped (1+ skipped))
                )
              )
              (setq i (1+ i))
            )
            (vla-endundomark doc)
            (setq undo-open nil)
            (princ
              (strcat
                "\n[SHANG] Done. Base Y: "
                (rtos base-y 2 4)
                ", changed: "
                (itoa changed)
                ", skipped: "
                (itoa skipped)
                "."))
          )
          (princ "\n[SHANG] No valid text extents found in selection.")
        )
        (princ "\n[SHANG] No text objects selected.")
      )
      (princ)
    )

    (defun c:XIA (/ *error* ss doc undo-open ref i ename base-y changed skipped)
      (vl-load-com)
      (setq doc       (vla-get-activedocument (vlax-get-acad-object))
            undo-open nil
            changed   0
            skipped   0)

      (defun *error* (msg)
        (if undo-open
          (vl-catch-all-apply 'vla-endundomark (list doc))
        )
        (if (and msg
                 (/= msg "Function cancelled")
                 (/= msg "quit / exit abort"))
          (princ (strcat "\n[XIA] Error: " msg))
        )
        (princ)
      )

      (princ "\n[XIA] Select text objects to bottom align...")
      (if (setq ss (ssget '((0 . "TEXT,MTEXT"))))
        (if (setq ref (aa:find-ref-by-left-bbox doc ss))
          (progn
            (setq base-y (aa:bbox-bottom-y (cadr ref)))
            (vla-startundomark doc)
            (setq undo-open T
                  i         0)
            (repeat (sslength ss)
              (setq ename (ssname ss i))
              (if (eq ename (car ref))
                nil
                (if (aa:align-text-vertical-by-bbox doc ename base-y 3)
                  (setq changed (1+ changed))
                  (setq skipped (1+ skipped))
                )
              )
              (setq i (1+ i))
            )
            (vla-endundomark doc)
            (setq undo-open nil)
            (princ
              (strcat
                "\n[XIA] Done. Base Y: "
                (rtos base-y 2 4)
                ", changed: "
                (itoa changed)
                ", skipped: "
                (itoa skipped)
                "."))
          )
          (princ "\n[XIA] No valid text extents found in selection.")
        )
        (princ "\n[XIA] No text objects selected.")
      )
      (princ)
    )

    (setq *ys-module-align_tools-loaded* T)
    (princ "\n[YS-Tools] align-tools.lsp loaded.")
  )
)
(princ)
