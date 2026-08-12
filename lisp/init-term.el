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
  "Toggle an Eat terminal panel at the bottom of the selected frame."
  (interactive)
  (let* ((eat-buffer (get-buffer "*eat*"))
         (eat-window (and eat-buffer
                          (get-buffer-window eat-buffer (selected-frame)))))
    (if eat-window
        (quit-window nil eat-window)
      (unless eat-buffer
        ;; `eat' normally replaces the selected window.  Preserve the layout,
        ;; then display the resulting terminal in the panel below.
        (setq eat-buffer
              (save-window-excursion
                (eat my/eat-shell-program))))
      (select-window
       (display-buffer
        eat-buffer
        '((display-buffer-reuse-window display-buffer-at-bottom)
          (window-height . 0.2)))))))

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
  
  ;; 2. 如果是 Evil 用户，确保进入 Eat 时是 insert 状态
  (with-eval-after-load 'evil
    (add-hook 'eat-mode-hook #'evil-insert-state))

  ;; Eshell is already loaded by the time Eat is initialized.
  (eat-eshell-mode 1)
  (eat-eshell-visual-command-mode 1))

;; 3. 保留 Eshell 增强 (作为辅助工具)
;; 即使主终端用 Eat，Eshell 在处理 Emacs 文件时依然好用
(use-package eshell
  :ensure nil
  :commands eshell
  :init
  (setq eshell-history-size 10000
        eshell-scroll-to-bottom-on-input t))

;; 4. 语法高亮与提示 (针对 Eshell)
(use-package eshell-syntax-highlighting
  :ensure t
  :after eshell
  :config (eshell-syntax-highlighting-global-mode +1))

(provide 'init-term)
