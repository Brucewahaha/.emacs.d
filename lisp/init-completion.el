;;; init-completion.el --- In-buffer completion and snippets -*- lexical-binding: t -*-
;;; Code:

(use-package corfu
  :ensure t
  :hook (after-init . global-corfu-mode)
  :bind (("C-c t c" . global-corfu-mode)
         :map corfu-map
               ("SPC" . corfu-insert-separator)
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
  (setq completion-cycle-threshold 0)

  (defun my/corfu-use-basic-completion ()
    "在编辑区使用开销较低的前缀匹配。"
    (setq-local completion-styles '(basic)
                completion-category-overrides nil
                completion-category-defaults nil))
  (add-hook 'corfu-mode-hook #'my/corfu-use-basic-completion)

  (add-hook 'eshell-mode-hook
            (lambda ()
              (setq-local corfu-auto nil)))

  :custom
  (global-corfu-minibuffer nil)
  (corfu-cycle t)
  (corfu-auto t)
  (corfu-auto-delay 0.1)
  (corfu-auto-prefix 2)
  (corfu-preselect 'first)
  (corfu-preview-current nil))

;; `C-SPC' starts completion in editing buffers; minibuffers retain its default.
(global-set-key (kbd "C-SPC") #'completion-at-point)

(remove-hook 'completion-at-point-functions #'ispell-completion-at-point)

(use-package cape
  :ensure t
  :init
  ;; `completion-at-point-functions' may become buffer-local.  Updating its
  ;; default hook ensures buffers created after startup inherit Cape.
  (dolist (function '(cape-file cape-dabbrev cape-keyword))
    (add-hook 'completion-at-point-functions function)))

(use-package yasnippet
  :ensure t
  :diminish yas-minor-mode
  :hook ((after-init . yas-reload-all)
         ((prog-mode LaTeX-mode org-mode) . yas-minor-mode))
  :bind (:map yas-minor-mode-map
              ("TAB" . nil)
              ("<tab>" . nil)
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
