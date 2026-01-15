;;; init-project.el --- Project management and Git -*- lexical-binding: t -*-
;;; Commentary:
;;; Code:

;; Projectile: 项目管理
(use-package projectile
  :ensure t
  :init
  (projectile-mode +1)
  :bind (:map projectile-mode-map
              ("C-c p" . projectile-command-map)))

;; Magit: 最好的 Git 客户端
(use-package magit
  :ensure t
  :bind ("C-x g" . magit-status))

(provide 'init-project)
;;; init-project.el ends here
