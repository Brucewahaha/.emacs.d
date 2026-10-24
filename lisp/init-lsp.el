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
  :hook ((python-mode . my/eglot-ensure)
         (python-ts-mode . my/eglot-ensure)
         (c-mode . my/eglot-ensure)
         (c++-mode . my/eglot-ensure)
         (c-ts-mode . my/eglot-ensure)
         (c++-ts-mode . my/eglot-ensure)
         (js-mode . my/eglot-ensure)
         (js-ts-mode . my/eglot-ensure)
         (typescript-ts-mode . my/eglot-ensure)
         (tsx-ts-mode . my/eglot-ensure)
         (go-mode . my/eglot-ensure)
         (go-ts-mode . my/eglot-ensure)
         (sh-mode . my/eglot-ensure)
         (bash-ts-mode . my/eglot-ensure)
         (rust-mode . my/eglot-ensure)
         (rust-ts-mode . my/eglot-ensure)
         (ruby-mode . my/eglot-ensure)
         (ruby-ts-mode . my/eglot-ensure)
         (haskell-mode . my/eglot-ensure)
         (haskell-ts-mode . my/eglot-ensure)
         (json-mode . my/eglot-ensure)
         (json-ts-mode . my/eglot-ensure)
         (cmake-mode . my/eglot-ensure)
         (cmake-ts-mode . my/eglot-ensure))
  :config
  (setq eglot-events-buffer-size 0
        eglot-autoshutdown t)
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
