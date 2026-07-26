// YS-Tools DCL 工具栏定义
// 兼容 AutoCAD 2018 + ZWCAD 2026

ys_tools_toolbar : dialog {
  label = "YS-Tools v1.5.0";
  key = "ys_toolbar";
  initial_focus = "close_btn";

  : row {
    : column {
      : boxed_column {
        label = "文字工具";
        : button { key = "btn_cont";   label = "CONT (合并文字)"; }
        : button { key = "btn_txt";    label = "TXT/T (拆分文字)"; }
        : button { key = "btn_ysdl";   label = "YSDL (导出文字)"; }
        : button { key = "btn_hei";    label = "HEI (修改字高)"; }
        : button { key = "btn_qstxt";  label = "QSTXT (快速文字)"; }
        : button { key = "btn_he";     label = "HE (文字求和)"; }
        : button { key = "btn_qw";     label = "QW (修改字高)"; }
        : button { key = "btn_wi";     label = "WI (通配替换)"; }
        : button { key = "btn_gtx";    label = "GTX (提取文字)"; }
        : button { key = "btn_gty";    label = "GTY (提取文字)"; }
      }
    }

    : column {
      : boxed_column {
        label = "对齐工具";
        : button { key = "btn_zhong";  label = "ZHONG (居中)"; }
        : button { key = "btn_zuo";    label = "ZUO (左对齐)"; }
        : button { key = "btn_you";    label = "YOU (右对齐)"; }
        : button { key = "btn_shang";  label = "SHANG (上对齐)"; }
        : button { key = "btn_xia";    label = "XIA (下对齐)"; }
      }

      : boxed_column {
        label = "颜色/移动";
        : button { key = "btn_y";      label = "Y (青色)"; }
        : button { key = "btn_rr";     label = "RR (红色)"; }
        : button { key = "btn_uu";     label = "UU (白色)"; }
        : button { key = "btn_gg";     label = "GG (绿色)"; }
        : button { key = "btn_syi";    label = "SYI (上移)"; }
        : button { key = "btn_xyi";    label = "XYI (下移)"; }
        : button { key = "btn_zyy";    label = "ZYI (左移)"; }
        : button { key = "btn_yyi";    label = "YYI (右移)"; }
      }
    }

    : column {
      : boxed_column {
        label = "线段工具";
        : button { key = "btn_yan";    label = "YAN (延长)"; }
        : button { key = "btn_syan";   label = "SYAN (上缩短)"; }
        : button { key = "btn_xyan";   label = "XYAN (下缩短)"; }
        : button { key = "btn_xSUO";   label = "XSUO (缩短上)"; }
        : button { key = "btn_sSUO";   label = "SSUO (缩短下)"; }
        : button { key = "btn_sj";     label = "SJ (上角标)"; }
        : button { key = "btn_xj";     label = "XJ (下角标)"; }
        : button { key = "btn_long";   label = "LONG (总长)"; }
      }
    }

    : column {
      : boxed_column {
        label = "绘图/线缆";
        : button { key = "btn_excel";  label = "EXCEL (表格)"; }
        : button { key = "btn_nu";     label = "NU (数值减)"; }
        : button { key = "btn_kuang";  label = "KUANG (图框)"; }
        : button { key = "btn_bian";   label = "BIAN (编号)"; }
        : button { key = "btn_lan";    label = "LAN (复制线组)"; }
        : button { key = "btn_xin";    label = "XIN (统计)"; }
        : button { key = "btn_xy";     label = "XY (提取)"; }
      }

      : boxed_column {
        label = "图框工具";
        : button { key = "btn_pai";    label = "PAI (排列)"; }
        : button { key = "btn_zdml";   label = "ZDML (目录)"; }
        : button { key = "btn_hao";    label = "HAO (页码)"; }
        : button { key = "btn_diag";   label = "DIAGFRAME"; }
      }
    }
  }

  : row {
    : button {
      key = "btn_aa";
      label = "AA整合版命令 (51)";
      width = 22;
      fixed_width = true;
    }
    : button {
      key = "btn_aa_reload";
      label = "重载 AA";
      width = 12;
      fixed_width = true;
    }
    : button {
      key = "close_btn";
      label = "关闭";
      is_cancel = true;
      width = 12;
      fixed_width = true;
    }
  }
}

ys_aa_toolbar : dialog {
  label = "AA整合版命令";
  key = "ys_aa_toolbar";
  initial_focus = "aa_command_list";

  : list_box {
    key = "aa_command_list";
    width = 68;
    height = 28;
    fixed_width = true;
    fixed_height = true;
  }

  : row {
    : button {
      key = "aa_run_btn";
      label = "执行";
      is_default = true;
      width = 12;
      fixed_width = true;
    }
    : button {
      key = "aa_close_btn";
      label = "关闭";
      is_cancel = true;
      width = 12;
      fixed_width = true;
    }
  }
}
