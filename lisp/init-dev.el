;;; init-dev.el --- Unified Development Environment -*- lexical-binding: t -*-
;;; Code:
(require 'init-treesitter)
;; 1. 编程基础行为
(electric-pair-mode t)                       ; 自动补全括号
(add-hook 'prog-mode-hook #'show-paren-mode) ; 高亮对应括号
(add-hook 'prog-mode-hook #'hs-minor-mode)   ; 代码折叠

;; === Tab 智能缩进与补全方案 ===
;; 在 init-dev.el 中添加 editorconfig 支持
(use-package editorconfig
  :ensure t
  :config
  (editorconfig-mode 1))

;; 优化 Tab 行为：如果选中了区域，则缩进选区；否则执行智能缩进/补全
(setq-default indent-tabs-mode nil) ; 默认使用空格
(setq-default tab-width 4)
(setq tab-always-indent 'complete)  ; 【关键】Tab 键先缩进，再尝试补全
(setq-default standard-indent 4)

(setq-default c-basic-offset 4) ; 针对传统的 c-mode / c++-mode
(setq-default c++-basic-offset 4)

(use-package dtrt-indent
  :ensure t
  :diminish
  :hook (after-init . dtrt-indent-global-mode)
  :config
  (setq dtrt-indent-verbosity 0)) ; 减少在 minibuffer 里的提示

(use-package indent-bars
  :ensure t
  :hook (prog-mode . indent-bars-mode)
  :custom
  (indent-bars-width-frac 0.1)  ; 对齐线的宽度
  (indent-bars-pad-frac 0.1)    ; 间距
  (indent-bars-pattern " .  ")  ; 样式
  (indent-bars-zigzag nil))     ; 是否使用锯齿线

(electric-indent-mode 1) ; 开启回车自动缩进对齐
;; ;; 如果使用 tree-sitter 版的 mode (c++-ts-mode)，有时需要单独设置：
(add-hook 'c++-ts-mode-hook (lambda () (setq-local c-ts-mode-indent-offset 4)))
(add-hook 'c-ts-mode-hook (lambda () (setq-local c-ts-mode-indent-offset 4)))

;; 拷贝粘贴设置
(setq select-enable-primary nil)        ; 选择文字时不拷贝
(setq select-enable-clipboard t)        ; 拷贝时使用剪贴板

;; Directly modify when selecting text
(use-package delsel
  :ensure nil
  :hook (after-init . delete-selection-mode))

;; auto save configuration
(setq make-backup-files nil)                                  ; 不自动备份
(setq auto-save-default nil)                                  ; 不使用Emacs自带的自动保存


(use-package eglot
  :ensure nil
  :hook ((python-ts-mode . eglot-ensure)
         (c-ts-mode      . eglot-ensure)
         (c++-ts-mode    . eglot-ensure)
         (js-ts-mode     . eglot-ensure)
         (typescript-ts-mode . eglot-ensure)
         (tsx-ts-mode    . eglot-ensure)
         (go-ts-mode     . eglot-ensure)
         (sh-mode        . eglot-ensure) ; Bash
	     (rust-ts-mode   . eglot-ensure)
         (ruby-ts-mode   . eglot-ensure)
         (haskell-ts-mode . eglot-ensure)
         (json-ts-mode   . eglot-ensure)
         (cmake-mode     . eglot-ensure))
  :config
  (setq eglot-events-buffer-size 0) ; 提高性能
  (setq eglot-autoshutdown t)

  (let ((map eglot-mode-map))
    (define-key map (kbd "C-c l r") 'eglot-rename)
    (define-key map (kbd "C-c l a") 'eglot-code-actions)
    (define-key map (kbd "C-c l f") 'eglot-format-buffer)))
;; 2. 补全增强
(use-package corfu
  :ensure t
  :hook (after-init . global-corfu-mode)
  :bind
  (:map corfu-map
        ("SPC" . corfu-insert-separator)    ; configure space for separator insertion
        ("M-q" . corfu-quick-complete)      ; use C-g to exit
        ("TAB" . corfu-next)
        ([tab] . corfu-next)
        ("S-TAB" . corfu-previous)
        ([backtab] . corfu-previous))
  :config
  ;; TAB cycle if there are only few candidates
  (setq completion-cycle-threshold 0)
  (setq tab-always-indent 'complete)

  (defun corfu-enable-always-in-minibuffer ()
    "Enable Corfu in the minibuffer if Vertico/Mct are not active."
    (unless (or (bound-and-true-p mct--active)
                (bound-and-true-p vertico--input))
      ;; (setq-local corfu-auto nil) Enable/disable auto completion
      (corfu-mode 1)))
  (add-hook 'minibuffer-setup-hook #'corfu-enable-always-in-minibuffer 1)

  ;; enable corfu in eshell
  (add-hook 'eshell-mode-hook
            (lambda ()
              (setq-local corfu-auto nil)
              (corfu-mode)))

  ;; For Eshell
  ;; ===========
  ;; avoid press RET twice in Eshell
  (defun corfu-send-shell (&rest _)
    "Send completion candidate when inside comint/eshell."
    (cond
     ((and (derived-mode-p 'eshell-mode) (fboundp 'eshell-send-input))
      (eshell-send-input))
     ((and (derived-mode-p 'comint-mode)  (fboundp 'comint-send-input))
      (comint-send-input))))

  (advice-add #'corfu-insert :after #'corfu-send-shell)

  :custom
  (corfu-cycle t)                ;; Enable cycling for `corfu-next/previous'
  (corfu-auto t)
  (corfu-auto-delay 0.1)
  (corfu-auto-prefix 2)
  (corfu-preview-current nil)
  )

;; 永远不要让 ispell 补全进列表
(setq completion-at-point-functions 
      (delq 'ispell-completion-at-point completion-at-point-functions))

;;Cape 插件提供了一系列开箱即用的补全后端，跟corfu联合使用。
;;(use-package cape
;;  :ensure t
;;  :init
;;  ;; Add `completion-at-point-functions', used by `completion-at-point'.
;;  (add-to-list 'completion-at-point-functions #'cape-file)
;;  (add-to-list 'completion-at-point-functions #'cape-dabbrev)
;;  (add-to-list 'completion-at-point-functions #'cape-keyword)  ; programming language keyword
;;  (add-to-list 'completion-at-point-functions #'cape-ispell)
;;  (add-to-list 'completion-at-point-functions #'cape-dict)
;;  (add-to-list 'completion-at-point-functions #'cape-symbol)   ; elisp symbol
;;  (add-to-list 'completion-at-point-functions #'cape-line)
;;
;;  :config
;;  (require 'cape)
;;  (setq cape-dict-file (expand-file-name "etc/hunspell_dict.txt" user-emacs-directory))
;;
;;  ;; for Eshell:
;;  ;; ===========
;;  ;; Silence the pcomplete capf, no errors or messages!
;;  (advice-add 'pcomplete-completions-at-point :around #'cape-wrap-silent)
;;
;;  ;; Ensure that pcomplete does not write to the buffer
;;  ;; and behaves as a pure `completion-at-point-function'.
;;  (advice-add 'pcomplete-completions-at-point :around #'cape-wrap-purify)
;;  )

;; 3. 语法检查 (Eglot 默认使用 Flymake)
;; 如果你坚持想用 Flycheck，需要安装 `exec-path-from-shell` 并配置兼容层
;; 但建议尝试原生的 Flymake：
(use-package flymake
  :ensure nil
  :bind (("M-n" . flymake-goto-next-error)
         ("M-p" . flymake-goto-prev-error)))
;; 4. Consult 集成 (用 consult-eglot 替换 consult-lsp)
(use-package consult-eglot
  :ensure t
  :after (eglot consult))

;; 6. Yasnippet
(use-package yasnippet
  :ensure t
  :diminish yas-minor-mode
  :hook ((after-init . yas-reload-all)
         ((prog-mode LaTeX-mode org-mode) . yas-minor-mode))
  :config
  ;; Suppress warning for yasnippet code.
  (require 'warnings)
  (add-to-list 'warning-suppress-types '(yasnippet backquote-change))

  (setq yas-prompt-functions '(yas-x-prompt yas-dropdown-prompt))
  (defun smarter-yas-expand-next-field ()
    "Try to `yas-expand' then `yas-next-field' at current cursor position."
    (interactive)
    (let ((old-point (point))
          (old-tick (buffer-chars-modified-tick)))
      (yas-expand)
      (when (and (eq old-point (point))
                 (eq old-tick (buffer-chars-modified-tick)))
        (ignore-errors (yas-next-field))))))

;; 显式确保 lsp-bridge 必须的依赖包已安装
;; (dolist (pkg '(markdown-mode posframe yasnippet))
;;   (unless (package-installed-p pkg)
;;     (package-install pkg)))

;; (use-package lsp-bridge
;;   :ensure nil
;;   :init
;;   (require 'lsp-bridge)
;;   :config
;;   (global-lsp-bridge-mode)
;;   ;; --- Windows 环境自动适配 ---
;;   (when (eq system-type 'windows-nt)
;;     ;; 1. 强制指定 python 路径（防止 Windows 找不到 python3）
;;     (setq lsp-bridge-python-command "python")
    
;;     ;; 2. 优化 Windows 下的异步进程性能
;;     (setq process-adaptive-read-buffering nil))

;;   ;; --- 针对你配置中的 Evil 模式进行适配 ---
;;   (with-eval-after-load 'evil
;;     (setq lsp-bridge-enable-hover-diagnostic t)
;;     ;; 定义 Evil 风格的快捷键
;;     (evil-define-key 'normal lsp-bridge-mode-map (kbd "g d") 'lsp-bridge-find-def)
;;     (evil-define-key 'normal lsp-bridge-mode-map (kbd "g r") 'lsp-bridge-find-references)
;;     (evil-define-key 'normal lsp-bridge-mode-map (kbd "K")   'lsp-bridge-lookup-documentation)
;;     (evil-define-key 'normal lsp-bridge-mode-map (kbd "M-n") 'lsp-bridge-diagnostic-jump-next)
;;     (evil-define-key 'normal lsp-bridge-mode-map (kbd "M-p") 'lsp-bridge-diagnostic-jump-prev))

;;   ;; 默认开启代码多光标支持等高级功能
;;   (setq lsp-bridge-enable-org-header-completion t))


(use-package treemacs
 :ensure t
 :defer t
 :config
 (treemacs-tag-follow-mode)
 (with-eval-after-load 'treemacs
   (define-key treemacs-mode-map [mouse-1] #'treemacs-single-click-expand-action)
   (define-key treemacs-mode-map [mouse-2] #'treemacs-rightclick-menu))
 :bind
 (:map global-map
    ("M-0"    . treemacs-select-window)
    ("C-x t 1"  . treemacs-delete-other-windows)
    ("C-x t t"  . treemacs)
    ("C-x t B"  . treemacs-bookmark)
    ;; ("C-x t C-t" . treemacs-find-file)
    ("C-x t M-t" . treemacs-find-tag))
 (:map treemacs-mode-map
	("/" . treemacs-advanced-helpful-hydra)))

(use-package treemacs-evil
  :ensure t
  :after (treemacs evil))

(use-package doom-themes
  :ensure t
  :config
  ;; 这一行是核心：它会让 treemacs 的外观变得像 doom 一样简洁
  (doom-themes-treemacs-config)
  ;; 修正主题中一些细微的 UI 闪烁
  (doom-themes-visual-bell-config))

(use-package treemacs-projectile
 :ensure t
 :after (treemacs projectile))


(provide 'init-dev)
