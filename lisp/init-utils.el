;;; init-utils.el --- Elisp helper functions and commands -*- lexical-binding: t -*-
;;; Commentary:
;;; Code:

(require 'cl-lib)

(defconst my/windows-p (eq system-type 'windows-nt))
(defconst my/macos-p (memq system-type '(darwin ns)))
(defconst my/linux-p (eq system-type 'gnu/linux))

(defvar my/package-archives-override nil
  "Package archives supplied by a machine-local configuration.")
(defvar my/extra-exec-paths nil
  "Directories prepended to `exec-path' by a machine-local configuration.")
(defvar my/notification-function nil
  "Optional function accepting TITLE and BODY for desktop notifications.")

(defun my/notify (title body)
  "Send a desktop notification with TITLE and BODY, or show a message."
  (or (and my/notification-function
           (funcall my/notification-function title body))
      (and my/linux-p
           (fboundp 'notifications-notify)
           (condition-case nil
               (progn
                 (notifications-notify :title title :body body :urgency 'normal)
                 t)
             (error nil)))
      (and my/macos-p
           (executable-find "osascript")
           (progn
             (start-process
              "emacs-notification" nil "osascript" "-e"
              (format "display notification %S with title %S" body title))
             t))
      (message "%s: %s" title body)))

;; Show the package list full-frame and restore the layout when it is quit.
(defun my/display-buffer-full-frame (buffer alist)
  "Display BUFFER full-frame per ALIST, remembering the prior window layout."
  (let ((initial-window-configuration (current-window-configuration)))
    (or (display-buffer-reuse-window buffer alist)
        (let ((full-window (display-buffer-full-frame buffer alist)))
          (prog1 full-window
            (set-window-parameter full-window 'my/previous-config
                                  initial-window-configuration))))))

(defun my/maybe-restore-window-configuration (orig &optional kill window)
  "Call ORIG with KILL and WINDOW, then restore a layout saved for WINDOW."
  (let* ((window (or window (selected-window)))
         (to-restore (window-parameter window 'my/previous-config)))
    (set-window-parameter window 'my/previous-config nil)
    (funcall orig kill window)
    (when to-restore
      (set-window-configuration to-restore))))

(advice-add 'quit-window :around #'my/maybe-restore-window-configuration)
(add-to-list 'display-buffer-alist
             '((major-mode . package-menu-mode) my/display-buffer-full-frame))

;; Renaming is built in: `rename-visited-file'.
(defun delete-this-file ()
  "Delete the current file, and kill the buffer."
  (interactive)
  (unless (buffer-file-name)
    (user-error "No file is currently being edited"))
  (when (yes-or-no-p (format "Really delete '%s'?"
                             (file-name-nondirectory buffer-file-name)))
    (delete-file (buffer-file-name))
    (kill-current-buffer)))

(provide 'init-utils)
;;; init-utils.el ends here
