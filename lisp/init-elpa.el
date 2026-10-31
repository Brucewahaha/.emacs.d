;;; init-elpa.el --- Settings for package.el and use-package -*- lexical-binding: t -*-
;;; Commentary:
;;; Code:

(require 'package)

;;; Install into separate package dirs for each Emacs version, to prevent bytecode incompatibility
(setq package-user-dir
      (expand-file-name (format "elpa-%s.%s" emacs-major-version emacs-minor-version)
                        user-emacs-directory))

;; MSYS GPG treats drive-letter paths passed via --homedir as relative paths.
;; Let GPG choose its native Windows home while retaining signature checks.
(when my/windows-p
  (setq package-gnupghome-dir nil)
  ;; gnu-elpa-keyring-update keeps its timestamp here when GPG uses its
  ;; default home.  The directory must exist before package autoloads run.
  (make-directory (expand-file-name "gnupg" package-user-dir) t))


;;; Standard package repositories

;; 1. 默认使用清华镜像，本机可通过 local.el 覆盖。
(setq package-archives
      (or my/package-archives-override
          '(("gnu"    . "https://mirrors.tuna.tsinghua.edu.cn/elpa/gnu/")
            ("nongnu" . "https://mirrors.tuna.tsinghua.edu.cn/elpa/nongnu/")
            ;; MELPA snapshots change frequently.  Using its canonical archive
            ;; avoids mirror indexes referring to files not yet synchronized.
            ("melpa"  . "https://melpa.org/packages/"))))
(setq package-archive-priorities '(("melpa" . 10)
                                   ("gnu" . 0)
                                   ("nongnu" . 0)))

;; Allow built-in packages to be upgraded
(setq package-install-upgrade-built-in t)

(defun my/package-install-refresh-on-missing-file (original package &rest args)
  "Refresh stale archive metadata and retry installing PACKAGE once.
This handles mirrors whose archive index temporarily points at a package file
which has not arrived yet, or has already been replaced."
  (condition-case err
      (apply original package args)
    (file-missing
     (message "Package file for %s is missing; refreshing archives and retrying" package)
     (package-refresh-contents)
     (apply original package args))
    (error
     (if (string-match-p "\\(?:404\\|Not found\\)"
                         (error-message-string err))
         (progn
           (message "Package file for %s vanished; refreshing archives and retrying" package)
           (package-refresh-contents)
           (apply original package args))
       (signal (car err) (cdr err))))))

(advice-add 'package-install :around
            #'my/package-install-refresh-on-missing-file)

(defun my/package-ensure (package &optional min-version)
  "Install PACKAGE unless MIN-VERSION or any version is already installed.
Use this only where `use-package' `:ensure' cannot: it accepts a built-in
package as installed, so it never upgrades one to MIN-VERSION."
  (unless (package-installed-p package (and min-version
                                            (version-to-list min-version)))
    (unless (assq package package-archive-contents)
      (package-refresh-contents))
    (package-install package)))


;;; Fire up package.el

(setq package-native-compile t)
(package-initialize)

;; `:ensure' skips packages that are already installed, so it never marks them
;; as selected.  Without this, `package-autoremove' would offer to delete most
;; of the configuration's packages.
(defvar my/ensured-packages nil
  "Packages declared by this configuration during startup.")

(defun my/note-ensured-package (name args &rest _)
  "Record packages that use-package `:ensure' for NAME with ARGS."
  (dolist (ensure args)
    (let ((package (if (eq ensure t) (use-package-as-symbol name) ensure)))
      (when (consp package)
        (setq package (car package)))
      (when (and package (symbolp package) (package-installed-p package))
        (add-to-list 'my/ensured-packages package)))))

(defun my/note-vc-package (arg &rest _)
  "Record the package that use-package `:vc' describes with ARG."
  (when (package-installed-p (car arg))
    (add-to-list 'my/ensured-packages (car arg))))

(with-eval-after-load 'use-package-ensure
  (advice-add 'use-package-ensure-elpa :after #'my/note-ensured-package))
(with-eval-after-load 'use-package-core
  (advice-add 'use-package-vc-install :after #'my/note-vc-package))

(defun my/save-selected-packages ()
  "Save the selected package list, writing `custom-file' only on change."
  (let ((selected (seq-uniq (append my/ensured-packages
                                    package-selected-packages))))
    (unless (seq-set-equal-p selected package-selected-packages)
      (package--save-selected-packages selected))))

(add-hook 'after-init-hook #'my/save-selected-packages)

;; The keyring has to be installed before signatures made with newer GNU ELPA
;; keys can be checked, so this one package skips the check.
(unless (package-installed-p 'gnu-elpa-keyring-update)
  (let ((package-check-signature nil))
    (my/package-ensure 'gnu-elpa-keyring-update)))


(provide 'init-elpa)
;;; init-elpa.el ends here
