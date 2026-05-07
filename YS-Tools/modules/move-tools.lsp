;;; ====================================================================
;;; YS-Tools - ??????????
;;; ????: SYI(????) XYI(????) ZYI(????) YYI(????)
;;; ====================================================================

(vl-load-com)

(defun c:SYI (/ *error* doc undo-open ss)
  (setq doc (vla-get-ActiveDocument (vlax-get-acad-object))
        undo-open nil)
  (defun *error* (msg)
    (if undo-open
      (vl-catch-all-apply 'vla-EndUndoMark (list doc))
    )
    (if (and msg
             (not (wcmatch (strcase msg) "*BREAK*,*CANCEL*,*EXIT*,*QUIT*")))
      (princ (strcat "\n????: " msg))
    )
    (princ)
  )
  (setq ss (ssget "_:L"))
  (if ss
    (progn
      (vla-StartUndoMark doc)
      (setq undo-open T)
      (command "_.MOVE" ss "" "0,0,0" "0,5,0")
      (vla-EndUndoMark doc)
      (setq undo-open nil)
    )
    (princ "\n???????百汎???")
  )
  (princ)
)

(defun c:XYI (/ *error* doc undo-open ss)
  (setq doc (vla-get-ActiveDocument (vlax-get-acad-object))
        undo-open nil)
  (defun *error* (msg)
    (if undo-open
      (vl-catch-all-apply 'vla-EndUndoMark (list doc))
    )
    (if (and msg
             (not (wcmatch (strcase msg) "*BREAK*,*CANCEL*,*EXIT*,*QUIT*")))
      (princ (strcat "\n????: " msg))
    )
    (princ)
  )
  (setq ss (ssget "_:L"))
  (if ss
    (progn
      (vla-StartUndoMark doc)
      (setq undo-open T)
      (command "_.MOVE" ss "" "0,0,0" "0,-5,0")
      (vla-EndUndoMark doc)
      (setq undo-open nil)
    )
    (princ "\n???????百汎???")
  )
  (princ)
)

(defun c:ZYI (/ *error* doc undo-open ss)
  (setq doc (vla-get-ActiveDocument (vlax-get-acad-object))
        undo-open nil)
  (defun *error* (msg)
    (if undo-open
      (vl-catch-all-apply 'vla-EndUndoMark (list doc))
    )
    (if (and msg
             (not (wcmatch (strcase msg) "*BREAK*,*CANCEL*,*EXIT*,*QUIT*")))
      (princ (strcat "\n????: " msg))
    )
    (princ)
  )
  (setq ss (ssget "_:L"))
  (if ss
    (progn
      (vla-StartUndoMark doc)
      (setq undo-open T)
      (command "_.MOVE" ss "" "0,0,0" "-5,0,0")
      (vla-EndUndoMark doc)
      (setq undo-open nil)
    )
    (princ "\n???????百汎???")
  )
  (princ)
)

(defun c:YYI (/ *error* doc undo-open ss)
  (setq doc (vla-get-ActiveDocument (vlax-get-acad-object))
        undo-open nil)
  (defun *error* (msg)
    (if undo-open
      (vl-catch-all-apply 'vla-EndUndoMark (list doc))
    )
    (if (and msg
             (not (wcmatch (strcase msg) "*BREAK*,*CANCEL*,*EXIT*,*QUIT*")))
      (princ (strcat "\n????: " msg))
    )
    (princ)
  )
  (setq ss (ssget "_:L"))
  (if ss
    (progn
      (vla-StartUndoMark doc)
      (setq undo-open T)
      (command "_.MOVE" ss "" "0,0,0" "5,0,0")
      (vla-EndUndoMark doc)
      (setq undo-open nil)
    )
    (princ "\n???????百汎???")
  )
  (princ)
)

(princ "\n[YS-Tools] move-tools.lsp loaded.")
(princ)
