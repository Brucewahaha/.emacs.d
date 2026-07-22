# Emacs Configuration

这是一个面向 Emacs 30 的轻量个人配置，采用 ELPA 和 Emacs 内置功能优先的策略。配置以模块化 Lisp 文件组织，重点覆盖 Evil 编辑、项目开发、补全、文件管理、终端和 Org 工作流。

## 前提

- Emacs 30.1
- Linux/WSL 下建议安装 `zsh`，Eat 会优先启动 `/bin/zsh`
- 按需安装语言服务器，例如 `clangd`、`basedpyright`、`gopls`、`rust-analyzer`
- 首次使用前确认 ELPA 镜像可访问；已安装包不会在正常启动时联网安装

## 配置结构

| 模块 | 作用 |
| --- | --- |
| `init-environment.el` | UTF-8、Shell 环境变量、direnv |
| `init-ui.el` | 主题、字体、Modeline、Tab Line |
| `init-enhance.el` | Vertico、Consult、Embark、彩虹括号 |
| `init-editing.el` | Tree-sitter、缩进、括号、基础编辑行为 |
| `init-lsp.el` | Eglot、Flymake、Consult-Eglot |
| `init-completion.el` | Corfu、Cape、Yasnippet、补全开关 |
| `init-project.el` | Projectile、Magit |
| `init-dired.el` | Dired、Wdired、Dired Subtree |
| `init-treemacs.el` | Treemacs、项目文件树 |
| `init-term.el` | Eat、Eshell 集成 |
| `init-evil.el` | Evil、Evil Collection、多光标、快捷键 |
| `init-org.el` / `init-sicp.el` | Org、Scheme、SICP |

## 主要插件

- 编辑与 UI：`evil`、`doric-themes`、`doom-themes`、`doom-modeline`、`nerd-icons`
- Minibuffer：`vertico`、`orderless`、`marginalia`、`consult`、`embark`
- 代码补全：`corfu`、`cape`、`yasnippet`
- 开发：内置 `eglot`、内置 `flymake`、`consult-eglot`、`treesit-auto`
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
C-c t t            在 Doric Fire 夜间主题与 Doric Jade 浅色主题之间切换
```

Doom Themes 的集成配置保留为备选，但当前不会加载或启用。

### 代码模板

Yasnippet 提供常用代码片段的展开和占位符跳转。

```text
S-TAB              展开当前模板，或跳转到下一个模板字段
```

### 候选项操作

在文件搜索、Buffer 切换或命令执行等 Minibuffer 候选列表中，可对当前候选项执行额外操作。

```text
C-.                显示当前候选项可用的操作
M-.                直接执行最合适的候选项操作
C-h B              查看当前快捷键绑定
```

### 弹窗窗口

帮助、编译输出、诊断、消息和 Eat 终端等临时 Buffer 由 Popper 统一管理，不打断主编辑窗口布局。

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
```

### 文件管理

使用 `C-x d` 打开 Dired。Evil Normal 状态下：

```text
h                  返回上级目录
l                  打开文件或进入目录
H                  显示/隐藏隐藏文件
a                  新建文件；以 / 结尾则新建目录
r                  重命名当前或标记文件
c                  复制当前路径
v                  将复制路径的文件或目录复制到当前目录
d                  删除当前或标记文件
\                  关闭 Dired Window
i / C-c C-e        进入 Wdired 重命名模式
TAB                展开或收起子目录
```

Wdired 中使用 `C-c C-c` 提交重命名，`C-c C-k` 放弃修改。

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
K                  显示符号文档
C-c l r            重命名符号
C-c l a            Code Action
C-c l f            格式化当前 Buffer
M-n / M-p          下一个 / 上一个 Flymake 诊断
```

关闭代码补全弹窗不会关闭 Eglot、诊断、跳转、重命名或格式化功能。

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

### 终端与 Org

```text
C-`                打开或关闭 Eat 终端
C-c c              Org Capture
C-c a              Org Agenda
C-c l              保存 Org Link
```

Eat 是主终端，会优先使用 zsh；Eshell 保留用于 Emacs 内部对象和轻量命令。

## 启动性能

默认不记录每个 `require` 的耗时，避免启动期 advice 开销。需要分析启动时，在 `early-init.el` 增加：

```elisp
(setq my/enable-startup-benchmarking t)
```

启动后可执行 `M-x sanityinc/require-times` 查看模块加载耗时。
