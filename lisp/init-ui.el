;;; init-ui.el --- UI settings, Themes and Fonts -*- lexical-binding: t -*-
;; 1. 基础界面清理
(setq confirm-kill-emacs #'yes-or-no-p
      use-dialog-box nil)
(require 'color)
(defconst my/programming-font-families
  '("0xProto Nerd Font Mono" "Cascadia Mono" "JetBrains Mono"
    "Menlo" "Monaco" "Consolas" "Liberation Mono"
    "DejaVu Sans Mono" "monospace")
  "Preferred programming font families, ordered by preference.")
(defconst my/cjk-font-families
  '("Microsoft YaHei" "PingFang SC" "Hiragino Sans GB"
    "Noto Sans CJK SC" "WenQuanYi Zen Hei Mono" "SimSun" "sans-serif")
  "Preferred CJK font families, ordered by preference.")
(defconst my/nerd-font-families
  '("Symbols Nerd Font Mono" "0xProto Nerd Font Mono")
  "Font families that provide the Nerd Font private-use glyphs.")
(defun my/nerd-font-available-p ()
  "Return non-nil when this GUI frame can render Nerd Font icons."
  (and (display-graphic-p)
       (cl-find-if (lambda (family)
                     (member family (font-family-list)))
                   my/nerd-font-families)))
;; (when (fboundp 'tool-bar-mode) (tool-bar-mode -1))
;; (when (fboundp 'set-scroll-bar-mode) (set-scroll-bar-mode nil))
;; (menu-bar-mode -1)
;; 2. 行号与视觉反馈
(global-display-line-numbers-mode 1)
(setq display-line-numbers-type 'relative)
(column-number-mode t)
(fset 'yes-or-no-p 'y-or-n-p)
(setq visible-bell 1)

;; 内置 tab-line：每个 Window 保持独立的普通 Buffer 和特殊 Buffer 标签序列。
(require 'tab-line)
(defun my/special-buffer-p (&optional buffer)
  "判断 BUFFER 是否为名称以星号开头和结尾的特殊 Buffer。"
(let ((name (buffer-name (or buffer (current-buffer)))))
    (and (string-prefix-p "*" name)
         (string-suffix-p "*" name))))
(defvar my/tab-line-known-windows (make-hash-table :test #'eq)
  "已初始化私有标签列表的 Window。")
(defvar my/tab-line-suspend-recording nil
  "When non-nil, do not record internal buffer switches as tabs.")
(defun my/tab-line-initialize-window (window)
  "为 WINDOW 建立只包含当前 Buffer 的私有标签列表。"
  (set-window-parameter window 'my-tab-line-buffers
                        (list (window-buffer window)))
  (set-window-parameter window 'tab-line-cache nil)
  (puthash window t my/tab-line-known-windows))
(defun my/tab-line-track-windows ()
  "初始化新建 Window 的私有标签列表。"
  (dolist (window (window-list nil 'no-minibuf))
    (unless (gethash window my/tab-line-known-windows)
      (my/tab-line-initialize-window window))))
(defun my/tab-line-reset-window-tabs ()
  "重置所有 Window 的私有标签列表。"
  (interactive)
  (clrhash my/tab-line-known-windows)
  (dolist (window (window-list nil 'no-minibuf))
    (my/tab-line-initialize-window window))
  (force-mode-line-update t))
(defun my/tab-line-record-window-buffer (window _previous-buffer)
  "将 WINDOW 新显示的 Buffer 追加到它自己的标签列表。"
  (unless (gethash window my/tab-line-known-windows)
    (my/tab-line-initialize-window window))
  (let* ((current (window-buffer window))
         (buffers (seq-filter #'buffer-live-p
                              (window-parameter window 'my-tab-line-buffers))))
    (unless (memq current buffers)
      (setq buffers (append buffers (list current))))
    (set-window-parameter window 'my-tab-line-buffers buffers)
    (set-window-parameter window 'tab-line-cache nil)))
(defun my/tab-line-record-after-switch-to-buffer (&rest _)
  "在切换 Buffer 后更新当前 Window 的私有标签列表。"
  (unless my/tab-line-suspend-recording
    (my/tab-line-record-window-buffer (selected-window) nil)))
(defun my/tab-line-window-buffers ()
  "返回当前 Window 的私有标签列表，并追加新显示的 Buffer。"
  (let* ((window (selected-window))
         (current (window-buffer window))
         (buffers (seq-filter #'buffer-live-p
                              (window-parameter window 'my-tab-line-buffers))))
    (unless (memq current buffers)
      (setq buffers (append buffers (list current))))
    (set-window-parameter window 'my-tab-line-buffers buffers)
    buffers))
(defun my/tab-line-tabs ()
  "返回当前 Window 中与当前 Buffer 同组的标签。"
  (let ((special-p (my/special-buffer-p)))
    (seq-filter (lambda (buffer)
                  (eq special-p (my/special-buffer-p buffer)))
                (my/tab-line-window-buffers))))
(defun my/tab-line-tab-name (buffer buffers)
  "返回 BUFFER 的编号和截断后的标签名称。"
  (let ((index (1+ (seq-position buffers buffer))))
    (concat (when (eq buffer (current-buffer))
              (propertize "▌" 'face 'font-lock-keyword-face))
            (format "%d %s" index (tab-line-tab-name-truncated-buffer buffer buffers)))))
(defun my/tab-line-switch (offset)
  "按当前 Window 标签栏的显示顺序移动 OFFSET 个标签。"
  (let* ((buffers (my/tab-line-tabs))
         (position (seq-position buffers (current-buffer))))
    (unless position
      (user-error "当前 Buffer 不在标签栏中"))
    (switch-to-buffer (nth (mod (+ position offset) (length buffers)) buffers))
    (set-window-parameter nil 'tab-line-cache nil)
    (force-mode-line-update)))
(defun my/tab-line-switch-to-index (index)
  "跳转到当前 Window 标签栏中的第 INDEX 个 Buffer。"
  (interactive "p")
  (if-let ((buffer (nth (1- index) (my/tab-line-tabs))))
      (switch-to-buffer buffer)
    (user-error "当前标签栏没有第 %d 个标签" index)))
(defun my/tab-line-switch-to-shifted-index ()
  "按 Shift+数字跳转到当前 Window 标签栏中的对应 Buffer。"
  (interactive)
  (let ((index (seq-position "!@#$%^&*(" last-command-event)))
    (unless index
      (user-error "无法识别 Shift+数字按键"))
    (my/tab-line-switch-to-index (1+ index))))
(defun my/tab-line-switch-to-control-shift-index ()
  "按 Ctrl+Shift+数字跳转到当前 Window 标签栏中的对应 Buffer。"
  (interactive)
  (let* ((event (event-basic-type last-command-event))
         (index (cond ((and (characterp event) (<= ?1 event ?9))
                       (- event ?1))
                      ((characterp event)
                       (seq-position "!@#$%^&*(" event)))))
    (unless index
      (user-error "无法识别 Ctrl+Shift+数字按键"))
    (my/tab-line-switch-to-index (1+ index))))
(defun my/tab-line-switch-to-prev-tab ()
  "切换到当前 Window 标签栏左侧的 Buffer。"
  (interactive)
  (my/tab-line-switch -1))
(defun my/tab-line-switch-to-next-tab ()
  "切换到当前 Window 标签栏右侧的 Buffer。"
  (interactive)
  (my/tab-line-switch 1))
(defun my/switch-to-prev-buffer-skip (window buffer _bury-or-kill)
  "让自动 Buffer 切换停留在当前普通或特殊 Buffer 组内。"
  (with-selected-window window
    (not (eq (my/special-buffer-p (window-buffer window))
             (my/special-buffer-p buffer)))))
(defun my/tab-line-remove-killed-buffer (buffer)
  "从所有 Window 的私有标签列表中移除已关闭的 BUFFER。"
  (dolist (window (copy-sequence (window-list nil 'no-minibuf)))
    (let ((buffers (delq buffer
                         (window-parameter window 'my-tab-line-buffers))))
      (set-window-parameter window 'my-tab-line-buffers buffers)
      (set-window-parameter window 'tab-line-cache nil)
      (when (and (null buffers)
                 (window-live-p window)
                 (with-selected-window window (not (one-window-p t))))
        (delete-window window))))
  (force-mode-line-update t))
(defun my/tab-line-kill-buffer-advice (original &rest args)
  "在 Buffer 被关闭后同步私有标签列表。"
  (let ((buffer (if args (get-buffer (car args)) (current-buffer))))
    (prog1 (apply original args)
      (when (and buffer (not (buffer-live-p buffer)))
        (my/tab-line-remove-killed-buffer buffer)))))
(defun my/tab-line-close-tab (tab)
  "关闭 TAB 对应的 Buffer。"
  (when-let ((buffer (if (bufferp tab) tab (alist-get 'buffer tab))))
    (kill-buffer buffer)))
(setq tab-line-tabs-function #'my/tab-line-tabs
      tab-line-switch-cycling t
      tab-line-new-button-show nil
      tab-line-close-button-show t
      tab-line-tab-name-function #'my/tab-line-tab-name
      tab-line-tab-name-truncated-max 20
       tab-line-separator ""
      tab-line-close-tab-function #'my/tab-line-close-tab
      switch-to-prev-buffer-skip #'my/switch-to-prev-buffer-skip)
(defun my/set-tab-line-close-button (icon)
  "将标签关闭按钮设置为 ICON。"
  (setq tab-line-close-button
        (propertize (concat " " icon)
                    'rear-nonsticky nil
                    'keymap tab-line-tab-close-map
                    'mouse-face 'tab-line-close-highlight
                    'help-echo "关闭标签")))
(my/set-tab-line-close-button "×")
(with-eval-after-load 'nerd-icons
  (when (my/nerd-font-available-p)
    (my/set-tab-line-close-button
     (nerd-icons-mdicon "nf-md-close_thick" :height 0.8))))
(add-hook 'window-configuration-change-hook #'my/tab-line-track-windows)
(unless (advice-member-p #'my/tab-line-record-after-switch-to-buffer 'switch-to-buffer)
  (advice-add 'switch-to-buffer :after #'my/tab-line-record-after-switch-to-buffer))
(unless (advice-member-p #'my/tab-line-kill-buffer-advice 'kill-buffer)
  (advice-add 'kill-buffer :around #'my/tab-line-kill-buffer-advice))
(my/tab-line-reset-window-tabs)
(global-tab-line-mode 1)

(defun my/darken-color (color amount)
  "将十六进制 COLOR 按 AMOUNT 比例加深。"
  (if (string-match-p "\\`#[[:xdigit:]]\\{6\\}\\'" color)
      (format "#%02x%02x%02x"
              (floor (* (string-to-number (substring color 1 3) 16) (- 1 amount)))
              (floor (* (string-to-number (substring color 3 5) 16) (- 1 amount)))
              (floor (* (string-to-number (substring color 5 7) 16) (- 1 amount))))
    (color-darken-name color amount)))
(defun my/tab-line-apply-theme-colors ()
  "根据当前主题的编辑区背景设置标签栏颜色。"
  (interactive)
  (let ((editor-background (face-attribute 'default :background nil t)))
    (when (and (stringp editor-background)
               (not (member editor-background '("unspecified" "unspecified-bg"))))
      (let ((tab-background (my/darken-color editor-background 0.38)))
        (set-face-attribute 'tab-line nil :background tab-background :box nil)
        (set-face-attribute 'tab-line-tab nil :background tab-background :box nil)
        (set-face-attribute 'tab-line-tab-inactive nil
                            :inherit 'mode-line-inactive
                            :background tab-background
                            :box nil)
        (set-face-attribute 'tab-line-tab-current nil
                            :inherit 'mode-line
                            :background editor-background
                            :weight 'normal
                            :box nil
                            :underline nil)))))

;; 3. 插件：图标库与状态栏
(use-package nerd-icons
  :ensure t)
(use-package nerd-icons-dired
  :ensure t
  :if (my/nerd-font-available-p)
  :hook (dired-mode . nerd-icons-dired-mode))
(use-package doom-modeline
  :ensure t
  :init (doom-modeline-mode 1)
  :config
  (setq doom-modeline-icon (my/nerd-font-available-p)
        doom-modeline-major-mode-icon (my/nerd-font-available-p)))


(defconst my/night-theme 'doom-wilmersdorf)
(defconst my/light-theme 'doric-jade)

(defun my/load-theme (theme)
  "Enable THEME after disabling every currently active theme."
  (dolist (enabled-theme (copy-sequence custom-enabled-themes))
    (disable-theme enabled-theme))
  (load-theme theme t)
  (my/tab-line-apply-theme-colors))

(defun my/toggle-theme ()
  "Switch between the configured night and light themes."
  (interactive)
  (my/load-theme (if (memq my/night-theme custom-enabled-themes)
                     my/light-theme
                   my/night-theme)))

(use-package doric-themes
  :ensure t)

;; 加载 Doom Themes 集成，供 Treemacs、Org 和视觉铃声在两种主题下使用。
(use-package doom-themes
  :ensure t
  :demand t
  :init
  (setq doom-themes-enable-bold t
        doom-themes-enable-italic t
        doom-themes-treemacs-theme "doom-atom"
        doom-themes-treemacs-enable-variable-pitch nil)
  :config
  (doom-themes-visual-bell-config)
  (doom-themes-neotree-config)
  (doom-themes-treemacs-config)
  (doom-themes-org-config))

(my/load-theme my/night-theme)
(global-set-key (kbd "C-c t t") #'my/toggle-theme)

;; 4. 字体设置
(defun my/setup-font ()
  (interactive)
  (let* ((font-size 15)
         (cjk-font-scale 0.9)
          ;; 英文/基础字体
          (efl my/programming-font-families)
         ;; 中文字体
          (cfl my/cjk-font-families)
         ;; 符号/图标字体
          (sfl my/nerd-font-families)
         
         (ef (cl-find-if (lambda (f) (member f (font-family-list))) efl))
         (cf (cl-find-if (lambda (f) (member f (font-family-list))) cfl))
         (sf (cl-find-if (lambda (f) (member f (font-family-list))) sfl)))
    ;; A. 设置默认字体
    (when ef
      (set-face-attribute 'default nil :family ef :height 140))
    ;; B. 设置中文字体 (han 字符集)
     (when cf
       (set-fontset-font t 'han (font-spec :family cf))
       (set-fontset-font t 'cjk-misc (font-spec :family cf))
       (setq face-font-rescale-alist `((,cf . ,cjk-font-scale))))
    ;; C. 设置符号字体 (注意：Elisp 中十六进制必须用 #x 开头)
    (when sf
      ;; 基础符号
      (set-fontset-font t 'symbol (font-spec :family sf))
      ;; Nerd Fonts 常用图标范围 (PUA 区域)
      (set-fontset-font t '(#xe000 . #xf8ff) (font-spec :family sf))
      ;; 更多符号
      (set-fontset-font t '(#x2100 . #x2bcf) (font-spec :family sf))
      ;; Emoji 范围
      (set-fontset-font t '(#x1f000 . #x1faf0) (font-spec :family sf)))
   ));; 确保在 GUI 环境下正确加载
(if (daemonp)
    (add-hook 'after-make-frame-functions (lambda (frame) (with-selected-frame frame (my/setup-font))))
  (add-hook 'window-setup-hook #'my/setup-font))

(provide 'init-ui)
