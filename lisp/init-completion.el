;;; init-completion.el --- In-buffer completion and snippets -*- lexical-binding: t -*-
;;; Code:

(use-package corfu
  :ensure t
  :hook (after-init . global-corfu-mode)
  :bind (("C-c t c" . global-corfu-mode)
         :map corfu-map
               ("M-q" . corfu-quick-complete)
               ("C-n" . corfu-next)
               ("C-p" . corfu-previous)
               ("RET" . nil)
               ("M-RET" . corfu-insert)
               ("TAB" . corfu-insert)
               ([tab] . corfu-insert)
              ("S-TAB" . corfu-previous)
              ([backtab] . corfu-previous))
  :config
  (defun my/corfu-use-basic-completion ()
    "在编辑区使用开销较低的前缀匹配。
保留补全类别的默认样式：Eglot 依赖它直接使用语言服务器已过滤的结果，
否则模糊、驼峰匹配的候选会被前缀匹配再次过滤掉。"
    (setq-local completion-styles '(basic)))
  (add-hook 'corfu-mode-hook #'my/corfu-use-basic-completion)

  (add-hook 'eshell-mode-hook
            (lambda ()
              (setq-local corfu-auto nil)))

  :custom
  (global-corfu-minibuffer nil)
  (corfu-cycle t)
  (corfu-auto t)
  (corfu-auto-delay 0.2)
  (corfu-auto-prefix 2)
  (corfu-preselect 'first)
  (corfu-preview-current nil))

;; Text modes add ispell word completion buffer-locally; keep it out of Corfu.
(setq text-mode-ispell-word-completion nil)

(use-package cape
  :ensure t
  :custom
  ;; Keep fallback word completion bounded even with many source files open.
  (cape-dabbrev-buffer-function #'current-buffer)
  :init
  ;; `completion-at-point-functions' may become buffer-local.  Updating its
  ;; default hook ensures buffers created after startup inherit Cape.
  (dolist (function '(cape-file cape-dabbrev cape-keyword))
    (add-hook 'completion-at-point-functions function)))

(use-package yasnippet
  :ensure t
  :hook ((after-init . yas-reload-all)
         ((prog-mode LaTeX-mode org-mode) . yas-minor-mode))
  :bind (:map yas-minor-mode-map
              ("TAB" . nil)
              ([tab] . nil)
              ("S-TAB" . smarter-yas-expand-next-field)
              ([backtab] . smarter-yas-expand-next-field))
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
