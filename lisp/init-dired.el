;;; init-dired.el --- Dired file manager settings -*- lexical-binding: t -*-
;;; Code:

(defun my/dired-mouse-bindings-after-evil-collection (mode &rest _)
  "Keep mouse visits in the clicked window after MODE's Evil setup."
  (when (eq mode 'dired)
    (evil-define-key 'normal dired-mode-map
      [mouse-2] #'dired-mouse-find-file
      [follow-link] 'mouse-face)))

(add-hook 'evil-collection-setup-hook
          #'my/dired-mouse-bindings-after-evil-collection)

;; 基础行为
(use-package dired
  :ensure nil
  :defer t
  :config
  ;; Follow filenames in the clicked window rather than opening another split.
  (define-key dired-mode-map [mouse-2] #'dired-mouse-find-file)
  (define-key dired-mode-map [follow-link] 'mouse-face)
  (setq dired-recursive-copies 'always
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
