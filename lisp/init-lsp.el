;;; init-lsp.el --- Eglot, diagnostics and LSP navigation -*- lexical-binding: t -*-
;;; Code:

(use-package eglot
  :ensure nil
  :hook ((python-mode . eglot-ensure)
         (python-ts-mode . eglot-ensure)
         (c-mode . eglot-ensure)
         (c++-mode . eglot-ensure)
         (c-ts-mode . eglot-ensure)
         (c++-ts-mode . eglot-ensure)
         (js-mode . eglot-ensure)
         (js-ts-mode . eglot-ensure)
         (typescript-ts-mode . eglot-ensure)
         (tsx-ts-mode . eglot-ensure)
         (go-mode . eglot-ensure)
         (go-ts-mode . eglot-ensure)
         (sh-mode . eglot-ensure)
         (bash-ts-mode . eglot-ensure)
         (rust-mode . eglot-ensure)
         (rust-ts-mode . eglot-ensure)
         (ruby-mode . eglot-ensure)
         (ruby-ts-mode . eglot-ensure)
         (haskell-mode . eglot-ensure)
         (haskell-ts-mode . eglot-ensure)
         (json-mode . eglot-ensure)
         (json-ts-mode . eglot-ensure)
         (cmake-mode . eglot-ensure)
         (cmake-ts-mode . eglot-ensure))
  :config
  (setq eglot-events-buffer-size 0
        eglot-autoshutdown t)
  (when-let ((g++ (and (not my/windows-p)
                       (executable-find "g++"))))
    (add-to-list
     'eglot-server-programs
     `((c-mode c-ts-mode c++-mode c++-ts-mode)
       . ("clangd" ,(concat "--query-driver=" g++)))))
  (let ((map eglot-mode-map))
    (define-key map (kbd "C-c l r") #'eglot-rename)
    (define-key map (kbd "C-c l a") #'eglot-code-actions)
    (define-key map (kbd "C-c l f") #'eglot-format-buffer)))

(use-package flymake
  :ensure nil
  :bind (("M-n" . flymake-goto-next-error)
         ("M-p" . flymake-goto-prev-error)))

(use-package consult-eglot
  :ensure t
  :after (eglot consult))

(use-package eldoc-box
  :ensure t
  :after eglot
  :demand t
  :config
  (setq eldoc-box-clear-with-C-g t)
  (with-eval-after-load 'evil
    (evil-define-key 'normal eglot-mode-map (kbd "g h")
      #'eldoc-box-help-at-point)))

(provide 'init-lsp)
;;; init-lsp.el ends here
