# Emacs Configuration

面向 Emacs 30 的个人配置，优先使用 Emacs 内置功能，覆盖 Evil 编辑、项目开发、补全、文件管理、终端、远程开发和 Org 工作流。

## 前提

- Emacs 30.1
- 按需安装 `clangd`、`basedpyright`、`gopls`、`rust-analyzer` 等语言服务器
- Linux、WSL 和 macOS 建议安装 `zsh` 或 `bash`
- Tree-sitter grammar 通过 `M-x treesit-auto-install-all` 显式安装
- 高速远程开发需要本机 OpenSSH、Git、SCP，以及可通过 SSH 登录的 Linux/macOS 目标

本机差异写入不提交的 `local.el`。可参考 `local.example.el` 设置包源、Org 目录、工具路径、Eat shell 和通知后端。

## 配置结构

| 模块 | 作用 |
| --- | --- |
| `init-ui.el` / `init-window.el` | 主题、字体、Tab Line、窗口和弹窗 |
| `init-enhance.el` / `init-completion.el` | Vertico、Consult、Embark、Corfu、Cape、Yasnippet |
| `init-editing.el` / `init-treesitter.el` | 编辑行为、缩进、括号、Tree-sitter |
| `init-project.el` / `init-lsp.el` | Project、Compilation、Magit、Eglot、Flymake |
| `init-dired.el` / `init-treemacs.el` | 文件管理和项目文件树 |
| `init-term.el` / `init-remote.el` | Eat、Eshell、TRAMP、tramp-rpc |
| `init-evil.el` | Evil、窗口操作、多光标和撤销 |
| `init-org.el` / `init-sicp.el` | Org 工作流、日历、Scheme 和 SICP |

## 常用操作

### 搜索、补全与帮助

```text
C-s                搜索当前 Buffer
M-s r              使用 ripgrep 搜索项目或目录
C-x b              搜索并切换 Buffer
C-c r              打开最近文件
C-. / M-.          在 Minibuffer 中显示候选操作 / 执行默认操作
C-h f/v/k          查看函数、变量或按键帮助
C-h B              查看当前可用按键
S-TAB              在代码、LaTeX、Org 中展开 Yasnippet 或跳到下一字段
```

### 编辑、撤销与跳转

```text
u / C-r            Evil 撤销 / 重做
C-x u              打开 Vundo 可视化撤销历史
C-/                注释或取消注释当前行
s                  输入两个字符后使用 Avy 跳转
M-↑ / M-↓          移动当前代码行或选区
M-d / M-D          添加下一个 / 上一个相同文本到多光标
C-g                退出多光标会话
```

Vundo 用于查看分叉的撤销历史；日常 `u`/`C-r` 使用内置 undo-redo 后端。

### Buffer、Tab 与窗口

```text
[b / ]b            切换当前 Window 的 Tab
Ctrl+Shift+1..9    跳转到当前 Window 的第 1 到第 9 个 Tab
C-x k              关闭当前 Buffer
:q / :wq / :x      关闭 / 保存并关闭当前 Buffer
:qa / :wqa         退出 Emacs / 保存后退出
C-w v / C-w s      向右 / 向下分屏
C-w h/j/k/l        在 Window 间移动
C-w u / C-w C-r    撤销 / 重做窗口布局
C-w o 或 M-o       使用 Ace Window 选择窗口
```

帮助、编译、诊断和终端等临时 Buffer 由 Popper 管理：

```text
C-c `              显示或隐藏最近的弹窗
M-`                在弹窗间循环
C-M-`              切换当前窗口是否由 Popper 管理
q                  关闭当前临时窗口
```

### 项目、编译与 Git

```text
C-c p f            在当前项目查找文件
C-c p p            切换项目
C-c p b            切换当前项目 Buffer
C-c p D            在项目根打开 Dired
C-c p e            在项目根打开 Eshell
C-c b c            保存文件并选择项目编译命令
C-c b r            保存文件并重复当前项目上次编译
C-c b n / p        下一个 / 上一个编译错误
M-!                选择当前目录编译命令
C-x g              打开 Magit Status
```

内置 Project 默认把 Git、Hg、SVN 等版本控制仓库根目录视为项目。编译输出由 Compilation Mode 和 Popper 管理，可直接跳到错误位置。

### 代码补全与 LSP

```text
C-c t c            开关 Corfu 自动补全
C-SPC              在编辑区手动唤出 Corfu 补全菜单
C-n/C-p，TAB       选择上/下一个候选，确认当前候选
C-c t r            开关彩虹括号
g d / g r          跳到定义 / 查找引用
M-, / C-M-,        Xref 历史后退 / 前进
g h                显示光标处悬浮文档
K                  在回显区显示简要文档
C-c l r/a/f        重命名 / Code Action / 格式化 Buffer
M-n / M-p          下一个 / 上一个 Flymake 诊断
```

Eglot 只在配置过的语言 Buffer 中启动；关闭 Corfu 不会关闭 LSP、诊断或跳转。

### Dired 与 Treemacs

```text
C-x d              打开 Dired
C-x C-j            打开当前文件所在目录并定位文件
RET / gf            打开文件或目录
- / ^               返回上级目录
m / u / U           标记 / 取消 / 清除标记
C / R / D           复制 / 移动 / 立即删除
i                   进入 Wdired 批量重命名
TAB                 展开或收起 Dired 子目录
```

```text
C-e                 在编辑区与 Treemacs 之间切换
h / l               根目录上移 / 进入目录或打开文件
H                   显示或隐藏隐藏文件
a / r / c / d       新建 / 重命名 / 复制 / 删除
\                   关闭 Treemacs 侧栏
```

### 终端、中文输入与主题

```text
C-`                打开或关闭底部终端
C-\                切换 Pyim 小鹤双拼
M-j                转换光标前的拼音
C-c t t            切换深色和浅色主题
```

Linux、WSL 和 macOS 使用 Eat；原生 Windows 使用 Eshell。Pyim、Eshell 和 SICP/Geiser 都在首次使用时加载。

## Org 工作流

```text
C-c c              打开 Capture 菜单
C-c a              打开 Agenda 菜单
C-c o              搜索并打开 Org 文件或 Org 目录
C-c C              打开可视日历
C-c l              保存 Org Link
C-c C-t            切换 TODO 状态
C-c C-s / C-c C-d  设置计划日期 / 截止日期
C-c C-w            Refile
C-c C-x C-s        归档当前任务或项目
```

常用 Capture：

```text
i t / i n          Inbox Task / Thought
w t / w p          Work Task / Project
p l / p p / p s    Personal Life / Project / Someday
s                  Add subtask to a Work/Personal NEXT project
n i / n q / n v    Note Idea / Quote / Insight
c e / j e          Calendar Event / Journal Entry
```

常用 Agenda：

```text
d / i / p          今日与 NEXT / Inbox / 工作和个人任务回顾
w / o              本周 / 本月
j / k              移动选择
RET / TAB           打开源位置 / 在另一 Window 显示源位置
t / s / C-c C-d    修改 TODO / 计划日期 / 截止日期
a / r / q           归档 / 刷新 / 退出
```

Org 文件默认位于 `~/org/`，Windows 位于 `%USERPROFILE%/org/`。首次调用 Capture/Agenda 时若缺少工作流文件会询问是否初始化。Agenda 读取 Inbox、Work、Personal 和 Calendar；Journal 不进入 Agenda。首次打开 Org Buffer 或调用 Capture/Agenda 后启动提醒，要求 Emacs 保持运行且时间戳包含具体时间。

重要注意事项：

- Capture 用 `C-c C-c` 保存、`C-c C-k` 取消；Agenda 是只读面板，应按 `RET` 回源文件编辑。
- Refile 应选择带标题的目标，例如 `work.org/Tasks`，不要选择文件根。
- 手机同步应落到本机 Org 目录，不建议让 Agenda 直接操作 WebDAV TRAMP 路径。
- Windows 仅对同步 Org 文件每 5 秒轮询；未修改的 Buffer 才会自动重载。

可视日历中使用 `h/j/k/l` 移动，`v d/w/m` 切换日、周、月视图，`SPC` 打开当日 Agenda，`RET` 打开事项，`q` 退出。

## 远程开发

```text
C-x C-f
/rpc:user@host:/path/to/project
```

`tramp-rpc` 通过 SSH 访问 x86_64/aarch64 Linux 或 macOS 远端，支持远程文件、Eglot、Magit、编译和终端。首次连接需要访问 GitHub 下载 server，并写入远端用户缓存目录；失败时可改用 `/ssh:user@host:/path` 排查。终端快捷键 `C-\`` 复用同一个 Eat Buffer，多项目或多主机之间不会自动创建独立终端。

Windows Emacs 也可以把 WSL 当作 SSH 远端：在 WSL 中安装并启动 `openssh-server`，并配置 Windows 到 WSL 的 SSH 公钥登录。先在 PowerShell 确认以下命令无需密码且输出 Linux 信息：

```powershell
ssh -o BatchMode=yes <WSL用户名>@localhost "uname -a"
```

然后访问（尖括号内容必须替换，`user` 不是固定用户名）：

```text
/rpc:<WSL用户名>@localhost:/home/<WSL用户名>/project
```

这与 VS Code Remote WSL 的目标接近，但运行模型不同：Emacs 本体和界面仍在 Windows，文件操作和开发进程通过 TRAMP 在 WSL 执行。WSL2 的 `localhost` 转发通常可直接使用；若 SSH 端口不是 22，可写 `localhost#端口`。当前配置会优先加载外部 TRAMP 2.8.2，并在 Windows 关闭 SSH ControlMaster。使用不存在的用户名时，TRAMP 可能在文件名补全阶段等待认证，看起来像输入路径时卡住。

## 关键踩坑

- Tree-sitter grammar 与操作系统、CPU 和 Emacs ABI 绑定，不要跨机器同步 `tree-sitter/`。Emacs 30.1 的 C grammar 固定到兼容 ABI 的版本。
- `.editorconfig` 优先决定缩进；C/C++ 没有规则时固定使用 4 空格，避免续行让 dtrt-indent 误判为 2。其他语言没有明确规则时才在打开文件时推断宽度和 Tab 风格。
- 文本和代码 Buffer 使用 Visual Line 按窗口宽度折行，不修改文件内容；缩进线使用 indent-bars，并强调光标所在的缩进深度。
- C/C++ 输入时不根据未完成的语法树自动重排：`RET` 在 `{` 或 `case/default:` 后增加一级，并在宏定义行尾自动添加续行反斜杠；`TAB` 前进到下一个缩进位置。需要整理完整代码时选中区域执行 `M-x indent-region`。
- 原生 Windows 的 MSYS GPG 可能错误处理盘符路径。配置已让 GPG 使用默认 home；不要长期关闭包签名验证。
- TTY、SSH 和 WSL 终端没有额外系统剪贴板桥接，默认只操作 Emacs kill-ring。

## 启动分析

默认不记录逐个 `require` 的耗时。需要分析时，在 `early-init.el` 设置：

```elisp
(setq my/enable-startup-benchmarking t)
```

启动后执行 `M-x sanityinc/require-times`。
