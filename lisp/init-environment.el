;;; init-environment.el --- Locale, shell environment and direnv -*- lexical-binding: t -*-
;;; Code:

(require 'subr-x)

;; 编码与 locale
(defun sanityinc/locale-var-encoding (value)
  "Return the encoding portion of locale string VALUE, or nil if missing."
  (when value
    (save-match-data
      (let ((case-fold-search t))
        (when (string-match "\\.\\([^.]*\\)\\'" value)
          (intern (downcase (match-string 1 value))))))))

(dolist (varname '("LC_ALL" "LANG" "LC_CTYPE"))
  (let ((encoding (sanityinc/locale-var-encoding (getenv varname))))
    (unless (memq encoding '(nil utf8 utf-8))
      (message "Warning: non-UTF8 encoding in environment variable %s may cause interop problems with this Emacs configuration." varname))))

(when (fboundp 'set-charset-priority)
  (set-charset-priority 'unicode))
(prefer-coding-system 'utf-8)
(setq locale-coding-system 'utf-8)
(unless (eq system-type 'windows-nt)
  (set-selection-coding-system 'utf-8))
(when (eq system-type 'windows-nt)
  (setq selection-coding-system 'utf-16le-dos)
  (set-next-selection-coding-system 'utf-16le-dos))

;; Shell 环境变量
;; Keep the interactive login shell: this machine adds tool paths in .zshrc,
;; which a non-interactive `-l' shell would silently omit.
(when (require 'exec-path-from-shell nil t)
  (dolist (var '("SSH_AUTH_SOCK" "SSH_AGENT_PID" "GPG_AGENT_INFO" "LANG"
                 "LC_CTYPE" "NIX_SSL_CERT_FILE" "NIX_PATH"))
    (add-to-list 'exec-path-from-shell-variables var))
  (when (or (memq window-system '(mac ns x pgtk))
            (unless (memq system-type '(ms-dos windows-nt))
              (daemonp)))
    (exec-path-from-shell-initialize)))

(defun my/prepend-exec-paths (directories)
  "Prepend existing DIRECTORIES to both `exec-path' and PATH."
  (let* ((separator path-separator)
         (directories
          (delete-dups
           (seq-filter #'file-directory-p
                       (mapcar #'expand-file-name directories))))
         (environment-path
          (split-string (or (getenv "PATH") "") separator t)))
    (setq exec-path (delete-dups (append directories exec-path)))
    (setenv "PATH"
            (string-join (delete-dups (append directories environment-path))
                         separator))))

;; Local additions must be merged after importing the login shell environment.
(my/prepend-exec-paths my/extra-exec-paths)

;; direnv
(when (require 'envrc nil t)
  (define-key envrc-mode-map (kbd "C-c e") #'envrc-command-map)
  (add-hook 'after-init-hook #'envrc-global-mode))

(defun my/check-local-environment ()
  "Show local configuration and tool paths without changing the environment."
  (interactive)
  (let* ((frame (selected-frame))
         (graphic (display-graphic-p frame))
         (tools (mapcar (lambda (tool) (cons tool (executable-find tool)))
                        '("git" "rg" "clangd" "basedpyright-langserver"
                          "gopls" "rust-analyzer")))
         (variables '(my/buffer-font-height my/ui-font-height
                      my/initial-frame-settings org-directory
                      my/extra-exec-paths my/preferred-shell)))
    (with-help-window "*Local Environment*"
      (princ (format "Emacs %s | %s | %s\n\n"
                     emacs-version system-type (if graphic "GUI" "Terminal")))
      (princ (format "Local configuration: %s (%s)\n\n"
                     my/local-config-file
                     (if (file-exists-p my/local-config-file) "exists" "absent")))
      (princ "Settings (font heights are in 1/10 point):\n")
      (dolist (variable variables)
        (princ (format "  %s: %S\n" variable
                       (if (boundp variable) (symbol-value variable) 'not-loaded))))
      (princ (format "\nSelected frame: %s columns x %s rows; fullscreen=%S\n"
                     (frame-width frame) (frame-height frame)
                     (frame-parameter frame 'fullscreen)))
      (if graphic
          (dolist (face '(default mode-line tab-line))
            (princ (format "  %s font: %S\n" face
                           (face-attribute face :font frame t))))
        (princ "  Fonts are controlled by the terminal application.\n"))
      (princ "\nExecutable paths (missing optional servers are not errors):\n")
      (dolist (tool tools)
        (princ (format "  %s: %s\n" (car tool) (or (cdr tool) "NOT FOUND"))))
      (princ "\nPaths reflect this buffer's environment; remote tools are not checked.\n"))))

(provide 'init-environment)
;;; init-environment.el ends here
