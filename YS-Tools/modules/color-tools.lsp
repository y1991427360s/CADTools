;;; YS-Tools v1.5.0 module
;;; Encoding: GBK/ANSI, CRLF

(if (and (boundp '*ys-module-color_tools-loaded*)
         *ys-module-color_tools-loaded*)
  (princ)
  (progn
    (vl-catch-all-apply 'vl-load-com '())

    (defun c:y (/ targetColor ss i ename)
      (setq targetColor *Y_TextColor*) ; 从配置区获取颜色
      (princ "\n选择要改变颜色的对象: ")
      (setq ss (ssget))

      (if ss
        (progn
          (setq i 0)
          (repeat (sslength ss)
            (setq ename (ssname ss i))
            (vla-put-Color (vlax-ename->vla-object ename) targetColor)
            (setq i (1+ i))
          )
          (princ (strcat "\n所有选中的对象颜色已更改。"))
        )
        (princ "\n没有选中任何对象。")
      )
      (princ)
    )

    (defun c:RR (/ targetColor ss i ename)
      (setq targetColor *RR_TextColor*) ; 从配置区获取颜色
      (princ "\n选择要改为红色的对象: ")
      (setq ss (ssget))

      (if ss
        (progn
          (setq i 0)
          (repeat (sslength ss)
            (setq ename (ssname ss i))
            (vla-put-Color (vlax-ename->vla-object ename) targetColor)
            (setq i (1+ i))
          )
          (princ "\n所有选中的对象已改为红色。")
        )
        (princ "\n没有选中任何对象。")
      )
      (princ)
    )

    (defun c:UU (/ targetColor ss i ename)
      (setq targetColor *UU_TextColor*) ; 从配置区获取颜色
      (princ "\n选择要改为白色的对象: ")
      (setq ss (ssget))

      (if ss
        (progn
          (setq i 0)
          (repeat (sslength ss)
            (setq ename (ssname ss i))
            (vla-put-Color (vlax-ename->vla-object ename) targetColor)
            (setq i (1+ i))
          )
          (princ "\n所有选中的对象已改为白色。")
        )
        (princ "\n没有选中任何对象。")
      )
      (princ)
    )

    (defun c:GG (/ targetColor ss i ename)
      (setq targetColor *GG_TextColor*) ; 从配置区获取颜色
      (princ "\n选择要改为绿色的对象: ")
      (setq ss (ssget))

      (if ss
        (progn
          (setq i 0)
          (repeat (sslength ss)
            (setq ename (ssname ss i))
            (vla-put-Color (vlax-ename->vla-object ename) targetColor)
            (setq i (1+ i))
          )
          (princ "\n所有选中的对象已改为绿色。")
        )
        (princ "\n没有选中任何对象。")
      )
      (princ)
    )

    (setq *ys-module-color_tools-loaded* T)
    (princ "\n[YS-Tools] color-tools.lsp loaded.")
  )
)
(princ)
