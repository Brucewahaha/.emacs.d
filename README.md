# Emacs Configuration

这是一个面向 Emacs 30 的轻量个人配置，采用 ELPA 和 Emacs 内置功能优先的策略。配置以模块化 Lisp 文件组织，重点覆盖 Evil 编辑、项目开发、补全、文件管理、终端和 Org 工作流。

## 前提

- Emacs 30.1
- Linux、WSL 和 macOS 下建议安装 `zsh`；也可在 `local.el` 指定 Eat 使用的 shell
- 按需安装语言服务器，例如 `clangd`、`basedpyright`、`gopls`、`rust-analyzer`
- 使用高速远程开发需要本机安装 Git、OpenSSH 和 SCP，并能通过 SSH 登录 Linux 或 macOS 远端
- 首次使用或缺包时确认 ELPA 镜像可访问；包与 grammar 齐全后正常启动不会联网

## 配置结构

| 模块 | 作用 |
| --- | --- |
| `init-environment.el` | UTF-8、Shell 环境变量、direnv |
| `init-ui.el` | 主题、字体、Modeline、Tab Line |
| `init-enhance.el` | Vertico、Consult、Embark、彩虹括号 |
| `init-editing.el` | Tree-sitter、缩进、括号、基础编辑行为 |
| `init-lsp.el` | Eglot、Flymake、Consult-Eglot |
| `init-completion.el` | Corfu、Cape、Yasnippet、补全开关 |
| `init-project.el` | Project、Compilation Mode、Projectile、Magit |
| `init-remote.el` | TRAMP、tramp-rpc 高速 SSH 远程开发 |
| `init-dired.el` | Dired、Wdired、Dired Subtree |
| `init-treemacs.el` | Treemacs、项目文件树 |
| `init-term.el` | Eat、Eshell 集成 |
| `init-evil.el` | Evil、Evil Collection、多光标、快捷键 |
| `init-org.el` / `init-sicp.el` | Org、Scheme、SICP、Lisp 结构化编辑 |

## 主要插件

- 编辑与 UI：`evil`、`doric-themes`、`doom-themes`、`doom-modeline`、`nerd-icons`
- Minibuffer：`vertico`、`orderless`、`marginalia`、`consult`、`embark`
- 代码补全：`corfu`、`cape`、`yasnippet`
- 开发：内置 `eglot`、内置 `flymake`、`consult-eglot`、`treesit-auto`、`tramp-rpc`
- 文件与项目：内置 `dired`、`dired-subtree`、`treemacs`、`projectile`、`magit`
- 终端：`eat`、内置 `eshell`
- 窗口与工具：`popper`、`ace-window`、`winner`、`avy`、`helpful`
- 文本编辑：`rainbow-delimiters`、`evil-multiedit`、`evil-surround`

## 重要操作

### 中文输入

```text
C-\\                切换 Pyim 中文输入法
M-j                将光标前的拼音转换为中文
```

Pyim 使用小鹤双拼方案，候选词默认在光标附近显示。

### 主题

```text
C-c t t            在 Doom Wilmersdorf 夜间主题与 Doric Jade 浅色主题之间切换
```

Doom Themes 的 Org、Treemacs 与视觉铃声集成在两种主题下都保留。

### 代码模板

Yasnippet 提供常用代码片段的展开和占位符跳转。

```text
S-TAB              展开当前模板，或跳转到下一个模板字段
```

### Tree-sitter

仅在对应 grammar 可用时自动启用 TS Mode，缺失或不兼容时回退到传统 Major Mode。`tree-sitter/` 中的二进制与操作系统、CPU 架构和 Emacs ABI 相关，不应直接跨系统复用；使用 `M-x treesit-auto-install-all` 显式安装或重建本机 grammar。打开文件和正常启动不会自动下载。Emacs 30.1 不接受 ABI 15 的 C parser，因此 C grammar 固定到 ABI 14 的 `tree-sitter-c v0.23.6`。

### 缩进与括号

项目存在 `.editorconfig` 时，其 `indent_size` 与 `indent_style` 优先；未明确指定的部分才由 dtrt-indent 根据现有文件推断。缩进宽度确定后才启用 `indent-bars`：普通缩进线与背景融合，Tree-sitter 当前代码块中只高亮光标所在深度的一根连续竖线，颜色跟随当前主题。普通语言使用 electric-pair 自动补全括号；Emacs Lisp、Common Lisp、Scheme、Racket、Clojure 和 Geiser REPL 使用 Paredit，并在对应 Buffer 中局部关闭 electric-pair。

### 候选项操作

在文件搜索、Buffer 切换或命令执行等 Minibuffer 候选列表中，可对当前候选项执行额外操作。

```text
C-.                显示当前候选项可用的操作
M-.                直接执行最合适的候选项操作
C-h B              查看当前快捷键绑定
```

### 弹窗窗口

帮助、编译输出、诊断、消息和平台终端等临时 Buffer 由 Popper 统一管理，不打断主编辑窗口布局。

```text
C-c `              显示或隐藏最近的弹窗
M-`                在多个弹窗间切换
C-M-`              切换当前窗口是否按弹窗管理
```

### Buffer 与 Tab

```text
C-x b              按名称搜索并切换已打开 Buffer
[b / ]b            在当前 Window 的 Tab 中向左/向右切换
Ctrl+Shift+1..9    跳转到当前 Window 的第 1 到第 9 个 Tab
C-x k              关闭当前 Buffer
```

每个 Window 维护自己的 Tab 列表。普通 Buffer 和 `*Messages*`、`*Warnings*`、`*EGLOT*` 等特殊 Buffer 分组隔离。

### 窗口

```text
C-w v              在右侧分屏
C-w s              在下方分屏
C-w h/j/k/l        在 Window 间移动
C-w u              撤销窗口布局
C-w C-r            重做窗口布局
C-w o              使用 Ace Window 选择窗口
M-o                使用 Ace Window 选择窗口
```

### 项目与 Git

```text
C-c p f            在当前 Projectile 项目中查找文件
C-c p p            切换项目
M-s r              使用 ripgrep 搜索项目或目录内容
C-x g              打开 Magit Status
C-c b c            在当前项目根目录选择并执行编译命令
C-c b r            保存修改并重复当前项目的上一次编译
C-c b n / p        跳到下一个 / 上一个编译错误
```

`M-s r` 会优先把选区或光标处符号作为初始搜索内容。编译输出由 Compilation Mode 解析，错误位置可以直接跳回源文件。

### 文件管理

使用 `C-x d` 打开 Dired；`C-x C-j` 会打开当前文件所属目录并定位到该文件。进入其他目录时会自动关闭当前 Dired Buffer，避免目录 Buffer 和 Tab 不断累积。Evil Normal 状态下：

```text
j / k              下移 / 上移
h / l              左移 / 右移光标
RET / gf           打开文件或进入目录
- / ^              返回上级目录
m / u / U          标记 / 取消标记 / 清除全部标记
C / R              复制 / 移动或重命名当前或标记文件
d / x              标记删除 / 执行全部已标记删除
D                  立即删除当前或标记文件
+                  新建目录
Y                  复制当前文件名
g r                刷新目录
q                  关闭 Dired Window
i                  进入 Wdired 重命名模式
TAB                展开或收起子目录
```

Wdired 默认进入 Evil Normal 状态，按 `i`、`a` 等进入 Insert 编辑文件名，按 `ESC` 返回 Normal 但不退出 Wdired。使用 `ZZ` 或 `C-c C-c` 提交修改，使用 `ZQ` 或 `C-c C-k` 放弃修改。需要批量修改文件名时，可选中共同片段后按 `S-r`，或重复按 `M-d` 添加匹配，再统一编辑。

### Treemacs

```text
C-e                打开当前项目文件树；再次按关闭可见 Treemacs 侧栏
h                  将文件树根目录上移一级
l                  目录设为新根；文件直接打开
H                  显示/隐藏隐藏文件
a / r / c / d      新建 / 重命名 / 复制 / 删除
\                  关闭 Treemacs
```

### 补全与 LSP

```text
C-c t c            全局开关 Corfu 代码补全弹窗
C-c t r            全局开关彩虹括号
g d                Eglot 跳转定义
g r                Eglot 查找引用
M-,                返回上一次 Definition/Reference 跳转位置
C-M-,              在 Xref 历史中向前
C-o / C-i          在 Evil 的广义跳转历史中后退 / 前进
K                  显示符号文档
C-c l r            重命名符号
C-c l a            Code Action
C-c l f            格式化当前 Buffer
M-n / M-p          下一个 / 上一个 Flymake 诊断
```

关闭代码补全弹窗不会关闭 Eglot、诊断、跳转、重命名或格式化功能。

`g d` 跳到符号定义，`g r` 列出引用该符号的位置。`M-,` 只处理 Xref 跳转历史，返回定义或引用来源时最准确；`C-o` / `C-i` 还会包含搜索和其他 Evil 跳转。

### 远程开发

`tramp-rpc` 使用 SSH 上的 MessagePack RPC server 代替传统 TRAMP 的远端 shell 命令解析，适合远程文件、Eglot、Git/Magit、编译和终端操作。TRAMP、msgpack 和 tramp-rpc 由配置管理；Git checkout 使用官方 release server，不要求本机安装 Rust。

```text
C-x C-f
/rpc:user@host:/path/to/project
```

首次连接会下载约 850 KB 的对应平台 server，并部署到远端的用户缓存目录。远端支持 Linux 和 macOS，不支持 Windows；Windows 可以作为本地 Emacs 客户端，但会关闭 OpenSSH 不支持的 ControlMaster，遇到兼容问题时使用普通 `/ssh:user@host:/path` 回退。

### 多光标编辑

```text
M-d                添加下一个匹配
M-D                添加前一个匹配
Visual 选中文本后 R  选中当前 Buffer 的全部相同文本
C-n / C-p          在多光标匹配项间移动
RET                切换当前匹配项是否参与编辑
C-g                退出多光标会话
```

矩形、多行同列编辑仍建议使用 Evil Visual Block。

### 终端

```text
C-`                打开或关闭平台终端
```

Linux、WSL 和 macOS 使用 Eat，并优先选择 `local.el` 指定的 shell、zsh 或 bash。原生 Windows 使用底部 Eshell，避免 Eat 对 Unix `/usr/bin/env` 的依赖。Eat 加载后也会接管 Eshell 中需要完整终端能力的交互程序。

### Org 日程与项目

```text
C-c c t            Capture 内容到统一 Inbox
C-c c w / p        直接创建工作 / 个人任务
C-c c W / P        直接创建工作 / 个人项目
C-c c e            直接记录有明确时间的日程或约会
C-c c j            记录当天自由日记
C-c a d            今日 Agenda 与下一步行动
C-c a i            查看 Inbox 中待分类任务
C-c a u            查看未设置日期的工作和个人任务
C-c a p            查看工作和个人任务的 NEXT、WAITING、TODO
C-c C-w            将 Inbox 内容 Refile 到工作、个人或日程文件
C-c C-t            切换任务状态
C-c C-s            设置计划开始日期
C-c C-d            设置截止日期
C-c C-x C-s        归档当前任务或项目
```

日常文件位于 `~/org/`：`inbox.org` 是唯一的默认 Capture 入口；`work.org` 保存工作；`personal.org` 保存个人项目、生活事务和 Someday；`calendar.org` 保存带具体时间的事件；`journal.org` 保存自由日记且不进入 Agenda。完成或取消的内容归档到各文件对应的 `_archive.org` 文件。配置不会自动创建或询问创建 `~/org/`；新机器应先手动建立该目录，目标文件可在首次 Capture 保存时创建。

Capture 会打开聚焦的 `CAPTURE-*` 临时 Buffer。输入完成后按 `C-c C-c` 保存，或按 `C-c C-k` 取消，随后自动恢复 Capture 前的窗口布局；无需手动切换到目标 `.org` 文件。Capture 默认处于 Evil Insert 状态，按 `ESC q` 也可取消。

`C-c c t` 只要求标题，创建时间自动记录；在 Capture Buffer 中可按需用 `C-c C-q` 添加标签、`C-c C-t` 修改状态、`C-c C-s` 设置计划时间、`C-c C-d` 设置截止时间，再补充说明。`C-c c w/p` 与 `C-c c W/P` 用于已明确归属的任务或项目。项目不强制要求多个子任务。`C-c c e` 直接记录名称、开始时间和备注。`C-c c j` 在当天日期下创建自由记录。

Agenda 读取 Inbox、工作、个人和日程四个文件；每日视图显示当天时间事项、可立即做的 NEXT，并在标题中显示 Inbox 待处理数量。日程会在 30 分钟前开始显示桌面提醒，之后每 10 分钟重复提醒；桌面需要可用的通知服务。

Android 可使用 Orgzly Revived，将其 WebDAV 仓库指向与 `~/org/` 同步的远程目录。避免在手机与桌面同时编辑同一文件。

Calendar 使用周一作为每周第一天，并显示中国节日。`M-x calendar` 后双击任意日期可打开该日期的 Agenda。习惯任务可放在 `calendar.org` 的 `Habits` 标题下，或放在 `personal.org`；前者适合把所有周期性时间项集中查看，后者适合把习惯与个人项目放在一起。

`org-modern` 已启用，用于美化 Org 标题、标签、TODO、复选框和表格。Refile 会一次性显示完整路径；选择带标题的目标，例如 `work.org/Tasks`，不要选择文件名本身。

### 跨平台本机设置

配置支持 Linux、WSL、macOS 与原生 Windows。复制 `local.example.el` 为 `local.el` 可覆盖本机包镜像、外部工具路径、Eat shell 和通知后端；`local.el` 不会提交到 Git。登录 shell 环境会先导入，再将 `my/extra-exec-paths` 中真实存在的目录加入 `PATH` 与 `exec-path`。Tree-sitter grammar 必须在每台机器上分别构建；不要同步 `tree-sitter/` 生成目录。

所有系统默认使用 TUNA ELPA 镜像，可在 `local.el` 切换到官方源。Linux 使用 D-Bus 通知，macOS 使用 `osascript` 通知，Windows 默认回退到 Emacs 消息提示，可在 `local.el` 配置 Toast。Linux、WSL 与 macOS 使用 Eat，原生 Windows 使用 Eshell。daemon 后创建 GUI Frame 时会重新初始化字体、Modeline 图标、Dired 图标和平滑滚动。GUI 剪贴板可直接使用；TTY、SSH 与 WSL 终端没有额外的系统剪贴板桥接，默认只写入 Emacs kill-ring。

#### 临时窗口关闭

Evil Normal 状态下，`q` 会关闭当前的 Popper 弹窗或侧边临时窗口，例如 Help、编译输出、Messages、Eat、Eshell 与搜索结果；在普通编辑 Buffer 中，`q` 保持 Evil 的宏录制功能。`C-c \`` 仍用于显示或隐藏最近的 Popper，`M-\`` 用于循环切换。

#### Agenda Buffer 操作

`C-c a d` 打开的 Agenda 是只读的任务面板，不是普通 Org 编辑 Buffer。使用 `j` / `k` 选择任务；不要按 `i`，它是 Evil 的插入命令，而 Agenda 不支持直接插入文本。

```text
j / k              下移 / 上移选择任务
RET                跳到任务的源 Org 文件并在原处编辑
TAB                在另一个 Window 显示任务源位置
t                  切换所选任务的 TODO 状态
s                  为所选任务设置或修改计划日期
C-c C-d            为所选任务设置或修改截止日期
C-c C-w            将所选任务 Refile 到项目或其他目标
a                  归档所选任务或项目
r                  刷新 Agenda
g j                输入日期并跳转
g t                回到今天
q                  退出 Agenda
```

典型流程是：`C-c a d` -> 用 `j` / `k` 选择 -> `RET` 查看任务上下文或 `t` / `s` 直接更新 -> `r` 刷新。项目任务通常在 `RET` 跳回源文件后，再用 `M-S-RET` 新建子任务。

### 全局 Org 快捷键

```text
C-c c              Org Capture
C-c a              Org Agenda
C-c l              保存 Org Link
```

`C-c c` 和 `C-c a` 可在任何 Buffer 中调用。

### 代码文档

```text
g h                在 Eglot 管理的代码中显示光标处符号的悬浮文档
K                  在回显区显示光标处符号的简要文档
```

## 启动性能

默认不记录每个 `require` 的耗时，避免启动期 advice 开销。需要分析启动时，在 `early-init.el` 增加：

```elisp
(setq my/enable-startup-benchmarking t)
```

启动后可执行 `M-x sanityinc/require-times` 查看模块加载耗时。
