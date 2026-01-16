;;; init-evil.el --- Vim emulation and compatibility -*- lexical-binding: t -*-
;;; Commentary:
;;; Code:

;; 1.撤销系统配置
(use-package undo-fu
  :ensure t
  :config
  ;; 如果你觉得撤销/重做的回显太烦，可以把 minibuffer 消息关掉，不用管
  )

(use-package vundo
  :ensure t
  :bind ("C-x u" . vundo) ; 绑定到 C-x u，或者你想用的任何键
  :config
  (setq vundo-glyph-alist vundo-unicode-symbols))

;; 2. Evil 核心配置
(use-package evil
  :ensure t
  :init
  (setq evil-want-integration t)
  (setq evil-want-keybinding nil)
  (setq evil-undo-system 'undo-fu)
  ;; --- 【关键：在 Insert 模式保留 Emacs 快捷键】 ---
  ;; 告诉 Evil 不要拦截 Insert 模式下的按键
  (setq evil-disable-insert-state-bindings t)
  :config
  (evil-mode 1)
  ;; 确保在 Insert 模式下 ESC 依然能回到 Normal 模式
  (define-key evil-insert-state-map [escape] 'evil-normal-state)
  (define-key evil-normal-state-map (kbd "[ SPC") (lambda () (interactive) (evil-insert-newline-above) (forward-line)))
  (define-key evil-normal-state-map (kbd "] SPC") (lambda () (interactive) (evil-insert-newline-below) (forward-line -1)))

  (define-key evil-normal-state-map (kbd "[ b") 'previous-buffer)
  (define-key evil-normal-state-map (kbd "] b") 'next-buffer)
  (define-key evil-motion-state-map (kbd "[ b") 'previous-buffer)
  (define-key evil-motion-state-map (kbd "] b") 'next-buffer)
  ;; s -> 输入 1 或 2 个字符后根据提示跳转
  (define-key evil-normal-state-map (kbd "s") 'avy-goto-char-timer)
  ;; 在可视化模式 (Visual Mode) 也能跳，方便快速选区
  (define-key evil-visual-state-map (kbd "s") 'avy-goto-char-timer)
  ;; Eglot 相关快捷键绑定 (Normal 模式下生效)
  (with-eval-after-load 'eglot
    (evil-define-key 'normal eglot-mode-map (kbd "g d") 'eglot-find-definition)
    (evil-define-key 'normal eglot-mode-map (kbd "g r") 'xref-find-references)
    (evil-define-key 'normal eglot-mode-map (kbd "K")   'eldoc)))
  
;; 3. Evil Collection
(use-package evil-collection
  :ensure t
  :after evil
  :config
  (evil-collection-init))

(use-package iedit
  :ensure t
  :init
  (setq iedit-toggle-key-default nil)
  :config
  (define-key iedit-mode-keymap (kbd "M-h") 'iedit-restrict-function)
  (define-key iedit-mode-keymap (kbd "M-i") 'iedit-restrict-current-line))

(use-package evil-multiedit
  :ensure t
  :commands (evil-multiedit-default-keybinds)
  :init
  (evil-multiedit-default-keybinds))

(use-package evil-surround
  :ensure t
  :init
  (global-evil-surround-mode 1))

(use-package emacs
  :bind* ("C-/" . comment-line))


;;; esc quits
(defun minibuffer-keyboard-quit ()
  "Abort recursive edit.
In Delete Selection mode, if the mark is active, just deactivate it;
then it takes a second \\[keyboard-quit] to abort the minibuffer."
  (interactive)
  (if (and delete-selection-mode transient-mark-mode mark-active)
      (setq deactivate-mark  t)
    (when (get-buffer "*Completions*") (delete-windows-on "*Completions*"))
    (abort-recursive-edit)))
(define-key evil-normal-state-map [escape] 'keyboard-quit)
(define-key evil-visual-state-map [escape] 'keyboard-quit)
(define-key minibuffer-local-map [escape] 'minibuffer-keyboard-quit)
(define-key minibuffer-local-ns-map [escape] 'minibuffer-keyboard-quit)
(define-key minibuffer-local-completion-map [escape] 'minibuffer-keyboard-quit)
(define-key minibuffer-local-must-match-map [escape] 'minibuffer-keyboard-quit)
(define-key minibuffer-local-isearch-map [escape] 'minibuffer-keyboard-quit)


(provide 'init-evil)
;;; init-evil.el ends here
