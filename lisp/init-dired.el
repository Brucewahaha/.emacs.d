;;; init-dired.el --- Dired file manager settings -*- lexical-binding: t -*-
;;; Code:

;; 基础行为
(use-package dired
  :ensure nil
  :bind ("C-x C-j" . dired-jump)
  :config
  (require 'dired-x)
  (setq dired-recursive-copies 'always
        dired-recursive-deletes 'top
        dired-omit-files "^\\..+"
        dired-auto-revert-buffer t
        dired-dwim-target t
        dired-kill-when-opening-new-dired-buffer t
        wdired-allow-to-change-permissions t)
  (add-hook 'dired-mode-hook #'auto-revert-mode))

;; 目录树状视图
(use-package dired-subtree
  :ensure t
  :after dired
  :bind (:map dired-mode-map
              ("<tab>" . dired-subtree-toggle)
              ("TAB" . dired-subtree-toggle)))

(provide 'init-dired)
;;; init-dired.el ends here
