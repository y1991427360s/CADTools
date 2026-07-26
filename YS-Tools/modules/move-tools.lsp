;;; YS-Tools v1.5.0 module
;;; Encoding: GBK/ANSI, CRLF

(if (and (boundp '*ys-module-move_tools-loaded*)
         *ys-module-move_tools-loaded*)
  (princ)
  (progn
    (vl-catch-all-apply 'vl-load-com '())

    (defun c:SYI (/ ss)
      (setq ss (ssget "_:L"))
      (if ss
        (command "_.MOVE" ss "" "0,0,0" "0,5,0")
        (princ "\n未选择任何对象。")
      )
      (princ)
    )

    (defun c:XYI (/ ss)
      (setq ss (ssget "_:L"))
      (if ss
        (command "_.MOVE" ss "" "0,0,0" "0,-5,0")
        (princ "\n未选择任何对象。")
      )
      (princ)
    )

    (defun c:ZYI (/ ss)
      (setq ss (ssget "_:L"))
      (if ss
        (command "_.MOVE" ss "" "0,0,0" "-5,0,0")
        (princ "\n未选择任何对象。")
      )
      (princ)
    )

    (defun c:YYI (/ ss)
      (setq ss (ssget "_:L"))
      (if ss
        (command "_.MOVE" ss "" "0,0,0" "5,0,0")
        (princ "\n未选择任何对象。")
      )
      (princ)
    )

    (setq *ys-module-move_tools-loaded* T)
    (princ "\n[YS-Tools] move-tools.lsp loaded.")
  )
)
(princ)
