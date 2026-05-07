;;; ====================================================================
;;; YS-Tools v1.4 - CAD startup loader and DCL toolbar
;;; Target: AutoCAD 2018 + ZWCAD 2026
;;; Encoding: GBK/ANSI, CRLF
;;; ====================================================================

(if *ys-tools-loaded*
  (princ)
  (progn
    (setq *ys-tools-loaded* T)
    (vl-load-com)

    (defun ys:safe-getvar (name / result)
      (setq result (vl-catch-all-apply 'getvar (list name)))
      (if (vl-catch-all-error-p result) nil result)
    )

    (defun ys:find-root (/ env-val fpath)
      (if (and (boundp '*YS-Tools-Path*) *YS-Tools-Path*)
        *YS-Tools-Path*
        (progn
          (setq env-val (getenv "YS_TOOLS_PATH"))
          (if (and env-val (> (strlen env-val) 0))
            env-val
            (progn
              (setq fpath (findfile "YS-Tools\\YS-Tools.lsp"))
              (if fpath
                (vl-filename-directory fpath)
                (progn
                  (setq fpath (findfile "YS-Tools.lsp"))
                  (if fpath
                    (vl-filename-directory fpath)
                    nil
                  )
                )
              )
            )
          )
        )
      )
    )

    (defun ys:parent-dir (path)
      (if path (vl-filename-directory path) nil)
    )

    (defun ys:load-file (file / actual result)
      (if (and file (> (strlen file) 0))
        (progn
          (setq actual (findfile file))
          (if actual
            (progn
              (setq result (vl-catch-all-apply 'load (list actual)))
              (if (vl-catch-all-error-p result)
                (progn
                  (princ (strcat "\n[YS-Tools] load failed: " actual " - " (vl-catch-all-error-message result)))
                  nil
                )
                T
              )
            )
            nil
          )
        )
        nil
      )
    )

    (defun ys:load-first (files / loaded item)
      (setq loaded nil)
      (foreach item files
        (if (and (null loaded) (ys:load-file item))
          (setq loaded T)
        )
      )
      loaded
    )

    (setq *YS-Tools-Path* (ys:find-root))
    (setq *YS-Tools-Project-Path* (ys:parent-dir *YS-Tools-Path*))

    (princ
      (cond
        ((ys:safe-getvar "ZWCADVERSION") "\n[YS-Tools] ZWCAD detected. Loading...")
        ((ys:safe-getvar "ACADVER") "\n[YS-Tools] AutoCAD detected. Loading...")
        (T "\n[YS-Tools] Loading...")
      )
    )

    ;; Load the known-good GBK package first. YS-Tools must not override these commands.
    (ys:load-first
      (list
        (if *YS-Tools-Project-Path* (strcat *YS-Tools-Project-Path* "\\AA整合版本.lsp") "")
        "E:/366256/vibecoding/CADTools/AA整合版本.lsp"
        "AA整合版本.lsp"
        "AA_main.lsp"
      )
    )

    ;; Extra standalone commands used by the toolbar.
    (ys:load-first
      (list
        (if *YS-Tools-Project-Path* (strcat *YS-Tools-Project-Path* "\\小命令\\排列框PAI.LSP") "")
        "E:/366256/vibecoding/CADTools/小命令/排列框PAI.LSP"
        "小命令\\排列框PAI.LSP"
        "排列框PAI.LSP"
      )
    )
    (ys:load-first
      (list
        (if *YS-Tools-Project-Path* (strcat *YS-Tools-Project-Path* "\\小命令\\自动目录ZDML.lsp") "")
        "E:/366256/vibecoding/CADTools/小命令/自动目录ZDML.lsp"
        "小命令\\自动目录ZDML.lsp"
        "自动目录ZDML.lsp"
      )
    )
    (ys:load-first
      (list
        (if *YS-Tools-Project-Path* (strcat *YS-Tools-Project-Path* "\\小命令\\自动页码HAO.lsp") "")
        "E:/366256/vibecoding/CADTools/小命令/自动页码HAO.lsp"
        "小命令\\自动页码HAO.lsp"
        "自动页码HAO.lsp"
      )
    )

    ;; KUANG is kept here because the old draw-tools module also redefined EXCEL/NU.
    (defun ys:make-eff-poly (p / x y p1 p2 p3 p4 p5 p6)
      (setq x (car p))
      (setq y (cadr p))
      (setq p1 (list x y 0.0))
      (setq p2 (list (+ x 390.0) y 0.0))
      (setq p3 (list (+ x 390.0) (- y 237.0) 0.0))
      (setq p4 (list (+ x 210.0) (- y 237.0) 0.0))
      (setq p5 (list (+ x 210.0) (- y 287.0) 0.0))
      (setq p6 (list x (- y 287.0) 0.0))
      (list p1 p2 p3 p4 p5 p6)
    )

    (if (not (member "C:KUANG" (atoms-family 1)))
      (defun C:KUANG (/ pt pts)
        (vl-load-com)
        (setq pt (getpoint "\nPick upper-left point for L frame: "))
        (if pt
          (progn
            (setq pts (ys:make-eff-poly pt))
            (command "_.PLINE"
                     (nth 0 pts) "_non"
                     (nth 1 pts) "_non"
                     (nth 2 pts) "_non"
                     (nth 3 pts) "_non"
                     (nth 4 pts) "_non"
                     (nth 5 pts) "_close")
            (princ "\nL frame created. Size: 390x237 + 210x50.")
          )
          (princ "\nCanceled.")
        )
        (princ)
      )
    )

    (if *YS-Tools-Path*
      (ys:load-file (strcat *YS-Tools-Path* "\\dcl\\toolbar.lsp"))
      (ys:load-file "YS-Tools\\dcl\\toolbar.lsp")
    )

    (defun C:YS ()
      (if (member "C:YSTOOLS" (atoms-family 1))
        (C:YSTOOLS)
        (princ "\n[YS-Tools] Toolbar is not loaded.")
      )
      (princ)
    )

    (defun C:YSOOLS ()
      (C:YS)
    )

    (princ "\n[YS-Tools] Loaded. Commands: YS / YSTOOLS.")
    (princ)
  )
)
