;;; init-lsp.el --- Eglot, diagnostics and LSP navigation -*- lexical-binding: t -*-
;;; Code:

(use-package eglot
  :ensure nil
  :init
  (defvar my/eglot-missing-server-notifications (make-hash-table :test #'equal)
    "Projects and modes for which a missing Eglot server was reported.")

  (defconst my/eglot-install-hints
    '((python-ts-mode . "Install one server, for example: pipx install basedpyright")
      (c-ts-mode . "Install clangd, for example: sudo apt install clangd")
      (c++-ts-mode . "Install clangd, for example: sudo apt install clangd")
      (js-ts-mode . "Install TypeScript support: npm install -g typescript typescript-language-server")
      (typescript-ts-mode . "Install TypeScript support: npm install -g typescript typescript-language-server")
      (tsx-ts-mode . "Install TypeScript support: npm install -g typescript typescript-language-server")
      (go-ts-mode . "Install gopls: go install golang.org/x/tools/gopls@latest")
      (sh-mode . "Install Bash support: npm install -g bash-language-server")
      (bash-ts-mode . "Install Bash support: npm install -g bash-language-server")
      (rust-ts-mode . "Install rust-analyzer: rustup component add rust-analyzer")
      (ruby-ts-mode . "Install Solargraph: gem install solargraph")
      (haskell-ts-mode . "Install HLS with ghcup")
      (json-ts-mode . "Install JSON support: npm install -g vscode-langservers-extracted")
      (cmake-mode . "Install CMake support: pipx install cmake-language-server")
      (cmake-ts-mode . "Install CMake support: pipx install cmake-language-server")))

  (defun my/eglot-project-key ()
    "Return a stable key for reporting a missing language server once."
    (list (or (when-let ((project (project-current nil)))
                (project-root project))
              default-directory)
          major-mode))

  (defun my/eglot-ensure ()
    "Start Eglot when its server exists, otherwise show one useful warning."
    (require 'eglot)
    (condition-case nil
        (progn
          (eglot--guess-contact)
          (eglot-ensure))
      (error
       (let ((key (my/eglot-project-key)))
         (unless (gethash key my/eglot-missing-server-notifications)
           (puthash key t my/eglot-missing-server-notifications)
           (display-warning
            'eglot
            (format "No language server found for %s. %s"
                    major-mode
                    (or (alist-get major-mode my/eglot-install-hints)
                        "Install a server listed in `eglot-server-programs'."))
            :warning))))))
  :hook ((python-ts-mode . my/eglot-ensure)
         (c-ts-mode . my/eglot-ensure)
         (c++-ts-mode . my/eglot-ensure)
         (js-ts-mode . my/eglot-ensure)
         (typescript-ts-mode . my/eglot-ensure)
         (tsx-ts-mode . my/eglot-ensure)
         (go-ts-mode . my/eglot-ensure)
         (sh-mode . my/eglot-ensure)
         (bash-ts-mode . my/eglot-ensure)
         (rust-ts-mode . my/eglot-ensure)
         (ruby-ts-mode . my/eglot-ensure)
         (haskell-ts-mode . my/eglot-ensure)
         (json-ts-mode . my/eglot-ensure)
         (cmake-mode . my/eglot-ensure)
         (cmake-ts-mode . my/eglot-ensure))
  :config
  (setq eglot-events-buffer-size 0
        eglot-autoshutdown t)
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

(provide 'init-lsp)
;;; init-lsp.el ends here
