;;; ====================================================================
;;; YS-Tools - ???1??????
;;; ????: BIAN(???) LAN(????????) XIN(???) XY(???+???)
;;; ====================================================================

(vl-load-com)

;;; --- BIAN ???¡À?? ---
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

(defun c:BIAN (/ *error* ss i ent ed sty cnt)
  (defun *error* (msg)
    (if (and msg (not (member (strcase msg)
                              '("FUNCTION CANCELLED"
                                "QUIT / EXIT ABORT"
                                "CONSOLE BREAK"))))
      (princ (strcat "\nBIAN ????: " msg))
    )
    (princ)
  )
  (setq sty (if (tblsearch "STYLE" "HZ") "HZ" (getvar "TEXTSTYLE")))
  (if (setq ss (ssget '((0 . "LINE"))))
    (progn
      (command "_.UNDO" "_BE")
      (setq i 0
            cnt (sslength ss))
      (repeat cnt
        (setq ent (ssname ss i)
              ed  (entget ent))
        (bian-draw-one ed sty)
        (setq i (1+ i))
      )
      (command "_.UNDO" "_E")
      (if (tblsearch "STYLE" "HZ")
        (princ (strcat "\nBIAN ?????????? " (itoa cnt) " ?????"))
        (princ
          (strcat
            "\nBIAN ?????????? "
            (itoa cnt)
            " ????????HZ¦Ä????????????? "
            sty
            "."
          )
        )
      )
    )
    (princ "\n???????LINE??????????BIAN??")
  )
  (princ)
)

;;; --- LAN ???û`??+??? ---
(defun lan-get-option (vert_count move_right / kw)
  (initget "Shang Xia")
  (setq kw
    (getkword
      (strcat "\n??? " (itoa vert_count)
              " ????????????????? " (rtos move_right 2 0)
              " ??¦Ë????????? [????(Shang)/????(Xia)] <????>: ")))
  (cond
    ((or (null kw) (equal kw "Shang")) "S")
    ((equal kw "Xia") "X")
  )
)

(defun c:LAN ( / *error* ss total_count
               vert_lines  horiz_lines  diag_lines
               vert_count  horiz_count  diag_count
               opt  move_right  dy  proceed
               i  ent  copy_ent  entdata
               pt1 pt2 new_pt1 new_pt2 )
  (defun *error* (msg)
    (if (and msg (not (member (strcase msg)
                              '("FUNCTION CANCELLED"
                                "QUIT / EXIT ABORT"
                                "CONSOLE BREAK"))))
      (princ (strcat "\nLAN ????: " msg))
    )
    (princ)
  )
  (setq ss (ssget))
  (if (null ss)
    (princ "\n???????¦Ê¦Æ???")
    (progn
      (setq total_count (sslength ss)
            vert_lines  '()
            horiz_lines '()
            diag_lines  '())
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
      (setq proceed T)
      (cond
        ((= vert_count 0)
         (setq proceed nil)
         (princ "\n¦Ä???????????????????"))
        ((/= horiz_count 1)
         (setq proceed nil)
         (princ (strcat "\n?????????? 1 ?????????????? "
                        (itoa horiz_count) " ??")))
        ((/= diag_count vert_count)
         (setq proceed nil)
         (princ (strcat "\n§Ò??????(" (itoa diag_count)
                        ")?????????(" (itoa vert_count)
                        ")?????")))
      )
      (when proceed
        (setq move_right (* 5 vert_count))
        (setq opt (lan-get-option vert_count move_right))
        (if (null opt)
          (princ "\n?????????")
          (progn
            (setq dy (if (equal opt "S") 5.0 -5.0))
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
            (princ
              (strcat "\n???! ???§Ø?????????????"
                      "\n????? & §Ò??: ???? " (rtos move_right 2 0)
                      " ??¦Ë + " (if (> dy 0) "????" "????") " 5 ??¦Ë??"
                      "\n      ????: " (if (> dy 0) "????" "????")
                      " 5 ??¦Ë + ??????????? " (rtos move_right 2 0) " ??¦Ë??????????"))
          )
        )
      )
    )
  )
  (princ)
)

;;; --- XIN ??? ---
(defun c:XIN ( / ss i ent entData pt1 pt2 leftX rightX topY bottomY
                countSS countNum insertPt textStr rightPt)
  (setq ss (ssget '((0 . "LINE"))))
  (if (null ss)
    (princ "\n¦Ä????¦Ê?????")
    (progn
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
      (princ (strcat "\n????????????? " (itoa (sslength ss)) " ??????"))
    )
  )
  (princ)
)

;;; --- XY ???¡¤??? (????XY???) ---
(setq *xy-last-xin-counts* nil)
(setq *xy-last-vrec-map*   nil)

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
  (while (< a 0.0) (setq a (+ a (* 2.0 pi))))
  (while (>= a (* 2.0 pi)) (setq a (- a (* 2.0 pi))))
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

(defun xy:get-text-rotation (ed) (xy:dxf 50 ed 0.0))
(defun xy:get-text-height (ed) (xy:dxf 40 ed 3.0))
(defun xy:get-text-style (ed) (xy:dxf 7 ed "Standard"))
(defun xy:get-text-value (ed) (xy:dxf 1 ed ""))

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
        (setq vrec (xy:make-vrec-if-valid en hinfo *xy-geom-tol*))
        (if vrec
          (setq vrecs (cons vrec vrecs))
        )
      )
      (xy:dedup-vrecs vrecs *xy-geom-tol*)
    )
  )
)

(defun xy:run-xin (sel / selList lineSS lineList ss i ent entData rightPt handle countMap vrecMap vrecs countNum insertPt textStr totalLines)
  (setq *xy-last-xin-counts* nil)
  (setq *xy-last-vrec-map* nil)
  (setq selList  (xy:ss->list sel))
  (princ "\r??????????????...")
  (setq lineSS   (ssget "_X" '((0 . "LINE"))))
  (if lineSS
    (princ (strcat "\r????? " (itoa (sslength lineSS)) " ?????????????????..."))
    (princ "\r¦Ä????¦Ê?????")
  )
  (setq lineList (xy:filter-vertical-lines (xy:ss->list lineSS)))
  (setq ss (ssadd))
  (foreach ent selList
    (if (xy:is-horizontal-line-p ent *xy-geom-tol*)
      (ssadd ent ss)
    )
  )
  (if (= (sslength ss) 0)
    (progn
      (princ "\n???????§á??XIN??????????")
      nil
    )
    (progn
      (setq i 0)
      (setq countMap '())
      (setq vrecMap '())
      (setq totalLines (sslength ss))
      (princ (strcat "\n??????? " (itoa totalLines) " ???????..."))
      (while (< i totalLines)
        (if (= (rem i 10) 0)
          (princ (strcat "\r???????: " (itoa (1+ i)) "/" (itoa totalLines)))
        )
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
      (princ (strcat "\rXIN????????????? " (itoa totalLines) " ????????"))
      (setq *xy-last-xin-counts* (reverse countMap))
      (setq *xy-last-vrec-map*   (reverse vrecMap))
      T
    )
  )
)

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
           (list x 'DOWN lo ven))
          ((and (xy:near (cadr lo) hy tol)
                (> (cadr hi) (+ hy tol)))
           (list x 'UP hi ven))
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
    ((eq side 'DOWN) (if (< (cadr pa) (cadr pb)) a b))
    ((eq side 'UP)   (if (> (cadr pa) (cadr pb)) a b))
    (t a)
  )
)

(defun xy:dedup-vrecs (lst tol / sorted out rec top)
  (setq sorted (vl-sort lst '(lambda (a b) (< (car a) (car b)))))
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
                      (list en (car bbox) (cadr bbox) (caddr bbox) (cadddr bbox) rot)
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
     (setq best nil bestHit nil bestXDist nil)
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
               (setq best en bestHit hitY bestXDist xDist))
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
     (setq best nil bestHit nil bestXDist nil)
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
               (setq best en bestHit hitY bestXDist xDist))
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
  (if (assoc 41 ed) (setq data (append data (list (assoc 41 ed)))))
  (if (assoc 51 ed) (setq data (append data (list (assoc 51 ed)))))
  (if (assoc 39 ed) (setq data (append data (list (assoc 39 ed)))))
  (if (assoc 62 ed) (setq data (append data (list (assoc 62 ed)))))
  (if (assoc 420 ed) (setq data (append data (list (assoc 420 ed)))))
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
  (setq found (vl-sort found '(lambda (a b) (< (car a) (car b)))))
  (setq rightPt (cadddr hinfo))
  (setq startPt
        (list (+ (car rightPt) *xy-out-offx*)
              (+ (cadr rightPt) *xy-out-offy*)
              (if (caddr rightPt) (caddr rightPt) 0.0)))
  (setq idx 0 newCnt 0)
  (foreach item found
    (xy:copy-text-horizontal
      (cadr item)
      (list (+ (car startPt) (* idx *xy-step-x*))
            (cadr startPt)
            (caddr startPt)))
    (setq idx (1+ idx))
    (setq newCnt (1+ newCnt))
  )
  (list newCnt missCnt allVCnt)
)

(defun xy:run-yuan (sel / selList lineSS textSS lineList textList textMetaList hLines en res totalH totalNew totalMiss totalV handle ed warnCnt hY warnYText)
  (if (null sel)
    (progn (princ "\n¦Ä??§Ø???YUAN??????§³?") nil)
    (progn
      (princ "\r??????????????????????...")
      (setq lineSS   (ssget "_X" '((0 . "LINE"))))
      (setq textSS   (ssget "_X" '((0 . "TEXT,MTEXT"))))
      (if lineSS
        (princ (strcat "\r????? " (itoa (sslength lineSS)) " ??????"))
      )
      (if textSS
        (princ (strcat "\r????? " (itoa (sslength textSS)) " ?????????"))
      )
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
        (progn (princ "\n???????§á?????????? LINE??YUAN???????¦Ä??§³?") nil)
        (progn
          (setq totalH 0 totalNew 0 totalMiss 0 totalV 0 warnCnt 0 warnYText "")
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
                "\n???? Handle=" handle
                " | ???????=" (itoa (caddr res))
                " | ???=" (itoa (car res))
                " | ¦Ä???????=" (itoa (cadr res))))
            (if (/= (car res) (caddr res))
              (progn
                (setq warnCnt (1+ warnCnt))
                (setq warnYText
                      (if (= warnYText "")
                        (rtos hY 2 4)
                        (strcat warnYText ", " (rtos hY 2 4))))
                (princ
                  (strcat
                    "\n????: ???? Handle=" handle ",Y="
                    (rtos hY 2 4) " ???????=" (itoa (car res))
                    ",???????=" (itoa (caddr res)) ",??????î•"))
              )
            )
          )
          (princ
            (strcat
              "\n--- YUAN ??§ß?? ---"
              "\n????????????: " (itoa totalH)
              "\n??????????: " (itoa totalV)
              "\n????????????: " (itoa totalNew)
              "\n¦Ä???????????: " (itoa totalMiss)))
          (if (> warnCnt 0)
            (princ
              (strcat
                "\n???: ???? " (itoa warnCnt)
                " ?????????????????????????????¡ê????????????"
                "\n??????Y?????§Ò?: " warnYText)))
          T
        )
      )
    )
  )
)

(defun c:XY (/ sel)
  (princ "\n??????(XY????????????XIN??YUAN): ")
  (setq sel (ssget))
  (if (null sel)
    (princ "\n¦Ä??§Ø???XY¦Ä????¦Ê¦Â?????")
    (progn
      (princ "\n?????? XY????????? XIN???????? YUAN??")
      (xy:run-xin sel)
      (xy:run-yuan sel)
      (princ "\nXY ??§ß?????")
    )
  )
  (princ)
)

(princ "\n[YS-Tools] cable-tools.lsp loaded.")
(princ)
