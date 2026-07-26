;;; YS-Tools v1.5.0 PAI commands
;;; Encoding: GBK/ANSI, CRLF

(if (and (boundp '*ys-pai-loaded*) *ys-pai-loaded*)
  (princ)
  (progn
    (vl-load-com)

    (defun pai:r (v)
      (if (numberp v) (float v) 0.0)
    )

    (defun pai:num-or-nil (v)
      (if (numberp v) (float v) nil)
    )

    (defun pai:valid-pt-p (pt)
      (and (listp pt)
           (numberp (car pt))
           (numberp (cadr pt)))
    )

    (defun pai:valid-box-p (box)
      (and (listp box)
           (numberp (car box))
           (numberp (cadr box))
           (numberp (nth 2 box))
           (numberp (nth 3 box)))
    )

    (defun pai:normalize-box (box)
      (if (pai:valid-box-p box)
        (list (min (car box) (nth 2 box))
              (min (cadr box) (nth 3 box))
              (max (car box) (nth 2 box))
              (max (cadr box) (nth 3 box)))
      )
    )

    (defun pai:safe-call (fn args)
      (setq fn
             (vl-catch-all-apply
               fn
               args))
      (if (vl-catch-all-error-p fn)
        nil
        fn)
    )

    (defun pai:ed-pt (ed code / v y z)
      (setq v (if (assoc code ed) (cdr (assoc code ed)) nil)
            y (if (assoc (+ code 10) ed) (cdr (assoc (+ code 10) ed)) 0.0)
            z (if (assoc (+ code 20) ed) (cdr (assoc (+ code 20) ed)) 0.0))
      (cond
        ((listp v)
         (list (pai:r (car v))
               (pai:r (cadr v))
               (pai:r (if (caddr v) (caddr v) 0.0))))
        ((numberp v)
         (list (pai:r v) (pai:r y) (pai:r z)))
      )
    )

    (defun pai:points-bbox (pts / xs ys)
      (setq pts (vl-remove-if-not 'pai:valid-pt-p pts))
      (if pts
        (progn
          (setq xs (mapcar 'car pts)
                ys (mapcar 'cadr pts))
          (pai:normalize-box
            (list (apply 'min xs)
                  (apply 'min ys)
                  (apply 'max xs)
                  (apply 'max ys))))
      )
    )

    (defun pai:lwpoly-pts (ent ed / elev pts pair v x)
      (setq elev (if (assoc 38 ed) (cdr (assoc 38 ed)) 0.0)
            pts  '()
            x    nil)
      (foreach pair ed
        (cond
          ((= (car pair) 10)
           (setq v (cdr pair))
           (if (listp v)
             (setq pts
                    (cons
                      (trans
                        (list (pai:r (car v))
                              (pai:r (cadr v))
                              (pai:r elev))
                        ent
                        0)
                      pts))
             (setq x (pai:r v))))
          ((and (= (car pair) 20) (numberp x))
           (setq pts
                  (cons
                    (trans
                      (list x (pai:r (cdr pair)) (pai:r elev))
                      ent
                      0)
                    pts))
           (setq x nil))))
      (reverse pts)
    )

    (defun pai:poly-pts (ent / pts sub sbed pt)
      (setq pts '()
            sub (entnext ent))
      (while (and sub
                  (setq sbed (entget sub))
                  (/= (cdr (assoc 0 sbed)) "SEQEND"))
        (setq pt (pai:ed-pt sbed 10))
        (if pt
          (setq pts (cons (trans pt ent 0) pts))
        )
        (setq sub (entnext sub))
      )
      (reverse pts)
    )

    (defun pai:get-bbox-dxf (ent / ed typ pts center radius)
      (setq ed  (entget ent)
            typ (if ed (cdr (assoc 0 ed)) nil))
      (cond
        ((null typ) nil)
        ((= typ "LINE")
         (pai:points-bbox
           (vl-remove nil
             (list (pai:ed-pt ed 10)
                   (pai:ed-pt ed 11)))))
        ((= typ "LWPOLYLINE")
         (pai:points-bbox (pai:lwpoly-pts ent ed)))
        ((= typ "POLYLINE")
         (pai:points-bbox (pai:poly-pts ent)))
        ((= typ "CIRCLE")
         (setq center (trans (pai:ed-pt ed 10) ent 0)
               radius (pai:r (cdr (assoc 40 ed))))
         (if center
           (list (- (car center) radius)
                 (- (cadr center) radius)
                 (+ (car center) radius)
                 (+ (cadr center) radius))))
      )
    )

    (defun pai:get-bbox-activex (ent / obj min-arr max-arr min-pt max-pt result)
      (if (and ent
               (setq obj (vlax-ename->vla-object ent))
               (vlax-method-applicable-p obj 'GetBoundingBox))
        (progn
          (setq result
                 (vl-catch-all-apply
                   '(lambda ()
                      (vla-GetBoundingBox obj 'min-arr 'max-arr))))
          (if (not (vl-catch-all-error-p result))
            (progn
              (setq min-pt (vlax-safearray->list min-arr)
                    max-pt (vlax-safearray->list max-arr))
              (pai:normalize-box
                (list (car min-pt) (cadr min-pt) (car max-pt) (cadr max-pt))))
          )
        )
      )
    )

    (defun pai:get-bbox (ent)
      (or (pai:get-bbox-dxf ent)
          (pai:get-bbox-activex ent))
    )

    (defun pai:transform-point-2d (pt ins base sx sy ang / x y c s)
      (if (and (pai:valid-pt-p pt)
               (pai:valid-pt-p ins)
               (pai:valid-pt-p base)
               (numberp sx)
               (numberp sy)
               (numberp ang))
        (progn
          (setq x (- (car pt)  (car base))
                y (- (cadr pt) (cadr base))
                c (cos ang)
                s (sin ang)
                x (* x sx)
                y (* y sy))
          (list (+ (car ins) (- (* x c) (* y s)))
                (+ (cadr ins) (+ (* x s) (* y c)))
                0.0))
      )
    )

    (defun pai:transform-bbox-for-insert (box ins base sx sy ang / pts out)
      (setq box (pai:normalize-box box))
      (if box
        (progn
          (setq pts
                 (list
                   (list (car box)   (cadr box) 0.0)
                   (list (car box)   (nth 3 box) 0.0)
                   (list (nth 2 box) (cadr box) 0.0)
                   (list (nth 2 box) (nth 3 box) 0.0))
                out
                 (vl-remove nil
                   (mapcar
                     '(lambda (pt)
                        (pai:transform-point-2d pt ins base sx sy ang))
                     pts)))
          (pai:points-bbox out)
        )
      )
    )

    (defun pai:bbox-union (box1 box2)
      (setq box1 (pai:normalize-box box1)
            box2 (pai:normalize-box box2))
      (cond
        ((null box1) box2)
        ((null box2) box1)
        (T
         (list (min (car box1) (car box2))
               (min (cadr box1) (cadr box2))
               (max (nth 2 box1) (nth 2 box2))
               (max (nth 3 box1) (nth 3 box2)))))
    )

    (defun pai:ent-type (ent / ed)
      (setq ed (entget ent))
      (if ed
        (cdr (assoc 0 ed))
        "<unknown>")
    )

    (defun pai:block-name (ent / ed)
      (setq ed (entget ent))
      (if (and ed (= (cdr (assoc 0 ed)) "INSERT"))
        (cdr (assoc 2 ed))
      )
    )

    (defun pai:block-base-point (name / row pt)
      (setq row (tblsearch "BLOCK" name)
            pt  (if row (cdr (assoc 10 row)) nil))
      (if (pai:valid-pt-p pt)
        (list (pai:r (car pt))
              (pai:r (cadr pt))
              (pai:r (if (caddr pt) (caddr pt) 0.0)))
        '(0.0 0.0 0.0))
    )

    (defun pai:block-def-bbox (name / head ent ed typ box)
      (setq head (tblobjname "BLOCK" name)
            box  nil)
      (if head
        (progn
          (setq ent (entnext head))
          (while ent
            (setq ed  (entget ent)
                  typ (if ed (cdr (assoc 0 ed)) nil))
            (if (= typ "ENDBLK")
              (setq ent nil)
              (progn
                (setq box (pai:bbox-union box (pai:get-bbox ent)))
                (setq ent (entnext ent))
              )
            )
          )
          box
        )
      )
    )

    (defun pai:get-bbox-insert-by-blockdef (ent / ed name ins sx sy ang base local)
      (setq ed   (entget ent)
            name (if ed (cdr (assoc 2 ed)) nil))
      (if name
        (progn
          (setq ins   (pai:safe-call 'trans (list (pai:ed-pt ed 10) ent 0))
                sx    (if (assoc 41 ed) (pai:r (cdr (assoc 41 ed))) 1.0)
                sy    (if (assoc 42 ed) (pai:r (cdr (assoc 42 ed))) 1.0)
                ang   (if (assoc 50 ed) (pai:r (cdr (assoc 50 ed))) 0.0)
                base  (pai:block-base-point name)
                local (pai:block-def-bbox name))
          (if (and ins local)
            (pai:transform-bbox-for-insert local ins base sx sy ang)
          )
        )
      )
    )

    (defun pai:ents-after (ent / result cur)
      (setq result '()
            cur    (entnext ent))
      (while cur
        (setq result (cons cur result)
              cur    (entnext cur))
      )
      (reverse result)
    )

    (defun pai:delete-ents (ents)
      (foreach ent ents
        (if (entget ent)
          (entdel ent)
        )
      )
    )

    (defun pai:get-bbox-insert-by-explode (ent / obj copied before result new-ents box cmdecho)
      (setq obj (pai:safe-call 'vlax-ename->vla-object (list ent)))
      (if obj
        (progn
          (setq before (entlast)
                copied (pai:safe-call 'vla-Copy (list obj)))
          (if copied
            (progn
              (setq copied  (pai:safe-call 'vlax-vla-object->ename (list copied))
                    cmdecho (getvar "CMDECHO"))
              (setvar "CMDECHO" 0)
              (setq result
                     (pai:safe-call
                       'vl-cmdf
                       (list "_.EXPLODE" copied "")))
              (setvar "CMDECHO" cmdecho)

              (if (and copied (entget copied))
                (entdel copied)
              )

              (if result
                (progn
                  (setq new-ents (pai:ents-after before)
                        box      nil)
                  (foreach e new-ents
                    (if (not (equal e copied))
                      (setq box (pai:bbox-union box (pai:get-bbox e)))
                    )
                  )
                  (pai:delete-ents new-ents)
                  box)
                (progn
                  (if new-ents (pai:delete-ents new-ents))
                  nil))
            )
          )
        )
      )
    )

    (defun pai:get-bbox-insert-safe (ent)
      (or (pai:safe-call 'pai:get-bbox-insert-by-blockdef (list ent))
          (pai:safe-call 'pai:get-bbox-insert-by-explode (list ent)))
    )

    (defun pai:get-frame-bbox (ent)
      (if (= (pai:ent-type ent) "INSERT")
        (or (pai:get-bbox ent)
            (pai:get-bbox-insert-safe ent))
        (pai:get-bbox ent))
    )

    (defun pai:rect-width (box)
      (- (nth 2 box) (car box))
    )

    (defun pai:rect-height (box)
      (- (nth 3 box) (cadr box))
    )

    (defun pai:rect-area (box)
      (* (abs (pai:rect-width box))
         (abs (pai:rect-height box)))
    )

    (defun pai:rect-center (box)
      (list (/ (+ (car box) (nth 2 box)) 2.0)
            (/ (+ (cadr box) (nth 3 box)) 2.0)
            0.0)
    )

    (defun pai:list-min (vals / result)
      (if vals
        (progn
          (setq result (car vals))
          (foreach v (cdr vals)
            (if (< v result)
              (setq result v)
            )
          )
          result
        )
      )
    )

    (defun pai:list-max (vals / result)
      (if vals
        (progn
          (setq result (car vals))
          (foreach v (cdr vals)
            (if (> v result)
              (setq result v)
            )
          )
          result
        )
      )
    )

    (defun pai:point-in-rect-p (pt box tol)
      (and (>= (car pt) (- (car box) tol))
           (<= (car pt) (+ (nth 2 box) tol))
           (>= (cadr pt) (- (cadr box) tol))
           (<= (cadr pt) (+ (nth 3 box) tol)))
    )

    (defun pai:probe-point (ent / box pt)
      (cond
        ((setq box (pai:get-bbox ent))
         (pai:rect-center box))
        ((setq pt (cdr (assoc 10 (entget ent))))
         (list (car pt) (cadr pt) 0.0))
      )
    )

    (defun pai:frame-ent (frame)
      (car frame)
    )

    (defun pai:frame-box (frame)
      (cadr frame)
    )

    (defun pai:frame-minx (frame)
      (car (pai:frame-box frame))
    )

    (defun pai:frame-miny (frame)
      (cadr (pai:frame-box frame))
    )

    (defun pai:collect-frames (ss / frames idx ent box)
      (setq frames '()
            idx    0)
      (while (< idx (sslength ss))
        (setq ent (ssname ss idx)
              box (pai:get-frame-bbox ent))
        (if box
          (setq frames (cons (list ent box) frames))
        )
        (setq idx (1+ idx))
      )
      frames
    )

    (defun pai:lowest-miny (frames / base-y)
      (if frames
        (progn
          (setq base-y (pai:frame-miny (car frames)))
          (foreach frame (cdr frames)
            (if (< (pai:frame-miny frame) base-y)
              (setq base-y (pai:frame-miny frame))
            )
          )
          base-y
        )
      )
    )

    (defun pai:owner-frame (ent frames tol / probe frame area best best-area)
      (if (setq probe (pai:probe-point ent))
        (progn
          (foreach frame frames
            (if (pai:point-in-rect-p probe (pai:frame-box frame) tol)
              (progn
                (setq area (pai:rect-area (pai:frame-box frame)))
                (if (or (null best) (< area best-area))
                  (setq best      frame
                        best-area area)
                )
              )
            )
          )
          best
        )
      )
    )

    (defun pai:crossing-window (box / corners ucs-corners xs ys)
      (setq corners
             (list
               (list (car box)   (cadr box) 0.0)
               (list (car box)   (nth 3 box) 0.0)
               (list (nth 2 box) (cadr box) 0.0)
               (list (nth 2 box) (nth 3 box) 0.0))
            ucs-corners
             (mapcar
               '(lambda (pt) (trans pt 0 1))
               corners)
            xs (mapcar 'car ucs-corners)
            ys (mapcar 'cadr ucs-corners))
      (list
        (list (pai:list-min xs) (pai:list-min ys) 0.0)
        (list (pai:list-max xs) (pai:list-max ys) 0.0))
    )

    (defun pai:ssget-crossing-from-box (box / win result)
      (setq win (pai:crossing-window box)
            result
              (vl-catch-all-apply
                '(lambda ()
                   (ssget "_C" (car win) (cadr win)))))
      (if (vl-catch-all-error-p result)
        nil
        result)
    )

    (defun pai:collect-members (frame frames claimed tol / box ss idx ent owner members)
      (if (= (pai:ent-type (pai:frame-ent frame)) "INSERT")
        (list (list (pai:frame-ent frame)) claimed)
        (progn
          (setq box     (pai:frame-box frame)
                members (list (pai:frame-ent frame))
                ss      (pai:ssget-crossing-from-box box))
          (if ss
            (progn
              (setq idx 0)
              (while (< idx (sslength ss))
                (setq ent (ssname ss idx))
                (cond
                  ((equal ent (pai:frame-ent frame))
                   nil)
                  ((member ent claimed)
                   nil)
                  (T
                   (setq owner (pai:owner-frame ent frames tol))
                   (if (and owner
                            (equal (pai:frame-ent owner) (pai:frame-ent frame)))
                     (progn
                       (setq members (cons ent members))
                       (setq claimed (cons ent claimed))
                     )
                   )
                  )
                )
                (setq idx (1+ idx))
              )
            )
          )
          (list members claimed)
        )
      )
    )

    (defun pai:move-entity (ent dx dy / result)
      (setq result
             (vl-catch-all-apply
               '(lambda ()
                  (vla-Move
                    (vlax-ename->vla-object ent)
                    (vlax-3d-point '(0.0 0.0 0.0))
                    (vlax-3d-point (list dx dy 0.0))
                  )
                )
             )
      )
      (not (vl-catch-all-error-p result))
    )

    (defun pai:report-frame (index members dx dy)
      (princ
        (strcat
          "\nFrame "
          (itoa index)
          ": "
          (itoa (length members))
          " objects, move dx="
          (rtos dx 2 3)
          ", dy="
          (rtos dy 2 3)))
    )

    (defun c:SHOWBB (/ ent box)
      (setq ent (car (entsel "\nSelect object to inspect bounding box: ")))
      (if (null ent)
        (princ "\nNothing selected.")
        (progn
          (setq box (pai:get-bbox ent))
          (princ (strcat "\nType: " (pai:ent-type ent)))
          (if (= (pai:ent-type ent) "INSERT")
            (princ (strcat "\nBlock name: " (vl-princ-to-string (pai:block-name ent))))
          )
          (if (and (null box) (= (pai:ent-type ent) "INSERT"))
            (setq box (pai:get-bbox-insert-safe ent))
          )
          (if box
            (progn
              (princ
                (strcat
                  "\nMin point: ("
                  (rtos (car box) 2 3)
                  ", "
                  (rtos (cadr box) 2 3)
                  ")"))
              (princ
                (strcat
                  "\nMax point: ("
                  (rtos (nth 2 box) 2 3)
                  ", "
                  (rtos (nth 3 box) 2 3)
                  ")"))
              (princ
                (strcat
                  "\nWidth: "
                  (rtos (pai:rect-width box) 2 3)
                  ", Height: "
                  (rtos (pai:rect-height box) 2 3)))
            )
            (princ "\nThis object does not expose a bounding box.")
          )
        )
      )
      (princ)
    )

    (defun c:PAI (/ *error* gap tol frame-ss frames base-y cur-x
                     claimed groups frame box dx dy result members
                     moved skipped frame-index)
      (defun *error* (msg)
        (if (and msg
                 (not (member (strcase msg)
                              '("FUNCTION CANCELLED"
                                "QUIT / EXIT ABORT"
                                "CONSOLE BREAK"))))
          (princ (strcat "\nError: " msg))
        )
        (princ)
      )

      (vl-load-com)

      (setq tol 1e-8)
      (princ "\nPAI - arrange frames and enclosed contents on one horizontal line.")

      (initget 6)
      (setq gap (getdist "\nSpecify gap between adjacent frames <300>: "))
      (if (null gap)
        (setq gap 300.0)
      )

      (princ
        "\nSelect one outer border object for each frame. Content inside each border will move with it."
      )
      (setq frame-ss (ssget))

      (if (null frame-ss)
        (princ "\nNothing selected.")
        (progn
          (setq frames (pai:collect-frames frame-ss))
          (if (null frames)
            (progn
              (princ "\nNo valid frame objects were found.")
              (setq frame-index 0)
              (while (< frame-index (sslength frame-ss))
                (setq frame (ssname frame-ss frame-index))
                (princ
                  (strcat
                    "\nSelected object "
                    (itoa (1+ frame-index))
                    ": "
                    (pai:ent-type frame)
                    (if (= (pai:ent-type frame) "INSERT")
                      (strcat " / " (vl-princ-to-string (pai:block-name frame)))
                      "")))
                (setq frame-index (1+ frame-index)))
            )
            (progn
              (setq frames
                     (vl-sort
                       frames
                       '(lambda (a b)
                          (if (= (pai:frame-minx a) (pai:frame-minx b))
                            (< (pai:frame-miny a) (pai:frame-miny b))
                            (< (pai:frame-minx a) (pai:frame-minx b))
                          )
                        )
                     )
              )

              (setq base-y  (pai:lowest-miny frames)
                    cur-x   (pai:frame-minx (car frames))
                    claimed (mapcar 'pai:frame-ent frames)
                    groups  '()
                    frame-index 0)

              (foreach frame frames
                (setq box    (pai:frame-box frame)
                      dx     (- cur-x (car box))
                      dy     (- base-y (cadr box))
                      result (pai:collect-members frame frames claimed tol)
                      members (car result)
                      claimed (cadr result)
                      groups (cons (list members dx dy) groups)
                      frame-index (1+ frame-index))

                (pai:report-frame frame-index members dx dy)

                (setq cur-x (+ cur-x (pai:rect-width box) gap))
              )

              (setq groups  (reverse groups)
                    moved   0
                    skipped 0)

              (foreach group groups
                (foreach ent (car group)
                  (if (pai:move-entity ent (cadr group) (caddr group))
                    (setq moved (1+ moved))
                    (setq skipped (1+ skipped))
                  )
                )
              )

              (princ
                (strcat
                  "\nDone. Frames arranged: "
                  (itoa (length groups))
                  ", objects moved: "
                  (itoa moved)
                  "."))
              (princ
                (strcat
                  "\nBaseline Y: "
                  (rtos base-y 2 3)
                  ", gap: "
                  (rtos gap 2 3)
                  "."))
              (if (> skipped 0)
                (princ
                  (strcat
                    "\nSkipped objects: "
                    (itoa skipped)
                    " (usually locked-layer objects or unsupported entities)."))
              )
            )
          )
        )
      )
      (princ)
    )

    (princ "\nPAI loaded. Command: PAI. Debug command: SHOWBB.")
    (princ)
    (setq *ys-pai-loaded* T)
  )
)
(princ)
