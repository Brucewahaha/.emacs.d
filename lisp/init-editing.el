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

(defun my/indent-bars-maybe-enable ()
  "Enable indentation bars after the buffer's indentation is settled."
  (when (derived-mode-p 'prog-mode)
    (require 'indent-bars-ts)
    (indent-bars-mode 1)))

(use-package indent-bars
  :ensure t
  :init
  ;; Run after EditorConfig, file-local variables and dtrt-indent.
  (add-hook 'hack-local-variables-hook #'my/indent-bars-maybe-enable 90)
  :custom
  (indent-bars-prefer-character nil)
  (indent-bars-no-stipple-char ?│)
  (indent-bars-width-frac 0.1)
  (indent-bars-pad-frac 0.0)
  (indent-bars-pattern ".")
  (indent-bars-zigzag nil)
  (indent-bars-color '(default :face-bg t :blend 1))
  (indent-bars-color-by-depth nil)
  (indent-bars-highlight-current-depth
   '(:face font-lock-keyword-face :blend 1
     :width 0.12 :pad 0.0 :pattern "."))
  (indent-bars-highlight-selection-method nil)
  (indent-bars-depth-update-delay 0)
  (indent-bars-treesit-support t)
  (indent-bars-ts-styling-scope 'out-of-scope)
  (indent-bars-ts-color
   '(no-inherit default :face-bg t :blend 1))
  (indent-bars-treesit-scope
   '((python block)
     (c compound_statement)
     (cpp compound_statement)
     (javascript statement_block)
     (typescript statement_block)
     (tsx statement_block)
     (go block)
     (rust block)
     (bash compound_statement if_statement for_statement while_statement
           function_definition case_statement subshell)
     (ruby body_statement do_block block method class module)
     (cmake body)))
  (indent-bars-treesit-scope-min-lines 1)
  (indent-bars-ts-highlight-current-depth '(no-inherit)))

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
