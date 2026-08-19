;;; init-window.el --- Window management like Doom Emacs -*- lexical-binding: t -*-

;; 1. Winner-mode: 佈局撤銷 (Doom 必備)
;; 快捷鍵：C-c left (撤銷), C-c right (重做)
(use-package winner
  :ensure nil
  :hook (after-init . winner-mode))

;; 2. Popper: 實現 Doom 的 Popup 彈出窗口管理
(defun my/popper-window-height (window)
  "Use half the frame height for compilation windows."
  (if (with-current-buffer (window-buffer window)
        (derived-mode-p 'compilation-mode))
      (floor (/ (frame-height (window-frame window)) 2))
    (popper--fit-window-height window)))

(use-package popper
  :ensure t
  :demand t
  :bind (("C-c `"   . popper-toggle)    ; 切換最近的彈出窗口
         ("M-`"   . popper-cycle)            ; 在多個彈出窗口間循環
         ("C-M-`" . popper-toggle-type))     ; 將普通窗口提升為彈出窗口
  :init
  (setq popper-reference-buffers
        '("\\*Messages\\*"
          "Output\\*$"
          "\\*Compile-Log\\*"
          "\\*Help\\*"
          "\\*helpful.*"
          "\\*Symbols\\*"
          "\\*Warnings\\*"
          "\\*Flymake errors\\*"
          "\\*Async Shell Command\\*"
          "\\*eat\\*"             ; 你的 eat 終端
          "\\*sdcv\\*"            ; 查詞窗口
          help-mode
          compilation-mode
          grep-mode
          occur-mode))
  (setq popper-window-height #'my/popper-window-height)
  :config
   (popper-mode 1)
   (popper-echo-mode 1)) ; 在底欄提示當前有幾個彈出窗口

(defun my/popper-buffer-p ()
  "Return non-nil when the current buffer is configured as a Popper buffer."
  (and (bound-and-true-p popper-mode)
       (popper-popup-p (current-buffer))))

(defun my/temporary-window-p ()
  "Return non-nil when the selected window is safe to quit with `q'."
  (or (bound-and-true-p org-capture-mode)
      (my/popper-buffer-p)
      (window-parameter (selected-window) 'window-side)))

(defun my/quit-temporary-window ()
  "Cancel a capture or close the selected temporary window."
  (interactive)
  (if (bound-and-true-p org-capture-mode)
      (org-capture-kill)
    (quit-window nil (selected-window))
    (when (fboundp 'popper--update-popups)
      (popper--update-popups))))

(defun my/evil-quit-temporary-window-or-record-macro ()
  "Close a temporary window with `q', otherwise start an Evil macro."
  (interactive)
  (if (my/temporary-window-p)
      (my/quit-temporary-window)
    (call-interactively #'evil-record-macro)))

;; 3. Ace-window: 快速跳轉窗口 (Doom 的 SPC w w)
(use-package ace-window
  :ensure t
  :bind ("M-o" . ace-window)
  :config
  (setq aw-keys '(?a ?s ?d ?f ?g ?h ?j ?k ?l))
  (setq aw-scope 'frame))

;; 4. Transpose-frame: 旋轉佈局 (Doom 的 SPC w r)
(use-package transpose-frame
  :ensure t)

;; 5. 強化 Evil 模式下的窗口快捷鍵 (如果你使用 Evil)
(with-eval-after-load 'evil
  (define-key evil-normal-state-map (kbd "q")
              #'my/evil-quit-temporary-window-or-record-macro)
  (define-key evil-window-map (kbd "u") 'winner-undo)
  (define-key evil-window-map (kbd "C-r") 'winner-redo)
  (define-key evil-window-map (kbd "o") 'ace-window)
  (define-key evil-window-map (kbd "r") 'transpose-frame))

(provide 'init-window)
