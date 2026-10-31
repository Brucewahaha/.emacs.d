;;; init-enhance.el --- UI and Modern Completion Stack -*- lexical-binding: t -*-
;;; Commentary:
;;; This file replaces Ivy/Counsel with the Vertico + Consult + Embark stack.
;;; Code:

(defun my/consult-ripgrep-dwim ()
  "Search with Ripgrep, initially using the region or symbol at point."
  (interactive)
  (consult-ripgrep
   nil
   (if (use-region-p)
       (buffer-substring-no-properties (region-beginning) (region-end))
     (thing-at-point 'symbol t))))

;; =============================================================================
;; 1. 基础 UI 与体验增强 (保持原有功能)
;; =============================================================================
(use-package emacs
  :init
  (recentf-mode 1)
  (save-place-mode 1)
  (global-auto-revert-mode 1)
  (setq history-length 25
        auto-revert-interval (if my/windows-p 5 2)))

(defun my/use-polling-for-synced-org-file ()
  "Use polling for Org files replaced by Windows sync clients."
  (when (and my/windows-p
             buffer-file-name
             (file-in-directory-p buffer-file-name org-directory))
    (setq-local auto-revert-use-notify nil)))

(add-hook 'org-mode-hook #'my/use-polling-for-synced-org-file)

(use-package dashboard
  :ensure t
  :config
   (defun my/dashboard-goto-first-item ()
     "Place point on the first Dashboard item after initialization."
     (goto-char (point-min))
     (widget-forward 1))
   (setq dashboard-banner-logo-title "Welcome to Emacs!")
   (setq dashboard-startup-banner 'logo)
   (setq dashboard-projects-backend 'project-el)
   (setq dashboard-page-separator "\n────────────────────────────────────────\n")
   (setq dashboard-icon-type 'nerd-icons
         dashboard-display-icons-p #'my/nerd-font-available-p
         dashboard-set-file-icons t)
   (setq dashboard-items '((recents . 5)
                            (projects . 10)))
   (add-hook 'dashboard-after-initialize-hook #'my/dashboard-goto-first-item)
   (dashboard-setup-startup-hook))

;; Built-in highlighting; M-s h u removes a highlight.
(global-set-key (kbd "<f3>") #'highlight-symbol-at-point)

;; 彩虹括号默认关闭；C-c t r 在所有编程 Buffer 中开关。
(defvar my/rainbow-delimiters-enabled nil
  "非 nil 时在编程 Buffer 中启用彩虹括号。")

(defun my/rainbow-delimiters-maybe-enable ()
  "按全局开关启用当前 Buffer 的彩虹括号。"
  (when my/rainbow-delimiters-enabled
    (rainbow-delimiters-mode 1)))

(defun my/toggle-rainbow-delimiters ()
  "全局开关彩虹括号。"
  (interactive)
  (setq my/rainbow-delimiters-enabled (not my/rainbow-delimiters-enabled))
  (dolist (buffer (buffer-list))
    (with-current-buffer buffer
      (when (derived-mode-p 'prog-mode)
        (rainbow-delimiters-mode
         (if my/rainbow-delimiters-enabled 1 -1)))))
  (message "彩虹括号已%s" (if my/rainbow-delimiters-enabled "开启" "关闭")))

;; The hook is ours, so the package itself loads only when first enabled.
(add-hook 'prog-mode-hook #'my/rainbow-delimiters-maybe-enable)
(global-set-key (kbd "C-c t r") #'my/toggle-rainbow-delimiters)

(use-package rainbow-delimiters
  :ensure t
  :commands rainbow-delimiters-mode)

;; =============================================================================
;; 2. Vertico 补全全家桶 (替代 Ivy/Counsel)
;; =============================================================================

;; Vertico: 提供垂直补全界面 (替代 Ivy 界面)
(use-package vertico
  :ensure t
  :init
  (vertico-mode 1)
  :config
  (setq vertico-cycle t))


;; Orderless: 模糊匹配策略 (替代 Ivy 的匹配算法)
(use-package orderless
  :ensure t
  :custom
  (completion-styles '(orderless basic))
  (completion-category-overrides '((file (styles basic partial-completion)))))

;; Marginalia: 补全列表侧边栏 (显示函数说明、文件权限等)
(use-package marginalia
  :ensure t
  :init
  (marginalia-mode 1))

(use-package savehist
  :init
  (savehist-mode 1))

;; Consult: 增强型搜索命令 (完全替代 Counsel 和 Swiper)
(use-package consult
  :ensure t
  :bind (;; 替换 Swiper
         ("C-s" . consult-line)
         ;; 替换 Counsel 的常用命令
         ("M-y" . consult-yank-pop)      ; 替换 counsel-yank-pop
         ("C-x b" . consult-buffer)      ; 替换 switch-to-buffer
         ("C-c r" . consult-recent-file) ; 替换 counsel-recentf
         ("M-g i" . consult-imenu)       ; 快速跳转函数
         ("M-g g" . consult-goto-line)   ; 跳转行
         
         ;; --- 修复 M-s 冲突的部分 ---
         ;; 我们将这些命令绑定到 search-map (通常就是 M-s 键)
         :map search-map
         ("r" . my/consult-ripgrep-dwim) ; 对应 M-s r
         ("g" . consult-git-grep))       ; 对应 M-s g
  :hook (completion-list-mode . consult-preview-at-point-mode))

;; Embark: “右键菜单”功能，允许在补全项上执行多种动作
(use-package embark
  :ensure t
  :bind (("C-." . embark-act)         ; 触发动作
         ("M-." . embark-dwim)        ; 智能动作
         ("C-h B" . embark-bindings)) ; 查看所有快捷键
  :init
  (setq prefix-help-command #'embark-prefix-help-command))

;; 让 Embark 和 Consult 配合使用
(use-package embark-consult
  :ensure t
  :after (embark consult)
  :demand t)

;; Wgrep: 允许在 grep/ripgrep 结果 buffer 中直接修改文件 (类似 ivy-occur)
;; Its autoloads hook into grep buffers, so loading can wait until then.
(use-package wgrep
  :ensure t
  :defer t
  :custom
  (wgrep-auto-save-buffer t))

(provide 'init-enhance)
;;; init-enhance.el ends here
