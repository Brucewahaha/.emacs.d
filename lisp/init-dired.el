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

(defvar my/dired-preserving-tab-position nil
  "Non-nil while an outer Dired navigation tracks its tab position.")

(defun my/dired-preserve-tab-position (original &rest args)
  "Keep same-window directory navigation in its previous tab slot."
  (if my/dired-preserving-tab-position
      (apply original args)
    (let* ((my/dired-preserving-tab-position t)
           (event (car args))
           (window (if (mouse-event-p event)
                       (posn-window (event-end event))
                     (selected-window)))
           (old (and (window-live-p window) (window-buffer window)))
           (tabs (and old
                      (with-selected-window window
                        (tab-line-tabs-fixed-window-buffers))))
           (result (apply original args)))
      (when (and (window-live-p window)
                 (with-current-buffer (window-buffer window)
                   (derived-mode-p 'dired-mode))
                 (or (not (buffer-live-p old))
                     (with-current-buffer old (derived-mode-p 'dired-mode))))
        (let ((new (window-buffer window)))
          (when (and (not (eq old new)) (not (memq new tabs)))
            (set-window-parameter
             window 'tab-line-buffers
             (seq-filter #'buffer-live-p
                         (mapcar (lambda (buffer) (if (eq buffer old) new buffer))
                                 tabs)))
            (set-window-parameter window 'tab-line-cache nil)
            (force-mode-line-update t))))
      result)))

;; 基础行为
(use-package dired
  :ensure nil
  :defer t
  :config
  (dolist (command '(dired-find-file dired-up-directory
                     dired-find-alternate-file dired-mouse-find-file))
    (advice-add command :around #'my/dired-preserve-tab-position))
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
