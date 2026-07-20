;;; init-sicp.el --- Scheme and SICP settings -*- lexical-binding: t -*-
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

;; 可选：设置执行代码时不询问是否确认
(setq org-confirm-babel-evaluate nil)

;; 1. 开启 org 自带的快捷输入 (解决 <s + TAB 问题)
(require 'org-tempo)
(provide 'init-sicp)
