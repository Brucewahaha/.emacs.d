;;; init-treemacs.el --- Project file tree settings -*- lexical-binding: t -*-
;;; Code:

(use-package treemacs
  :ensure t
  :defer t
  :config
  (treemacs-tag-follow-mode)
  (with-eval-after-load 'treemacs
    (define-key treemacs-mode-map [mouse-1] #'treemacs-single-click-expand-action)
    (define-key treemacs-mode-map [mouse-2] #'treemacs-rightclick-menu))
  :bind (:map global-map
              ("M-0" . treemacs-select-window)
              ("C-x t 1" . treemacs-delete-other-windows)
              ("C-x t t" . treemacs)
              ("C-x t B" . treemacs-bookmark)
              ("C-x t M-t" . treemacs-find-tag)
              :map treemacs-mode-map
              ("/" . treemacs-advanced-helpful-hydra)))

(defun my/treemacs-display-current-project ()
  "在 Treemacs 中只显示当前项目根目录。"
  (interactive)
  (treemacs-add-and-display-current-project-exclusively)
  (when (eq (treemacs-current-visibility) 'exists)
    (treemacs-select-window)))

(defun my/treemacs-visible-window ()
  "返回当前 Frame 中可见的 Treemacs Window。"
  (seq-find (lambda (window)
              (with-current-buffer (window-buffer window)
                (derived-mode-p 'treemacs-mode)))
            (window-list nil 'no-minibuf)))

(defun my/treemacs-toggle-current-project ()
  "打开当前项目的 Treemacs，或关闭可见文件树。"
  (interactive)
  (require 'treemacs)
  (if-let ((window (my/treemacs-visible-window)))
      (if (with-selected-window window (one-window-p t))
          (with-selected-window window (treemacs-quit))
        (delete-window window))
    (my/treemacs-display-current-project)))

(defun my/treemacs-open-or-enter ()
  "进入当前目录为 Treemacs 根，或直接打开当前文件。"
  (interactive)
  (let ((button (treemacs-current-button)))
    (pcase (and button (treemacs-button-get button :state))
      ((or 'dir-node-open 'dir-node-closed)
       (treemacs-root-down))
      ((or 'file-node-open 'file-node-closed)
       (treemacs-visit-node-no-split))
      (_
       (treemacs-TAB-action)))))

(with-eval-after-load 'projectile
  (add-hook 'projectile-after-switch-project-hook
            #'my/treemacs-display-current-project))

(use-package treemacs-evil
  :ensure t
  :after (treemacs evil)
  :config
  (evil-define-key 'treemacs treemacs-mode-map
    "h" #'treemacs-root-up
    "l" #'my/treemacs-open-or-enter
    "H" #'treemacs-toggle-show-dotfiles
    "a" #'treemacs-create-file
    "r" #'treemacs-rename-file
    "c" #'treemacs-copy-file
    "d" #'treemacs-delete-file
    "\\" #'treemacs-quit))

(use-package treemacs-projectile
  :ensure t
  :after (treemacs projectile))

(provide 'init-treemacs)
;;; init-treemacs.el ends here
