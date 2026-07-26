;;; YS-Tools v1.5.0 configuration
;;; Encoding: GBK/ANSI, CRLF

;;; --- YSDL 命令相关参数 ---
(setq *YSDL_RowFuzz*      1.0)          ; 判断文字是否在同一行的 Y 坐标容差
(setq *YSDL_CsvFileName*  "output.csv") ; 输出 CSV 文件名
(setq *YSDL_TextColor*    2)            ; 提取后文字颜色，ACI: 1 红, 2 黄, 3 绿, 4 青, 5 蓝, 6 品红, 7 白/黑

;;; --- CONT 命令相关参数 ---
(setq *CONT_TextStyle*       "宋体")    ; 目标文字样式名称
(setq *CONT_TextHeight*      4.0)       ; 目标文字高度
(setq *CONT_TextWidthFactor* 0.8)       ; 目标文字宽度因子
(setq *CONT_LineSpacing*     9.0)       ; 文字垂直间距

;;; --- EXCEL 命令相关参数 ---
(setq *EXCEL_LayerName*  "表格")        ; 表格图层名称
(setq *EXCEL_LayerColor* 3)             ; 表格图层颜色

;;; --- 快速改色命令相关参数 ---
(setq *Y_TextColor*  4)                 ; Y  命令: 青色
(setq *RR_TextColor* 1)                 ; RR 命令: 红色
(setq *UU_TextColor* 7)                 ; UU 命令: 白色/黑色
(setq *GG_TextColor* 3)                 ; GG 命令: 绿色

;;; --- XY 命令相关参数 ---
(setq *xy-geom-tol*        1e-4)        ; 几何容差
(setq *xy-ang-tol*         (/ pi 180.0)); 角度容差 1 度
(setq *xy-ray-len*         20.0)        ; 搜索射线长度
(setq *xy-hit-half-width*  1.0)         ; 命中半宽
(setq *xy-out-offx*        10.0)        ; 输出文字 X 偏移
(setq *xy-out-offy*        1.0)         ; 输出文字 Y 偏移
(setq *xy-step-x*          30.0)        ; 输出列间距
(setq *xy-warn-extend-len* 200.0)       ; 异常标记延伸长度

;;; --- ZDML 自动目录参数 ---
(setq *TKTJ-COL-OFFSETS* '(0.0 7.5 57.5))
(setq *TKTJ-ROW-GAP* 9.0)
(setq *TKTJ-TEXT-HEIGHT* 4.0)
(setq *TKTJ-TEXT-STYLE* "宋体")
(setq *TKTJ-TEXT-FONTFILE* "simsun.ttc")
(setq *TKTJ-TEXT-WIDTH-FACTOR* 0.8)
(setq *TKTJ-OUTPUT-HEADER* T)
(setq *TKTJ-SORT-BY-POSITION* T)
(setq *TKTJ-ROW-SORT-TOL* 5.0)
(setq *TKTJ-SORT-BY-PAGE* nil)

;;; --- ZDML 图框属性标记 ---
(setq *TKTJ-SHEETNO-TAGS*   '("图号" "图纸编号" "DRAWINGNO" "DWGNO"))
(setq *TKTJ-SHEETNAME-TAGS* '("图名" "图纸名称" "SHEETNAME" "DRAWINGNAME"))
(setq *TKTJ-PAGE-TAGS*      '("页码" "页号" "PAGE" "SHEET"))
(setq *TKTJ-ARCHIVE-TAGS*   '("档案号" "工程号" "设计号" "DWGNO" "DRAWINGNO"))

(princ "\n[YS-Tools] config.lsp loaded.")
(princ)
