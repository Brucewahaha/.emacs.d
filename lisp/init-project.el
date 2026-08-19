;;; init-project.el --- Project management and Git -*- lexical-binding: t -*-
;;; Commentary:
;;; Code:

(require 'ansi-color)
(require 'project)

(defun my/project-compilation-buffer ()
  "Return the compilation buffer for the current project, if any."
  (let ((root (if-let ((project (project-current nil)))
                  (project-root project)
                default-directory)))
    (seq-find
     (lambda (buffer)
       (with-current-buffer buffer
         (and (eq major-mode 'compilation-mode)
              (file-equal-p default-directory root))))
     (buffer-list))))

(defun my/project-compile ()
  "Save modified buffers and compile from the current project root."
  (interactive)
  (save-some-buffers t)
  (call-interactively #'project-compile))

(defun my/project-recompile ()
  "Save modified buffers and repeat the current project's last compilation."
  (interactive)
  (save-some-buffers t)
  (if-let ((buffer (my/project-compilation-buffer)))
      (with-current-buffer buffer
        (recompile))
    (my/project-compile)))

(use-package compile
  :ensure nil
  :bind (("C-c b c" . my/project-compile)
         ("C-c b r" . my/project-recompile)
         ("C-c b n" . next-error)
         ("C-c b p" . previous-error)
         ("M-!" . compile))
  :hook (compilation-filter . ansi-color-compilation-filter)
  :custom
  (compilation-always-kill t)
  (compilation-scroll-output t))

;; Keep the familiar prefix while using Emacs' built-in project commands.
(global-set-key (kbd "C-c p") project-prefix-map)

;; Magit: 最好的 Git 客户端
(use-package magit
  :ensure t
  :bind ("C-x g" . magit-status))

(provide 'init-project)
;;; init-project.el ends here
