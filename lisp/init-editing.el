;;; init-editing.el --- General editing and indentation settings -*- lexical-binding: t -*-
;;; Code:

(require 'init-treesitter)
(require 'init-sicp)

;; 基础编辑行为
(electric-pair-mode t)
(setq electric-pair-open-newline-between-pairs nil)
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
  :ensure nil
  :config
  (editorconfig-mode 1))

(setq-default indent-tabs-mode nil
              tab-width 4
              standard-indent 4
              c-basic-offset 4)
(with-eval-after-load 'cc-mode
  (setf (alist-get 'c-mode c-default-style) "bsd"
        (alist-get 'c++-mode c-default-style) "bsd"))
(setq c-ts-mode-indent-style 'bsd
      c-ts-mode-indent-offset 4)
(setq tab-always-indent 'complete)

(defun my/tab-or-complete ()
  "Confirm an active Corfu candidate, or advance to the next tab stop."
  (interactive)
  ;; Evil's Insert-state map takes precedence over Corfu's popup map.
  (if (and (bound-and-true-p completion-in-region-mode)
           (boundp 'corfu--candidates)
           corfu--candidates
           (fboundp 'corfu-insert))
      (corfu-insert)
    (tab-to-tab-stop)))

(defun my/newline-with-inherited-indent (&optional count)
  "Insert COUNT newlines and inherit the current line's indentation."
  (interactive "*p")
  (let ((indent (current-indentation))
        (electric-indent-mode nil)
        (electric-pair-open-newline-between-pairs nil))
    (newline count)
    (indent-to indent)))

(defun my/setup-prog-indentation ()
  "Use predictable manual indentation while keeping native region indentation."
  (local-set-key (kbd "RET") #'my/newline-with-inherited-indent)
  (local-set-key (kbd "TAB") #'my/tab-or-complete)
  (local-set-key (kbd "<tab>") #'my/tab-or-complete)
  (when (fboundp 'evil-local-set-key)
    (evil-local-set-key 'insert (kbd "RET") #'my/newline-with-inherited-indent)
    (evil-local-set-key 'insert (kbd "TAB") #'my/tab-or-complete)
    (evil-local-set-key 'insert (kbd "<tab>") #'my/tab-or-complete)))

(add-hook 'prog-mode-hook #'my/setup-prog-indentation)

;; Traditional CC Mode has its own electric commands, independent of
;; Electric Indent.  Disable those without changing manual syntax indentation.
(defun my/disable-c-electric-editing ()
  "Disable automatic CC Mode indentation and keyword expansion."
  (c-toggle-electric-state -1)
  (abbrev-mode -1))

(add-hook 'c-mode-common-hook #'my/disable-c-electric-editing)

;; Display only: dots for spaces and arrows for real tabs, without changing text.
(defun my/dim-whitespace-space (&rest _)
  "Blend space markers toward the current theme's background."
  (require 'color)
  (let ((foreground (color-name-to-rgb (face-foreground 'shadow nil t)))
        (background (color-name-to-rgb (face-background 'default nil t))))
    (when (and foreground background)
      (set-face-attribute
       'whitespace-space nil
       :foreground
       (apply #'color-rgb-to-hex
              (cl-mapcar (lambda (fg bg) (+ (* 0.25 fg) (* 0.75 bg)))
                         foreground background))
       :background 'unspecified))))

(use-package whitespace
  :ensure nil
  :hook (prog-mode . whitespace-mode)
  :custom
  (whitespace-style '(face spaces tabs space-mark tab-mark))
  :custom-face
  (whitespace-space ((t (:inherit shadow :foreground unspecified :background unspecified))))
  (whitespace-tab ((t (:inherit shadow :foreground unspecified :background unspecified))))
  :config
  (my/dim-whitespace-space)
  (advice-add 'my/load-theme :after #'my/dim-whitespace-space))

(defun my/indent-bars-maybe-enable ()
  "Enable indentation bars after the buffer's indentation is settled."
  (when (derived-mode-p 'prog-mode)
    (indent-bars-mode 1)))

(defun my/indent-bars-scope-at-cursor (original buffer)
  "Query the cursor's character, using the first token for leading whitespace."
  ;; indent-bars 1.0 queries [point-1, point], which selects the enclosing
  ;; block on the first letter of a statement.  Shift only its query point;
  ;; leave the user's cursor and buffer contents untouched.
  (with-current-buffer buffer
    (save-excursion
      (when (<= (current-column) (current-indentation))
        (back-to-indentation))
      (unless (eobp) (forward-char 1))
      (funcall original buffer))))

(with-eval-after-load 'indent-bars-ts
  (advice-add 'indent-bars-ts--update-scope1 :around
              #'my/indent-bars-scope-at-cursor))

(use-package indent-bars
  :ensure t
  :commands indent-bars-mode
  :diminish
  :init
  ;; Run after EditorConfig and file-local variables.
  (add-hook 'hack-local-variables-hook
            #'my/indent-bars-maybe-enable 90)
  :custom
  ;; Character bars replace the space glyph, avoiding colored whitespace
  ;; dots superimposed on graphical stipple bars.
  (indent-bars-prefer-character t)
  (indent-bars-color '(font-lock-comment-face :blend 0.45))
  (indent-bars-color-by-depth nil)
  (indent-bars-width-frac 0.18)
  (indent-bars-pad-frac 0.15)
  (indent-bars-pattern ".")
  (indent-bars-display-on-blank-lines t)
  ;; Without a syntax scope, keep ordinary bars rather than highlighting
  ;; every unrelated block at the same depth throughout the buffer.
  (indent-bars-highlight-current-depth nil)
  (indent-bars-treesit-support t)
  (indent-bars-ts-styling-scope 'in-scope)
  (indent-bars-ts-color '(inherit unspecified))
  (indent-bars-ts-highlight-current-depth
   '(no-inherit :face font-lock-keyword-face :blend 1.0 :width 0.18))
  (indent-bars-treesit-scope-min-lines 2)
  (indent-bars-treesit-scope
    '((c compound_statement for_statement while_statement do_statement
         if_statement switch_statement)
      (cpp compound_statement for_statement for_range_loop while_statement
           do_statement if_statement switch_statement try_statement catch_clause)
      (python block for_statement while_statement if_statement
              with_statement try_statement)
      (rust block for_expression while_expression loop_expression
            if_expression match_expression)
      (javascript statement_block for_statement for_in_statement
                  while_statement do_statement if_statement switch_statement
                  try_statement catch_clause)
      (typescript statement_block for_statement for_in_statement
                  while_statement do_statement if_statement switch_statement
                  try_statement catch_clause)
      (tsx statement_block for_statement for_in_statement
           while_statement do_statement if_statement switch_statement
           try_statement catch_clause)
      (go block for_statement if_statement expression_switch_statement
          type_switch_statement select_statement))))

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

;; 文件恢复：自动保存应对崩溃，编号备份保留非 Git 文件的已保存历史。
(defconst my/auto-save-directory
  (expand-file-name "auto-save/" user-emacs-directory))
(defconst my/backup-directory
  (expand-file-name "backups/" user-emacs-directory))
(make-directory my/auto-save-directory t)
(make-directory my/backup-directory t)
(setq auto-save-default t
      auto-save-timeout 15
      auto-save-interval 200
      auto-save-file-name-transforms
      `((".*" ,my/auto-save-directory t))
      auto-save-list-file-prefix
      (expand-file-name ".saves-" my/auto-save-directory)
      make-backup-files t
      backup-directory-alist `(("." . ,my/backup-directory))
      version-control t
      kept-new-versions 10
      kept-old-versions 5
      delete-old-versions t
      backup-by-copying t
      backup-by-copying-when-linked t
      ;; Git history already covers version-controlled files.
      vc-make-backup-files nil)

(provide 'init-editing)
;;; init-editing.el ends here
