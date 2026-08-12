;;; init-treemacs.el --- Project file tree settings -*- lexical-binding: t -*-
;;; Code:

(use-package treemacs
  :ensure t
  :defer t
  :config
  (treemacs-tag-follow-mode)
  (define-key treemacs-mode-map (kbd "C-e")
              #'my/treemacs-toggle-current-project)
  (define-key treemacs-mode-map [mouse-1] #'treemacs-single-click-expand-action)
  (define-key treemacs-mode-map [mouse-2] #'treemacs-rightclick-menu)
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
  "Move between the editor and Treemacs, opening it when necessary."
  (interactive)
  (require 'treemacs)
  (if (derived-mode-p 'treemacs-mode)
      (if-let ((window (get-mru-window nil nil t t)))
          (select-window window)
        (user-error "没有可切换的编辑窗口"))
    (if-let ((window (my/treemacs-visible-window)))
        (select-window window)
      (my/treemacs-display-current-project))))

(defun my/treemacs-close ()
  "Close the visible Treemacs sidebar in the selected frame."
  (interactive)
  (if-let ((window (my/treemacs-visible-window)))
      (with-selected-window window
        (treemacs-quit))
    (user-error "当前 Frame 没有可见的 Treemacs")))

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

(use-package treemacs-evil
  :ensure t
  :after (treemacs evil)
  :config
  (define-key evil-treemacs-state-map (kbd "C-e")
              #'my/treemacs-toggle-current-project)
  (define-key evil-treemacs-state-map (kbd "h") #'treemacs-root-up)
  (define-key evil-treemacs-state-map (kbd "l") #'my/treemacs-open-or-enter)
  (define-key evil-treemacs-state-map (kbd "H") #'treemacs-toggle-show-dotfiles)
  (define-key evil-treemacs-state-map (kbd "a") #'treemacs-create-file)
  (define-key evil-treemacs-state-map (kbd "r") #'treemacs-rename-file)
  (define-key evil-treemacs-state-map (kbd "c") #'treemacs-copy-file)
  (define-key evil-treemacs-state-map (kbd "d") #'treemacs-delete-file)
  (define-key evil-treemacs-state-map (kbd "\\") #'my/treemacs-close))

(provide 'init-treemacs)
;;; init-treemacs.el ends here
