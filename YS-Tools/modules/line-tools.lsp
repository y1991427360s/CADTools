;;; YS-Tools v1.5.0 module
;;; Encoding: GBK/ANSI, CRLF

(if (and (boundp '*ys-module-line_tools-loaded*)
         *ys-module-line_tools-loaded*)
  (princ)
  (progn
    (vl-catch-all-apply 'vl-load-com '())

    (defun c:LONG (/ ss total-length index ename obj)
      (prompt "\n请选择要计算总长度的多段线: ")
      (setq ss (ssget '((0 . "POLYLINE,LWPOLYLINE"))))
      (if ss
        (progn
          (setq total-length 0.0 index 0)
          (repeat (sslength ss)
            (setq ename (ssname ss index))
            (setq obj (vlax-ename->vla-object ename))
            (setq total-length (+ total-length (vla-get-length obj)))
            (setq index (1+ index))
          )
          (prompt (strcat "\n所选多段线的总长度为: " (rtos total-length)))
        )
        (prompt "\n未选择任何多段线。")
      )
      (princ)
    )

    (defun c:YAN (/ *error* doc group_num extend_dir ss ent_list sorted_list i ent p10 p11 p10y p11y multiplier delta new_y new_pt obj)

      ;; --- 错误处理函数 ---
      (defun *error* (msg)
        (if (and msg (not (wcmatch (strcase msg) "*BREAK*,*CANCEL*,*EXIT*")))
          (princ (strcat "\n错误: " msg))
        )
        (if (= (type doc) 'vla-object) (vla-EndUndoMark doc))
        (princ)
      )

      (vl-load-com)
      (setq doc (vla-get-ActiveDocument (vlax-get-acad-object)))

      ;; --- 1. 获取用户输入选项 ---

      ;; 初始化选项：分组数量 (2 或 4)
      (initget 1 "2 4")
      (setq group_num (atoi (getkword "\n请输入分组数量 [2/4]: ")))

      ;; 初始化选项：延伸方向 (Up 或 Down)
      (initget 1 "Up Down")
      (setq extend_dir (getkword "\n请输入延伸方向 [向上(Up)/向下(Down)]: "))

      ;; --- 2. 选择对象 ---
      (princ "\n请选择竖直直线 (从左到右将自动排序): ")
      (setq ss (ssget '((0 . "LINE"))))

      (if ss
        (progn
          (vla-StartUndoMark doc)

          ;; --- 3. 将选择集转换为图元列表 ---
          (setq ent_list '())
          (setq i 0)
          (repeat (sslength ss)
            (setq ent_list (cons (ssname ss i) ent_list))
            (setq i (1+ i))
          )

          ;; --- 4. 从左到右排序 ---
          ;; 依据组码10 (起点) 的 X 坐标进行排序
          (setq sorted_list
            (vl-sort ent_list
              '(lambda (e1 e2)
                 (< (car (cdr (assoc 10 (entget e1))))
                    (car (cdr (assoc 10 (entget e2)))))
               )
            )
          )

          ;; --- 5. 循环处理每一条线 ---
          (setq i 0) ;; 重置计数器作为列表索引
          (foreach ent sorted_list
            (setq obj (entget ent))
            (setq p10 (cdr (assoc 10 obj))) ;; 起点坐标 (X Y Z)
            (setq p11 (cdr (assoc 11 obj))) ;; 终点坐标 (X Y Z)

            ;; 计算当前的倍数
            ;; 逻辑：索引除以组数取整，然后+1
            ;; 例如组数为2：0,1 -> 倍数1; 2,3 -> 倍数2
            (setq multiplier (1+ (fix (/ i group_num))))
            (setq delta (* multiplier 5))

            (setq p10y (cadr p10))
            (setq p11y (cadr p11))

            ;; 根据方向修改坐标
            (if (eq extend_dir "Down")
              ;; --- 向下延伸 ---
              ;; 逻辑：找到Y值较小的那个点，将其Y值减去delta
              (if (< p10y p11y)
                (progn
                  ;; p10 是下端点
                  (setq new_y (- p10y delta))
                  (setq new_pt (list (car p10) new_y (caddr p10)))
                  (setq obj (subst (cons 10 new_pt) (assoc 10 obj) obj))
                )
                (progn
                  ;; p11 是下端点
                  (setq new_y (- p11y delta))
                  (setq new_pt (list (car p11) new_y (caddr p11)))
                  (setq obj (subst (cons 11 new_pt) (assoc 11 obj) obj))
                )
              )
              ;; --- 向上延伸 ---
              ;; 逻辑：找到Y值较大的那个点，将其Y值加上delta
              (if (> p10y p11y)
                (progn
                  ;; p10 是上端点
                  (setq new_y (+ p10y delta))
                  (setq new_pt (list (car p10) new_y (caddr p10)))
                  (setq obj (subst (cons 10 new_pt) (assoc 10 obj) obj))
                )
                (progn
                  ;; p11 是上端点
                  (setq new_y (+ p11y delta))
                  (setq new_pt (list (car p11) new_y (caddr p11)))
                  (setq obj (subst (cons 11 new_pt) (assoc 11 obj) obj))
                )
              )
            )

            ;; 更新图元
            (entmod obj)

            ;; 增加索引
            (setq i (1+ i))
          )

          (vla-EndUndoMark doc)
          (princ (strcat "\n完成! 共处理了 " (itoa (length sorted_list)) " 条直线。"))
        )
        (princ "\n未选择任何对象。")
      )
      (princ)
    )

    (defun c:SYAN (/ ss i ent p1 p2 high low ang new_high)
      (princ "\n请选择要向上延长的直线...")
      ;; 仅选择直线(LINE)
      (if (setq ss (ssget '((0 . "LINE"))))
        (progn
          (setq i 0)
          (repeat (sslength ss)
            (setq ent (entget (ssname ss i)))
            (setq p1 (cdr (assoc 10 ent))) ; 起点
            (setq p2 (cdr (assoc 11 ent))) ; 终点

            ;; 比较 Y 坐标，确定哪一个点在上方
            (if (> (cadr p1) (cadr p2))
              (setq high p1 low p2)
              (setq high p2 low p1)
            )

            ;; 计算从低点到高点的角度
            (setq ang (angle low high))
            ;; 在高点位置沿角度方向延长 5
            (setq new_high (polar high ang 5))

            ;; 更新实体数据
            (if (equal high p1)
              (setq ent (subst (cons 10 new_high) (assoc 10 ent) ent))
              (setq ent (subst (cons 11 new_high) (assoc 11 ent) ent))
            )

            (entmod ent) ; 修改实体
            (setq i (1+ i))
          )
          (princ (strcat "\n成功向上延长了 " (itoa i) " 条直线。"))
        )
        (princ "\n未选中任何直线。")
      )
      (princ)
    )

    (defun c:XYAN (/ ss i ent p1 p2 high low ang new_low)
      (princ "\n请选择要向下延长的直线...")
      ;; 仅选择直线(LINE)
      (if (setq ss (ssget '((0 . "LINE"))))
        (progn
          (setq i 0)
          (repeat (sslength ss)
            (setq ent (entget (ssname ss i)))
            (setq p1 (cdr (assoc 10 ent)))
            (setq p2 (cdr (assoc 11 ent)))

            ;; 比较 Y 坐标，确定哪一个点在下方
            (if (< (cadr p1) (cadr p2))
              (setq low p1 high p2)
              (setq low p2 high p1)
            )

            ;; 计算从高点到低点的角度
            (setq ang (angle high low))
            ;; 在低点位置沿角度方向延长 5
            (setq new_low (polar low ang 5))

            ;; 更新实体数据
            (if (equal low p1)
              (setq ent (subst (cons 10 new_low) (assoc 10 ent) ent))
              (setq ent (subst (cons 11 new_low) (assoc 11 ent) ent))
            )

            (entmod ent) ; 修改实体
            (setq i (1+ i))
          )
          (princ (strcat "\n成功向下延长了 " (itoa i) " 条直线。"))
        )
        (princ "\n未选中任何直线。")
      )
      (princ)
    )

    (defun c:XSUO ( / ss i ent entdata p10 p11 low_pt high_pt dx dy dz len ux uy uz new_pt is_p10_low )
      (princ "\n【XSUO】请选择要【从下往上】缩短 5 单位的直线...")
      (setq ss (ssget '((0 . "LINE"))))

      (if ss
        (progn
          (command "_.UNDO" "_Begin")
          (setq i 0)
          (repeat (sslength ss)
            (setq ent (ssname ss i))
            (setq entdata (entget ent))
            (setq p10 (cdr (assoc 10 entdata)))
            (setq p11 (cdr (assoc 11 entdata)))

            (if (< (cadr p10) (cadr p11))
              (setq low_pt p10 high_pt p11 is_p10_low T)
              (setq low_pt p11 high_pt p10 is_p10_low nil)
            )

            (setq dx (- (car high_pt) (car low_pt))
                  dy (- (cadr high_pt) (cadr low_pt))
                  dz (- (caddr high_pt) (caddr low_pt))
                  len (sqrt (+ (* dx dx) (* dy dy) (* dz dz))))

            (if (> len 5.01)
              (progn
                (setq ux (/ dx len) uy (/ dy len) uz (/ dz len))
                (setq new_pt (list (+ (car low_pt) (* 5.0 ux))
                                   (+ (cadr low_pt) (* 5.0 uy))
                                   (+ (caddr low_pt) (* 5.0 uz))))
                (if is_p10_low
                  (setq entdata (subst (cons 10 new_pt) (assoc 10 entdata) entdata))
                  (setq entdata (subst (cons 11 new_pt) (assoc 11 entdata) entdata))
                )
                (entmod entdata)
                (entupd ent)
              )
              (princ (strcat "\n第 " (itoa (1+ i)) " 条线太短，已跳过。"))
            )
            (setq i (1+ i))
          )
          (command "_.UNDO" "_End")
          (princ (strcat "\nXSUO 完成！共处理 " (itoa (sslength ss)) " 条直线。"))
        )
        (princ "\n未选择直线，命令结束。")
      )
      (princ)
    )

    (defun c:SSUO ( / ss i ent entdata p10 p11 low_pt high_pt dx dy dz len ux uy uz new_pt is_p10_low )
      (princ "\n【SSUO】请选择要【从上往下】缩短 5 单位的直线...")
      (setq ss (ssget '((0 . "LINE"))))

      (if ss
        (progn
          (command "_.UNDO" "_Begin")
          (setq i 0)
          (repeat (sslength ss)
            (setq ent (ssname ss i))
            (setq entdata (entget ent))
            (setq p10 (cdr (assoc 10 entdata)))
            (setq p11 (cdr (assoc 11 entdata)))

            (if (< (cadr p10) (cadr p11))
              (setq low_pt p10 high_pt p11 is_p10_low T)
              (setq low_pt p11 high_pt p10 is_p10_low nil)
            )

            (setq dx (- (car high_pt) (car low_pt))
                  dy (- (cadr high_pt) (cadr low_pt))
                  dz (- (caddr high_pt) (caddr low_pt))
                  len (sqrt (+ (* dx dx) (* dy dy) (* dz dz))))

            (if (> len 5.01)
              (progn
                (setq ux (/ dx len) uy (/ dy len) uz (/ dz len))
                (setq new_pt (list (- (car high_pt) (* 5.0 ux))
                                   (- (cadr high_pt) (* 5.0 uy))
                                   (- (caddr high_pt) (* 5.0 uz))))
                (if is_p10_low
                  (setq entdata (subst (cons 11 new_pt) (assoc 11 entdata) entdata))
                  (setq entdata (subst (cons 10 new_pt) (assoc 10 entdata) entdata))
                )
                (entmod entdata)
                (entupd ent)
              )
              (princ (strcat "\n第 " (itoa (1+ i)) " 条线太短，已跳过。"))
            )
            (setq i (1+ i))
          )
          (command "_.UNDO" "_End")
          (princ (strcat "\nSSUO 完成！共处理 " (itoa (sslength ss)) " 条直线。"))
        )
        (princ "\n未选择直线，命令结束。")
      )
      (princ)
    )

    (defun c:SJ (/ ss i ent ed p1 p2 top sp ep)
      (princ "\n=== SJ 上接模式 ===")

      (if (setq ss (ssget '((0 . "LINE"))))
        (progn
          (setq i 0)
          (repeat (sslength ss)
            (setq ent (ssname ss i)
                  ed  (entget ent)
                  p1  (cdr (assoc 10 ed))
                  p2  (cdr (assoc 11 ed)))
            (setq top (if (> (cadr p1) (cadr p2)) p1 p2))
            (setq sp (list (+ (car top) 1.0) (cadr top) (caddr top))
                  ep (list (car top) (- (cadr top) 1.0) (caddr top)))
            (command "._LINE" "_non" sp "_non" ep "")
            (setq i (1+ i))
          )
          (princ (strcat "\n已成功为 " (itoa (sslength ss)) " 条直线绘制【上接】短线！"))
        )
        (princ "\n未选中直线！请框选直线后再输入 SJ")
      )
      (princ)
    )

    (defun c:XJ (/ ss i ent ed p1 p2 bot sp ep)
      (princ "\n=== XJ 下接模式 ===")

      (if (setq ss (ssget '((0 . "LINE"))))
        (progn
          (setq i 0)
          (repeat (sslength ss)
            (setq ent (ssname ss i)
                  ed  (entget ent)
                  p1  (cdr (assoc 10 ed))
                  p2  (cdr (assoc 11 ed)))
            (setq bot (if (< (cadr p1) (cadr p2)) p1 p2))
            (setq sp (list (+ (car bot) 1.0) (cadr bot) (caddr bot))
                  ep (list (car bot) (+ (cadr bot) 1.0) (caddr bot)))
            (command "._LINE" "_non" sp "_non" ep "")
            (setq i (1+ i))
          )
          (princ (strcat "\n已成功为 " (itoa (sslength ss)) " 条直线绘制【下接】短线！"))
        )
        (princ "\n未选中直线！请框选直线后再输入 XJ")
      )
      (princ)
    )

    (setq *ys-module-line_tools-loaded* T)
    (princ "\n[YS-Tools] line-tools.lsp loaded.")
  )
)
(princ)
