# Emacs Configuration

面向 Emacs 30.1 的个人配置：Evil 编辑、项目开发、中文输入和 Org 工作流。优先使用内置功能，输入时少干预，格式按需整理。

按键记法：`C-` = Ctrl，`M-` = Alt/Meta，`S-` = Shift；空格表示依次按键，`/` 分隔可选操作。Buffer 是缓冲区，Window 是分屏，Frame 是整个 Emacs 窗口。

## 概览

- [编辑与开发](#编辑与开发)：补全、编译、搜索、窗口和文件管理。
- [批量编辑](#批量编辑)：Evil、矩形编辑与匹配项同步编辑。
- [Org 工作流](#org-工作流)：Capture、Agenda 和日历。
- [环境与维护](#环境与维护)：本机设置、字体、远程开发和大文件保护。

| 功能 | 组件 | 用途 |
| --- | --- | --- |
| Vim 编辑 | Evil、Evil Collection | 普通/插入/可视状态，以及各模式的 Vim 按键 |
| 批量编辑 | Evil Multiedit、Evil Surround、Move Text | 同步编辑匹配项、操作包围符、移动代码行 |
| 搜索与选择 | Vertico、Orderless、Consult、Marginalia | 垂直候选、多关键词匹配、搜索及候选说明 |
| 候选操作 | Embark、Wgrep | 对候选执行操作、编辑搜索结果 |
| 代码补全 | Corfu、Cape、Yasnippet | 补全弹窗、文件/文本/关键词候选、代码模板 |
| 开发工具（内置） | Eglot、Flymake、Project、Compilation | LSP、诊断、项目管理与编译 |
| Git | Magit | 查看差异、暂存、提交等 Git 操作 |
| 缩进与显示 | EditorConfig、Tree-sitter、Whitespace、Indent Bars、Rainbow Delimiters | 项目缩进规则、语法分析、空格点、作用域竖线和彩虹括号 |
| 窗口与撤销 | Tab Line、Winner（内置）、Popper、Ace Window、Vundo | 标签、布局恢复、临时窗口、窗口选择、撤销历史 |
| 文件管理 | Dired（内置）、Dired Subtree、Treemacs | 目录操作、展开子目录、项目侧栏 |
| 终端与远程 | Eat、Eshell / TRAMP（内置）、tramp-rpc | 内置终端及 SSH 远程开发 |
| 中文输入 | Pyim、Pyim Basedict | 小鹤双拼及基础词库 |
| Org | Org / Agenda（内置）、Org Modern、Calfw、Cal China X | 任务捕获、日程、外观和日历 |
| Lisp / Scheme | Paredit、Geiser Racket | 结构化编辑、Scheme REPL 与 SICP |
| 界面与帮助 | Chyla / Amaranth / Flatfluc、Doom Modeline、Nerd Icons、Dashboard、Which Key、Helpful、Avy | 主题、状态栏、图标、首页、按键提示、帮助与跳转 |
| 大文件保护（内置） | So Long | 对大文件和超长行关闭重型增强 |
| 可选环境工具 | Exec Path from Shell、Envrc、GCMH | 已安装时导入 Shell 环境、支持 direnv、管理垃圾回收 |

配置入口是 [init.el](init.el)，功能模块位于 [lisp/](lisp/)。搜索相关配置看 `init-enhance.el`，编辑看 `init-editing.el`，LSP 看 `init-lsp.el`，Org 看 `init-org.el`。

## 编辑与开发

### 编辑与补全

以下 Enter/Tab 行为用于编程 Buffer 的 Evil **插入状态**；不替代 Org、Dired 等模式的专用按键。

```text
RET                按语法缩进新行；在 {} 之间换行展开成三行
TAB                确认 Corfu 候选；否则缩进当前行，已对齐时触发补全
C-M-\              按语言语法整理选中区域的缩进
S-TAB              在代码、LaTeX、Org 中展开模板或跳到下一模板字段
C-/                注释/取消注释；可视选区不会多处理下一行
s                  输入两个字符后用 Avy 跳转（普通/可视状态）
M-↑ / M-↓          移动代码行或选区；Lisp 插入状态保留 Paredit 的按键
C-c t c            开关 Corfu 补全弹窗，不影响 LSP
C-c t r            开关彩虹括号，默认关闭
C-c t t            切换 Chyla Dark 深色 / Flatfluc 浅色
F3 / M-s h u       用内置 Hi Lock 高亮当前符号 / 取消高亮
```

- **缩进**：项目的 `.editorconfig` / 局部变量优先，其次检测文件已有缩进，否则默认 4 格。通常用空格，Makefile / Go 等按语言规则使用 Tab；C/C++ 默认 BSD/Allman 风格。保存时不自动格式化。
- **补全**：输入 2 个字符后等待 0.2 秒弹出；手动触发见下方。Cape 的文本候选只扫描当前 Buffer。
- **显示**：空格为淡点、Tab 为箭头；竖线高亮当前语法作用域，光标在行首空白中也按本行语句识别。括号自动配对，Lisp 由 Paredit 管理。
- **主题**：默认 `chyla-dark`，备选 `amaranth-dark`（`M-x load-theme`），浅色 `flatfluc`。从任一深色主题切换到浅色后，再切回默认深色。

### 标签、窗口与退出

以下 Vim 按键用于 Evil 普通状态；`[b` / `]b`、数字标签跳转也支持 Motion 状态。

```text
[b / ]b           按当前 Window 的标签顺序切换 Buffer
Ctrl+Shift+1..9    跳到当前 Window 第 1–9 个标签，需终端/系统支持
:q / ZQ / C-w q   关闭当前 Buffer，不是退出 Emacs
:wq / :x / ZZ     保存并关闭 Buffer；:x / ZZ 仅在修改后保存
:qa / :wqa        退出 Emacs / 保存后退出
C-w v / C-w s     固定向右 / 向下分屏
C-w h/j/k/l       在窗口间移动
C-w u / C-w C-r   撤销 / 重做窗口布局
C-w o / M-o       用 Ace Window 选择窗口，不是只保留当前窗口
C-w c             关闭窗口但保留 Buffer，也可隐藏终端面板
q                 关闭 Popper/侧边窗口，在 Capture 中取消捕获
                  普通编辑区仍为录制宏，各模式专用绑定优先
```

每个 Window 单独保留标签序列，普通 Buffer 与 `*特殊 Buffer*` 分组显示。

### 终端、弹窗与文件树

```text
C-`                首次打开终端；之后在终端和原编辑窗口之间切换焦点
C-w t              切换终端面板在右侧 / 底部（普通状态，仅图形界面）
C-c `              显示/隐藏最近的 Popper 弹窗
M-`                循环切换 Popper 弹窗
C-M-`              切换当前窗口是否由 Popper 管理
C-e                在编辑区与 Treemacs 间切换，未打开时显示当前项目（普通状态）
```

图形界面的终端默认在右侧，终端界面中在底部。终端快捷键**不负责隐藏终端**，且复用同一终端 Buffer，不按项目/主机自动新建。Linux、WSL、macOS 用 Eat，原生 Windows 用 Eshell。

Treemacs 内：`h` 根目录上移，`l` 将目录设为根或打开文件，`H` 切换隐藏文件，`a/r/c/d` 新建/重命名/复制/删除，`\` 关闭侧栏。

### 项目编译

```text
C-c b c            保存修改后，确认并运行当前 Buffer 的编译命令
C-c b r            保存修改后，重复上次编译；没有记录时询问命令
M-x compile        没有历史或局部设置时命令为空，自行输入 Shell 命令
```

`C-c b c/r` 会不经确认保存可自动保存的已修改文件，范围不限于当前项目；编译输出由 Popper 管理。

默认编译命令按以下顺序选择，提示时都可以修改，修改后该 Buffer 会记住：

1. `.dir-locals.el` 或文件局部变量里的 `compile-command`，例如项目根放 `((nil . ((compile-command . "ninja -C build"))))`。
2. 项目根的构建文件：`CMakeLists.txt`、`Makefile`、`Cargo.toml`、`go.mod`，在项目根运行。
3. 文件所在目录的同类构建文件，在该目录运行。
4. 单文件：C/C++/Rust 编译并运行同名程序，Go 用 `go run`，Python、Shell 直接执行，在文件所在目录运行。

### 搜索、文件与帮助

```text
C-x C-f / C-x C-s  打开 / 保存文件
C-x b / C-x k      搜索切换 / 选择关闭 Buffer
C-SPC              设置标记，再移动光标选择区域（插入状态）
C-s                搜索当前 Buffer（Minibuffer 中为普通增量搜索）
M-s r              ripgrep 搜索项目/目录，预填选区或光标处符号
C-c r              打开最近文件
M-y                从 kill-ring 中选择粘贴内容
C-. / M-.          Embark 候选操作 / 默认操作
C-h f / C-h v      函数 / 变量帮助
C-h k / C-h B      按键帮助 / 当前可用按键
C-\ / M-j          切换小鹤双拼 / 转换光标前的拼音
```

### 补全、诊断与跳转

代码导航的 `g d`、`g r`、`g h`、`K` 使用 Evil 普通状态；LSP 功能需要对应语言服务器。

```text
C-M-i              手动触发补全（Ctrl+Alt+i，插入状态）
C-n / C-p          补全弹窗中选择下一个 / 上一个候选
TAB / M-RET        确认补全；RET 仍用于换行
g d / g r          跳到定义 / 查找引用
M-, / C-M-,        Xref 历史后退 / 前进
g h / K            悬浮文档 / 回显区简要文档
C-c l r            重命名
C-c l a / C-c l f  Code Action / 手动格式化 Buffer
M-n / M-p          下一个 / 上一个 Flymake 诊断
```

`C-SPC` 保留 Emacs 的设置标记功能。补全使用 `C-M-i`（Ctrl+Alt+i），
不用 Alt+Tab，避免 Windows 窗口切换冲突。

### 项目、Git 与文件管理

```text
C-c p p            切换项目
C-c p f / C-c p b  查找项目文件 / 切换项目 Buffer
C-c p D / C-c p e  在项目根打开 Dired / Eshell
C-x g              Magit Status
M-g n / M-g p      下一个 / 上一个编译错误
M-!                在当前目录执行 Shell 命令
C-x d / C-x C-j    打开 Dired / 定位当前文件所在目录
```

### Dired 常用操作

以下用于 Evil Collection 的 Dired 普通状态。大写按键需要 Shift；有标记时批量处理标记项，
没有标记时通常处理光标所在项。复制、移动时，另一个 Dired 窗口可作为默认目标目录。

```text
RET / g f          打开文件或目录
- / ^              上一级目录
j / k              下一行 / 上一行
TAB                展开或收起子目录（Dired Subtree）
m / u / U          标记 / 取消当前标记 / 取消全部标记
t                  反转标记
% m                按文件名正则批量标记
C / R              复制 / 重命名或移动；可作用于多个标记项
D                  删除当前文件或标记项（会询问确认）
d / x              标记待删除 / 执行待删除项
+                  新建目录
g r                刷新目录
s                  切换按名称 / 修改时间排序
(                  隐藏或显示文件详情（权限、大小、时间等）
! / &              对文件执行 Shell 命令 / 异步执行
i                  进入 Wdired，直接编辑文件名以批量重命名
C-c C-c            Wdired 中确认修改
C-c C-k            Wdired 中取消修改
q                  退出 Dired 窗口
```

在 Dired 中新建文件可用 `C-x C-f` 输入新文件名，再保存；重命名整个目录或跨目录移动也用 `R`。

## 批量编辑

### Evil 基础

```text
i / a / Esc        插入 / 光标后插入 / 返回普通状态
v / V / C-v        字符 / 行 / 矩形可视选区
u / C-r            撤销 / 重做（内置 undo-redo 后端）
C-x u              Vundo 可视化撤销历史
ysiw)              为当前单词添加括号
cs"' / ds"         将双引号改成单引号 / 删除双引号
```

### 矩形编辑

Evil Visual Block 适合同一列的多行插入、删除或替换。

```text
C-v                从普通状态进入矩形选择
h/j/k/l            扩展或收缩矩形，数字前缀可一次移动多列/行
I                  在矩形左边界插入（大写 I）
A                  在矩形右边界追加（大写 A）
$ 然后 A           在每一行末尾追加，适合长度不同的行
c / d              替换 / 删除矩形内文本
Esc                结束插入，并把第一行的输入应用到其余选中行
```

例如给三行加前缀：在第一行行首依次按 `C-v j j I`，输入 `// `，再按 `Esc`。
输入时只有第一行变化，**按 Esc 后其他行才同步**；不要用 `C-g` 代替 Esc。
终端若拦截 `C-v`，可用 `M-x evil-visual-block` 进入矩形选择，或修改终端的按键设置。
`C-h k C-v` 可检查 Emacs 是否收到该键。

### 匹配项同步编辑

Evil Multiedit 类似多光标，适合同时修改散布在文件中的相同文本。
它同步的是匹配区域，不是任意位置的独立光标；修改变量名称时优先用 LSP 重命名 `C-c l r`。

```text
M-d / M-D          添加当前符号及下一个 / 上一个匹配项（普通状态）
v 选择文本，M-d    按所选文本启动同步编辑，再添加下一个匹配项
v 选择文本，R      一次选中全文所有匹配项（大写 R）
C-n / C-p          同步编辑中跳到下一个 / 上一个匹配项
RET                切换当前匹配项是否参与；有可视选区时限制到选区
c / i / a          替换匹配文本 / 在匹配项内插入 / 追加，同步到其他项
Esc                从插入回到普通状态；同步编辑仍保持活动
C-g                退出同步编辑（普通状态）
```

例如统一修改 `foo`：光标放在 `foo` 上，按 `M-d` 添加匹配项，继续按 `M-d` 添加更多，
再按 `c i w` 输入新名称，`Esc` 完成输入、`C-g` 退出同步编辑。

## Org 工作流

默认文件位于 `~/org/`，Windows 为 `%USERPROFILE%/org/`；首次 Capture/Agenda 会询问是否初始化缺少的文件。

### 入口与自定义操作

```text
C-c c / C-c a      Capture / Agenda 菜单
C-c o / C-c C      搜索 Org 文件或打开目录 / 打开可视日历
C-c C-x C-k        将光标处的创建时间转入 CREATED Property
C-c l              保存 Org Link（LSP Buffer 中同此前缀用于 LSP 操作）
```

Capture 菜单中依次按键，例如 `i t`：

```text
i t / i n         收件箱任务 / 想法
w t / w p         工作任务 / 项目
p l / p p / p s   个人生活任务 / 项目 / Someday
s                 为工作或个人的 NEXT 项目添加子任务
n i / n q / n v   笔记：想法 / 引用 / 洞见
c e / j e         日程 / 日志
```

Capture 中 `C-c C-c` 保存，`C-c C-k` 取消。任务、项目和笔记的创建时间默认放在正文，不创建 Property Drawer。

Agenda 菜单：`d` 今日与 NEXT，`i` 收件箱，`p` 工作/个人回顾，`w/o` 本周/本月，`f` 笔记中的未来想法。

### Agenda、日历与任务编辑

- **Agenda 内**：`j/k` 移动，`h/l` 前后日期，`g t` 今天，`g j` 指定日期；`RET` 打开源位置，`TAB` 在另一窗口显示；`t/s/C-c C-d` 修改状态/计划/截止日期，`a/r/q` 归档/刷新/退出。
- **可视日历内**：`h/j/k/l` 移动，`v d` / `v w` / `v m` 切换日/周/月，`SPC` 打开当天 Agenda，`RET` 打开事项，`r/q` 刷新/退出。
- **Org 文件内**：`C-c C-t` 切换 TODO，`C-c C-s` / `C-c C-d` 设置计划/截止日期，`C-c C-w` Refile，`C-c C-x C-s` 归档，`C-c C-x p` 设置 Property。

Agenda 读取 Inbox、Work、Personal、Calendar；编辑正文请回源文件。Refile 选择带标题的目标，如 `work.org/Tasks`。日程提醒在首次使用 Org 后启动，需要时间戳包含具体时间且 Emacs 保持运行。手机同步请落到本机 Org 目录。

## 环境与维护

- 使用 Emacs 30.1，安装 Git、`rg`；按需安装 `clangd`、`basedpyright`、`gopls`、`rust-analyzer` 等语言服务器。
- Tree-sitter grammar 用 `M-x treesit-auto-install-all` 安装；与平台和 ABI 绑定，不要跨机器同步 `tree-sitter/`。
- 本机差异放入不提交的 `local.el`，参考 [local.example.el](local.example.el) 设置包源、工具路径、Org 目录和 Shell。
- GUI 的中文和图标需要对应字体；TTY 没有额外的系统剪贴板桥接。

### 字体与显示排查

GUI 按 `lisp/init-ui.el` 的字体候选列表选择已安装字体；TTY 使用终端自身的字体。
主文本大小由 `my/buffer-font-height` 控制，界面文字由 `my/ui-font-height` 控制。

字符太细、颜色不清或疑似回退字体时，把光标放在字符上执行 `M-x describe-char`，
查看实际字体与 face；可在 `M-x set-frame-font` 临时比较其他字体。不要把代码中的 ASCII `-`
换成 Unicode 减号 `−` 或长横线，它们是不同字符。

### 远程开发

`C-x C-f` 输入 `/rpc:user@host:/path/to/project`；异常时可用 `/ssh:user@host:/path` 排查。请替换用户名、主机和路径。

- 本机需要 OpenSSH、Git、SCP；远端为支持的 x86_64/aarch64 Linux 或 macOS。首次 RPC 连接需从 GitHub 下载 server。
- 语言服务器和编译工具装在远端；远程 clangd 不携带本机 `g++` 路径，本地 Unix 才按需设置 `--query-driver`。
- Windows 连接 WSL：先在 WSL 启动 SSH 服务并配置公钥登录，再访问 `/rpc:user@localhost:/home/user/project`。非默认端口写作 `host#端口`。

### 大文件保护与维护

达到约 **2 MiB**，或单行超过 **10,000 字节**时启用轻量模式：保留语言模式和编辑能力，关闭较重的显示/补全增强，并跳过自动 LSP（包括加入已有项目服务器）。检测只读取内存文本，不卸载解析器。

- `M-x so-long-revert`：恢复被关闭的显示功能。
- 阈值可在 `local.el` 设置 `my/large-file-size-threshold`、`so-long-threshold`（字节）。
- 修改配置后建议重启 Emacs，避免旧 Hook/按键残留。
- 启动分析：`M-x emacs-init-time` 看总耗时；需要按包细分时，在 `early-init.el` 设置 `(setq use-package-compute-statistics t)`，重启后执行 `M-x use-package-report`。
- Avy、Wgrep、Rainbow Delimiters 和浅色主题按需加载；字体列表按 Frame 缓存，安装新字体后重建 Frame 或重启 Emacs。
