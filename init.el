;;; init.el --- Load the full configuration -*- lexical-binding: t -*-
;;; Code:

(setq debug-on-error t)

;; 基础性能与目录设置
(add-to-list 'load-path (expand-file-name "lisp" user-emacs-directory))
(require 'init-benchmarking)
(defconst *is-a-mac* (eq system-type 'darwin))

;; 性能优化 (GC & Process)
(setq gc-cons-threshold (* 128 1024 1024))
(setq read-process-output-max (* 4 1024 1024))
(setq process-adaptive-read-buffering nil)

;; 核心引导 (包管理与基础工具)
(setq custom-file (locate-user-emacs-file "custom.el"))
(require 'init-utils)     ; 包含基础函数和文件操作
(require 'init-site-lisp) ; 手动安装的包
(require 'init-elpa)      ; 镜像源与 use-package 设置
(require 'init-environment)

;; GCMH 自动管理垃圾回收
(when (require 'gcmh nil t)
  (add-hook 'after-init-hook (lambda () (gcmh-mode 1))))

;; --- 界面与增强 ---
(require 'init-ui)        ; 合并了原 gui-frames 和 themes
(require 'init-enhance)   ; 核心补全架构 (Vertico/Consult)
(require 'init-window)    ; 窗口管理
(require 'init-tools)     ; 各种小工具 (Helpful/Avy/Ace-window)
(require 'init-dired)

;; --- 开发环境 ---
(require 'init-project)    ; Magit/Projectile
(require 'init-editing)
(require 'init-lsp)
(require 'init-completion)
(require 'init-treemacs)
(require 'init-term)
(require 'init-org)

;; --- 模拟层 (最后加载) ---
(require 'init-evil)

;; --- sicp ---
(require 'init-sicp)

;; 杂项
(require 'sudo-edit nil t)
(require 'htmlize nil t)
(when (file-exists-p custom-file) (load custom-file))

(provide 'init)
;;; init.el ends here
