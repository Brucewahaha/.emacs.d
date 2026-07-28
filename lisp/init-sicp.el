;;; init-sicp.el --- Scheme and SICP settings -*- lexical-binding: t -*-
;; 1. Scheme 增强，Geiser 的核心
(use-package geiser-racket :ensure t)
;; 2. Lisp 结构化编辑
(defun my/enable-paredit ()
  "Enable Paredit and let it exclusively manage paired delimiters."
  (electric-pair-local-mode -1)
  (paredit-mode 1))

(use-package paredit
  :ensure t
  :hook ((emacs-lisp-mode
          lisp-interaction-mode
          lisp-mode
          scheme-mode
          racket-mode
          clojure-mode
          geiser-repl-mode)
         . my/enable-paredit))
;; 3. Org-mode 整合代码块
(org-babel-do-load-languages
 'org-babel-load-languages
 '((scheme . t)))
;; 可选：设置执行代码时不询问是否确认
(setq org-confirm-babel-evaluate nil)

;; 1. 开启 org 自带的快捷输入 (解决 <s + TAB 问题)
(require 'org-tempo)
(provide 'init-sicp)
