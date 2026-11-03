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
| 缩进与显示 | EditorConfig、Tree-sitter、Whitespace、Indent Bars、Rainbow Delimiters | 项目缩进规则、语法分析、异常空白提示、作用域竖线和彩虹括号 |
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
- **显示**：普通空格不显示圆点，不专门标记行尾空白；保留 Tab 和特定空格/Tab 混用提示，不自动清理。Tab 在 Makefile 等文件中可以是合法内容。竖线高亮当前语法作用域，光标在行首空白中也按本行语句识别。括号自动配对，Lisp 由 Paredit 管理。
- **主题**：默认 `chyla-dark`，备选 `amaranth-dark`（`M-x load-theme`），浅色 `flatfluc`。从任一深色主题切换到浅色后，再切回默认深色。
- **Chyla 定制**：仅 GUI 背景采用 One Dark 的 `#282c34`，TTY 保留原主题背景；当前行为 `#353b45`，选区为蓝色 `#3e5c76`，光标为橙色 `#FF9800`。仅作用于 Chyla，代码语法配色保持原样。TTY 实际颜色及光标颜色受终端能力影响。
- **Flatfluc 定制**：仅 GUI 背景改为 `#E5EAF0`，TTY 保留原主题配色。
- **Amaranth Dark 定制**：仅 GUI 背景采用 One Dark 的 `#282c34`，TTY 保留原背景。
- **Paredit**：Lisp/Scheme 等 Buffer 中保留 `M-s` 为搜索前缀；`C-c s` 执行 `paredit-splice-sexp`（去掉包围当前表达式的外层结构，保留其内容）。

### 标签、窗口与退出

以下 Vim 按键用于 Evil 普通状态；`[b` / `]b`、数字标签跳转也支持 Motion 状态。

```text
[b / ]b           按当前 Window 的标签顺序切换 Buffer
Ctrl+Shift+1..9    跳到当前 Window 第 1–9 个标签，需终端/系统支持
:q / ZQ           关闭当前窗口的 Buffer 标签，保留分屏和其他窗口的显示
:wq / :x / ZZ     保存并关闭 Buffer；:x / ZZ 仅在修改后保存
:qa / :wqa        退出 Emacs / 保存后退出
C-w v / C-w s     固定向右 / 向下分屏
C-w h/j/k/l       在窗口间移动
C-w u / C-w C-r   撤销 / 重做窗口布局
C-w o / M-o       用 Ace Window 选择窗口，不是只保留当前窗口
C-w q / C-w C-q   删除当前分屏，保留 Buffer；无法删除时提示，不退出 Emacs
C-w c / C-x 0     删除当前分屏，保留 Buffer，也可隐藏终端面板
q                 退出 Popper/侧边窗口的临时显示，在 Capture 中取消捕获
                  普通编辑区仍为录制宏，各模式专用绑定优先
```

每个 Window 单独保留标签序列，普通 Buffer 与 `*特殊 Buffer*` 分组显示。

- `:q` / `ZQ` 关闭当前窗口的标签：若其他窗口仍显示同一 Buffer，只从当前窗口移出；否则尝试 kill Buffer，未保存修改需确认。`:wq` / `:x` / `ZZ` 保存后使用相同关闭规则。不删除分屏，也不退出 Emacs。`:q!` 只在确实 kill Buffer 时丢弃未保存修改；共享显示时不会丢弃其他窗口的编辑。`C-x k` 则始终尝试全局 kill 选定 Buffer。
- 标签栏 × 关闭对应 Buffer；关闭当前窗口最后一个标签时，若该窗口可删除，则连同分屏一起关闭。
- 临时显示中的 `q` 使用 `quit-window`，可能删除窗口，也可能恢复之前显示的 Buffer；若明确要删除分屏，用 `C-w q` 或 `C-x 0`。
- `C-x 3` / `C-w v` 在右侧新建窗口显示当前 Buffer，新窗口初始只有该 Buffer 的标签；原窗口保留它，并非将标签搬走。当前配置中这两个操作都不自动切换焦点，可用 `C-w l` 进入右侧。

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
RET                在编译输出的错误信息处，访问对应文件和行
M-g n / M-g p      从代码或输出中访问下一个 / 上一个错误位置，可跨文件
M-n / M-p          在编译输出中仅移动到下一条 / 上一条错误信息
```

`C-c b c/r` 会不经确认保存可自动保存的已修改文件，范围不限于当前项目；编译输出由 Popper 管理。

从编译输出跳转时，优先复用已有目标窗口或最近使用的其他可用窗口显示源文件，保留编译输出；没有可复用窗口时才分屏。`M-g n/p` 调用原生 `next-error` / `previous-error`，无需切回编译窗口，也可导航 grep/occur 等结果；来源混淆时用 `M-x next-error-select-buffer` 指定结果 Buffer。修改后需重新编译，输出才会更新。

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
C-h w / C-h b      查询命令的快捷键 / 列出当前按键绑定
M-g i / M-g g      当前 Buffer 结构列表（Imenu）/ 跳到行号
C-\ / M-j          切换小鹤双拼 / 转换光标前的拼音
```

**搜索怎么选：** `C-s` 搜当前 Buffer（含未保存修改），`M-s r` 搜项目/目录的磁盘正文，`C-c p f` 搜文件名，`C-x b` 切换 Buffer。候选中用 `C-n/C-p` 选择、`RET` 确认、`C-g` 取消；许多界面可用空格分隔多个筛选词，例如 `M-x` 输入 `buffer kill`。

**Ripgrep：** 提示括号中的路径是搜索根，默认项目根，未识别项目则用当前目录；不是全盘搜索，且通常遵循 `.gitignore`、跳过隐藏文件。用 `C-u M-x consult-ripgrep RET` 可指定目录（当前 `C-u M-s r` 不支持此功能）。

- `#timeout`：搜索 `timeout`，`#` 是分隔符，不是搜索词。
- `#timeout#client.cpp`：先搜索 `timeout`，再按路径/内容筛选返回结果中的 `client.cpp`。
- 它与 grep 都搜索文件内容，主要区别是 Consult 提供实时候选和预览；传统 `grep/rgrep` 直接保留结果 Buffer。

**常用操作：**

- `C-h k` 后按目标键查作用；`C-h w` 输入命令名查绑定；`C-h b/B` 浏览绑定。请在实际 Buffer 和 Evil 状态中查询。按前缀后停顿可看 Which Key 提示。
- `M-y` 搜索复制/剪切历史，粘贴后也可更换刚粘贴的内容。
- `M-g i` 找函数/章节，`M-g g` 跳行号，`M-g n/p` 导航编译/grep/occur 结果；代码中的 `M-n/p` 则是 Flymake 实时诊断。
- 原生 Isearch 用 `M-x isearch-forward` 启动，边输入边在正文中查找；搜索中 `C-s/C-r` 前后查找、`RET` 结束。本配置编辑区的 `C-s` 已改成列出匹配行的 Consult Line。
- 候选中按 `C-.` 打开 Embark 操作菜单，如复制路径、文件操作；`M-.` 执行上下文默认动作，不是定义跳转。代码定义/引用仍用 `g d/g r`。

**Wgrep 批量修改：** `M-s r` 搜索 → `C-. E`（`embark-export`）导出 grep 结果 → `M-x wgrep-change-to-wgrep-mode` → 编辑结果正文 → `C-c C-c` 应用，或 `C-c C-k` 取消未应用修改。结果中的 `RET` 可访问源位置。

**确认 Wgrep 会自动保存修改到的源文件**，请检查 Git diff；代码变量改名优先用 `C-c l r`，避免文本替换误改同名变量。

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
M-n / M-p          代码 Buffer 中：当前文件下一个 / 上一个 Flymake 实时诊断
```

`C-SPC` 保留 Emacs 的设置标记功能。补全使用 `C-M-i`（Ctrl+Alt+i），
不用 Alt+Tab，避免 Windows 窗口切换冲突。

C/C++ 的 Eglot 行内提示默认关闭；用 `M-x eglot-inlay-hints-mode` 在当前 Buffer 手动开关参数名、类型、数组下标等提示，不影响补全和诊断。重新进入 Eglot 管理状态时再次按默认规则关闭；其他语言不受此配置影响。

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

项目默认主要按 Git 等版本控制识别，仅有 C++ 文件或 `CMakeLists.txt` 不保证被识别。`C-c p f` 先询问目录通常表示未识别项目，可选择普通目录临时使用。编译命令的构建文件检测与项目识别是两套逻辑。

在目标文件/Dired 中按 `M-:` 执行下式，返回项目根或 `nil`；`M-: default-directory` 查看当前 Buffer 的目录：

```elisp
(when-let ((project (project-current nil)))
  (project-root project))
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
y / p / P          可视选区中：复制 / 替换并收集被替换内容 / 替换且保留粘贴来源
ysiw)              为当前单词添加括号
cs"' / ds"         将双引号改成单引号 / 删除双引号
```

沿用 Evil 默认粘贴规则：Visual `p` 会使被替换文本成为下一次默认粘贴内容；连续用同一段文字替换多个选区时用大写 `P`。这里的 `P` 说明仅针对可视状态。

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
- TTY 默认启用内置 `xterm-mouse-mode`，支持的终端可将点击、滚轮等鼠标事件交给 Emacs；终端自身的文本选择通常可按住 Shift 绕过鼠标捕获，具体取决于终端设置。用 `M-x xterm-mouse-mode` 可临时关闭。

### 字体与显示排查

GUI 按 `lisp/init-ui.el` 的字体候选列表选择已安装字体；TTY 使用终端自身的字体。
主文本大小由 `my/buffer-font-height` 控制，界面文字由 `my/ui-font-height` 控制。
终端选区、光标及当前行的颜色修复限定在对应 TTY Frame，并在切换主题后重新应用，不覆盖同一 daemon 中 GUI Frame 的主题颜色。

字符太细、颜色不清或疑似回退字体时，把光标放在字符上执行 `M-x describe-char`，
查看实际字体与 face；可在 `M-x set-frame-font` 临时比较其他字体。不要把代码中的 ASCII `-`
换成 Unicode 减号 `−` 或长横线，它们是不同字符。

### 远程开发

`C-x C-f` 输入 `/rpc:user@host:/path/to/project`；异常时可用 `/ssh:user@host:/path` 排查。请替换用户名、主机和路径。

- 本机需要 OpenSSH、Git、SCP；远端为支持的 x86_64/aarch64 Linux 或 macOS。首次 RPC 连接需从 GitHub 下载 server。
- 语言服务器和编译工具装在远端；远程 clangd 不携带本机 `g++` 路径，本地 Unix 才按需设置 `--query-driver`。
- Windows 连接 WSL：先在 WSL 启动 SSH 服务并配置公钥登录，再访问 `/rpc:user@localhost:/home/user/project`。非默认端口写作 `host#端口`。

### 自动保存、备份与崩溃恢复

- **未保存编辑的恢复副本**：文件 Buffer 默认使用 Emacs 自动保存，配置为闲置约 15 秒或输入约 200 个事件后触发（并非严格定时保证）。副本集中在 `user-emacs-directory` 下的 `auto-save/`，恢复会话列表为其中的 `.saves-*`；不会自动覆盖原文件。
- **崩溃后恢复**：先用 `M-x recover-session` 查看可恢复会话；也可用 `M-x recover-file` 按原文件路径恢复单个文件。核对恢复内容后再保存。恢复的是最近一次成功写出的副本，不保证包含崩溃前最后几次输入。
- **保存前备份**：集中在 `backups/`，使用编号备份，保留最旧 5 份与最新 10 份，自动删除超出保留范围的版本。采用复制方式，避免备份操作移动原文件而影响硬链接。
- **备份边界**：沿用 Emacs 默认策略，版本控制管理的文件通常不生成保存前备份；Git 只能恢复已提交/已保存到 Git 对象中的内容，不能替代未保存编辑的恢复副本。同一次访问文件期间通常仅首次保存生成备份，不是每次 `C-x C-s` 都保留一个版本。
- **注意事项**：大幅删除可能触发 Emacs 的自动保存保护并暂停该 Buffer 的自动保存；无文件关联的临时 Buffer 不保证自动恢复。Vundo/undo-redo 的撤销历史目前不持久化，重启后不能靠它找回编辑过程。
- 恢复目录不提交 Git；可能含源代码、笔记或其他敏感内容，应保留合适的目录权限，并纳入独立的磁盘/系统备份。它们与原文件若在同一磁盘，不能防磁盘损坏。远程和加密文件还受对应文件处理器策略影响。

### 大文件保护与维护

达到约 **2 MiB**，或单行超过 **10,000 字节**时启用轻量模式：保留语言模式和编辑能力，关闭较重的显示/补全增强，并跳过自动 LSP（包括加入已有项目服务器）。检测只读取内存文本，不卸载解析器。

- `M-x so-long-revert`：恢复被关闭的显示功能。
- 阈值可在 `local.el` 设置 `my/large-file-size-threshold`、`so-long-threshold`（字节）。
- 修改配置后建议重启 Emacs，避免旧 Hook/按键残留。
- 启动分析：`M-x emacs-init-time` 看总耗时；需要按包细分时，在 `early-init.el` 设置 `(setq use-package-compute-statistics t)`，重启后执行 `M-x use-package-report`。
- Avy、Wgrep、Rainbow Delimiters 和浅色主题按需加载；字体列表按 Frame 缓存，安装新字体后重建 Frame 或重启 Emacs。
