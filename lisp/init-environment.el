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

(when my/extra-exec-paths
  (let ((separator (if (characterp path-separator)
                       (char-to-string path-separator)
                     path-separator)))
    (dolist (directory (reverse my/extra-exec-paths))
      (when (file-directory-p directory)
        (add-to-list 'exec-path directory)))
    (setenv "PATH" (string-join (append my/extra-exec-paths
                                         (list (getenv "PATH")))
                                separator))))

;; Shell 环境变量
(when (require 'exec-path-from-shell nil t)
  (dolist (var '("SSH_AUTH_SOCK" "SSH_AGENT_PID" "GPG_AGENT_INFO" "LANG"
                 "LC_CTYPE" "NIX_SSL_CERT_FILE" "NIX_PATH"))
    (add-to-list 'exec-path-from-shell-variables var))
  (when (or (memq window-system '(mac ns x pgtk))
            (unless (memq system-type '(ms-dos windows-nt))
              (daemonp)))
    (exec-path-from-shell-initialize)))

;; direnv
(when (require 'envrc nil t)
  (define-key envrc-mode-map (kbd "C-c e") #'envrc-command-map)
  (add-hook 'after-init-hook #'envrc-global-mode))

(provide 'init-environment)
;;; init-environment.el ends here
