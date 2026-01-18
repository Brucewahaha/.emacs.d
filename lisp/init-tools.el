;;; init-tools.el --- Specialized Utilities -*- lexical-binding: t -*-
;;; Code:

;; 跳转与窗口
(use-package avy
  :ensure t
  :config
  (setq avy-timeout-seconds 0.3)
  (setq avy-all-windows t))

(use-package ace-window
  :ensure t
  :bind ("C-x o" . ace-window))


;; 增强帮助
(use-package which-key :ensure t :init (which-key-mode))
(use-package helpful
  :ensure t
  :bind (("C-h f" . helpful-function)
         ("C-h v" . helpful-variable)
         ("C-h k" . helpful-key)))

;; 滚动优化
(use-package good-scroll :ensure t :if window-system :init (good-scroll-mode))

(provide 'init-tools)
