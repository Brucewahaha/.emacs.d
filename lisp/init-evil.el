;;; init-evil.el --- Vim emulation and compatibility -*- lexical-binding: t -*-
;;; Commentary:
;;; Code:

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
  (setq evil-undo-system 'undo-redo)
  ;; 确保 C-u 保持为 Vim 的翻页功能
  (setq evil-want-C-u-scroll t)
  ;; --- 【关键：在 Insert 模式保留 Emacs 快捷键】 ---
  ;; 告诉 Evil 不要拦截 Insert 模式下的按键
  (setq evil-disable-insert-state-bindings t)

  :config
  (evil-mode 1)
   ;; Keep single-buffer Vim quit commands from escalating to frame/Emacs exit.
   (evil-define-command my/evil-write-and-delete-buffer (file &optional bang)
     "Write FILE and delete the current buffer."
     (interactive "<f><!>")
     (evil-write nil nil nil file bang)
     (evil-delete-buffer (current-buffer)))
   (evil-define-command my/evil-save-modified-and-delete-buffer (file &optional bang)
     "Write FILE when modified, then delete the current buffer."
     (interactive "<f><!>")
     (when (buffer-modified-p)
       (evil-write nil nil nil file bang))
     (evil-delete-buffer (current-buffer)))
   (evil-ex-define-cmd "q[uit]" #'evil-delete-buffer)
   (evil-ex-define-cmd "wq" #'my/evil-write-and-delete-buffer)
   (evil-ex-define-cmd "x[it]" #'my/evil-save-modified-and-delete-buffer)
   (evil-ex-define-cmd "exi[t]" #'my/evil-save-modified-and-delete-buffer)
   (define-key evil-normal-state-map (kbd "Z Z")
               #'my/evil-save-modified-and-delete-buffer)
   (define-key evil-normal-state-map (kbd "Z Q") #'evil-delete-buffer)
   (define-key evil-window-map (kbd "q") #'evil-delete-buffer)
   (define-key evil-window-map (kbd "C-q") #'evil-delete-buffer)
   ;; 文件树快捷键，仅覆盖 Evil Normal 状态。
   (define-key evil-normal-state-map (kbd "C-e") #'my/treemacs-toggle-current-project)

    ;; tab-line 使用当前 Window 的标签序列，[b 向左，]b 向右。
   (define-key evil-normal-state-map (kbd "[ b") #'tab-line-switch-to-prev-tab)
   (define-key evil-normal-state-map (kbd "] b") #'tab-line-switch-to-next-tab)
   (define-key evil-motion-state-map (kbd "[ b") #'tab-line-switch-to-prev-tab)
   (define-key evil-motion-state-map (kbd "] b") #'tab-line-switch-to-next-tab)
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
    (evil-define-key 'normal eglot-mode-map
      (kbd "K") #'eldoc
      (kbd "g r") #'xref-find-references)))
  
;; 3. Evil in terminal
(defun my-terminal-cursor-shape-block ()
  "Use a block cursor in the selected terminal frame."
  (unless (display-graphic-p)
    (send-string-to-terminal "\e[2 q")))

(defun my-terminal-cursor-shape-bar ()
  "Use a bar cursor in the selected terminal frame."
  (unless (display-graphic-p)
    (send-string-to-terminal "\e[6 q")))

(add-hook 'evil-insert-state-entry-hook #'my-terminal-cursor-shape-bar)
(add-hook 'evil-insert-state-exit-hook #'my-terminal-cursor-shape-block)
(my-terminal-cursor-shape-block)

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
    "[b" #'tab-line-switch-to-prev-tab
    "]b" #'tab-line-switch-to-next-tab))

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
(dolist (map (list minibuffer-local-map
                   minibuffer-local-ns-map
                   minibuffer-local-completion-map
                   minibuffer-local-must-match-map))
  ;; Keep minibuffer editing independent from global completion and Consult keys.
  (define-key map (kbd "C-SPC") #'set-mark-command)
  (define-key map (kbd "C-a") #'move-beginning-of-line)
  (define-key map (kbd "C-b") #'backward-char)
  (define-key map (kbd "C-d") #'delete-char)
  (define-key map (kbd "C-e") #'move-end-of-line)
  (define-key map (kbd "C-f") #'forward-char)
  (define-key map (kbd "C-k") #'kill-line)
  (define-key map (kbd "C-q") #'quoted-insert)
  (define-key map (kbd "C-t") #'transpose-chars)
  (define-key map (kbd "C-w") #'backward-kill-word)
  (define-key map (kbd "C-u") #'universal-argument)
  (define-key map (kbd "C-y") #'yank)
  (define-key map (kbd "C-/") #'undo)
  (define-key map (kbd "C-_") #'undo)
  (define-key map (kbd "M-b") #'backward-word)
  (define-key map (kbd "M-d") #'kill-word)
  (define-key map (kbd "M-f") #'forward-word)
  (define-key map (kbd "M-DEL") #'backward-kill-word)
  (define-key map (kbd "M-t") #'transpose-words)
  (define-key map (kbd "M-y") #'yank-pop)
  (define-key map (kbd "C-s") #'isearch-forward))
(define-key minibuffer-local-map [escape] 'minibuffer-keyboard-quit)
(define-key minibuffer-local-ns-map [escape] 'minibuffer-keyboard-quit)
(define-key minibuffer-local-completion-map [escape] 'minibuffer-keyboard-quit)
(define-key minibuffer-local-must-match-map [escape] 'minibuffer-keyboard-quit)
(define-key minibuffer-local-isearch-map [escape] 'minibuffer-keyboard-quit)


(provide 'init-evil)
;;; init-evil.el ends here
