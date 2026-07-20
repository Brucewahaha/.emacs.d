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
  ;; 确保 C-u 保持为 Vim 的翻页功能
  (setq evil-want-C-u-scroll t)
  ;; --- 【关键：在 Insert 模式保留 Emacs 快捷键】 ---
  ;; 告诉 Evil 不要拦截 Insert 模式下的按键
  (setq evil-disable-insert-state-bindings t)

  :config
  (evil-mode 1)
  ;; 确保在 Insert 模式下 ESC 依然能回到 Normal 模式
  (define-key evil-insert-state-map [escape] 'evil-normal-state)
   (define-key evil-normal-state-map (kbd "[ SPC") (lambda () (interactive) (evil-insert-newline-above) (forward-line)))
   (define-key evil-normal-state-map (kbd "] SPC") (lambda () (interactive) (evil-insert-newline-below) (forward-line -1)))
   ;; 文件树快捷键，仅覆盖 Evil Normal 状态。
   (define-key evil-normal-state-map (kbd "C-e") #'my/treemacs-toggle-current-project)

    ;; tab-line 使用当前 Window 的标签序列，[b 向左，]b 向右。
   (define-key evil-normal-state-map (kbd "[ b") #'my/tab-line-switch-to-prev-tab)
   (define-key evil-normal-state-map (kbd "] b") #'my/tab-line-switch-to-next-tab)
   (define-key evil-motion-state-map (kbd "[ b") #'my/tab-line-switch-to-prev-tab)
   (define-key evil-motion-state-map (kbd "] b") #'my/tab-line-switch-to-next-tab)
   (dotimes (index 9)
     (let ((index (1+ index)))
       (define-key evil-normal-state-map (kbd (format "C-S-%d" index))
                   (lambda () (interactive) (my/tab-line-switch-to-index index)))
       (define-key evil-motion-state-map (kbd (format "C-S-%d" index))
                   (lambda () (interactive) (my/tab-line-switch-to-index index)))))
   (dolist (key '("!" "@" "#" "$" "%" "^" "&" "*" "("))
     (define-key evil-normal-state-map (kbd (concat "C-" key))
                 #'my/tab-line-switch-to-control-shift-index)
     (define-key evil-motion-state-map (kbd (concat "C-" key))
                 #'my/tab-line-switch-to-control-shift-index))
   ;; 新 Window 固定创建在右侧或下方。
   (define-key evil-window-map (kbd "v") #'split-window-right)
   (define-key evil-window-map (kbd "s") #'split-window-below)
   ;; s -> 固定输入两个字符后跳转
   (define-key evil-normal-state-map (kbd "s") 'avy-goto-char-2)
   ;; 在可视化模式 (Visual Mode) 也能跳，方便快速选区
   (define-key evil-visual-state-map (kbd "s") 'avy-goto-char-2)
  
  ;; Eglot 相关快捷键绑定 (Normal 模式下生效)
  (with-eval-after-load 'eglot
    (evil-define-key 'normal eglot-mode-map (kbd "g d") 'eglot-find-definition)
    (evil-define-key 'normal eglot-mode-map (kbd "g r") 'xref-find-references)
    (evil-define-key 'normal eglot-mode-map (kbd "K")   'eldoc)))
  
;; 3. Evil in terminal
(when (not (display-graphic-p))
  ;; 定义修改光标形状的函数
  (defun my-terminal-cursor-shape-block ()
    (send-string-to-terminal "\e[2 q")) ;; 2 代表方块 (Block)
  (defun my-terminal-cursor-shape-bar ()
    (send-string-to-terminal "\e[6 q")) ;; 6 代表竖线 (Bar)
  ;; 在进入 Insert 模式时变为 竖线，退出时（进入 Normal）变为 方块
  (add-hook 'evil-insert-state-entry-hook 'my-terminal-cursor-shape-bar)
  (add-hook 'evil-insert-state-exit-hook 'my-terminal-cursor-shape-block)
  
  ;; 确保 Emacs 启动时默认就是方块（Normal 模式）
  (my-terminal-cursor-shape-block))

;; 强制设置 region 在终端下的颜色
(defun my/fix-terminal-faces ()
  (when (not (display-graphic-p))
    (set-face-attribute 'region nil
                        :background "#555555" ;; 设置一个明显的颜色，例如深灰色
                        :foreground "white")
    ;; 确保 cursor 颜色可见
    (set-cursor-color "#FF0000")))

(add-hook 'tty-setup-hook 'my/fix-terminal-faces)
(add-hook 'after-init-hook 'my/fix-terminal-faces)

;; 强制修复 hl-line 在终端下的颜色
(defun my/fix-hl-line-face ()
  (when (not (display-graphic-p))
    (set-face-attribute 'hl-line nil 
                        :background "#333333" ;; 设置一个比背景深一点或浅一点的颜色
                        :underline nil)))
(add-hook 'tty-setup-hook 'my/fix-hl-line-face)
(add-hook 'after-init-hook 'my/fix-hl-line-face)

;; 4. Evil Collection
(use-package evil-collection
  :ensure t
  :after evil
  :config
  (evil-collection-init)
  ;; 覆盖 unimpaired 的全局 Buffer 历史切换，统一按当前 Window 标签顺序切换。
  (evil-collection-define-key 'normal 'evil-collection-unimpaired-mode-map
    "[b" #'my/tab-line-switch-to-prev-tab
    "]b" #'my/tab-line-switch-to-next-tab)
  ;; 终端和多数图形环境将 Shift+数字解释为标点字符。
  (dolist (key '("!" "@" "#" "$" "%" "^" "&" "*" "("))
    (evil-collection-define-key 'normal 'evil-collection-unimpaired-mode-map
      key nil)
    (evil-collection-define-key 'normal 'evil-collection-unimpaired-mode-map
      (concat "C-" key) #'my/tab-line-switch-to-control-shift-index)))

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
