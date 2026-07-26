;;; YS-Tools v1.5.0 HAO commands
;;; Encoding: GBK/ANSI, CRLF

(if (and (boundp '*ys-hao-loaded*) *ys-hao-loaded*)
  (princ)
  (progn
    ;;; ============================================================
    ;;; FILLFRAMES.lsp
    ;;; 功能：批量填写图框属性 —— 页码（自动排序）+ 项目编号
    ;;; 排序方式：按Y轴从上到下，Y相同时按X从左到右
    ;;; 使用方法：加载后执行命令 HAO
    ;;; ============================================================

    (vl-load-com)

    ;; ── 工具函数 ──────────────────────────────────────────────────

    ;; 判断实体是否为带属性的块参照
    (defun is-attblock (ent / ed)
      (setq ed (entget ent))
      (and (= (cdr (assoc 0 ed)) "INSERT")
           (= (cdr (assoc 66 ed)) 1))   ; 66=1 表示有属性
    )

    ;; 获取块参照的所有属性对象列表 (VLA object)
    (defun get-att-objects (blk-obj / atts att-list)
      (setq atts (vlax-invoke blk-obj 'GetAttributes))
      atts
    )

    ;; 读取属性对象的标记名（大写）
    (defun att-tag (att-obj)
      (strcase (vlax-get-property att-obj 'TagString))
    )

    ;; 读取属性对象的当前值
    (defun att-value (att-obj)
      (vlax-get-property att-obj 'TextString)
    )

    ;; 写入属性值
    (defun set-att-value (att-obj val)
      (vlax-put-property att-obj 'TextString val)
    )

    ;; 获取块参照的插入点，返回普通 list (x y z)
    ;; InsertionPoint 返回的是 variant/safearray，必须用 vlax-safearray->list 转换
    (defun blk-insertpt (blk-obj / raw)
      (setq raw (vlax-get-property blk-obj 'InsertionPoint))
      (vlax-safearray->list (vlax-variant-value raw))
    )

    ;; ── 识别图框块 ────────────────────────────────────────────────

    ;; 判断一个块是否为图框：
    ;; 策略：检查属性标记中是否含有常见图框关键词
    (defun is-frame-block (blk-obj / atts tags found)
      (setq atts (get-att-objects blk-obj)
            found nil)
      (foreach att atts
        (setq tag (att-tag att))
        (if (or (wcmatch tag "*页*")
                (wcmatch tag "*PAGE*")
                (wcmatch tag "*图号*")
                (wcmatch tag "*编号*")
                (wcmatch tag "*项目*")
                (wcmatch tag "*单位*")
                (wcmatch tag "*日期*")
                (wcmatch tag "*比例*")
                (wcmatch tag "*设计*")
                (wcmatch tag "*审核*"))
          (setq found T)
        )
      )
      found
    )

    ;; 收集当前图纸中所有图框块
    (defun collect-frame-blocks (/ ss i ent blk result)
      (setq result '())
      (setq ss (ssget "X" '((0 . "INSERT") (66 . 1))))
      (if ss
        (progn
          (setq i 0)
          (while (< i (sslength ss))
            (setq ent (ssname ss i)
                  blk (vlax-ename->vla-object ent))
            (if (is-frame-block blk)
              (setq result (cons blk result))
            )
            (setq i (1+ i))
          )
        )
      )
      result
    )

    ;; ── 排序 ──────────────────────────────────────────────────────

    ;; 按Y从大到小（上到下），Y相同时按X从小到大（左到右）
    ;; 容差：Y差值小于 tolerance 视为同行
    (defun sort-frames-by-position (frame-list / tolerance)
      (setq tolerance 100.0)  ; 单位与图纸一致，可根据需要调整
      (vl-sort frame-list
        (function
          (lambda (a b / pa pb ya yb xa xb)
            (setq pa (blk-insertpt a)
                  pb (blk-insertpt b)
                  ya (cadr pa)
                  yb (cadr pb)
                  xa (car pa)
                  xb (car pb))
            (if (< (abs (- ya yb)) tolerance)
              (< xa xb)          ; 同行：X小的在前
              (> ya yb)          ; 不同行：Y大的（靠上）在前
            )
          )
        )
      )
    )

    ;; ── 属性标记匹配 ──────────────────────────────────────────────

    ;; 在属性列表中查找匹配关键词的属性对象
    ;; keywords: 标记关键词列表（大写），返回第一个匹配的 att-obj 或 nil
    (defun find-att-by-keywords (atts keywords / result)
      (setq result nil)
      (foreach att atts
        (if (null result)
          (progn
            (setq tag (att-tag att))
            (foreach kw keywords
              (if (and (null result) (wcmatch tag kw))
                (setq result att)
              )
            )
          )
        )
      )
      result
    )

    ;; ── 填写逻辑 ──────────────────────────────────────────────────

    ;; 页码属性的候选标记关键词（可扩展）
    (defun page-keywords ()
      '("*页码*" "*页次*" "页" "*PAGE*")
    )

    ;; 总页数属性的候选标记关键词
    (defun total-page-keywords ()
      '("*总页*" "*共*页*" "*TOTAL*")
    )

    ;; 档案号属性的候选标记关键词
    (defun proj-num-keywords ()
      '("*档案号*" "*档案*")
    )

    ;; 比例属性的候选标记关键词
    (defun scale-keywords ()
      '("*比例*" "*图纸比例*")
    )

    ;; 填写单个图框
    (defun fill-one-frame (blk-obj page-num total-pages archive-num scale-value / atts pg-att tp-att ar-att sc-att)
      (setq atts (get-att-objects blk-obj))

      ;; 查找并填写页码
      (setq pg-att (find-att-by-keywords atts (page-keywords)))
      (if pg-att
        (set-att-value pg-att (itoa page-num))
        (princ (strcat "\n  [警告] 未找到页码属性，块名: "
                       (vlax-get-property blk-obj 'Name)))
      )

      ;; 查找并填写总页数
      (setq tp-att (find-att-by-keywords atts (total-page-keywords)))
      (if tp-att
        (set-att-value tp-att (itoa total-pages))
      )

      ;; 查找并填写档案号（前缀 + 两位页码，如 SHY2025504-901-EE-01）
      (if (and archive-num (> (strlen archive-num) 0))
        (progn
          (setq ar-att (find-att-by-keywords atts (proj-num-keywords)))
          (if ar-att
            (set-att-value ar-att
              (strcat archive-num
                      (if (< page-num 10) "0" "")  ; 不足两位补前导零
                      (itoa page-num)))
            (princ (strcat "\n  [警告] 未找到档案号属性，块名: "
                           (vlax-get-property blk-obj 'Name)))
          )
        )
      )

      ;; 查找并填写比例
      (if (and scale-value (> (strlen scale-value) 0))
        (progn
          (setq sc-att (find-att-by-keywords atts (scale-keywords)))
          (if sc-att
            (set-att-value sc-att scale-value)
            (princ (strcat "\n  [警告] 未找到比例属性，块名: "
                           (vlax-get-property blk-obj 'Name)))
          )
        )
      )

      ;; 刷新块显示
      (vlax-invoke blk-obj 'Update)
    )

    ;; ── 诊断功能 ──────────────────────────────────────────────────

    ;; 打印某个块的所有属性标记，用于调试
    (defun diagnose-frame (blk-obj / atts)
      (setq atts (get-att-objects blk-obj))
      (princ (strcat "\n块名: " (vlax-get-property blk-obj 'Name)))
      (foreach att atts
        (princ (strcat "\n  标记: [" (att-tag att) "]  当前值: [" (att-value att) "]"))
      )
    )

    ;; ── 主命令：HAO ───────────────────────────────────────────────

    ;; 从选集中提取图框块 VLA 对象列表
    (defun collect-frames-from-ss (ss / i ent blk result)
      (setq result '())
      (if ss
        (progn
          (setq i 0)
          (while (< i (sslength ss))
            (setq ent (ssname ss i)
                  blk (vlax-ename->vla-object ent))
            (if (and (is-attblock ent) (is-frame-block blk))
              (setq result (cons blk result))
            )
            (setq i (1+ i))
          )
        )
      )
      result
    )

    (defun fillframes-run (/ ss frames sorted archive-num scale-value start-page total-pages i pg)

      (princ "\n=== HAO：批量填写图框属性 ===")

      ;; 1. 让用户框选要处理的图框
      (princ "\n请选择要填写的图框块（框选或点选，回车确认）：")
      (setq ss (ssget '((0 . "INSERT") (66 . 1))))

      (if (null ss)
        (progn
          (princ "\n[取消] 未选择任何对象。\n")
          (exit)
        )
      )

      ;; 2. 从选集中筛选出图框块
      (setq frames (collect-frames-from-ss ss))

      (if (null frames)
        (progn
          (princ "\n[错误] 选中的对象中未识别到图框块。")
          (princ "\n提示：请使用 DIAGFRAME 确认图框属性标记是否包含页码等关键词。\n")
          (exit)
        )
      )

      (princ (strcat "\n识别到 " (itoa (length frames)) " 个图框块"))

      ;; 3. 排序
      (setq sorted (sort-frames-by-position frames))
      (princ "，已按位置排序（从上到下，从左到右）。")

      ;; 4. 输入档案号
      (setq archive-num
        (getstring T "\n请输入档案号（直接回车跳过不填写）: "))

      ;; 5. 输入比例
      (setq scale-value
        (getstring T "\n请输入比例（直接回车跳过不填写）: "))

      ;; 6. 输入起始页码
      (setq start-page
        (getint "\n请输入起始页码（默认为1，直接回车使用默认值）: "))
      (if (null start-page) (setq start-page 1))

      ;; 7. 批量填写
      (setq i 0)
      (setq total-pages (length sorted))

      (princ "\n开始填写属性...")
      (foreach blk sorted
        (setq pg (+ start-page i))
        (princ (strcat "\n  第 " (itoa pg) " 页 → 块名: "
                       (vlax-get-property blk 'Name)
                       "  位置: ("
                       (rtos (car (blk-insertpt blk)) 2 0)
                       ", "
                       (rtos (cadr (blk-insertpt blk)) 2 0)
                       ")"))
        (fill-one-frame blk pg total-pages archive-num scale-value)
        (setq i (1+ i))
      )

      ;; 8. 刷新视图
      (command "_.REGEN")

      (princ (strcat "\n=== 完成！共填写 " (itoa total-pages) " 个图框 ===\n"))
    )

    (defun c:HAO ()
      (fillframes-run)
    )

    (defun c:FILLFRAMES ()
      (fillframes-run)
    )

    ;; ── 辅助命令：DIAGFRAME（诊断图框属性标记）─────────────────────

    (defun c:DIAGFRAME (/ ent blk)
      (princ "\n请点击选择一个图框块：")
      (setq ent (car (entsel)))
      (if (and ent (is-attblock ent))
        (diagnose-frame (vlax-ename->vla-object ent))
        (princ "\n[错误] 所选对象不是带属性的块。")
      )
      (princ "\n")
    )

    ;; ── 辅助命令：ADDKEYWORD（向代码添加自定义关键词提示）──────────

    (defun c:ADDKEYWORD ()
      (princ "\n当前页码关键词: ")
      (foreach kw (page-keywords) (princ (strcat "[" kw "] ")))
      (princ "\n当前项目编号关键词: ")
      (foreach kw (proj-num-keywords) (princ (strcat "[" kw "] ")))
      (princ "\n当前比例关键词: ")
      (foreach kw (scale-keywords) (princ (strcat "[" kw "] ")))
      (princ "\n提示：如需添加新关键词，请直接编辑 FILLFRAMES.lsp 中对应的函数。\n")
    )

    (princ "\nFILLFRAMES.lsp 已加载。")
    (princ "\n  HAO         - 选中图框后批量填写页码和档案号")
    (princ "\n  FILLFRAMES  - 兼容旧命令入口")
    (princ "\n  DIAGFRAME   - 诊断图框属性标记（帮助排查匹配问题）")
    (princ "\n  ADDKEYWORD  - 查看当前已配置的关键词\n")
    (setq *ys-hao-loaded* T)
  )
)
(princ)
