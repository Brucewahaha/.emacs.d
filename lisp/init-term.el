;;; init-term.el --- Eat Terminal toggle (Universal Windows/WSL) -*- lexical-binding: t -*-

;; 1. Eat 基础配置 (替代 Eshell 作为核心)
(defun my/eat-toggle ()
  "实现类似 VS Code 的终端开关效果：
   1. 如果当前窗口是 Eat，则隐藏它。
   2. 如果 Eat 缓存存在但不可见，则显示它。
   3. 如果没有 Eat 缓存，则创建一个。"
  (interactive)
  (let ((eat-buffer (get-buffer "*eat*")))
    (if (and eat-buffer (get-buffer-window eat-buffer))
        (delete-window (get-buffer-window eat-buffer))
      (eat))))

(use-package eat
  :ensure t
  :bind (("C-`" . my/eat-toggle)) ; 类似 VS Code 的项目终端切换
  :config
  ;; 历史记录与显示调整
  (setq eat-kill-buffer-on-exit t
        eat-buffer-maximum-lines 10000)
  
  ;; 核心：智能识别 Shell 程序
  (setq eat-shell-file-name
        (if (or (eq system-type 'gnu/linux)
                (string-match-p "wsl" (or (getenv "WSL_DISTRO_NAME") "")))
            (if (executable-find "zsh") "/bin/zsh" "bin/bash")  ; WSL 使用 Zsh
          (if (executable-find "pwsh.exe") 
              "pwsh.exe" 
            "powershell.exe"))) ; Windows 优先使用 PowerShell Core

  ;; 2. 实现 VS Code 样式的底部弹出逻辑
  ;; 这里的配置确保 eat 窗口始终在底部弹出并占用 20% 空间
  (add-to-list 'display-buffer-alist
               '("\\*eat\\*"
                 (display-buffer-reuse-window display-buffer-at-bottom)
                 (window-height . 0.2)))

  ;; 3. 如果是 Evil 用户，确保进入 Eat 时是 insert 状态
  (with-eval-after-load 'evil
    (add-hook 'eat-mode-hook #'evil-insert-state)))

;; 4. 保留 Eshell 增强 (作为辅助工具)
;; 即使主终端用 Eat，Eshell 在处理 Emacs 文件时依然好用
(use-package eshell
  :ensure nil
  :config
  (setq eshell-history-size 10000
        eshell-scroll-to-bottom-on-input t)
  
  ;; 杀手锏：让 Eshell 里的交互程序也借用 Eat 渲染
  ;; 这样你在 Eshell 里运行 conda, python, vim 也不会乱码
  (with-eval-after-load 'eat
    (add-hook 'eshell-load-hook #'eat-eshell-mode)
    (add-hook 'eshell-load-hook #'eat-eshell-visual-command-mode)))

;; 5. 语法高亮与提示 (针对 Eshell)
(use-package eshell-syntax-highlighting
  :ensure t
  :after eshell
  :config (eshell-syntax-highlighting-global-mode +1))

(use-package esh-autosuggest
  :ensure t
  :hook (eshell-mode . esh-autosuggest-mode))

(provide 'init-term)
