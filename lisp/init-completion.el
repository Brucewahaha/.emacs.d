;;; init-completion.el --- In-buffer completion and snippets -*- lexical-binding: t -*-
;;; Code:

(use-package corfu
  :ensure t
  :hook (after-init . global-corfu-mode)
  :bind (:map corfu-map
              ("SPC" . corfu-insert-separator)
              ("M-q" . corfu-quick-complete)
              ("C-n" . corfu-next)
              ("C-p" . corfu-previous)
              ("RET" . corfu-insert)
              ("TAB" . corfu-next)
              ([tab] . corfu-next)
              ("S-TAB" . corfu-previous)
              ([backtab] . corfu-previous))
  :config
  (setq completion-cycle-threshold 0
        tab-always-indent 'complete)

  (defun my/corfu-use-basic-completion ()
    "在编辑区使用开销较低的前缀匹配。"
    (setq-local completion-styles '(basic)
                completion-category-overrides nil
                completion-category-defaults nil))
  (add-hook 'corfu-mode-hook #'my/corfu-use-basic-completion)

  (defun corfu-enable-always-in-minibuffer ()
    "在不使用 Vertico 或 Mct 时为 minibuffer 启用 Corfu。"
    (unless (or (not my/code-completion-enabled)
                (bound-and-true-p mct--active)
                (bound-and-true-p vertico--input))
      (corfu-mode 1)))
  (add-hook 'minibuffer-setup-hook #'corfu-enable-always-in-minibuffer 1)

  (add-hook 'eshell-mode-hook
            (lambda ()
              (when my/code-completion-enabled
                (setq-local corfu-auto nil)
                (corfu-mode))))

  (defun corfu-send-shell (&rest _)
    "在 Eshell 或 Comint 中插入补全后立即发送输入。"
    (cond
     ((and (derived-mode-p 'eshell-mode) (fboundp 'eshell-send-input))
      (eshell-send-input))
     ((and (derived-mode-p 'comint-mode) (fboundp 'comint-send-input))
      (comint-send-input))))
  (advice-add #'corfu-insert :after #'corfu-send-shell)

  :custom
  (corfu-cycle t)
  (corfu-auto t)
  (corfu-auto-delay 0.1)
  (corfu-auto-prefix 2)
  (corfu-preselect 'first)
  (corfu-preview-current nil))

(defvar my/code-completion-enabled t
  "非 nil 时启用 Corfu 代码补全弹窗。")

(defun my/toggle-code-completion ()
  "全局开关 Corfu 代码补全弹窗。"
  (interactive)
  (setq my/code-completion-enabled (not my/code-completion-enabled))
  (if my/code-completion-enabled
      (global-corfu-mode 1)
    (global-corfu-mode -1)
    (dolist (buffer (buffer-list))
      (with-current-buffer buffer
        (when (bound-and-true-p corfu-mode)
          (corfu-mode -1)))))
  (message "代码补全弹窗已%s" (if my/code-completion-enabled "开启" "关闭")))

(global-set-key (kbd "C-c t c") #'my/toggle-code-completion)

(setq completion-at-point-functions
      (delq 'ispell-completion-at-point completion-at-point-functions))

(use-package cape
  :ensure t
  :init
  (add-to-list 'completion-at-point-functions #'cape-file)
  (add-to-list 'completion-at-point-functions #'cape-dabbrev)
  (add-to-list 'completion-at-point-functions #'cape-keyword))

(use-package yasnippet
  :ensure t
  :diminish yas-minor-mode
  :hook ((after-init . yas-reload-all)
         ((prog-mode LaTeX-mode org-mode) . yas-minor-mode))
  :bind (:map yas-minor-mode-map
              ("TAB" . nil)
              ("<tab>" . nil)
              ([tab] . nil)
              ("S-TAB" . yas-expand)
              ([backtab] . yas-expand))
  :config
  (require 'warnings)
  (add-to-list 'warning-suppress-types '(yasnippet backquote-change))
  (setq yas-prompt-functions '(yas-x-prompt yas-dropdown-prompt))
  (defun smarter-yas-expand-next-field ()
    "尝试展开模板，未展开时跳转到下一个模板字段。"
    (interactive)
    (let ((old-point (point))
          (old-tick (buffer-chars-modified-tick)))
      (yas-expand)
      (when (and (eq old-point (point))
                 (eq old-tick (buffer-chars-modified-tick)))
        (ignore-errors (yas-next-field))))))

(provide 'init-completion)
;;; init-completion.el ends here
