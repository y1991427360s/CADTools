;;; ====================================================================
;;; YS-Tools - ????????? (??3??那?????)
;;; ????: ZUO(?????) YOU(?????) SHANG(?????) XIA(?????) ZHONG(????)
;;; ====================================================================

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
  (princ "\n[ZHONG] ???????忪????????...")
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
              "\n[ZHONG] ???. ???X: "
              (rtos base-x 2 4)
              ", ?????: "
              (itoa changed)
              ", ??????: "
              (itoa skipped)
              "."))
        )
        (princ "\n[ZHONG] ?????汛?????完??????那??")
      )
    )
    (princ "\n[ZHONG] 汛????百????????")
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
  (princ "\n[ZUO] ??????????????...")
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
            "\n[ZUO] ???. ???X: "
            (rtos base-x 2 4)
            ", ?????: "
            (itoa changed)
            ", ??????: "
            (itoa skipped)
            "."))
      )
      (princ "\n[ZUO] ?????汛?????完???????朱??")
    )
    (princ "\n[ZUO] 汛????百????????")
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
  (princ "\n[YOU] ??????????????...")
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
            "\n[YOU] ???. ???X: "
            (rtos base-x 2 4)
            ", ?????: "
            (itoa changed)
            ", ??????: "
            (itoa skipped)
            "."))
      )
      (princ "\n[YOU] ?????汛?????完???????朱??")
    )
    (princ "\n[YOU] 汛????百????????")
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
  (princ "\n[SHANG] ??????????????...")
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
            "\n[SHANG] ???. ???Y: "
            (rtos base-y 2 4)
            ", ?????: "
            (itoa changed)
            ", ??????: "
            (itoa skipped)
            "."))
      )
      (princ "\n[SHANG] ?????汛?????完???????朱??")
    )
    (princ "\n[SHANG] 汛????百????????")
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
  (princ "\n[XIA] ??????????????...")
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
            "\n[XIA] ???. ???Y: "
            (rtos base-y 2 4)
            ", ?????: "
            (itoa changed)
            ", ??????: "
            (itoa skipped)
            "."))
      )
      (princ "\n[XIA] ?????汛?????完???????朱??")
    )
    (princ "\n[XIA] 汛????百????????")
  )
  (princ)
)

(princ "\n[YS-Tools] align-tools.lsp loaded.")
(princ)
