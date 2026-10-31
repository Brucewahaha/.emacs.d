;;; init.el --- Load the full configuration -*- lexical-binding: t -*-
;;; Code:

;; 基础性能与目录设置
(add-to-list 'load-path (expand-file-name "lisp" user-emacs-directory))

;; 启动分析：在 early-init.el 设置 (setq use-package-compute-statistics t)，
;; 重启后执行 M-x use-package-report；总耗时见 M-x emacs-init-time。

;; 性能优化 (Process)；GC 阈值在 early-init.el 中放到最大，启动后由 GCMH 接管。
(setq read-process-output-max (* 4 1024 1024))
(setq process-adaptive-read-buffering nil)

;; 核心引导 (包管理与基础工具)
(setq custom-file (locate-user-emacs-file "custom.el"))
(when (file-exists-p custom-file)
  (load custom-file nil 'nomessage))
(require 'init-utils)     ; 包含基础函数和文件操作
(defconst my/local-config-file (locate-user-emacs-file "local.el"))
(when (file-exists-p my/local-config-file)
  (load my/local-config-file nil 'nomessage))
(require 'init-site-lisp) ; 手动安装的包
(require 'init-elpa)      ; 镜像源与 use-package 设置
(require 'init-remote)    ; Load upgraded TRAMP before recentf can load built-in TRAMP
(require 'init-environment)
(require 'init-performance)

;; GCMH 自动管理垃圾回收；未安装时启动后恢复固定阈值，避免一直不回收。
(if (require 'gcmh nil t)
    (add-hook 'after-init-hook (lambda () (gcmh-mode 1)))
  (add-hook 'emacs-startup-hook
            (lambda () (setq gc-cons-threshold (* 128 1024 1024)))))

;; --- 界面与增强 ---
(require 'init-ui)        ; 合并了原 gui-frames 和 themes
(require 'init-enhance)   ; 核心补全架构 (Vertico/Consult)
(require 'init-window)    ; 窗口管理
(require 'init-tools)     ; 各种小工具 (Helpful/Avy/Ace-window)
(require 'init-dired)

;; --- 开发环境 ---
(require 'init-project)    ; Project/Magit
(require 'init-editing)
(require 'init-lsp)
(require 'init-completion)
(require 'init-treemacs)
(require 'init-term)
(require 'init-org)

;; --- 模拟层 (最后加载) ---
(require 'init-evil)

;; 杂项
(autoload 'sudo-edit "sudo-edit" nil t)

(provide 'init)
;;; init.el ends here
