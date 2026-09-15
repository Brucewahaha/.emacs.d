;;; init-term.el --- Eat Terminal toggle (Universal Windows/WSL) -*- lexical-binding: t -*-

(defvar-local my/terminal-origin-window nil
  "Window selected before this terminal buffer was focused.")

(defun my/terminal-focus-buffer (buffer &optional window)
  "Focus BUFFER in WINDOW and remember the previously selected window."
  (with-current-buffer buffer
    (setq my/terminal-origin-window (selected-window)))
  (select-window
   (or window (display-buffer buffer (my/terminal-display-buffer-alist))))
  (evil-insert-state))

(defun my/terminal-toggle-focus (buffer window)
  "Toggle focus between BUFFER's WINDOW and its originating window."
  (if (eq (selected-window) window)
      (if (window-live-p (buffer-local-value 'my/terminal-origin-window buffer))
          (select-window (buffer-local-value 'my/terminal-origin-window buffer))
        (other-window 1))
    (my/terminal-focus-buffer buffer window)))

(defun my/eshell-toggle ()
  "Show Eshell or toggle focus between it and the working window."
  (interactive)
  (let* ((buffer (get-buffer "*eshell*"))
         (window (and buffer (get-buffer-window buffer))))
    (if window
        (my/terminal-toggle-focus buffer window)
      (unless buffer
        (save-window-excursion (eshell))
        (setq buffer (get-buffer "*eshell*")))
      (my/terminal-focus-buffer buffer))))

;; 1. Eat 基础配置 (替代 Eshell 作为 Unix/WSL 核心)
(defun my/eat-toggle ()
  "Show Eat or toggle focus between it and the working window."
  (interactive)
  (let* ((eat-buffer (get-buffer "*eat*"))
         (eat-window (and eat-buffer
                          (get-buffer-window eat-buffer (selected-frame)))))
    (if eat-window
        (my/terminal-toggle-focus eat-buffer eat-window)
      (unless eat-buffer
        ;; `eat' normally replaces the selected window.  Preserve the layout,
        ;; then display the resulting terminal in the panel below.
        (setq eat-buffer
              (save-window-excursion
                (eat my/eat-shell-program))))
      (my/terminal-focus-buffer eat-buffer))))

(defun my/terminal-display-buffer-alist ()
  "Return display rules for a terminal panel in the selected frame."
  (if (and (display-graphic-p) (eq my/terminal-panel-side 'right))
      '((display-buffer-reuse-window display-buffer-in-side-window)
        (side . right)
        (window-width . 0.35))
    '((display-buffer-reuse-window display-buffer-at-bottom)
      (window-height . 0.33))))

(defun my/terminal-toggle ()
  "Toggle Eat, falling back to Eshell on native Windows."
  (interactive)
  (if my/windows-p
      (my/eshell-toggle)
    (my/eat-toggle)))

(global-set-key (kbd "C-`") #'my/terminal-toggle)

(defvar my/terminal-panel-side 'right
  "Preferred graphical-frame location for the terminal panel.")

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

(defun my/terminal-disable-line-numbers ()
  "Disable line numbers in terminal buffers."
  (display-line-numbers-mode -1))

(defun my/terminal-update-evil-cursor ()
  "Make Evil Insert and Normal cursors distinct in terminal buffers."
  (when (derived-mode-p 'eat-mode 'eshell-mode)
    (setq-local cursor-type (if (evil-insert-state-p) '(bar . 4) 'box))))

(defun my/toggle-terminal-panel-side ()
  "Move the visible terminal panel between the right side and bottom."
  (interactive)
  (unless (display-graphic-p)
    (user-error "Terminal panel placement requires a graphical frame"))
  (setq my/terminal-panel-side
        (if (eq my/terminal-panel-side 'right) 'bottom 'right))
  (let* ((buffer (if my/windows-p
                     (get-buffer "*eshell*")
                   (get-buffer "*eat*")))
         (window (and buffer (get-buffer-window buffer (selected-frame)))))
    (when window
      (delete-window window)
      (select-window
       (display-buffer buffer (my/terminal-display-buffer-alist)))
      (evil-insert-state))
    (message "Terminal panel: %s" my/terminal-panel-side)))

(with-eval-after-load 'evil
  (define-key evil-window-map (kbd "t") #'my/toggle-terminal-panel-side)
  (add-hook 'eat-mode-hook #'my/terminal-disable-line-numbers)
  (add-hook 'eat-mode-hook #'evil-insert-state)
  (add-hook 'eshell-mode-hook #'my/terminal-disable-line-numbers)
  (add-hook 'evil-insert-state-entry-hook #'my/terminal-update-evil-cursor)
  (add-hook 'evil-normal-state-entry-hook #'my/terminal-update-evil-cursor))

(use-package eat
  :ensure t
  :if (not my/windows-p)
  :commands eat
  :config
  ;; 历史记录与显示调整
  (setq eat-kill-buffer-on-exit t
        eat-term-scrollback-size 10000
        ;; Do not let terminal DECSCUSR blink styles override Evil's cursor.
        eat-default-cursor-type '(box nil nil)
        eat-very-visible-cursor-type '(box nil nil)
        eat-vertical-bar-cursor-type '(bar nil nil)
        eat-very-visible-vertical-bar-cursor-type '(bar nil nil)
        eat-horizontal-bar-cursor-type '(hbar nil nil)
        eat-very-visible-horizontal-bar-cursor-type '(hbar nil nil))
  
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
