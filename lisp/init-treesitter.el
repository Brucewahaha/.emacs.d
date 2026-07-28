;;; init-treesitter.el --- Native Tree-sitter configuration -*- lexical-binding: t -*-
;;; Code:

(require 'treesit)

;; Local grammars are machine-specific; unavailable or incompatible binaries
;; are ignored by treesit-auto's readiness checks.
(let ((parser-directory
       (expand-file-name "tree-sitter" user-emacs-directory)))
  (when (file-directory-p parser-directory)
    (add-to-list 'treesit-extra-load-path parser-directory)))

(setq treesit-font-lock-level 4)

(use-package treesit-auto
  :ensure t
  :custom
  ;; Installation remains an explicit action via `treesit-auto-install-all'.
  (treesit-auto-install nil)
  :config
  (global-treesit-auto-mode 1)
  ;; Add file associations only for grammars that are ready on this machine.
  (treesit-auto-add-to-auto-mode-alist)
  (when (treesit-ready-p 'cmake t)
    (add-to-list 'auto-mode-alist '("CMakeLists\\.txt\\'" . cmake-ts-mode))))

(provide 'init-treesitter)
;;; init-treesitter.el ends here
