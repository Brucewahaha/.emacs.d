;;; init-sicp.el --- Scheme and SICP settings -*- lexical-binding: t -*-
;;; Code:

;; Geiser is activated by its package autoloads when Scheme/Racket is used.
(use-package geiser-racket
  :ensure t
  :defer t)

;; Lisp 结构化编辑
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

(with-eval-after-load 'org
  ;; `org-babel-execute:scheme' autoloads ob-scheme on first execution.
  (add-to-list 'org-babel-load-languages '(scheme . t))
  (autoload 'org-babel-execute:scheme "ob-scheme")
  (setq org-confirm-babel-evaluate nil)
  (require 'org-tempo))

(provide 'init-sicp)
;;; init-sicp.el ends here
