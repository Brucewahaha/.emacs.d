;;; early-init.el --- Emacs 27+ pre-initialisation config

;;; Commentary:

;; Emacs 27+ loads this file before (normally) calling
;; `package-initialize'.  We use this file to suppress that automatic
;; behaviour so that startup is consistent across Emacs versions.

;;; Code:

;; 1. 彻底禁用 UI 元素（防止界面闪烁）
(setq default-frame-alist
      '((menu-bar-lines . 0)
        (tool-bar-lines . 0)
        (vertical-scroll-bars . nil)))
;; 2. 禁止启动画面（放在这里可以更早生效）
(setq inhibit-startup-screen t)
;; 3. 性能优化：禁用包自动初始化，由 init.el 掌控
(setq package-enable-at-startup nil)
(setq gc-cons-threshold most-positive-fixnum)

;; TRAMP-RPC requires a newer TRAMP than the one bundled with Emacs 30.1.
;; Prefer an already installed upgrade before any startup component can load
;; the built-in copy.  package.el will install it normally when absent.
(let* ((package-dir
        (expand-file-name
         (format "elpa-%s.%s" emacs-major-version emacs-minor-version)
         user-emacs-directory))
       (tramp-dirs
        (and (file-directory-p package-dir)
             (let (result)
               (dolist (directory
                        (directory-files package-dir t "\\`tramp-[0-9]"))
                 (when (and (file-exists-p
                             (expand-file-name "tramp.el" directory))
                            (file-exists-p
                             (expand-file-name "tramp-loaddefs.el" directory)))
                   (push directory result)))
               result))))
  (when tramp-dirs
    (let ((tramp-dir
           (car (sort tramp-dirs
                      (lambda (left right)
                        (string-version-lessp right left))))))
      (push tramp-dir load-path)
      (load (expand-file-name "tramp-loaddefs.el" tramp-dir)
            nil 'nomessage))))

(provide 'early-init)

;;; early-init.el ends here
