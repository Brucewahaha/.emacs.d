;;; init-editing.el --- General editing and indentation settings -*- lexical-binding: t -*-
;;; Code:

(require 'init-treesitter)
(require 'init-sicp)

;; 基础编辑行为
(electric-pair-mode t)
(defun my/disable-electric-pair-in-minibuffer ()
  "在 minibuffer 中关闭成对括号补全。"
  (electric-pair-local-mode -1))
(add-hook 'minibuffer-setup-hook #'my/disable-electric-pair-in-minibuffer)
(show-paren-mode 1)
(global-hl-line-mode 1)
(add-hook 'prog-mode-hook #'hs-minor-mode)
(add-hook 'prog-mode-hook #'visual-line-mode)
(add-hook 'text-mode-hook #'visual-line-mode)
(electric-indent-mode -1)

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

(defun my/insert-spaces-to-tab-stop ()
  "Insert spaces to the next tab stop without invoking completion."
  (interactive)
  (let ((indent-tabs-mode nil))
    (tab-to-tab-stop)))

(defun my/setup-basic-prog-indentation ()
  "Use lightweight newline and space-only tab behavior in programming modes."
  (unless (derived-mode-p 'c-mode 'c++-mode 'c-ts-mode 'c++-ts-mode)
    (electric-indent-local-mode -1)
    (local-set-key (kbd "RET") #'newline-and-indent)
    (local-set-key (kbd "TAB") #'my/insert-spaces-to-tab-stop)
    (local-set-key (kbd "<tab>") #'my/insert-spaces-to-tab-stop)))

(add-hook 'prog-mode-hook #'my/setup-basic-prog-indentation)

(defun my/c-like-newline-and-indent ()
  "Insert and indent a C/C++ newline, expanding an empty brace pair."
  (interactive)
  (if (and (eq (char-before) ?\{)
           (eq (char-after) ?\}))
      (let ((indent (current-indentation)))
        (newline)
        (indent-to (+ indent (my/c-like-indent-offset)))
        (save-excursion
          (newline)
          (indent-to indent)))
    (newline-and-indent)))

(defun my/c-like-indent-offset ()
  "Return the effective C/C++ indentation width for this buffer."
  tab-width)

(defun my/sync-c-like-indent-width ()
  "Use the buffer's configured tab width for C/C++ syntax indentation."
  (when (derived-mode-p 'c-mode 'c++-mode 'c-ts-mode 'c++-ts-mode)
    (setq-local c-basic-offset tab-width)
    (when (derived-mode-p 'c-ts-mode 'c++-ts-mode)
      (setq-local c-ts-mode-indent-offset tab-width))))

(defun my/c-like-tab-to-tab-stop ()
  "Indent forward to the next C/C++ indentation stop."
  (interactive)
  (my/insert-spaces-to-tab-stop))

(defun my/setup-flexible-c-like-editing ()
  "Use lightweight, predictable indentation while typing C/C++."
  (my/sync-c-like-indent-width)
  (electric-indent-local-mode -1)
  (local-set-key (kbd "RET") #'my/c-like-newline-and-indent)
  (local-set-key (kbd "TAB") #'my/c-like-tab-to-tab-stop)
  (local-set-key (kbd "<tab>") #'my/c-like-tab-to-tab-stop)
  (when (fboundp 'evil-local-set-key)
    (evil-local-set-key 'insert (kbd "RET") #'my/c-like-newline-and-indent)
    (evil-local-set-key 'insert (kbd "TAB") #'my/c-like-tab-to-tab-stop)
    (evil-local-set-key 'insert (kbd "<tab>") #'my/c-like-tab-to-tab-stop)))

(add-hook 'c++-ts-mode-hook #'my/setup-flexible-c-like-editing)
(add-hook 'c-ts-mode-hook #'my/setup-flexible-c-like-editing)
(add-hook 'c++-mode-hook #'my/setup-flexible-c-like-editing)
(add-hook 'c-mode-hook #'my/setup-flexible-c-like-editing)
(add-hook 'hack-local-variables-hook #'my/sync-c-like-indent-width 80)

(defun my/dtrt-indent-maybe-enable ()
  "Detect indentation where the language does not have a stable default."
  (when (and buffer-file-name
             (derived-mode-p 'prog-mode 'text-mode))
    (let ((properties
           (editorconfig-call-get-properties-function buffer-file-name)))
      (setq-local dtrt-indent-explicit-offset
                  (and (gethash 'indent_size properties) t)
                  dtrt-indent-explicit-tab-mode
                  (and (gethash 'indent_style properties) t)))
    ;; C/C++ continuation lines frequently make heuristic detection mistake
    ;; two spaces for the basic offset.  Use EditorConfig or the 4-space
    ;; defaults above instead.
    (unless (derived-mode-p 'c-mode 'c++-mode 'c-ts-mode 'c++-ts-mode)
      (dtrt-indent-mode 1))))

(use-package dtrt-indent
  :ensure t
  :diminish
  :hook (hack-local-variables . my/dtrt-indent-maybe-enable)
  :config
  (setq dtrt-indent-verbosity 0))

(defun my/indent-bars-maybe-enable ()
  "Enable indentation bars after the buffer's indentation is settled."
  (when (derived-mode-p 'prog-mode)
    (indent-bars-mode 1)))

(use-package indent-bars
  :ensure t
  :commands indent-bars-mode
  :diminish
  :init
  ;; Run after EditorConfig, file-local variables and dtrt-indent.
  (add-hook 'hack-local-variables-hook
            #'my/indent-bars-maybe-enable 90)
  :custom
  (indent-bars-color '(font-lock-comment-face :blend 0.45))
  (indent-bars-color-by-depth nil)
  (indent-bars-width-frac 0.18)
  (indent-bars-pad-frac 0.15)
  (indent-bars-pattern ".")
  (indent-bars-display-on-blank-lines t)
  (indent-bars-highlight-current-depth
   '(:face font-lock-keyword-face :blend 1.0 :width 0.18))
  (indent-bars-treesit-support t)
  ;; Tree-sitter still improves blank-line and wrapping behavior, but depth
  ;; highlighting avoids coloring every nested bar in the current scope.
  (indent-bars-treesit-scope nil))

(use-package move-text
  :ensure t
  :commands (move-text-up move-text-down)
  :bind (:map prog-mode-map
              ("M-<up>" . move-text-up)
              ("M-<down>" . move-text-down))
  :init
  ;; Paredit keeps these keys in Insert state; code movement wins in the
  ;; Normal and Visual states where line/region operations are expected.
  (with-eval-after-load 'evil
    (evil-define-key '(normal visual) prog-mode-map
      (kbd "M-<up>") #'move-text-up
      (kbd "M-<down>") #'move-text-down)))

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
