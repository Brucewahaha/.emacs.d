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

(provide 'early-init)

;;; early-init.el ends here
