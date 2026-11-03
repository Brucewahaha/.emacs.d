;;; init-tools.el --- Specialized Utilities -*- lexical-binding: t -*-
;;; Code:

;; 跳转
(use-package avy
  :ensure t
  :defer t
  :config
  (setq avy-timeout-seconds 0.3)
  (setq avy-all-windows t))


;; 增强帮助
(use-package which-key
  :ensure nil
  :init
  (which-key-mode 1))
(use-package helpful
  :ensure t
  :bind (("C-h f" . helpful-function)
         ("C-h v" . helpful-variable)
         ("C-h k" . helpful-key)))

;; 滚动优化
(use-package xt-mouse
  :ensure nil
  :config
  ;; Global mode also initializes terminals connected later by emacsclient.
  (xterm-mouse-mode 1))

(defun my/enable-pixel-scroll-on-graphical-frame (frame)
  "Enable precise pixel scrolling after a graphical FRAME is available."
  (with-selected-frame frame
    (when (display-graphic-p)
      (pixel-scroll-precision-mode 1))))

(add-hook 'after-make-frame-functions
          #'my/enable-pixel-scroll-on-graphical-frame)
(when (display-graphic-p)
  (pixel-scroll-precision-mode 1))

(use-package pyim
  :ensure t
  :commands (pyim-convert-string-at-point pyim-activate)
  :init
  ;; 1. 设置输入法激活快捷键 (C-\\)
  (setq default-input-method "pyim")

  ;; 2. 设置双拼方案为：小鹤双拼
  (setq pyim-default-scheme 'xiaohe-shuangpin)

  ;; 3. 设置选词框显示方式 (在光标处弹出)
  (setq pyim-page-tooltip 'posframe) ; 如果你没装 posframe，可以改为 'popup 或 'minibuffer

  ;; 4. 标点符号：关闭转换，始终输入半角标点
  (setq-default pyim-punctuation-dict nil)

  ;; C-\ 已默认绑定 `toggle-input-method'。
  :bind ("M-j" . pyim-convert-string-at-point)) ; 转换光标前的拼音为中文

(use-package pyim-basedict
  :ensure t
  :after pyim
  :config
  (pyim-basedict-enable))

(provide 'init-tools)
