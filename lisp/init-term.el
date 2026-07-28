;;; init-term.el --- Eat Terminal toggle (Universal Windows/WSL) -*- lexical-binding: t -*-

(defun my/eshell-toggle ()
  "Toggle an Eshell window at the bottom of the selected frame."
  (interactive)
  (let* ((buffer (get-buffer "*eshell*"))
         (window (and buffer (get-buffer-window buffer))))
    (if window
        (quit-window nil window)
      (unless buffer
        (save-window-excursion (eshell))
        (setq buffer (get-buffer "*eshell*")))
      (select-window
       (display-buffer
        buffer
        '((display-buffer-reuse-window display-buffer-at-bottom)
          (window-height . 0.2)))))))

;; 1. Eat 基础配置 (替代 Eshell 作为 Unix/WSL 核心)
(defun my/eat-toggle ()
  "实现类似 VS Code 的终端开关效果：
   1. 如果当前窗口是 Eat，则隐藏它。
   2. 如果 Eat 缓存存在但不可见，则显示它。
   3. 如果没有 Eat 缓存，则创建一个。"
  (interactive)
  (let ((eat-buffer (get-buffer "*eat*")))
    (if (and eat-buffer (get-buffer-window eat-buffer))
        (delete-window (get-buffer-window eat-buffer))
      (eat my/eat-shell-program))))

(defun my/terminal-toggle ()
  "Toggle Eat, falling back to Eshell on native Windows."
  (interactive)
  (if my/windows-p
      (my/eshell-toggle)
    (my/eat-toggle)))

(global-set-key (kbd "C-`") #'my/terminal-toggle)

(defvar my/preferred-shell nil
  "Optional machine-local shell executable used by Eat.")

(defvar my/eat-shell-program
  (unless my/windows-p
    (or (and my/preferred-shell
             (or (executable-find my/preferred-shell)
                 (and (file-executable-p my/preferred-shell)
                      (expand-file-name my/preferred-shell))))
        (executable-find "zsh")
        (executable-find "bash")
        shell-file-name))
  "Shell executable used only by Eat.")

(use-package eat
  :ensure t
  :if (not my/windows-p)
  :commands eat
  :config
  ;; 历史记录与显示调整
  (setq eat-kill-buffer-on-exit t
        eat-term-scrollback-size 10000)
  
  ;; 2. 实现 VS Code 样式的底部弹出逻辑
  ;; 这里的配置确保 eat 窗口始终在底部弹出并占用 20% 空间
  (add-to-list 'display-buffer-alist
               '("\\*eat\\*"
                 (display-buffer-reuse-window display-buffer-at-bottom)
                 (window-height . 0.2)))

  ;; 3. 如果是 Evil 用户，确保进入 Eat 时是 insert 状态
  (with-eval-after-load 'evil
    (add-hook 'eat-mode-hook #'evil-insert-state))

  ;; Eshell is already loaded by the time Eat is initialized.
  (eat-eshell-mode 1)
  (eat-eshell-visual-command-mode 1))

;; 4. 保留 Eshell 增强 (作为辅助工具)
;; 即使主终端用 Eat，Eshell 在处理 Emacs 文件时依然好用
(use-package eshell
  :ensure nil
  :config
  (setq eshell-history-size 10000
        eshell-scroll-to-bottom-on-input t))

;; 5. 语法高亮与提示 (针对 Eshell)
(use-package eshell-syntax-highlighting
  :ensure t
  :after eshell
  :config (eshell-syntax-highlighting-global-mode +1))

(provide 'init-term)
