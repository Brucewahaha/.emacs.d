;;; init-performance.el --- Lightweight handling of large source files -*- lexical-binding: t -*-
;;; Code:

(require 'so-long)

(defcustom my/large-file-size-threshold (* 2 1024 1024)
  "Buffer size in bytes at which automatic heavyweight features are skipped."
  :type 'integer
  :group 'files)

(defun my/buffer-needs-lightweight-p ()
  "Return non-nil for a large buffer or one containing excessively long lines.
Inspect only text already in memory; do not query local or remote file metadata."
  (save-restriction
    (widen)
    (or (>= (1- (position-bytes (point-max))) my/large-file-size-threshold)
        (so-long-statistics-excessive-p))))

;; Keep the language mode and allow editing; only shed expensive minor modes.
(setq so-long-predicate #'my/buffer-needs-lightweight-p
      so-long-action 'so-long-minor-mode
      so-long-variable-overrides
      (assq-delete-all 'buffer-read-only so-long-variable-overrides))
(dolist (mode '(indent-bars-mode corfu-mode yas-minor-mode hs-minor-mode))
  (add-to-list 'so-long-minor-modes mode))
(add-to-list 'so-long-target-modes 'text-mode)
(global-so-long-mode 1)

(provide 'init-performance)
;;; init-performance.el ends here
