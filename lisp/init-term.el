;;; init-term.el --- VS Code style Eshell toggle -*- lexical-binding: t -*-
;; 1. Eshell 基础增强
(use-package eshell
  :ensure nil ; 内置功能不需要 ensure
  :config
  ;; 历史记录调整
  (setq eshell-history-size 10000
        eshell-buffer-maximum-lines 10000
        ;; 忽略重复的命令
        eshell-hist-ignoredups t
        ;; 命令完成后跳转到末尾
        eshell-scroll-to-bottom-on-input t)

  ;; 视觉命令优化：让某些交互式命令在真正的终端里运行（防止乱码）
  (with-eval-after-load 'em-term
    (add-to-list 'eshell-visual-commands "htop")
    (add-to-list 'eshell-visual-commands "top")
    (add-to-list 'eshell-visual-commands "vim")
    (add-to-list 'eshell-visual-commands "git")))
;; 2. Eshell 语法高亮 (类似 Zsh)
(use-package eshell-syntax-highlighting
  :ensure t
  :after eshell
  :config (eshell-syntax-highlighting-global-mode +1))
;; 3. Eshell 漂亮的 Prompt (Git 支持)
(use-package eshell-git-prompt
  :ensure t
  :after eshell
  :config
  ;; 选择一个你喜欢的主题，'powerline' 或 'ext-rjka' 比较接近现代终端
  (eshell-git-prompt-use-theme 'powerline))
;; 4. 实现 VS Code 样式的浮动/底部切换逻辑
(use-package eshell-toggle
  :ensure t
  :bind (("C-`" . eshell-toggle)
         :map eshell-mode-map
         ("C-`" . eshell-toggle))
  :config
  ;; 设定弹出位置在底部
  (setq eshell-toggle-use-projection-daemon nil
        eshell-toggle-run-command nil)

  ;; 沿用你之前的底部占 20% 高度的布局逻辑
  (add-to-list 'display-buffer-alist
               '((lambda (bufname _) (with-current-buffer bufname (derived-mode-p 'eshell-mode)))
                 (display-buffer-reuse-window display-buffer-at-bottom)
                 (window-height . 0.3))) ; 占 30% 视野更好
  ;; 如果是 Evil 用户，确保进入 Eshell 时是 insert 状态
  (with-eval-after-load 'evil
    (evil-set-initial-state 'eshell-mode 'insert)))
;; 5. [额外增强] Eshell 补全建议 (类似 zsh-autosuggestions)
(use-package esh-autosuggest
  :ensure t
  :hook (eshell-mode . esh-autosuggest-mode))
(provide 'init-term)
