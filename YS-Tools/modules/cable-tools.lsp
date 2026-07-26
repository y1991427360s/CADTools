;;; YS-Tools v1.5.0 module
;;; Encoding: GBK/ANSI, CRLF

(if (and (boundp '*ys-module-cable_tools-loaded*)
         *ys-module-cable_tools-loaded*)
  (princ)
  (progn
    (vl-catch-all-apply 'vl-load-com '())

    (defun bian-make-text (pt txt sty / data)
      (setq data
        (list
          '(0 . "TEXT")
          '(100 . "AcDbEntity")
          '(100 . "AcDbText")
          (cons 10 pt)
          (cons 40 3.0)
          (cons 1 txt)
          (cons 7 sty)
          '(72 . 0)
          (cons 11 pt)
          '(50 . 0.0)
          '(41 . 0.7)
          '(51 . 0.0)
          '(71 . 0)
          '(73 . 0)
        )
      )
      (entmake data)
    )

    (defun bian-right-point (p1 p2)
      (if (> (car p1) (car p2)) p1 p2)
    )

    (defun bian-draw-one (ed sty / p1 p2 rp oz alt half bp1 bp2)
      (setq p1   (cdr (assoc 10 ed))
            p2   (cdr (assoc 11 ed))
            rp   (bian-right-point p1 p2)
            oz   (list (- (car rp) 40.0) (cadr rp) 0.0)
            alt  (* 2.5 (sqrt 3.0))
            half 2.5
            bp1  (list (- (car oz) alt) (+ (cadr oz) half) 0.0)
            bp2  (list (- (car oz) alt) (- (cadr oz) half) 0.0))

      (entmake
        (list
          '(0 . "LWPOLYLINE")
          '(100 . "AcDbEntity")
          '(100 . "AcDbPolyline")
          '(90 . 3)
          '(70 . 1)
          (cons 10 (list (car oz)  (cadr oz)))
          (cons 10 (list (car bp1) (cadr bp1)))
          (cons 10 (list (car bp2) (cadr bp2)))
        )
      )

      (bian-make-text (list (+ (car oz) 1.5)   (+ (cadr oz) 0.5) 0.0) "\\U+81F3"  sty)
      (bian-make-text (list (+ (car oz) 27.0)  (+ (cadr oz) 0.5) 0.0) "2\\U+00D74" sty)
      (bian-make-text (list (+ (car oz) -20.0) (+ (cadr oz) 0.5) 0.0) "UPS-12"    sty)
    )

    (defun c:BIAN (/ ss i ent ed sty cnt)
      (setq sty (if (tblsearch "STYLE" "HZ") "HZ" (getvar "TEXTSTYLE")))

      (if (setq ss (ssget '((0 . "LINE"))))
        (progn
          (setq i 0
                cnt (sslength ss))
          (repeat cnt
            (setq ent (ssname ss i)
                  ed  (entget ent))
            (bian-draw-one ed sty)
            (setq i (1+ i))
          )
          (if (tblsearch "STYLE" "HZ")
            (princ (strcat "\nBIAN finished for " (itoa cnt) " line(s)."))
            (princ
              (strcat
                "\nBIAN finished for "
                (itoa cnt)
                " line(s); style HZ not found, using current style "
                sty
                "."
              )
            )
          )
        )
        (princ "\nSelect LINE objects before running BIAN.")
      )
      (princ)
    )

    (defun lan-get-option (vert_count move_right / kw)
      (initget "Shang Xia")
      (setq kw
        (getkword
          (strcat "\n检测到 " (itoa vert_count)
                  " 条竖直线，副本将右移 " (rtos move_right 2 0)
                  " 单位。请选择方向 [向上(Shang)/向下(Xia)] <向上>: ")))

      (cond
        ((or (null kw) (equal kw "Shang")) "S")
        ((equal kw "Xia") "X")
      )
    )

    (defun c:LAN ( / ss total_count
                   vert_lines  horiz_lines  diag_lines
                   vert_count  horiz_count  diag_count
                   opt  move_right  dy
                   i  ent  copy_ent  entdata
                   pt1 pt2 new_pt1 new_pt2 )

      ;; 1. 取得选择集
      (setq ss (ssget))
      (if (null ss)
        (progn (princ "\n未选中任何对象。") (exit))
      )

      (setq total_count (sslength ss)
            vert_lines  '()
            horiz_lines '()
            diag_lines  '())

      ;; 2. 分类：竖直线 / 水平线 / 斜线
      (setq i 0)
      (while (< i total_count)
        (setq ent     (ssname ss i)
              entdata (entget ent)
              pt1     (cdr (assoc 10 entdata))
              pt2     (cdr (assoc 11 entdata)))

        (if (and pt1 pt2)
          (cond
            ((< (abs (- (car pt1) (car pt2))) 0.001)
             (setq vert_lines (cons ent vert_lines)))
            ((< (abs (- (cadr pt1) (cadr pt2))) 0.001)
             (setq horiz_lines (cons ent horiz_lines)))
            (T
             (setq diag_lines (cons ent diag_lines)))
          )
        )
        (setq i (1+ i))
      )

      (setq vert_count  (length vert_lines)
            horiz_count (length horiz_lines)
            diag_count  (length diag_lines))

      ;; 3. 校验选择集
      (cond
        ((= vert_count 0)
         (princ "\n错误：未检测到竖直直线，请重新选择。")
         (exit))
        ((/= horiz_count 1)
         (princ (strcat "\n错误：需要恰好 1 条水平直线，当前检测到 "
                        (itoa horiz_count) " 条。"))
         (exit))
        ((/= diag_count vert_count)
         (princ (strcat "\n错误：斜线数量（" (itoa diag_count)
                        "）与竖直线数量（" (itoa vert_count)
                        "）不匹配。"))
         (exit))
      )

      ;; 4. 计算移动量
      (setq move_right (* 5 vert_count))

      ;; 5. 获取 S / X 选项
      (setq opt (lan-get-option vert_count move_right))
      (if (null opt)
        (progn (princ "\n已取消。") (exit)))

      (setq dy (if (equal opt "S") 5.0 -5.0))

      ;; 6. 处理竖直直线：复制 → 右移 move_right → 端点延长 5
      (foreach ent vert_lines
        (setq copy_ent (entmakex (entget ent))
              entdata  (entget copy_ent)
              pt1      (cdr (assoc 10 entdata))
              pt2      (cdr (assoc 11 entdata)))

        (setq new_pt1 (list (+ (car pt1) move_right) (cadr pt1) (caddr pt1))
              new_pt2 (list (+ (car pt2) move_right) (cadr pt2) (caddr pt2)))

        (if (> (cadr new_pt1) (cadr new_pt2))
          (if (> dy 0)
            (setq new_pt1 (list (car new_pt1) (+ (cadr new_pt1) 5.0) (caddr new_pt1)))
            (setq new_pt2 (list (car new_pt2) (- (cadr new_pt2) 5.0) (caddr new_pt2))))
          (if (> dy 0)
            (setq new_pt2 (list (car new_pt2) (+ (cadr new_pt2) 5.0) (caddr new_pt2)))
            (setq new_pt1 (list (car new_pt1) (- (cadr new_pt1) 5.0) (caddr new_pt1))))
        )

        (setq entdata (subst (cons 10 new_pt1) (assoc 10 entdata) entdata))
        (setq entdata (subst (cons 11 new_pt2) (assoc 11 entdata) entdata))
        (entmod entdata)
      )

      ;; 7. 处理斜线：复制 → 右移 move_right → 上/下移 5
      (foreach ent diag_lines
        (setq copy_ent (entmakex (entget ent))
              entdata  (entget copy_ent)
              pt1      (cdr (assoc 10 entdata))
              pt2      (cdr (assoc 11 entdata)))

        (setq new_pt1 (list (+ (car pt1) move_right) (+ (cadr pt1) dy) (caddr pt1))
              new_pt2 (list (+ (car pt2) move_right) (+ (cadr pt2) dy) (caddr pt2)))

        (setq entdata (subst (cons 10 new_pt1) (assoc 10 entdata) entdata))
        (setq entdata (subst (cons 11 new_pt2) (assoc 11 entdata) entdata))
        (entmod entdata)
      )

      ;; 8. 处理水平直线：复制 → 上/下移 5 → 左端缩短 move_right（右端不动）
      (foreach ent horiz_lines
        (setq copy_ent (entmakex (entget ent))
              entdata  (entget copy_ent)
              pt1      (cdr (assoc 10 entdata))
              pt2      (cdr (assoc 11 entdata)))

        (if (< (car pt1) (car pt2))
          (setq new_pt1 (list (+ (car pt1) move_right) (+ (cadr pt1) dy) (caddr pt1))
                new_pt2 (list (car pt2)                 (+ (cadr pt2) dy) (caddr pt2)))
          (setq new_pt1 (list (car pt1)                 (+ (cadr pt1) dy) (caddr pt1))
                new_pt2 (list (+ (car pt2) move_right)  (+ (cadr pt2) dy) (caddr pt2)))
        )

        (setq entdata (subst (cons 10 new_pt1) (assoc 10 entdata) entdata))
        (setq entdata (subst (cons 11 new_pt2) (assoc 11 entdata) entdata))
        (entmod entdata)
      )

      ;; 9. 完成提示
      (princ
        (strcat "\n完成！所有对象已原地复制。"
                "\n副本：竖直线 & 斜线右移 " (rtos move_right 2 0)
                " 单位 + " (if (> dy 0) "向上" "向下") " 5 单位；"
                "\n      水平线 " (if (> dy 0) "向上" "向下")
                " 5 单位 + 左端缩短 " (rtos move_right 2 0) " 单位（右端不动）。"))
      (princ)
    )

    (defun c:XIN ( / ss i ent entData pt1 pt2 leftX rightX topY bottomY
                    countSS countNum insertPt textStr rightPt)
      (setq ss (ssget '((0 . "LINE"))))
      (if (null ss)
        (progn
          (alert "未选择任何直线！")
          (exit)
        )
      )

      (setq i 0)
      (while (< i (sslength ss))
        (setq ent (ssname ss i))
        (setq entData (entget ent))

        (setq pt1 (cdr (assoc 10 entData)))
        (setq pt2 (cdr (assoc 11 entData)))

        (if (< (car pt1) (car pt2))
          (progn
            (setq leftX (car pt1))
            (setq rightX (car pt2))
            (setq rightPt pt2)
          )
          (progn
            (setq leftX (car pt2))
            (setq rightX (car pt1))
            (setq rightPt pt1)
          )
        )

        (setq topY (+ (cadr pt1) 1.6))
        (setq bottomY (- (cadr pt1) 1.6))

        (setq countSS
               (ssget "W"
                 (list leftX bottomY 0.0)
                 (list rightX topY 0.0)
               )
        )

        (if countSS
          (progn
            (setq countNum (sslength countSS))
            (if (ssmemb ent countSS)
              (progn
                (ssdel ent countSS)
                (setq countNum (1- countNum))
              )
            )
          )
          (setq countNum 0)
        )

        (setq insertPt (list (+ (car rightPt) 2) (+ (cadr rightPt) 0.5) 0.0))
        (setq textStr (itoa countNum))

        (entmake
          (list
            (cons 0 "TEXT")
            (cons 10 insertPt)
            (cons 40 3.0)
            (cons 1 textStr)
            (cons 7 "Standard")
            (cons 50 0.0)
          )
        )

        (setq i (1+ i))
      )

      (princ (strcat "\n处理完成，共处理 " (itoa (sslength ss)) " 条直线。"))
      (princ)
    )

    (setq *ys-module-cable_tools-loaded* T)
    (princ "\n[YS-Tools] cable-tools.lsp loaded.")
  )
)
(princ)
