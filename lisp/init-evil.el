;;; init-evil.el --- Vim emulation and compatibility -*- lexical-binding: t -*-
;;; Commentary:
;;; Code:

(use-package vundo
  :ensure t
  :bind ("C-x u" . vundo) ; 绑定到 C-x u，或者你想用的任何键
  :config
   (setq vundo-glyph-alist vundo-unicode-symbols))

(defun my/evil-block-insert-without-reindent (original &rest args)
  "Keep rectangular insertions in their selected columns.
Evil replays the insertion on other lines when leaving Insert state.
Electric indentation during that replay can move the inserted text away
from the rectangle, especially when inserting paired delimiters."
  (let ((electric-indent-mode
         (and electric-indent-mode (not evil-insert-vcount))))
    (apply original args)))

(defun my/close-current-window-buffer (&optional force)
  "Close the selected window's buffer without deleting any windows.
If another window displays it, only remove it from this window's history.
Otherwise kill it, asking about unsaved changes unless FORCE is non-nil."
  (let* ((window (selected-window))
         (buffer (window-buffer window))
         (shared (delq window (get-buffer-window-list buffer nil t))))
    (if shared
        (progn
          (switch-to-prev-buffer window t)
          (when (eq (window-buffer window) buffer)
            (switch-to-buffer (if (eq buffer (get-buffer "*scratch*"))
                                  (generate-new-buffer "*scratch*")
                                (get-buffer-create "*scratch*"))))
          (unrecord-window-buffer window buffer)
          (set-window-parameter
           window 'tab-line-buffers
           (delq buffer (window-parameter window 'tab-line-buffers))))
      (if (not force)
          (kill-buffer buffer)
        (let ((modified (buffer-modified-p buffer)))
          (unwind-protect
              (progn
                (set-buffer-modified-p nil)
                (kill-buffer buffer))
            ;; A query hook can still cancel the kill; preserve its dirty flag.
            (when (buffer-live-p buffer)
              (with-current-buffer buffer
                (set-buffer-modified-p modified)))))))))

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
  (advice-add 'evil-cleanup-insert-state :around
              #'my/evil-block-insert-without-reindent)
   ;; Keep single-buffer Vim quit commands from escalating to frame/Emacs exit.
   (evil-define-command my/evil-close-window-buffer (&optional bang)
     "Close this window's buffer, preserving other windows."
     (interactive "<!>")
     (my/close-current-window-buffer bang))
   (evil-define-command my/evil-write-and-delete-buffer (file &optional bang)
     "Write FILE and delete the current buffer."
     (interactive "<f><!>")
     (evil-write nil nil nil file bang)
      (my/close-current-window-buffer))
   (evil-define-command my/evil-save-modified-and-delete-buffer (file &optional bang)
     "Write FILE when modified, then delete the current buffer."
     (interactive "<f><!>")
     (when (buffer-modified-p)
       (evil-write nil nil nil file bang))
      (my/close-current-window-buffer))
   (evil-ex-define-cmd "q[uit]" #'my/evil-close-window-buffer)
   (evil-ex-define-cmd "wq" #'my/evil-write-and-delete-buffer)
   (evil-ex-define-cmd "x[it]" #'my/evil-save-modified-and-delete-buffer)
   (evil-ex-define-cmd "exi[t]" #'my/evil-save-modified-and-delete-buffer)
   (define-key evil-normal-state-map (kbd "Z Z")
               #'my/evil-save-modified-and-delete-buffer)
   (define-key evil-normal-state-map (kbd "Z Q") #'my/evil-close-window-buffer)
   ;; Window commands never kill buffers or escalate to frame/Emacs exit.
   (define-key evil-window-map (kbd "q") #'delete-window)
   (define-key evil-window-map (kbd "C-q") #'delete-window)
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
(defun my/fix-terminal-faces (&optional frame)
  "Apply terminal-only face overrides to FRAME, never to GUI frames."
  (let ((frame (or frame (selected-frame))))
    (when (and (frame-live-p frame) (not (display-graphic-p frame)))
      (set-face-attribute 'region frame
                          :background "#555555"
                          :foreground "white")
      (set-frame-parameter frame 'cursor-color "#FF0000")
      (set-face-attribute 'hl-line frame
                          :background "#333333"
                          :underline nil))))

(add-hook 'tty-setup-hook 'my/fix-terminal-faces)
(add-hook 'after-init-hook 'my/fix-terminal-faces)
(add-hook 'after-make-frame-functions #'my/fix-terminal-faces)

(defun my/refresh-terminal-faces (&rest _)
  "Reapply terminal overrides after enabling a theme."
  (mapc #'my/fix-terminal-faces (frame-list)))
(add-hook 'enable-theme-functions #'my/refresh-terminal-faces)

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

(defun my/comment-dwim ()
  "Comment the visual region without including its trailing line boundary."
  (interactive)
  (if (and (bound-and-true-p evil-local-mode)
           (evil-visual-state-p)
           (region-active-p))
      (let ((beginning (region-beginning))
            (end (region-end)))
        ;; Linewise Visual selections end at the following line's beginning.
        (when (and (> end beginning)
                   (save-excursion (goto-char end) (bolp)))
          (setq end (1- end)))
        (comment-or-uncomment-region beginning end))
    (comment-line)))

(use-package emacs
  :bind* ("C-/" . my/comment-dwim))


;;; esc quits
(defun my/minibuffer-keyboard-quit ()
  "Deactivate an active selection, otherwise abort the minibuffer."
  (interactive)
  (if (and delete-selection-mode transient-mark-mode mark-active)
      (setq deactivate-mark t)
    (abort-recursive-edit)))
(define-key evil-normal-state-map [escape] 'keyboard-quit)
(define-key evil-visual-state-map [escape] 'keyboard-quit)
;; Every minibuffer keymap, Vertico's included, inherits this one, so a
;; binding here covers them all.  Keep minibuffer editing independent from
;; global completion and Consult keys.
(dolist (binding '(("<escape>" . my/minibuffer-keyboard-quit)
                   ("C-SPC" . set-mark-command)
                   ("C-a" . move-beginning-of-line)
                   ("C-b" . backward-char)
                   ("C-d" . delete-char)
                   ("C-e" . move-end-of-line)
                   ("C-f" . forward-char)
                   ("C-k" . kill-line)
                   ("C-q" . quoted-insert)
                   ("C-t" . transpose-chars)
                   ("C-w" . backward-kill-word)
                   ("C-u" . universal-argument)
                   ("C-y" . yank)
                   ("C-/" . undo)
                   ("C-_" . undo)
                   ("M-b" . backward-word)
                   ("M-d" . kill-word)
                   ("M-f" . forward-word)
                   ("M-DEL" . backward-kill-word)
                   ("M-t" . transpose-words)
                   ("M-y" . yank-pop)
                   ("C-s" . isearch-forward)))
  (keymap-set minibuffer-local-map (car binding) (cdr binding)))


(provide 'init-evil)
;;; init-evil.el ends here
