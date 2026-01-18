;;; init-dev.el --- Unified Development Environment -*- lexical-binding: t -*-
;;; Code:
(require 'init-treesitter)
;; 1. 编程基础行为
(electric-pair-mode t)                       ; 自动补全括号
(add-hook 'prog-mode-hook #'show-paren-mode) ; 高亮对应括号
(add-hook 'prog-mode-hook #'hs-minor-mode)   ; 代码折叠
;; === Tab 智能缩进与补全方案 ===
;; 原理：按下 Tab 时，如果当前位置可以缩进就缩进；如果是单词末尾则触发 Eglot/Company 补全
(setq-default indent-tabs-mode nil) ; 使用空格代替 Tab 字符
(setq-default tab-width 4)          ; 缩进宽度为 4
(setq tab-always-indent 'complete)  ; 【关键】Tab 键先缩进，再尝试补全

;; 拷贝粘贴设置
(setq select-enable-primary nil)        ; 选择文字时不拷贝
(setq select-enable-clipboard t)        ; 拷贝时使用剪贴板

;; Directly modify when selecting text
(use-package delsel
  :ensure nil
  :hook (after-init . delete-selection-mode))

;; auto save configuration
(setq make-backup-files nil)                                  ; 不自动备份
(setq auto-save-default nil)                                  ; 不使用Emacs自带的自动保存

(use-package super-save
  :ensure t
  :hook (after-init . super-save-mode)
  :config
  ;; Emacs空闲是否自动保存，这里不设置
  (setq super-save-auto-save-when-idle nil)
  ;; 切换窗口自动保存
  (add-to-list 'super-save-triggers 'other-window)
  ;; 查找文件时自动保存
  (add-to-list 'super-save-hook-triggers 'find-file-hook)
  ;; 远程文件编辑不自动保存
  (setq super-save-remote-files nil)
  ;; 特定后缀名的文件不自动保存
  (setq super-save-exclude '(".gpg"))
  ;; 自动保存时，保存所有缓冲区
  (defun super-save/save-all-buffers ()
    (save-excursion
      (dolist (buf (buffer-list))
        (set-buffer buf)
        (when (and buffer-file-name
                   (buffer-modified-p (current-buffer))
                   (file-writable-p buffer-file-name)
                   (if (file-remote-p buffer-file-name) super-save-remote-files t))
          (save-buffer)))))
  (advice-add 'super-save-command :override 'super-save/save-all-buffers)
  )

(use-package eglot
  :ensure nil
  :hook ((python-ts-mode . eglot-ensure)
         (c-ts-mode      . eglot-ensure)
         (c++-ts-mode    . eglot-ensure)
         (js-ts-mode     . eglot-ensure)
         (typescript-ts-mode . eglot-ensure)
         (tsx-ts-mode    . eglot-ensure)
         (go-ts-mode     . eglot-ensure)
         (sh-mode        . eglot-ensure) ; Bash
	     (rust-ts-mode   . eglot-ensure)
         (ruby-ts-mode   . eglot-ensure)
         (haskell-ts-mode . eglot-ensure)
         (json-ts-mode   . eglot-ensure)
         (cmake-mode     . eglot-ensure))
  :config
  (setq eglot-events-buffer-size 0) ; 提高性能
  (setq eglot-autoshutdown t)

  (let ((map eglot-mode-map))
    (define-key map (kbd "C-c l r") 'eglot-rename)
    (define-key map (kbd "C-c l a") 'eglot-code-actions)
    (define-key map (kbd "C-c l f") 'eglot-format-buffer)))
;; 2. 补全增强
(use-package corfu
  :ensure t
  :hook (after-init . global-corfu-mode)
  :bind
  (:map corfu-map
        ("SPC" . corfu-insert-separator)    ; configure space for separator insertion
        ("M-q" . corfu-quick-complete)      ; use C-g to exit
        ("TAB" . corfu-next)
        ([tab] . corfu-next)
        ("S-TAB" . corfu-previous)
        ([backtab] . corfu-previous))
  :config
  ;; TAB cycle if there are only few candidates
  (setq completion-cycle-threshold 0)
  (setq tab-always-indent 'complete)

  (defun corfu-enable-always-in-minibuffer ()
    "Enable Corfu in the minibuffer if Vertico/Mct are not active."
    (unless (or (bound-and-true-p mct--active)
                (bound-and-true-p vertico--input))
      ;; (setq-local corfu-auto nil) Enable/disable auto completion
      (corfu-mode 1)))
  (add-hook 'minibuffer-setup-hook #'corfu-enable-always-in-minibuffer 1)

  ;; enable corfu in eshell
  (add-hook 'eshell-mode-hook
            (lambda ()
              (setq-local corfu-auto nil)
              (corfu-mode)))

  ;; For Eshell
  ;; ===========
  ;; avoid press RET twice in Eshell
  (defun corfu-send-shell (&rest _)
    "Send completion candidate when inside comint/eshell."
    (cond
     ((and (derived-mode-p 'eshell-mode) (fboundp 'eshell-send-input))
      (eshell-send-input))
     ((and (derived-mode-p 'comint-mode)  (fboundp 'comint-send-input))
      (comint-send-input))))

  (advice-add #'corfu-insert :after #'corfu-send-shell)

  :custom
  (corfu-cycle t)                ;; Enable cycling for `corfu-next/previous'
  )

;;Cape 插件提供了一系列开箱即用的补全后端，跟corfu联合使用。
(use-package cape
  :ensure t
  :init
  ;; Add `completion-at-point-functions', used by `completion-at-point'.
  (add-to-list 'completion-at-point-functions #'cape-file)
  (add-to-list 'completion-at-point-functions #'cape-dabbrev)
  (add-to-list 'completion-at-point-functions #'cape-keyword)  ; programming language keyword
  (add-to-list 'completion-at-point-functions #'cape-ispell)
  (add-to-list 'completion-at-point-functions #'cape-dict)
  (add-to-list 'completion-at-point-functions #'cape-symbol)   ; elisp symbol
  (add-to-list 'completion-at-point-functions #'cape-line)

  :config
  (setq cape-dict-file (expand-file-name "etc/hunspell_dict.txt" user-emacs-directory))

  ;; for Eshell:
  ;; ===========
  ;; Silence the pcomplete capf, no errors or messages!
  (advice-add 'pcomplete-completions-at-point :around #'cape-wrap-silent)

  ;; Ensure that pcomplete does not write to the buffer
  ;; and behaves as a pure `completion-at-point-function'.
  (advice-add 'pcomplete-completions-at-point :around #'cape-wrap-purify)
  )

;; 3. 语法检查 (Eglot 默认使用 Flymake)
;; 如果你坚持想用 Flycheck，需要安装 `exec-path-from-shell` 并配置兼容层
;; 但建议尝试原生的 Flymake：
(use-package flymake
  :ensure nil
  :bind (("M-n" . flymake-goto-next-error)
         ("M-p" . flymake-goto-prev-error)))
;; 4. Consult 集成 (用 consult-eglot 替换 consult-lsp)
(use-package consult-eglot
  :ensure t
  :after (eglot consult))

;; 6. Yasnippet
(use-package yasnippet
  :ensure t
  :diminish yas-minor-mode
  :hook ((after-init . yas-reload-all)
         ((prog-mode LaTeX-mode org-mode) . yas-minor-mode))
  :config
  ;; Suppress warning for yasnippet code.
  (require 'warnings)
  (add-to-list 'warning-suppress-types '(yasnippet backquote-change))

  (setq yas-prompt-functions '(yas-x-prompt yas-dropdown-prompt))
  (defun smarter-yas-expand-next-field ()
    "Try to `yas-expand' then `yas-next-field' at current cursor position."
    (interactive)
    (let ((old-point (point))
          (old-tick (buffer-chars-modified-tick)))
      (yas-expand)
      (when (and (eq old-point (point))
                 (eq old-tick (buffer-chars-modified-tick)))
        (ignore-errors (yas-next-field))))))


(use-package treemacs
 :ensure t
 :defer t
 :config
 (treemacs-tag-follow-mode)
 :bind
 (:map global-map
    ("M-0"    . treemacs-select-window)
    ("C-x t 1"  . treemacs-delete-other-windows)
    ("C-x t t"  . treemacs)
    ("C-x t B"  . treemacs-bookmark)
    ;; ("C-x t C-t" . treemacs-find-file)
    ("C-x t M-t" . treemacs-find-tag))
 (:map treemacs-mode-map
	("/" . treemacs-advanced-helpful-hydra)))

(use-package treemacs-projectile
 :ensure t
 :after (treemacs projectile))


(provide 'init-dev)
