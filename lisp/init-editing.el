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
(global-hl-line-mode 1)
(add-hook 'prog-mode-hook #'hs-minor-mode)
(add-hook 'prog-mode-hook #'visual-line-mode)
(add-hook 'text-mode-hook #'visual-line-mode)

;; 缩进与 Tab
(defcustom my/indent-width 4
  "Indentation width used when a project states no rule of its own."
  :type 'integer
  :group 'editing)

(defconst my/indent-offset-variables
  '(standard-indent
    c-basic-offset c-ts-mode-indent-offset
    java-ts-mode-indent-offset
    js-indent-level js-switch-indent-offset
    typescript-ts-mode-indent-offset
    json-ts-mode-indent-offset
    css-indent-offset
    sgml-basic-offset html-ts-mode-indent-offset nxml-child-indent
    python-indent-offset
    sh-basic-offset
    rust-indent-offset rust-ts-mode-indent-offset
    go-ts-mode-indent-offset
    ruby-indent-level lua-indent-level
    cperl-indent-level perl-indent-level
    cmake-ts-mode-indent-offset
    yaml-indent-offset)
  "Per-language indentation width variables.
Mixed values across these is the usual cause of one block indenting by a
different amount than its neighbours.  `lisp-indent-offset' is absent on
purpose: Lisp indentation belongs to each form's own indent rule.")

(defun my/apply-indent-width (&optional width)
  "Set `tab-width' and every known language offset to WIDTH."
  (interactive (list (read-number "Indent width: " my/indent-width)))
  (let ((width (or width my/indent-width)))
    (setq-default tab-width width)
    (dolist (variable my/indent-offset-variables)
      (set-default variable width))))

(setq-default indent-tabs-mode nil)
(my/apply-indent-width)

;; Tree-sitter modes indent from the parse tree, which stays correct through
;; nested blocks where CC Mode's heuristics drift.
(setq c-ts-mode-indent-style 'bsd)

;; A CC Mode style overrides `c-basic-offset' when it is applied, so the
;; width has to live inside the style rather than beside it.  Plain "bsd"
;; carries an 8-column offset.
(with-eval-after-load 'cc-mode
  (c-add-style "my-bsd" `("bsd" (c-basic-offset . ,my/indent-width)))
  (setq c-default-style
        '((java-mode . "java") (awk-mode . "awk") (other . "my-bsd"))))

(setq tab-always-indent 'complete)

(defun my/tab-dwim ()
  "Confirm an active Corfu candidate, otherwise indent or complete."
  (interactive)
  ;; Evil's Insert-state map takes precedence over Corfu's popup map.
  (if (and (bound-and-true-p completion-in-region-mode)
           (boundp 'corfu--candidates)
           corfu--candidates
           (fboundp 'corfu-insert))
      (corfu-insert)
    (call-interactively #'indent-for-tab-command)))

(defun my/setup-prog-indentation ()
  "Make TAB indent by syntax, or complete once the line is already indented."
  (local-set-key (kbd "TAB") #'my/tab-dwim)
  (local-set-key (kbd "<tab>") #'my/tab-dwim)
  (when (fboundp 'evil-local-set-key)
    (evil-local-set-key 'insert (kbd "TAB") #'my/tab-dwim)
    (evil-local-set-key 'insert (kbd "<tab>") #'my/tab-dwim)))

(add-hook 'prog-mode-hook #'my/setup-prog-indentation)

(defun my/disable-c-abbrev ()
  "Disable CC Mode keyword expansion."
  (abbrev-mode -1))

(add-hook 'c-mode-common-hook #'my/disable-c-abbrev)

;; EditorConfig runs last so a project's own rules win over the defaults above.
(use-package editorconfig
  :ensure nil
  :config
  (editorconfig-mode 1))

;; Like VS Code's `editor.detectIndentation': follow an existing file's
;; indentation when neither EditorConfig nor a local variable states one.
;; Emacs 30 applies EditorConfig through directory-local variables.
(defun my/indentation-set-locally-p ()
  "Return non-nil when a project or file rule set this buffer's indentation."
  (seq-some (lambda (variable)
              (or (assq variable dir-local-variables-alist)
                  (assq variable file-local-variables-alist)))
            (cons 'indent-tabs-mode my/indent-offset-variables)))

(defun my/detect-indentation ()
  "Adopt the indentation already used in this file."
  (when (and (derived-mode-p 'prog-mode)
             (not (my/indentation-set-locally-p)))
    (dtrt-indent-mode 1)))

(use-package dtrt-indent
  :ensure t
  :commands dtrt-indent-mode
  :init
  ;; After local variables, and before indent-bars reads the offset.
  (add-hook 'hack-local-variables-hook #'my/detect-indentation 80))

;; Display only: dots for spaces and arrows for real tabs, without changing text.
(defun my/dim-whitespace-space-in-frame (frame)
  "Blend FRAME's space markers toward its theme background.
A daemon's initial frame has no real colors, so the blend has to be
recomputed per frame once `emacsclient' creates a displayable one."
  (require 'color)
  (when (frame-live-p frame)
    (let ((foreground
           (color-name-to-rgb (face-foreground 'shadow frame t) frame))
          (background
           (color-name-to-rgb (face-background 'default frame t) frame)))
      (when (and foreground background)
        (set-face-attribute
         'whitespace-space frame
         :foreground
         (apply #'color-rgb-to-hex
                (cl-mapcar (lambda (fg bg) (+ (* 0.25 fg) (* 0.75 bg)))
                           foreground background))
         :background 'unspecified)))))

(defun my/dim-whitespace-space (&rest _)
  "Blend space markers in every live frame."
  (mapc #'my/dim-whitespace-space-in-frame (frame-list)))

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
  (add-hook 'enable-theme-functions #'my/dim-whitespace-space)
  (add-hook 'after-make-frame-functions #'my/dim-whitespace-space-in-frame)
  (add-hook 'server-after-make-frame-hook #'my/dim-whitespace-space))

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

;; 选区：输入时替换选中文本
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
(setq auto-save-timeout 15
      auto-save-interval 200
      auto-save-file-name-transforms
      `((".*" ,my/auto-save-directory t))
      auto-save-list-file-prefix
      (expand-file-name ".saves-" my/auto-save-directory)
      backup-directory-alist `(("." . ,my/backup-directory))
      version-control t
      kept-new-versions 10
      kept-old-versions 5
      delete-old-versions t
      backup-by-copying t
      backup-by-copying-when-linked t)

(provide 'init-editing)
;;; init-editing.el ends here
