;;; init-term.el --- VS Code style terminal toggle -*- lexical-binding: t -*-

;; 1. 安装并配置 vterm (高性能终端模拟器)
;; 注意：vterm 需要你电脑安装了 cmake 和 libvterm 自行编译（Emacs 会提示安装）
(use-package vterm
  :ensure t
  :config
  (setq vterm-max-scrollback 10000))

;; 2. 安装并配置 vterm-toggle (实现唤醒/隐藏逻辑)
(use-package vterm-toggle
  :ensure t
  :bind (("C-`" . vterm-toggle) ; 全局绑定
         :map vterm-mode-map
         ("C-`" . vterm-toggle)) ; 在 vterm 窗口内也能通过该键隐藏
  :config
  ;; 设置终端窗口在底部弹出并占据 30% 高度
  (setq vterm-toggle-fullscreen-p nil)
  (add-to-list 'display-buffer-alist
               '((lambda (bufname _) (with-current-buffer bufname (equal major-mode 'vterm-mode)))
                 (display-buffer-reuse-window display-buffer-at-bottom)
                 (window-height . 0.20)))
  
  ;; 建议：如果是 Evil 用户，确保进入终端时是 Emacs 状态（方便直接输入）
  (with-eval-after-load 'evil
    (evil-set-initial-state 'vterm-mode 'emacs)))

(provide 'init-term)
