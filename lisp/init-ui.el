;;; init-ui.el --- UI settings, Themes and Fonts -*- lexical-binding: t -*-
;; 1. 基础界面清理
(setq confirm-kill-emacs #'yes-or-no-p
      make-backup-files nil
      use-dialog-box nil)
;; (when (fboundp 'tool-bar-mode) (tool-bar-mode -1))
;; (when (fboundp 'set-scroll-bar-mode) (set-scroll-bar-mode nil))
;; (menu-bar-mode -1)
;; 2. 行号与视觉反馈
(global-display-line-numbers-mode 1)
(setq display-line-numbers-type 'relative)
(column-number-mode t)
(global-hl-line-mode 1)
(fset 'yes-or-no-p 'y-or-n-p)
(setq visible-bell 1)
;; 3. 插件：图标库与状态栏
(use-package nerd-icons
  :ensure t
  :if (display-graphic-p))
(use-package nerd-icons-dired
  :ensure t
  :hook (dired-mode . nerd-icons-dired-mode))
(use-package doom-modeline
  :ensure t
  :init (doom-modeline-mode 1)
  :config
  (setq doom-modeline-icon t
        doom-modeline-major-mode-icon t))
(use-package monokai-theme 
  :ensure t 
  :config (load-theme 'monokai t))
;; 4. 字体设置
(defun my/setup-font ()
  (interactive)
  (let* ((font-size 16)
         ;; 英文/基础字体
         (efl '("0xProto Nerd Font Mono" "Cascadia Mono" "JetBrains Mono" "Monaco" "Consolas"))
         ;; 中文字体
         (cfl '("Microsoft YaHei" "STHeiti" "SimSun"))
         ;; 符号/图标字体
         (sfl '("Symbols Nerd Font Mono" "Apple Color Emoji" "Segoe UI Emoji"))
         
         (ef (cl-find-if (lambda (f) (member f (font-family-list))) efl))
         (cf (cl-find-if (lambda (f) (member f (font-family-list))) cfl))
         (sf (cl-find-if (lambda (f) (member f (font-family-list))) sfl)))
    ;; A. 设置默认字体
    (when ef
      (set-face-attribute 'default nil :family ef :height 140))
    ;; B. 设置中文字体 (han 字符集)
    (when cf
      (set-fontset-font t 'han (font-spec :family cf))
      (set-fontset-font t 'cjk-misc (font-spec :family cf))
      (setq face-font-rescale-alist `((,cf . 1))))
    ;; C. 设置符号字体 (注意：Elisp 中十六进制必须用 #x 开头)
    (when sf
      ;; 基础符号
      (set-fontset-font t 'symbol (font-spec :family sf))
      ;; Nerd Fonts 常用图标范围 (PUA 区域)
      (set-fontset-font t' (#xe000 . #xf8ff) (font-spec :family sf))
      ;; 更多符号
      (set-fontset-font t '(#x2100 . #x2bcf) (font-spec :family sf))
      ;; Emoji 范围
      (set-fontset-font t '(#x1f000 . #x1faf0) (font-spec :family sf)))
   ));; 确保在 GUI 环境下正确加载
(if (daemonp)
    (add-hook 'after-make-frame-functions (lambda (frame) (with-selected-frame frame (my/setup-font))))
  (add-hook 'window-setup-hook #'my/setup-font))
(provide 'init-ui)
