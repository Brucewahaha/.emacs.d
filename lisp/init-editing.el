;;; init-editing.el --- General editing and indentation settings -*- lexical-binding: t -*-
;;; Code:

(require 'init-treesitter)

;; 基础编辑行为
(electric-pair-mode t)
(defun my/disable-electric-pair-in-minibuffer ()
  "在 minibuffer 中关闭成对括号补全。"
  (electric-pair-local-mode -1))
(add-hook 'minibuffer-setup-hook #'my/disable-electric-pair-in-minibuffer)
(show-paren-mode 1)
(global-hl-line-mode 1)
(add-hook 'prog-mode-hook #'hs-minor-mode)
(electric-indent-mode 1)

;; 缩进与 Tab
(use-package editorconfig
  :ensure t
  :config
  (editorconfig-mode 1))

(setq-default indent-tabs-mode nil
              tab-width 4
              standard-indent 4
              c-basic-offset 4
              c++-basic-offset 4)
(setq tab-always-indent 'complete)
(add-hook 'c++-ts-mode-hook
          (lambda () (setq-local c-ts-mode-indent-offset 4)))
(add-hook 'c-ts-mode-hook
          (lambda () (setq-local c-ts-mode-indent-offset 4)))

(defun my/dtrt-indent-maybe-enable ()
  "Detect indentation without overriding explicit EditorConfig settings."
  (when (and buffer-file-name
             (derived-mode-p 'prog-mode 'text-mode))
    (let ((properties
           (editorconfig-call-get-properties-function buffer-file-name)))
      (setq-local dtrt-indent-explicit-offset
                  (and (gethash 'indent_size properties) t)
                  dtrt-indent-explicit-tab-mode
                  (and (gethash 'indent_style properties) t)))
    (dtrt-indent-mode 1)))

(use-package dtrt-indent
  :ensure t
  :diminish
  :hook (hack-local-variables . my/dtrt-indent-maybe-enable)
  :config
  (setq dtrt-indent-verbosity 0))

(defun my/highlight-indent-guides-maybe-enable ()
  "Enable indentation guides after the buffer's indentation is settled."
  (when (derived-mode-p 'prog-mode)
    (highlight-indent-guides-mode 1)))

(defface my/indent-guide-current-face
  '((t (:inherit font-lock-keyword-face :weight normal)))
  "Face for the indentation guide in the current block."
  :group 'highlight-indent-guides)

(defun my/highlight-indent-guides-highlighter (level responsive display)
  "Choose a theme-aware guide face for LEVEL, RESPONSIVE and DISPLAY."
  (if (eq responsive 'top)
      'my/indent-guide-current-face
    (highlight-indent-guides--highlighter-default level responsive display)))

(use-package highlight-indent-guides
  :ensure t
  :diminish
  :init
  ;; Run after EditorConfig, file-local variables and dtrt-indent.
  (add-hook 'hack-local-variables-hook
            #'my/highlight-indent-guides-maybe-enable 90)
  :custom
  (highlight-indent-guides-method 'character)
  (highlight-indent-guides-character ?│)
  (highlight-indent-guides-responsive 'top)
  (highlight-indent-guides-highlighter-function
   #'my/highlight-indent-guides-highlighter)
  (highlight-indent-guides-delay 0.05)
  (highlight-indent-guides-auto-character-face-perc 60))

;; 剪贴板与选区
(setq select-enable-primary nil
      select-enable-clipboard t)
(use-package delsel
  :ensure nil
  :hook (after-init . delete-selection-mode))

;; 文件恢复：自动保存集中到配置目录，不在项目中留下临时文件。
(defconst my/auto-save-directory
  (expand-file-name "auto-save/" user-emacs-directory))
(make-directory my/auto-save-directory t)
(setq make-backup-files nil
      auto-save-default t
      auto-save-file-name-transforms
      `((".*" ,my/auto-save-directory t)))

(provide 'init-editing)
;;; init-editing.el ends here
