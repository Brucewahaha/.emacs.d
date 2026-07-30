# Emacs Configuration

这是一个面向 Emacs 30 的轻量个人配置，采用 ELPA 和 Emacs 内置功能优先的策略。配置以模块化 Lisp 文件组织，重点覆盖 Evil 编辑、项目开发、补全、文件管理、终端和 Org 工作流。

## 前提

- Emacs 30.1
- Linux、WSL 和 macOS 下建议安装 `zsh`；也可在 `local.el` 指定 Eat 使用的 shell
- 按需安装语言服务器，例如 `clangd`、`basedpyright`、`gopls`、`rust-analyzer`
- 使用高速远程开发需要本机安装 Git、OpenSSH 和 SCP，并能通过 SSH 登录 Linux 或 macOS 远端
- 首次使用或缺包时确认 GNU/NonGNU ELPA 镜像及官方 MELPA 可访问；包与 grammar 齐全后正常启动不会联网

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
:q / :q!           关闭当前 Buffer / 放弃修改后关闭
:wq / :x / ZZ      保存并关闭当前 Buffer
:qa / :wqa         保存提示后退出整个 Emacs
```

每个 Window 维护自己的 Tab 列表。普通 Buffer 和 `*Messages*`、`*Warnings*`、`*EGLOT*` 等特殊 Buffer 分组隔离。单 Buffer 的 Evil 退出命令不会升级为关闭 Frame 或退出 Emacs，只有带 `all` 的命令执行全局退出。

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

#### 编译与错误跳转闭环

项目构建使用 Emacs 内置 Project 和 Compilation Mode，形成“保存、编译、定位、修复、重编译”的循环：

1. 在项目文件中按 `C-c b c`，自动保存所有已修改的文件，并在项目根目录选择或输入构建命令，例如 `make`、`cmake --build build` 或项目自己的测试命令。
2. 构建输出显示在 Compilation Buffer 中，ANSI 颜色会被解析；输出持续滚动，已有编译进程会被新一次构建直接替换。
3. 按 `C-c b n` / `C-c b p` 在编译器或测试工具报告的错误间前后跳转，也可以在 Compilation Buffer 的错误行按 `RET` 打开对应源码位置。
4. 修改代码后按 `C-c b r`：配置再次保存文件，并重复当前项目上一次的构建命令；如果项目还没有 Compilation Buffer，则回退到 `C-c b c` 的首次编译流程。

Compilation Buffer 由 Popper 管理，因此可以用 `q` 关闭，用 `C-c \`` 再次调出，而不会破坏主编辑窗口布局。编译错误跳转使用 `C-c b n/p`；Eglot/Flymake 的实时语义诊断是另一条独立链路，使用 `M-n` / `M-p`。前者适合完整构建和测试结果，后者适合编辑过程中的即时反馈。

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
C-c c i t / i n    Inbox：Task / Thought
C-c c w t / w p    Work：Task / Project
C-c c p l / p p    Personal：Life / Project
C-c c p s          Personal：Someday
C-c c n i/q/v      Notes：Idea / Quote / Insight
C-c c c e          Calendar：Event
C-c c j e          Journal：Entry
C-c a d            今日 Agenda 与下一步行动
C-c a i            查看 Inbox 中待分类任务
C-c a u            查看未设置日期的工作和个人任务
C-c a p            查看工作和个人任务的 NEXT、WAITING、TODO
C-c C-w            将 Inbox 内容 Refile 到工作、个人、日程或 Notes
C-c C-t            切换任务状态
C-c C-s            设置计划开始日期
C-c C-d            设置截止日期
C-c C-x C-s        归档当前任务或项目
```

日常文件位于本机 Org 根目录：Windows 默认为 `%USERPROFILE%/org/`，Linux 与 macOS 默认为 `~/org/`；可在 `local.el` 通过 `my/org-directory` 覆盖。`inbox.org` 包含 Tasks 与 Thoughts；`work.org` 保存工作任务和项目；`personal.org` 保存个人项目、生活事务和 Someday；`calendar.org` 保存带具体时间的事件；`journal.org` 保存自由日记且不进入 Agenda；`notes.org` 用 Ideas、Quotes 和 Insights 保存从 Inbox 整理出的长期内容。完成或取消的内容归档到 `org/archive/` 中各源文件对应的独立归档文件。Org 根目录、归档目录或基础文件缺失时，配置会按上述结构自动创建。

Capture 会打开聚焦的 `CAPTURE-*` 临时 Buffer。输入完成后按 `C-c C-c` 保存，或按 `C-c C-k` 取消，随后自动恢复 Capture 前的窗口布局；无需手动切换到目标 `.org` 文件。Capture 默认处于 Evil Insert 状态，按 `ESC q` 也可取消。

`C-c c` 使用 Org Capture 原生的两级菜单：先选择 Inbox、Work、Personal、Notes、Calendar 或 Journal，再选择该文件中的一级标题。Inbox/Task 依次询问标题、标签、计划日期和截止日期，后三项可以直接留空；正文前用普通方括号记录精确到秒的创建时间，不创建 Property Drawer。Inbox/Thought 以相同的简单时间格式保存不带 TODO 状态的临时想法，整理时可将其 Refile 到 `notes.org`。Notes 的三个选项会先询问标题，再分别把正文写入 Ideas、Quotes 或 Insights。Journal/Entry 不要求填写子标题，而是在当天日期标题下直接追加创建时间和正文；同一天可以连续追加多段记录。

Agenda 读取 Inbox、工作、个人和日程四个文件；每日视图显示当天时间事项、可立即做的 NEXT，并在标题中显示 Inbox 待处理数量。日程会在 30 分钟前开始提醒，之后每 10 分钟重复；Linux/macOS 使用系统通知，Windows 默认显示 Emacs 内提醒，可通过 `local.el` 配置 Toast。提醒要求 Emacs 保持运行且时间戳包含具体时间。

Android 可使用 Orgzly Revived、iOS 可使用 beorg，将其 WebDAV 仓库指向同一个远程 Org 目录。桌面端应使用服务商或 Nextcloud 同步客户端把该目录同步为本地 Org 根目录，不建议让 Agenda 和 Capture 直接操作远程 `/davs:` 路径。Windows 对同步文件每 2 秒轮询；未修改的 Org Buffer 自动重载后会刷新 Agenda 与提醒。避免在手机与桌面同时编辑同一文件，并在 WebDAV 服务端启用版本或回收站。

Calendar 使用周一作为每周第一天，并显示中国节日。`M-x calendar` 后双击任意日期可打开该日期的 Agenda。习惯任务可放在 `calendar.org` 的 `Habits` 标题下，或放在 `personal.org`；前者适合把所有周期性时间项集中查看，后者适合把习惯与个人项目放在一起。

`org-modern` 已启用，用于美化 Org 标题、标签、TODO、复选框和表格。Refile 会一次性显示完整路径；选择带标题的目标，例如 `work.org/Tasks`，不要选择文件名本身。

### 跨平台本机设置

配置支持 Linux、WSL、macOS 与原生 Windows。复制 `local.example.el` 为 `local.el` 可覆盖本机包源、Org 同步目录、外部工具路径、Eat shell 和通知后端；`local.el` 不会提交到 Git。登录 shell 环境会先导入，再将 `my/extra-exec-paths` 中真实存在的目录加入 `PATH` 与 `exec-path`。Tree-sitter grammar 必须在每台机器上分别构建；不要同步 `tree-sitter/` 生成目录。

GNU 与 NonGNU ELPA 默认使用 TUNA 镜像，更新频繁的 MELPA 使用官方源；下载地址失效时会刷新 archive 后重试，也可在 `local.el` 整体覆盖。Linux 使用 D-Bus 通知，macOS 使用 `osascript` 通知，Windows 默认回退到 Emacs 消息提示，可在 `local.el` 配置 Toast。Linux、WSL 与 macOS 使用 Eat，原生 Windows 使用 Eshell。daemon 后创建 GUI Frame 时会重新初始化字体、Dired 图标和平滑滚动。标准 Unicode 符号、Emoji 与 Nerd Font PUA 使用独立字体映射；Windows 的 Modeline 和 Tab Line 使用稳定的文本标记，Linux/macOS 在字体可用时显示 Nerd Font 图标。GUI 剪贴板可直接使用；TTY、SSH 与 WSL 终端没有额外的系统剪贴板桥接，默认只写入 Emacs kill-ring。

原生 Windows 的 Emacs 可能调用到 MSYS 版 GPG，它会把 `C:/Users/...` 形式的 `--homedir` 错当成相对路径。配置在 Windows 上让 GPG 使用自己的默认 home，仍保留 GNU ELPA 签名验证，并在首次启动时安装和导入 `gnu-elpa-keyring-update`。更新配置后应完全退出并重新启动 Emacs，之前因签名失败的包会由 `use-package` 重新安装。更彻底的本机方案是安装原生 MinGW GPG，并确保它在 MSYS `/usr/bin/gpg.exe` 之前被找到；不要长期设置 `package-check-signature` 为 `nil`。

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
