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
        wdired-allow-to-change-permissions t)
  (add-hook 'dired-mode-hook #'auto-revert-mode))

;; 目录树状视图
(use-package dired-subtree
  :ensure t
  :after dired
  :bind (:map dired-mode-map
              ("<tab>" . dired-subtree-toggle)
              ("TAB" . dired-subtree-toggle)))

;; Wdired 重命名
(defun my/dired-enter-wdired ()
  "进入 Wdired 重命名模式并切换到 Evil Insert 状态。"
  (interactive)
  (wdired-change-to-wdired-mode)
  (when (fboundp 'evil-insert-state)
    (evil-insert-state)))

(defun my/dired-configure-evil-keys ()
  "Add a small navigation layer on top of Evil Collection's Dired keys."
  (when (fboundp 'evil-define-key)
    (evil-define-key 'normal dired-mode-map
      "h" #'dired-up-directory
      "l" #'dired-find-file
      "H" #'dired-omit-mode
      "i" #'my/dired-enter-wdired
      (kbd "C-c C-e") #'my/dired-enter-wdired)))

(add-hook 'dired-mode-hook #'my/dired-configure-evil-keys t)

(provide 'init-dired)
;;; init-dired.el ends here
