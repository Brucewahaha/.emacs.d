;;; init-lsp.el --- Eglot, diagnostics and LSP navigation -*- lexical-binding: t -*-
;;; Code:

(require 'init-performance)

(defun my/eglot-ensure ()
  "Automatically start Eglot only for normal-sized buffers."
  (unless (my/buffer-needs-lightweight-p)
    (eglot-ensure)))

(defun my/eglot-clangd-contact (&optional _interactive)
  "Build a clangd command without leaking local compiler paths to a remote host."
  (let ((driver (and (not (file-remote-p default-directory))
                     (not my/windows-p)
                     (executable-find "g++"))))
    (if driver
        (list "clangd" (concat "--query-driver=" driver))
      '("clangd"))))

(defun my/eglot-activate-normal-buffer (original &rest args)
  "Avoid automatically attaching large buffers to an existing project server."
  (unless (my/buffer-needs-lightweight-p)
    (apply original args)))

(use-package eglot
  :ensure nil
  :commands eglot-ensure
  ;; Built-in modes plus their Tree-sitter variants.  A hook naming a mode that
  ;; is not installed (e.g. `haskell-mode') costs nothing and starts working
  ;; once the package is added.
  :hook (((python-base-mode c-mode c++-mode c-ts-base-mode
           js-base-mode typescript-ts-base-mode
           sh-base-mode ruby-base-mode json-ts-mode cmake-ts-mode
           go-mode go-ts-mode rust-mode rust-ts-mode
           haskell-mode haskell-ts-mode)
          . my/eglot-ensure))
  :config
  (setq eglot-events-buffer-config '(:size 0 :format full)
        eglot-autoshutdown t)
  ;; Typing-time indentation belongs to the major mode, as with VS Code's
  ;; default `editor.formatOnType: false'.  Otherwise clangd re-indents the
  ;; line after RET in its own style (LLVM, 2 columns, without .clang-format).
  (add-to-list 'eglot-ignored-server-capabilities
               :documentOnTypeFormattingProvider)
  (add-to-list 'eglot-server-programs
               '((c-mode c-ts-mode c++-mode c++-ts-mode)
                 . my/eglot-clangd-contact))
  ;; Skipping eglot-ensure alone does not prevent an already-running server
  ;; from claiming another file in its project.  Guard that entry point too.
  (advice-add 'eglot--maybe-activate-editing-mode :around
              #'my/eglot-activate-normal-buffer)
  (let ((map eglot-mode-map))
    (define-key map (kbd "C-c l r") #'eglot-rename)
    (define-key map (kbd "C-c l a") #'eglot-code-actions)
    (define-key map (kbd "C-c l f") #'eglot-format-buffer)))

(use-package flymake
  :ensure nil
  :bind (("M-n" . flymake-goto-next-error)
         ("M-p" . flymake-goto-prev-error)))

;; Eglot and eldoc-box render the servers' Markdown documentation with it.
(use-package markdown-mode
  :ensure t
  :defer t)

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
