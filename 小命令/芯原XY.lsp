(vl-load-com)

;; =========================
;; XY 参数区
;; =========================
(setq *xy-geom-tol*      1e-4)             ; 几何容差
(setq *xy-ang-tol*       (/ pi 180.0))     ; 角度容差：±1°
(setq *xy-ray-len*       20.0)             ; 竖直搜索区高度
(setq *xy-hit-half-width* 1.0)             ; 搜索矩形半宽
(setq *xy-out-offx*      10.0)             ; 输出起点相对水平线右端点偏移 X
(setq *xy-out-offy*      1.0)              ; 输出起点相对水平线右端点偏移 Y
(setq *xy-step-x*        30.0)             ; 新文字插入点固定间距
(setq *xy-last-xin-counts* nil)            ; 最近一次XIN输出数字表
(setq *xy-last-vrec-map*   nil)            ; 最近一次每条水平线匹配到的竖线表

;; =========================
;; 通用函数
;; =========================
(defun xy:abs (x)
  (if (< x 0.0) (- x) x)
)

(defun xy:near (a b tol)
  (<= (xy:abs (- a b)) tol)
)

(defun xy:between (v a b tol)
  (and (>= v (- (min a b) tol))
       (<= v (+ (max a b) tol)))
)

(defun xy:ss->list (ss / i lst)
  (setq lst '())
  (if ss
    (progn
      (setq i 0)
      (while (< i (sslength ss))
        (setq lst (cons (ssname ss i) lst))
        (setq i (1+ i))
      )
    )
  )
  (reverse lst)
)

(defun xy:get-line-pts (en / ed p1 p2)
  (setq ed (entget en))
  (setq p1 (cdr (assoc 10 ed)))
  (setq p2 (cdr (assoc 11 ed)))
  (list p1 p2)
)

(defun xy:is-line-p (en)
  (= (cdr (assoc 0 (entget en))) "LINE")
)

(defun xy:is-horizontal-line-p (en tol / pts p1 p2)
  (if (not (xy:is-line-p en))
    nil
    (progn
      (setq pts (xy:get-line-pts en))
      (setq p1 (car pts))
      (setq p2 (cadr pts))
      (xy:near (cadr p1) (cadr p2) tol)
    )
  )
)

(defun xy:is-vertical-line-p (en tol / pts p1 p2)
  (if (not (xy:is-line-p en))
    nil
    (progn
      (setq pts (xy:get-line-pts en))
      (setq p1 (car pts))
      (setq p2 (cadr pts))
      (xy:near (car p1) (car p2) tol)
    )
  )
)

(defun xy:right-endpoint (en / pts p1 p2)
  (setq pts (xy:get-line-pts en))
  (setq p1 (car pts))
  (setq p2 (cadr pts))
  (if (>= (car p1) (car p2)) p1 p2)
)

(defun xy:hline-info (en / pts p1 p2 x1 x2 y rightpt)
  (setq pts (xy:get-line-pts en))
  (setq p1 (car pts))
  (setq p2 (cadr pts))
  (setq x1 (car p1))
  (setq x2 (car p2))
  (setq y  (cadr p1))
  (setq rightpt (xy:right-endpoint en))
  (list (min x1 x2) (max x1 x2) y rightpt)
)

(defun xy:norm-angle (a)
  (while (< a 0.0)
    (setq a (+ a (* 2.0 pi)))
  )
  (while (>= a (* 2.0 pi))
    (setq a (- a (* 2.0 pi)))
  )
  a
)

(defun xy:is-vertical-text-90-p (ang tol / a)
  (setq a (xy:norm-angle ang))
  (<= (xy:abs (- a (/ pi 2.0))) tol)
)

(defun xy:dxf (code ed default / pair)
  (setq pair (assoc code ed))
  (if pair (cdr pair) default)
)

(defun xy:is-text-entity-p (en / typ)
  (setq typ (cdr (assoc 0 (entget en))))
  (or (= typ "TEXT") (= typ "MTEXT"))
)

(defun xy:get-text-rotation (ed)
  (xy:dxf 50 ed 0.0)
)

(defun xy:get-text-height (ed)
  (xy:dxf 40 ed 3.0)
)

(defun xy:get-text-style (ed)
  (xy:dxf 7 ed "Standard")
)

(defun xy:get-text-value (ed)
  (xy:dxf 1 ed "")
)

;; =========================
;; XIN 功能
;; =========================
(defun xy:filter-vertical-lines (lineList / out en)
  (setq out '())
  (foreach en lineList
    (if (xy:is-vertical-line-p en *xy-geom-tol*)
      (setq out (cons en out))
    )
  )
  (reverse out)
)

(defun xy:get-vrecs-for-hline (hen lineList / handle pair hinfo vrecs en vrec)
  (setq handle (cdr (assoc 5 (entget hen))))
  (setq pair (assoc handle *xy-last-vrec-map*))
  (if pair
    (cdr pair)
    (progn
      (setq hinfo (xy:hline-info hen))
      (setq vrecs '())
      (foreach en lineList
        (progn
          (setq vrec (xy:make-vrec-if-valid en hinfo *xy-geom-tol*))
          (if vrec
            (setq vrecs (cons vrec vrecs))
          )
        )
      )
      (xy:dedup-vrecs vrecs *xy-geom-tol*)
    )
  )
)

(defun xy:count-vlines-for-hline (hen lineList)
  (length (xy:get-vrecs-for-hline hen lineList))
)

(defun xy:run-xin (sel / selList lineSS lineList ss i ent entData rightPt handle countMap vrecMap vrecs countNum insertPt textStr)
  (setq *xy-last-xin-counts* nil)
  (setq *xy-last-vrec-map* nil)
  (setq selList  (xy:ss->list sel))
  (setq lineSS   (ssget "_X" '((0 . "LINE"))))
  (setq lineList (xy:filter-vertical-lines (xy:ss->list lineSS)))
  (setq ss (ssadd))
  (foreach ent selList
    (if (xy:is-horizontal-line-p ent *xy-geom-tol*)
      (ssadd ent ss)
    )
  )
  (if (= (sslength ss) 0)
    (progn
      (princ "\n选集中没有可供XIN处理的水平直线。")
      nil
    )
    (progn
      (setq i 0)
      (setq countMap '())
      (setq vrecMap '())
      (while (< i (sslength ss))
        (setq ent     (ssname ss i))
        (setq entData (entget ent))
        (setq rightPt (xy:right-endpoint ent))
        (setq vrecs (xy:get-vrecs-for-hline ent lineList))
        (setq countNum (length vrecs))

        (setq handle   (cdr (assoc 5 entData)))
        (setq countMap (cons (cons handle countNum) countMap))
        (setq vrecMap  (cons (cons handle vrecs) vrecMap))
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

      (setq *xy-last-xin-counts* (reverse countMap))
      (setq *xy-last-vrec-map*   (reverse vrecMap))
      (princ (strcat "\nXIN处理完成，共处理 " (itoa (sslength ss)) " 条水平直线。"))
      T
    )
  )
);; =========================
;; YUAN 功能
;; =========================
(defun xy:make-vrec-if-valid (ven hinfo tol / pts p1 p2 x y1 y2 hy xmin xmax lo hi)
  (if (not (xy:is-vertical-line-p ven tol))
    nil
    (progn
      (setq pts  (xy:get-line-pts ven))
      (setq p1   (car pts))
      (setq p2   (cadr pts))
      (setq x    (car p1))
      (setq y1   (cadr p1))
      (setq y2   (cadr p2))
      (setq xmin (car hinfo))
      (setq xmax (cadr hinfo))
      (setq hy   (caddr hinfo))
      (setq lo   (if (< y1 y2) p1 p2))
      (setq hi   (if (> y1 y2) p1 p2))

      (if (not (xy:between x xmin xmax tol))
        nil
        (cond
          ((and (xy:near (cadr hi) hy tol)
                (< (cadr lo) (- hy tol)))
           (list x 'DOWN lo ven)
          )
          ((and (xy:near (cadr lo) hy tol)
                (> (cadr hi) (+ hy tol)))
           (list x 'UP hi ven)
          )
          (t nil)
        )
      )
    )
  )
)

(defun xy:merge-vrec (a b / side pa pb)
  (setq side (cadr a))
  (setq pa   (caddr a))
  (setq pb   (caddr b))
  (cond
    ((eq side 'DOWN)
     (if (< (cadr pa) (cadr pb)) a b)
    )
    ((eq side 'UP)
     (if (> (cadr pa) (cadr pb)) a b)
    )
    (t a)
  )
)

(defun xy:dedup-vrecs (lst tol / sorted out rec top)
  (setq sorted
        (vl-sort lst
          '(lambda (a b) (< (car a) (car b)))
        )
  )
  (setq out '())
  (foreach rec sorted
    (if (null out)
      (setq out (list rec))
      (progn
        (setq top (car out))
        (if (and (xy:near (car rec) (car top) tol)
                 (eq (cadr rec) (cadr top)))
          (setq out (cons (xy:merge-vrec rec top) (cdr out)))
          (setq out (cons rec out))
        )
      )
    )
  )
  (reverse out)
)

(defun xy:sa->list (val)
  (vlax-safearray->list
    (if (= (type val) 'VARIANT)
      (vlax-variant-value val)
      val))
)

(defun xy:fallback-text-bbox (ed / ip h txt w)
  (setq ip  (xy:dxf 10 ed '(0.0 0.0 0.0)))
  (setq h   (xy:get-text-height ed))
  (setq txt (xy:get-text-value ed))
  (setq w   (max h (* (strlen txt) h 0.7)))
  (list (- (car ip) (/ h 2.0))
        (+ (car ip) (/ h 2.0))
        (- (cadr ip) (/ w 2.0))
        (+ (cadr ip) (/ w 2.0)))
)

(defun xy:get-text-bbox (en / ed obj minPt maxPt ret minLst maxLst)
  (setq ed (entget en))
  (if (xy:is-text-entity-p en)
    (progn
      (setq obj (vlax-ename->vla-object en))
      (setq ret (vl-catch-all-apply 'vla-getBoundingBox (list obj 'minPt 'maxPt)))
      (if (vl-catch-all-error-p ret)
        (xy:fallback-text-bbox ed)
        (progn
          (setq minLst (xy:sa->list minPt))
          (setq maxLst (xy:sa->list maxPt))
          (list (car minLst) (car maxLst) (cadr minLst) (cadr maxLst))
        )
      )
    )
    nil
  )
)

(defun xy:build-text-meta-list (textList / out en ed rot bbox)
  (setq out '())
  (foreach en textList
    (setq ed (entget en))
    (if (xy:is-text-entity-p en)
      (progn
        (setq rot (xy:get-text-rotation ed))
        (if (xy:is-vertical-text-90-p rot *xy-ang-tol*)
          (progn
            (setq bbox (xy:get-text-bbox en))
            (if bbox
              (setq out
                    (cons
                      (list en
                            (car bbox)
                            (cadr bbox)
                            (caddr bbox)
                            (cadddr bbox)
                            rot)
                      out))
            )
          )
        )
      )
    )
  )
  (reverse out)
)

(defun xy:find-text-for-vrec (textMetaList vrec / side anchor ax ay rectXmin rectXmax rectYmin rectYmax best bestHit bestXDist item en xmin xmax ymin ymax hitY xCenter xDist)
  (setq side   (cadr vrec))
  (setq anchor (caddr vrec))
  (setq ax     (car anchor))
  (setq ay     (cadr anchor))

  (cond
    ((eq side 'DOWN)
     (setq rectXmin (- ax *xy-hit-half-width*))
     (setq rectXmax (+ ax *xy-hit-half-width*))
     (setq rectYmin (- ay *xy-ray-len*))
     (setq rectYmax ay)
     (setq best nil)
     (setq bestHit nil)
     (setq bestXDist nil)

     (foreach item textMetaList
       (setq en   (car item))
       (setq xmin (cadr item))
       (setq xmax (caddr item))
       (setq ymin (cadddr item))
       (setq ymax (nth 4 item))
       (if (and (<= xmin (+ rectXmax *xy-geom-tol*))
                (>= xmax (- rectXmin *xy-geom-tol*))
                (<= ymin (+ rectYmax *xy-geom-tol*))
                (>= ymax (- rectYmin *xy-geom-tol*)))
         (progn
           (setq hitY (min rectYmax ymax))
           (setq xCenter (/ (+ xmin xmax) 2.0))
           (setq xDist (xy:abs (- xCenter ax)))
           (if (or (null best)
                   (> hitY (+ bestHit *xy-geom-tol*))
                   (and (xy:near hitY bestHit *xy-geom-tol*)
                        (< xDist bestXDist)))
             (progn
               (setq best      en)
               (setq bestHit   hitY)
               (setq bestXDist xDist)
             )
           )
         )
       )
     )
     best
    )
    ((eq side 'UP)
     (setq rectXmin (- ax *xy-hit-half-width*))
     (setq rectXmax (+ ax *xy-hit-half-width*))
     (setq rectYmin ay)
     (setq rectYmax (+ ay *xy-ray-len*))
     (setq best nil)
     (setq bestHit nil)
     (setq bestXDist nil)

     (foreach item textMetaList
       (setq en   (car item))
       (setq xmin (cadr item))
       (setq xmax (caddr item))
       (setq ymin (cadddr item))
       (setq ymax (nth 4 item))
       (if (and (<= xmin (+ rectXmax *xy-geom-tol*))
                (>= xmax (- rectXmin *xy-geom-tol*))
                (<= ymin (+ rectYmax *xy-geom-tol*))
                (>= ymax (- rectYmin *xy-geom-tol*)))
         (progn
           (setq hitY (max rectYmin ymin))
           (setq xCenter (/ (+ xmin xmax) 2.0))
           (setq xDist (xy:abs (- xCenter ax)))
           (if (or (null best)
                   (< hitY (- bestHit *xy-geom-tol*))
                   (and (xy:near hitY bestHit *xy-geom-tol*)
                        (< xDist bestXDist)))
             (progn
               (setq best      en)
               (setq bestHit   hitY)
               (setq bestXDist xDist)
             )
           )
         )
       )
     )
     best
    )
    (t nil)
  )
)
(defun xy:copy-text-horizontal (srcEn insPt / ed data)
  (setq ed (entget srcEn))
  (setq data
    (list
      '(0 . "TEXT")
      (cons 8  (xy:dxf 8 ed "0"))
      (cons 10 insPt)
      (cons 40 (xy:get-text-height ed))
      (cons 1  (xy:get-text-value ed))
      (cons 7  (xy:get-text-style ed))
      (cons 50 0.0)
      (cons 72 0)
      (cons 73 0)
      (cons 210 (xy:dxf 210 ed '(0.0 0.0 1.0)))
    )
  )

  (if (assoc 41 ed)
    (setq data (append data (list (assoc 41 ed))))
  )
  (if (assoc 51 ed)
    (setq data (append data (list (assoc 51 ed))))
  )
  (if (assoc 39 ed)
    (setq data (append data (list (assoc 39 ed))))
  )
  (if (assoc 62 ed)
    (setq data (append data (list (assoc 62 ed))))
  )
  (if (assoc 420 ed)
    (setq data (append data (list (assoc 420 ed))))
  )

  (entmakex data)
)
(defun xy:process-one-hline (hen lineList textMetaList / hinfo vrecs found txt rightPt startPt idx newCnt missCnt allVCnt)
  (setq hinfo (xy:hline-info hen))
  (setq vrecs (xy:get-vrecs-for-hline hen lineList))
  (setq allVCnt (length vrecs))
  (setq found   '())
  (setq missCnt 0)

  (foreach vrec vrecs
    (setq txt (xy:find-text-for-vrec textMetaList vrec))
    (if txt
      (setq found (cons (list (car vrec) txt) found))
      (setq missCnt (1+ missCnt))
    )
  )

  (setq found
        (vl-sort found
          '(lambda (a b) (< (car a) (car b)))
        )
  )

  (setq rightPt (cadddr hinfo))
  (setq startPt
        (list (+ (car rightPt) *xy-out-offx*)
              (+ (cadr rightPt) *xy-out-offy*)
              (if (caddr rightPt) (caddr rightPt) 0.0))
  )

  (setq idx 0)
  (setq newCnt 0)

  (foreach item found
    (xy:copy-text-horizontal
      (cadr item)
      (list (+ (car startPt) (* idx *xy-step-x*))
            (cadr startPt)
            (caddr startPt))
    )
    (setq idx    (1+ idx))
    (setq newCnt (1+ newCnt))
  )

  (list newCnt missCnt allVCnt)
)

(defun xy:run-yuan (sel / selList lineSS textSS lineList textList textMetaList hLines en res totalH totalNew totalMiss totalV handle ed warnCnt hY warnYText)
  (if (null sel)
    (progn
      (princ "\n未选择对象，YUAN部分结束。")
      nil
    )
    (progn
      (setq lineSS   (ssget "_X" '((0 . "LINE"))))
      (setq textSS   (ssget "_X" '((0 . "TEXT,MTEXT"))))
      (setq lineList (xy:filter-vertical-lines (xy:ss->list lineSS)))
      (setq textList (xy:ss->list textSS))
      (setq textMetaList (xy:build-text-meta-list textList))
      (setq selList  (xy:ss->list sel))

      (setq hLines '())
      (foreach en selList
        (if (xy:is-horizontal-line-p en *xy-geom-tol*)
          (setq hLines (cons en hLines))
        )
      )
      (setq hLines (reverse hLines))

      (if (null hLines)
        (progn
          (princ "\n选集中没有可处理的水平 LINE，YUAN部分结束。")
          nil
        )
        (progn
          (setq totalH    0)
          (setq totalNew  0)
          (setq totalMiss 0)
          (setq totalV    0)
          (setq warnCnt   0)
          (setq warnYText "")

          (foreach en hLines
            (setq res (xy:process-one-hline en lineList textMetaList))
            (setq totalH    (1+ totalH))
            (setq totalNew  (+ totalNew  (car res)))
            (setq totalMiss (+ totalMiss (cadr res)))
            (setq totalV    (+ totalV    (caddr res)))

            (setq ed      (entget en))
            (setq handle  (cdr (assoc 5 ed)))
            (setq hY      (caddr (xy:hline-info en)))

            (princ
              (strcat
                "\n水平线 Handle="
                handle
                " | 竖线数="
                (itoa (caddr res))
                " | 成功="
                (itoa (car res))
                " | 未找到文字="
                (itoa (cadr res))
              )
            )

            (if (/= (car res) (caddr res))
              (progn
                (setq warnCnt (1+ warnCnt))
                (setq warnYText
                      (if (= warnYText "")
                        (rtos hY 2 4)
                        (strcat warnYText ", " (rtos hY 2 4))))
                (princ
                  (strcat
                    "\n警告: 水平线 Handle="
                    handle
                    "，Y="
                    (rtos hY 2 4)
                    " 找到文字="
                    (itoa (car res))
                    "，竖线数="
                    (itoa (caddr res))
                    "。异常请检查。"
                  )
                )
              )
            )
          )

          (princ
            (strcat
              "\n--- YUAN 执行完成 ---"
              "\n处理水平线数量: " (itoa totalH)
              "\n识别竖线总数: "   (itoa totalV)
              "\n新建文字总数: "   (itoa totalNew)
              "\n未找到文字总数: " (itoa totalMiss)
            )
          )
          (if (> warnCnt 0)
            (princ
              (strcat
                "\n注意: 发现 "
                (itoa warnCnt)
                " 条水平线的找到文字数与竖线数不一致，请检查对应水平线。"
                "\n异常水平线Y坐标汇总: "
                warnYText
              )
            )
          )
          T
        )
      )
    )
  )
)

;; =========================
;; 主命令：XY
;; =========================
(defun c:XY (/ sel)
  (princ "\n选择对象，XY会共用这一批对象执行XIN和YUAN: ")
  (setq sel (ssget))
  (if (null sel)
    (princ "\n未选择对象，XY命令结束。")
    (progn
      (princ "\n开始执行 XY：先运行 XIN，再运行 YUAN。")
      (xy:run-xin sel)
      (xy:run-yuan sel)
      (princ "\nXY 执行结束。")
    )
  )
  (princ)
)

(princ "\nXY 插件已加载。输入 XY 开始使用。")
(princ)







