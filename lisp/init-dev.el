;;; init-dev.el --- Unified Development Environment -*- lexical-binding: t -*-
;;; Code:

(require 'init-treesitter)
(use-package eglot
  :ensure nil
  :hook ((python-ts-mode . eglot-ensure)
         (c-ts-mode      . eglot-ensure)
         (c++-ts-mode    . eglot-ensure)
         (js-ts-mode     . eglot-ensure)
         (typescript-ts-mode . eglot-ensure))
  :config
  (setq eglot-events-buffer-size 0)
  (setq eglot-autoshutdown t)
  
  (let ((map eglot-mode-map))
    (define-key map (kbd "C-c l r") 'eglot-rename)
    (define-key map (kbd "C-c l a") 'eglot-code-actions)
    (define-key map (kbd "C-c l f") 'eglot-format-buffer)))
;; 2. 补全增强 (仍使用 Company)
(use-package company
  :ensure t
  :init (global-company-mode)
  :config (setq company-idle-delay 0.0 company-minimum-prefix-length 1))
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
  :init (yas-global-mode 1))
(use-package yasnippet-snippets :ensure t)


(use-package treemacs
 :ensure t
 :defer t
 :config
 (treemacs-tag-follow-mode)
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

(use-package treemacs-projectile
 :ensure t
 :after (treemacs projectile))


(provide 'init-dev)
