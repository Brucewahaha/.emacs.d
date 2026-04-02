;;; init-term.el --- Eat Terminal toggle (Universal Windows/WSL) -*- lexical-binding: t -*-
;; 1. Scheme 增强，Geiser 的核心
(use-package geiser-racket :ensure t)
;; 2. 写 Lisp 必备！解决括号恐惧症
(use-package paredit :ensure t)
;; 3. Org-mode 整合代码块
(org-babel-do-load-languages
 'org-babel-load-languages
 '((scheme . t)))
;; --- Hook 配置 ---
;; 当进入 Scheme 模式时，自动开启 paredit
(add-hook 'scheme-mode-hook #'enable-paredit-mode)

(org-babel-do-load-languages
 'org-babel-load-languages
 '((scheme . t))) ;; 开启对 Scheme 的支持
;; 可选：设置执行代码时不询问是否确认
(setq org-confirm-babel-evaluate nil)

;; 在 org-mode 中禁用自动补全（如果你真的很烦它）
(add-hook 'org-mode-hook (lambda () (corfu-mode -1)))

;; 1. 彻底移除所有可能导致报错的 Advice
(advice-remove 'pcomplete-completions-at-point #'cape-wrap-silent)
(advice-remove 'pcomplete-completions-at-point #'cape-wrap-purify)
;; 2. 检查并重置补全列表，只保留最基本的行为
(setq-default completion-at-point-functions '(tags-completion-at-point))
;; 3. 在 org-mode 中完全禁用自动补全弹窗 (既然你想专注 SICP)
(add-hook 'org-mode-hook (lambda ()
                           (corfu-mode -1)
                           (setq-local completion-at-point-functions nil)))

;; 1. 开启 org 自带的快捷输入 (解决 <s + TAB 问题)
(require 'org-tempo)
;; 2. 如果你想用 Corfu，但又不想它一直弹，你可以配置它只在你按 M-TAB 时才出现
(use-package corfu
  :ensure t
  :custom
  (corfu-auto nil) ;; 禁用自动弹出 (这样你就不会在打字时被骚扰了)
  :init
  (global-corfu-mode 1))

(provide 'init-sicp)
