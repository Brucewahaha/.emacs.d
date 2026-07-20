;;; init-dired.el --- Dired file manager settings -*- lexical-binding: t -*-
;;; Code:

;; 基础行为
(use-package dired
  :ensure nil
  :config
  (require 'dired-x)
  (setq dired-recursive-copies 'always
        dired-recursive-deletes 'always
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

;; Neo-tree 风格文件操作
(defun my/dired-create-file-or-directory ()
  "在当前 Dired 目录中新建文件或以斜杠结尾的新目录。"
  (interactive)
  (let* ((name (read-string "新建文件或目录: "))
         (path (expand-file-name name default-directory)))
    (when (file-exists-p path)
      (user-error "目标已存在: %s" path))
    (if (string-suffix-p "/" name)
        (make-directory path t)
      (make-empty-file path))
    (revert-buffer)))

(defun my/dired-copy-path ()
  "复制当前文件或目录的绝对路径。"
  (interactive)
  (let ((path (dired-get-filename)))
    (kill-new path)
    (message "已复制: %s" path)))

(defun my/dired-paste-path ()
  "将最近复制的文件或目录复制到当前 Dired 目录。"
  (interactive)
  (let* ((source (current-kill 0))
         (name (file-name-nondirectory (directory-file-name source)))
         (target (expand-file-name name default-directory)))
    (unless (file-exists-p source)
      (user-error "剪贴板中没有可复制的本地路径"))
    (when (file-exists-p target)
      (user-error "目标已存在: %s" target))
    (if (file-directory-p source)
        (copy-directory source target)
      (copy-file source target))
    (revert-buffer)
    (message "已复制到: %s" target)))

(defun my/dired-configure-evil-keys ()
  "在 Evil Collection 初始化后设置 Dired 的 Evil 键位。"
  (when (fboundp 'evil-define-key)
    (evil-define-key 'normal dired-mode-map
      "h" #'dired-up-directory
      "l" #'dired-find-file
      "H" #'dired-omit-mode
      "a" #'my/dired-create-file-or-directory
      "r" #'dired-do-rename
      "c" #'my/dired-copy-path
      "v" #'my/dired-paste-path
      "d" #'dired-do-delete
      "\\" #'quit-window
      "i" #'my/dired-enter-wdired
      (kbd "C-c C-e") #'my/dired-enter-wdired)))

(add-hook 'dired-mode-hook #'my/dired-configure-evil-keys t)

(provide 'init-dired)
;;; init-dired.el ends here
