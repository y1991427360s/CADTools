;;; ====================================================================
;;; YS-Tools v1.5.0 - CAD startup loader and DCL toolbar
;;; Target: AutoCAD 2018 + ZWCAD 2026
;;; Encoding: GBK/ANSI, CRLF
;;; ====================================================================

(vl-catch-all-apply 'vl-load-com '())

(defun ys:safe-getvar (name / result)
  (setq result (vl-catch-all-apply 'getvar (list name)))
  (if (vl-catch-all-error-p result) nil result)
)

(defun ys:find-root (/ root candidate)
  (setq root
    (cond
      ((and (boundp '*YS-Tools-Path*)
            *YS-Tools-Path*
            (findfile (strcat *YS-Tools-Path* "\\YS-Tools.lsp")))
       *YS-Tools-Path*)
      ((and (setq candidate (getenv "YS_TOOLS_PATH"))
            (> (strlen candidate) 0)
            (findfile (strcat candidate "\\YS-Tools.lsp")))
       candidate)
      ((setq candidate (findfile "YS-Tools\\YS-Tools.lsp"))
       (vl-filename-directory candidate))
      ((setq candidate (findfile "YS-Tools.lsp"))
       (vl-filename-directory candidate))
      (T nil)
    )
  )
  root
)

(defun ys:load-required (path label / actual result)
  (setq actual (findfile path))
  (cond
    ((null actual)
     (setq *ys-tools-load-errors*
       (cons (strcat label ": file not found - " path)
             *ys-tools-load-errors*))
     nil)
    (T
     (setq result (vl-catch-all-apply 'load (list actual)))
     (if (vl-catch-all-error-p result)
       (progn
         (setq *ys-tools-load-errors*
           (cons
             (strcat label ": " (vl-catch-all-error-message result))
             *ys-tools-load-errors*))
         nil)
       T))
  )
)

(defun ys:print-load-errors (/ item)
  (foreach item (reverse *ys-tools-load-errors*)
    (princ (strcat "\n[YS-Tools] load failed - " item))
  )
  (princ)
)

(defun ys:read-first-line (path / stream value)
  (if (and path (findfile path) (setq stream (open path "r")))
    (progn
      (setq value (read-line stream))
      (close stream)
      value)
  )
)

(defun ys:find-aa-bundle (/ candidate pointer)
  (cond
    ((and (boundp '*YS-AA-Bundle-Path*)
          *YS-AA-Bundle-Path*
          (setq candidate (findfile *YS-AA-Bundle-Path*)))
     candidate)
    ((and (setq candidate (getenv "YS_AA_BUNDLE_PATH"))
          (> (strlen candidate) 0)
          (setq candidate (findfile candidate)))
     candidate)
    ((and (boundp '*YS-Tools-Path*)
          *YS-Tools-Path*
          (setq pointer
            (strcat *YS-Tools-Path* "\\aa-bundle.path"))
          (setq candidate (ys:read-first-line pointer))
          (setq candidate (findfile candidate)))
     candidate)
    (T nil)
  )
)

(defun ys:load-aa-bundle (show-warning / actual result)
  (setq actual (ys:find-aa-bundle))
  (cond
    ((null actual)
     (if show-warning
       (princ
         "\n[YS-Tools] AA整合版本.lsp 未配置或文件不存在。"))
     nil)
    (T
     (setq result (vl-catch-all-apply 'load (list actual)))
     (if (vl-catch-all-error-p result)
       (progn
         (princ
           (strcat
             "\n[YS-Tools] AA整合版加载失败: "
             (vl-catch-all-error-message result)))
         nil)
       (progn
         (setq *ys-aa-bundle-loaded-path* actual)
         (princ (strcat "\n[YS-Tools] AA整合版已加载: " actual))
         T)))
  )
)

(defun C:YSRELOADAA ()
  (ys:load-aa-bundle T)
  (princ)
)

(if (and (boundp '*ys-tools-loaded*)
         *ys-tools-loaded*
         (boundp '*ys-tools-version*)
         (= *ys-tools-version* "1.5.0"))
  (princ)
  (progn
    (setq *ys-tools-load-errors* '())
    (setq *YS-Tools-Path* (ys:find-root))
    (if *YS-Tools-Path*
      (progn
        (setq *YS-Tools-Project-Path*
          (vl-filename-directory *YS-Tools-Path*))
        (princ
          (cond
            ((ys:safe-getvar "ZWCADVERSION")
             "\n[YS-Tools] ZWCAD detected. Loading v1.5.0...")
            ((ys:safe-getvar "ACADVER")
             "\n[YS-Tools] AutoCAD detected. Loading v1.5.0...")
            (T "\n[YS-Tools] Loading v1.5.0...")))

        (ys:load-required
          (strcat *YS-Tools-Path* "\\config.lsp") "config")
        (ys:load-required
          (strcat *YS-Tools-Path* "\\utils.lsp") "utils")
        (ys:load-required
          (strcat *YS-Tools-Path* "\\modules\\text-tools.lsp") "text-tools")
        (ys:load-required
          (strcat *YS-Tools-Path* "\\modules\\align-tools.lsp") "align-tools")
        (ys:load-required
          (strcat *YS-Tools-Path* "\\modules\\color-tools.lsp") "color-tools")
        (ys:load-required
          (strcat *YS-Tools-Path* "\\modules\\move-tools.lsp") "move-tools")
        (ys:load-required
          (strcat *YS-Tools-Path* "\\modules\\line-tools.lsp") "line-tools")
        (ys:load-required
          (strcat *YS-Tools-Path* "\\modules\\draw-tools.lsp") "draw-tools")
        (ys:load-required
          (strcat *YS-Tools-Path* "\\modules\\cable-tools.lsp") "cable-tools")
        (ys:load-required
          (strcat *YS-Tools-Path* "\\modules\\xy-tools.lsp") "xy-tools")
        (ys:load-required
          (strcat *YS-Tools-Project-Path* "\\小命令\\排列框PAI.LSP") "PAI")
        (ys:load-required
          (strcat *YS-Tools-Project-Path* "\\小命令\\自动目录ZDML.lsp") "ZDML")
        (ys:load-required
          (strcat *YS-Tools-Project-Path* "\\小命令\\自动页码HAO.lsp") "HAO")
        (ys:load-required
          (strcat *YS-Tools-Path* "\\dcl\\toolbar.lsp") "toolbar")

        ;;; The user's monolithic bundle is the final command override layer.
        (ys:load-aa-bundle nil)

        (if *ys-tools-load-errors*
          (ys:print-load-errors)
          (progn
            (defun C:YS () (C:YSTOOLS) (princ))
            (defun C:YSOOLS () (C:YS) (princ))
            (setq *ys-tools-version* "1.5.0")
            (setq *ys-tools-loaded* T)
            (princ "\n[YS-Tools] Loaded. Commands: YS / YSTOOLS.")))
      )
      (progn
        (setq *ys-tools-load-errors*
          '("root: set YS_TOOLS_PATH or add the project parent to CAD support paths"))
        (ys:print-load-errors))
    )
  )
)
(princ)
