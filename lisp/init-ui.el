;;; init-ui.el --- UI settings, Themes and Fonts -*- lexical-binding: t -*-
;; 1. 基础界面清理
(setq confirm-kill-emacs #'yes-or-no-p
      use-dialog-box nil)
(defconst my/programming-font-families
  '("CaskaydiaMono Nerd Font Mono" "0xProto Nerd Font Mono" "Cascadia Mono" "JetBrains Mono"
    "Menlo" "Monaco" "Consolas" "Liberation Mono"
    "DejaVu Sans Mono" "monospace")
  "Preferred programming font families, ordered by preference.")
(defconst my/cjk-font-families
  '("Microsoft YaHei" "PingFang SC" "Hiragino Sans GB"
    "Noto Sans CJK SC" "WenQuanYi Zen Hei Mono" "SimSun" "sans-serif")
  "Preferred CJK font families, ordered by preference.")
(defconst my/nerd-font-families
  '("Symbols Nerd Font Mono" "CaskaydiaMono Nerd Font Mono" "0xProto Nerd Font Mono")
  "Font families that provide the Nerd Font private-use glyphs.")
(defconst my/symbol-font-families
  '("Segoe UI Symbol" "Apple Symbols" "Noto Sans Symbols 2"
    "Noto Sans Symbols" "DejaVu Sans")
  "Preferred fonts for standard Unicode symbols.")
(defconst my/emoji-font-families
  '("Segoe UI Emoji" "Apple Color Emoji" "Noto Color Emoji"
    "Noto Emoji")
  "Preferred fonts for Emoji characters.")
(defcustom my/ui-font-height 130
  "UI font height in 1/10 point."
  :type 'integer
  :group 'faces)
(defcustom my/buffer-font-height 140
  "Main Buffer text height in 1/10 point."
  :type 'integer
  :group 'faces)
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
(defun my/tab-line-tabs ()
  "返回当前 Window 中与当前 Buffer 同组的标签。"
  (let ((special-p (my/special-buffer-p)))
    (seq-filter (lambda (buffer)
                  (eq special-p (my/special-buffer-p buffer)))
                (tab-line-tabs-fixed-window-buffers))))
(defun my/tab-line-tab-name (buffer buffers)
  "返回 BUFFER 的编号和截断后的标签名称。"
  (let ((index (1+ (seq-position buffers buffer))))
    (concat (when (eq buffer (current-buffer))
              (propertize "▌" 'face 'font-lock-keyword-face))
            (format "%d %s" index
                    (tab-line-tab-name-truncated-buffer buffer buffers)))))
(defun my/tab-line-switch-to-index (index)
  "跳转到当前 Window 标签栏中的第 INDEX 个 Buffer。"
  (interactive "p")
  (if-let ((buffer (nth (1- index) (my/tab-line-tabs))))
      (switch-to-buffer buffer)
    (user-error "当前标签栏没有第 %d 个标签" index)))
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
(defun my/switch-to-prev-buffer-skip (window buffer _bury-or-kill)
  "让自动 Buffer 切换停留在当前普通或特殊 Buffer 组内。"
  (with-selected-window window
    (not (eq (my/special-buffer-p (window-buffer window))
             (my/special-buffer-p buffer)))))
(defun my/tab-line-close-tab (tab)
  "关闭 TAB 对应的 Buffer。"
  (when-let* ((buffer (if (bufferp tab) tab (alist-get 'buffer tab)))
              (window (selected-window)))
    (let ((delete-window-p
           (and (eq buffer (window-buffer window))
                (= (length (tab-line-tabs-fixed-window-buffers)) 1)
                (eq (window-deletable-p window) t))))
      (when (and (kill-buffer buffer) delete-window-p)
        (delete-window window)))))
(setq tab-line-tabs-function #'my/tab-line-tabs
      tab-line-switch-cycling t
      tab-line-new-button-show nil
      tab-line-close-button-show t
      tab-line-tab-name-function #'my/tab-line-tab-name
      tab-line-tab-name-truncated-max 20
      tab-line-separator (propertize " " 'display '(space :width 0.5))
      tab-line-close-tab-function #'my/tab-line-close-tab
      switch-to-prev-buffer-skip #'my/switch-to-prev-buffer-skip)
(defun my/set-tab-line-close-button (icon)
  "将标签关闭按钮设置为 ICON。"
  (setq tab-line-close-button
        (propertize (concat " " icon)
                    'rear-nonsticky nil
                    'face '(:height 0.85)
                    'keymap tab-line-tab-close-map
                    'mouse-face 'tab-line-close-highlight
                    'help-echo "关闭标签")))
;; Start with a font-independent fallback; graphical frames upgrade it below.
(my/set-tab-line-close-button "x")
(defun my/setup-icons ()
  "Configure compact UI icons for the selected graphical frame.
Windows keeps text fallbacks in the mode-line and tab-line because its font
metrics can clip Nerd Font glyphs there.  Other uses of Nerd Font stay enabled."
  (let* ((nerd-enabled (and (my/nerd-font-available-p)
                            (fboundp 'nerd-icons-mdicon)))
         (compact-icons-enabled (and nerd-enabled (not my/windows-p))))
    (setq doom-modeline-icon compact-icons-enabled
          doom-modeline-major-mode-icon compact-icons-enabled
          doom-modeline-check-icon compact-icons-enabled
          doom-modeline-unicode-fallback nil)
    (my/set-tab-line-close-button
     (if compact-icons-enabled
         (nerd-icons-mdicon "nf-md-close_thick")
       "x"))
    (force-mode-line-update t)))
(with-eval-after-load 'nerd-icons
  (my/setup-icons))
(global-tab-line-mode 1)

(defun my/tab-line-apply-theme-colors ()
  "Use the current theme's semantic faces for tab-line states."
  (interactive)
  (set-face-attribute 'tab-line nil
                      :inherit 'mode-line-inactive
                      :box nil)
  (set-face-attribute 'tab-line-tab nil
                      :inherit 'tab-line
                      :box nil)
  (set-face-attribute 'tab-line-tab-inactive nil
                      :inherit 'tab-line
                      :weight 'normal
                      :box nil)
  (set-face-attribute 'tab-line-tab-current nil
                      :inherit 'default
                      :weight 'bold
                      :box nil
                      :underline nil)
  (set-face-attribute 'tab-line-tab-modified nil
                      :inherit 'warning)
  (set-face-attribute 'tab-line-tab-special nil
                      :inherit 'font-lock-comment-face
                      :slant 'italic)
  (set-face-attribute 'tab-line-close-highlight nil
                      :inherit 'error
                      :box nil))

(defun my/apply-ui-font-size ()
  "Apply `my/ui-font-height' to interface text faces."
  (dolist (face '(mode-line mode-line-active mode-line-inactive
                  header-line header-line-highlight
                  tab-line tab-line-tab tab-line-tab-current
                  tab-line-tab-inactive tooltip))
    (when (facep face)
      (set-face-attribute face nil :height my/ui-font-height))))

(defun my/setup-minibuffer-font-size ()
  "Use the UI font size for minibuffer input and completion text."
  (setq-local buffer-face-mode-face `(:height ,my/ui-font-height))
  (buffer-face-mode 1))

(add-hook 'minibuffer-setup-hook #'my/setup-minibuffer-font-size)

;; 3. 插件：图标库与状态栏
(use-package nerd-icons
  :ensure t)
(use-package nerd-icons-dired
  :ensure t
  :hook (dired-mode . my/nerd-icons-dired-maybe-enable))
(defun my/nerd-icons-dired-maybe-enable ()
  "Enable Nerd Icons Dired when the selected frame supports its font."
  (when (my/nerd-font-available-p)
    (nerd-icons-dired-mode 1)))
(use-package doom-modeline
  :ensure t
  :init (doom-modeline-mode 1)
  :config
  (my/setup-icons))


(defconst my/night-theme 'doom-wilmersdorf)
(defconst my/light-theme 'doric-jade)

(defun my/load-theme (theme)
  "Enable THEME after disabling every currently active theme."
  (dolist (enabled-theme (copy-sequence custom-enabled-themes))
    (disable-theme enabled-theme))
  (load-theme theme t)
  (when (fboundp 'my/setup-font)
    (my/setup-font))
  (my/tab-line-apply-theme-colors)
  (my/apply-ui-font-size))

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
  (doom-themes-treemacs-config)
  (doom-themes-org-config))

(my/load-theme my/night-theme)
(global-set-key (kbd "C-c t t") #'my/toggle-theme)

;; 4. 字体设置
(defun my/setup-font ()
  (interactive)
  (set-face-attribute 'default nil :height my/buffer-font-height)
  (let* ((cjk-font-scale 0.9)
          ;; 英文/基础字体
          (efl my/programming-font-families)
         ;; 中文字体
          (cfl my/cjk-font-families)
         ;; 标准符号、Emoji 与 Nerd Font PUA 使用不同字体。
          (symfl my/symbol-font-families)
          (emjfl my/emoji-font-families)
          (nerdfl my/nerd-font-families)
         
         (ef (cl-find-if (lambda (f) (member f (font-family-list))) efl))
         (cf (cl-find-if (lambda (f) (member f (font-family-list))) cfl))
         (symf (cl-find-if (lambda (f) (member f (font-family-list))) symfl))
         (emjf (cl-find-if (lambda (f) (member f (font-family-list))) emjfl))
         (nerdf (cl-find-if (lambda (f) (member f (font-family-list))) nerdfl)))
    ;; A. 设置默认字体
    (when ef
      (set-face-attribute 'default nil :family ef))
    ;; B. 设置中文字体 (han 字符集)
     (when cf
       (set-fontset-font t 'han (font-spec :family cf))
       (set-fontset-font t 'cjk-misc (font-spec :family cf))
       (setq face-font-rescale-alist `((,cf . ,cjk-font-scale))))
    ;; C. 标准 Unicode 符号。Org Modern 的星号、列表和复选框位于此处。
    (when symf
      (set-fontset-font t 'symbol (font-spec :family symf))
      (set-fontset-font t '(#x2000 . #x2bff) (font-spec :family symf))
      (when (facep 'org-modern-symbol)
        (set-face-attribute 'org-modern-symbol nil :family symf)))
    ;; D. Emoji 保留彩色/系统 Emoji 字体，不再交给 Nerd Font。
    (when emjf
      (set-fontset-font t '(#x1f000 . #x1faff) (font-spec :family emjf)))
    ;; E. Nerd Font 仅负责私用区图标。
    (when nerdf
      (set-fontset-font t '(#xe000 . #xf8ff) (font-spec :family nerdf)))))

(with-eval-after-load 'org-modern
  ;; `org-modern-symbol' is defined lazily when the first Org buffer is opened.
  (when (display-graphic-p)
    (my/setup-font)))

(defun my/setup-graphical-frame (&optional frame)
  "Configure fonts and icon state for graphical FRAME."
  (with-selected-frame (or frame (selected-frame))
    (when (display-graphic-p)
      (my/setup-font)
      (my/apply-ui-font-size)
      (my/setup-icons))))

(add-hook 'after-make-frame-functions #'my/setup-graphical-frame)
(add-hook 'window-setup-hook #'my/setup-graphical-frame)

(provide 'init-ui)
