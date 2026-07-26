# CADTools

CADTools 是面向 AutoCAD 2018 和 ZWCAD 2026 的 AutoLISP 工具集。当前版本为 `YS-Tools v1.5.0`。

## 使用入口

- `YS`、`YSTOOLS`：打开 DCL 工具面板。面板底部的“AA整合版命令”包含外部整合版的 51 个分类命令。
- `YSOOLS`：`YS` 的兼容别名。
- `YSRELOADAA`：保存外部 `AA整合版本.lsp` 后，在当前 CAD 会话中重新加载最新版，无需重启 CAD。
- `AA整合版本.lsp`：由模块源码自动生成的单文件兼容包，可继续直接通过 APPLOAD 加载。
- `小命令/芯原XY.lsp`：由权威 XY 模块自动生成的单文件兼容包。

工具面板包含文字、对齐、颜色、移动、线段、绘图、电缆、XY 和图框处理命令。调试命令 `SHOWBB`、`ZDMLDEBUG`、`FILLFRAMES`、`ADDKEYWORD` 仍保留。

## 目录结构

```text
YS-Tools/
  YS-Tools.lsp       主加载器
  config.lsp         用户配置
  utils.lsp          公共函数
  modules/           权威命令源码
  dcl/               工具面板
  install.ps1        非破坏式安装器
  uninstall.ps1      基于清单的卸载器
小命令/              PAI、ZDML、HAO 及生成的 XY 单文件
tools/                生成与静态校验脚本
tests/                安装器往返测试
```

主加载顺序固定为：配置、公共函数、文字、对齐、颜色、移动、线段、绘图、电缆、XY、图框命令、DCL 面板。任一必需文件加载失败时，主加载器不会设置完成标志，可以修复后重新加载。

在 ZWCAD 2026 中，支持目录下的 `YS-Tools\aa-bundle.path` 用来指定最终加载的外部 `AA整合版本.lsp`。该文件应指向 `E:\366256\ZW-auto_lisp\AA整合版本.lsp`；否则模块命令可能覆盖项目主文件中的同名命令。修改文字命令模块后，必须重新生成兼容包并同步部署实际支持目录。

## 安装与卸载

双击 `YS-Tools/install.bat`，或在 PowerShell 中运行：

```powershell
.\YS-Tools\install.ps1
```

指定测试或自定义支持目录：

```powershell
.\YS-Tools\install.ps1 -SupportPaths 'D:\CAD-Support'
.\YS-Tools\install.ps1 -SupportPaths 'D:\CAD-Support' -WhatIf
```

安装器不会修改 AutoCAD 的 `acad.lsp`。它会在 `acaddoc.lsp` 中维护带唯一标记的 ASCII 加载块。针对 ZWCAD，除兼容的 `acad.lsp` 加载块外，还会把主入口登记到所有现有配置的 APPLOAD 启动组，并同步维护 `AppAutoLoad.app` 和 `appload.dfs`。如果现有 APPLOAD 项中包含外部 `AA整合版本.lsp`，安装器会自动生成 `YS-Tools/aa-bundle.path` 指向该原文件；YS 基础模块和面板加载完成后会再次加载该文件，使其中的同名命令成为最终生效版本。注册表键和启动文件修改前都会建立时间戳备份，现有 APPLOAD 项不会被覆盖。已有 `YS-Tools/config.lsp` 会被保留，不会在升级时覆盖。

安装或卸载真实 ZWCAD 支持目录前必须先保存图纸并退出 ZWCAD，防止程序退出时用内存中的旧启动组覆盖修改。安装完成后重新启动 ZWCAD，输入 `YS` 即可打开面板。

卸载入口：

```powershell
.\YS-Tools\uninstall.ps1 -SupportPaths 'D:\CAD-Support'
```

卸载器只移除自己的启动块、APPLOAD 项和安装清单内的文件，并会对其余 APPLOAD 项重新连续编号。发生用户修改的文件会移动到 `YS-Tools-backups`，不会直接删除。

## 配置

编辑 `YS-Tools/config.lsp` 可以调整文字样式、字号、颜色、表格图层、XY 几何容差和 ZDML 图框属性标记。主入口会在加载命令模块之前加载该文件。

仓库中的 LSP 和 DCL 运行文件统一使用 GBK/ANSI、CRLF，以兼容 AutoCAD 2018 和 ZWCAD 2026。PowerShell 脚本使用带 BOM 的 UTF-8。

## 构建与检查

修改模块后重新生成兼容包：

```powershell
python .\tools\build_bundle.py
```

确认生成文件没有过期，并执行静态校验：

```powershell
python .\tools\build_bundle.py --check
python .\tools\validate.py
```

安装器不会触碰真实 CAD 环境的往返测试：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\test_installer.ps1
```
