;;; init-editing.el --- General editing and indentation settings -*- lexical-binding: t -*-
;;; Code:

(require 'init-treesitter)

;; 基础编辑行为
(electric-pair-mode t)
(defun my/disable-electric-pair-in-minibuffer ()
  "在 minibuffer 中关闭成对括号补全。"
  (electric-pair-local-mode -1))
(add-hook 'minibuffer-setup-hook #'my/disable-electric-pair-in-minibuffer)
(show-paren-mode 1)
(global-hl-line-mode 1)
(add-hook 'prog-mode-hook #'hs-minor-mode)
(electric-indent-mode 1)

;; 缩进与 Tab
(use-package editorconfig
  :ensure t
  :config
  (editorconfig-mode 1))

(setq-default indent-tabs-mode nil
              tab-width 4
              standard-indent 4
              c-basic-offset 4
              c++-basic-offset 4)
(setq tab-always-indent 'complete)
(add-hook 'c++-ts-mode-hook
          (lambda () (setq-local c-ts-mode-indent-offset 4)))
(add-hook 'c-ts-mode-hook
          (lambda () (setq-local c-ts-mode-indent-offset 4)))

(use-package dtrt-indent
  :ensure t
  :diminish
  :hook (after-init . dtrt-indent-global-mode)
  :config
  (setq dtrt-indent-verbosity 0))

(use-package indent-bars
  :ensure t
  :hook (prog-mode . indent-bars-mode)
  :custom
   (indent-bars-width-frac 0.1)
   (indent-bars-pad-frac 0.1)
   (indent-bars-pattern " .  ")
   (indent-bars-zigzag nil)
   (indent-bars-color '(default :face-bg t :blend 1))
   (indent-bars-color-by-depth nil)
   (indent-bars-highlight-current-depth
    '(:face font-lock-keyword-face :blend 1 :width 0.18 :pattern ".")))

;; 剪贴板与选区
(setq select-enable-primary nil
      select-enable-clipboard t)
(use-package delsel
  :ensure nil
  :hook (after-init . delete-selection-mode))

;; 文件保存
(setq make-backup-files nil
      auto-save-default nil)

(provide 'init-editing)
;;; init-editing.el ends here
