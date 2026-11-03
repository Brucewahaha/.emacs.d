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
  '("Maple Mono Normal NF CN"
    "Source Han Sans SC"
    "Microsoft YaHei"
    "Noto Sans SC"
    "PingFang SC")
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
(defun my/available-font (families)
  "Return the first installed member of FAMILIES on the selected frame.
Cache the font list per frame, not globally across daemon displays."
  (when (display-graphic-p)
    (let ((fonts (or (frame-parameter nil 'my/font-families)
                     (let ((fonts (font-family-list)))
                       (set-frame-parameter nil 'my/font-families fonts)
                       fonts))))
      (seq-find (lambda (family) (member family fonts)) families))))

(defun my/nerd-font-available-p ()
  "Return non-nil when this GUI frame can render Nerd Font icons."
   (my/available-font my/nerd-font-families))
;; 2. 行号与视觉反馈
(global-display-line-numbers-mode 1)
(setq display-line-numbers-type 'relative)
(column-number-mode t)
(setq use-short-answers t)
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
  (format "%d %s%s"
          (1+ (seq-position buffers buffer))
          (tab-line-tab-name-truncated-buffer buffer buffers)
          (if (and (buffer-file-name buffer) (buffer-modified-p buffer)) " *" "")))
(defun my/tab-line-tab-name-format (tab tabs)
  "Format TAB and apply semantic faces to Dired and unsaved indicators."
  (let* ((buffer (if (bufferp tab) tab (alist-get 'buffer tab)))
         (selected-p (if (bufferp tab)
                         (eq buffer (window-buffer))
                       (alist-get 'selected tab)))
         (name (if buffer
                   (funcall tab-line-tab-name-function buffer tabs)
                 (alist-get 'name tab)))
         (display-name (string-replace "%" "%%" name))
         (formatted (tab-line-tab-name-format-default tab tabs)))
    (when (and buffer (not selected-p)
                (with-current-buffer buffer (derived-mode-p 'dired-mode)))
      (add-face-text-property 0 (length display-name)
                              'font-lock-comment-face nil formatted))
    (when (and buffer (buffer-file-name buffer) (buffer-modified-p buffer))
      ;; A warning foreground can be indistinguishable from the selection
      ;; background (e.g. Chyla).  Keep the selected face's color pair.
      (add-face-text-property 0 (length display-name)
                              (if selected-p '(:weight bold) 'warning)
                              nil formatted))
    formatted))
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
      tab-line-new-button-show nil
      tab-line-tab-name-function #'my/tab-line-tab-name
      tab-line-tab-name-format-function #'my/tab-line-tab-name-format
      tab-line-separator (propertize "|" 'face 'tab-line)
      tab-line-tab-face-functions '(tab-line-tab-face-modified
                                    my/tab-line-tab-face-current-highlight)
      tab-line-close-tab-function #'my/tab-line-close-tab
      switch-to-prev-buffer-skip #'my/switch-to-prev-buffer-skip)
(defun my/tab-line-tab-face-current-highlight
    (tab _tabs face buffer-p selected-p)
  "Apply the theme's hover highlight to the selected TAB."
  (when selected-p
    (let ((buffer (if buffer-p tab (alist-get 'buffer tab))))
      (setq face
            `(:inherit (tab-line-highlight
                        ,(if (and buffer (buffer-file-name buffer)
                                  (buffer-modified-p buffer))
                             face
                           'tab-line-tab-inactive))))))
  face)
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

(defun my/tab-line-remove-borders ()
  "Remove Tab Line borders while leaving its colors to the current theme."
  (interactive)
  (dolist (face '(tab-line tab-line-tab tab-line-tab-current
                  tab-line-tab-inactive tab-line-tab-modified
                  tab-line-close-highlight))
    (set-face-attribute face nil :box nil))
  (tab-line-force-update t))

(defun my/reset-tab-line-faces ()
  "Clear old direct Tab Line face attributes before loading a theme."
  (dolist (face '(tab-line tab-line-tab tab-line-tab-current
                  tab-line-tab-inactive tab-line-tab-modified
                  tab-line-close-highlight))
    (face-spec-reset-face face)))

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
         
         (ef (my/available-font efl))
         (cf (my/available-font cfl))
         (symf (my/available-font symfl))
         (emjf (my/available-font emjfl))
         (nerdf (my/available-font nerdfl)))
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

(defconst my/night-theme 'chyla-dark)
(defconst my/alternate-night-theme 'amaranth-dark)
(defconst my/light-theme 'flatfluc)

(defun my/after-enable-theme (theme)
  "Reapply font and Tab Line adjustments after THEME is enabled.
Runs for every theme switch, including `M-x load-theme' and `consult-theme'."
  ;; `user' and `use-package' are settings pseudo-themes, not color themes.
  (unless (memq theme '(user use-package))
    ;; Store overrides in Chyla itself, not in the higher-priority user theme,
    ;; so disabling Chyla restores the next theme's own face definitions.
    (when (eq theme 'chyla-dark)
      (let ((custom--inhibit-theme-enable nil))
        (custom-theme-set-faces
         'chyla-dark
         '(default ((((type graphic)) (:background "#282c34" :foreground "#dddddd"))
                    (t (:background "#121212" :foreground "#dddddd"))))
         '(hl-line ((t (:background "#353b45"))))
         '(cursor ((t (:background "#FF9800"))))
         '(region ((t (:background "#3e5c76")))))))
    (when (eq theme 'flatfluc)
      (let ((custom--inhibit-theme-enable nil))
        (custom-theme-set-faces
         'flatfluc
         '(default ((((type graphic)) (:background "#E5EAF0" :foreground "#425d78"))
                    (t (:background "#ecf0f1" :foreground "#425d78")))))))
    (when (eq theme 'amaranth-dark)
      (let ((custom--inhibit-theme-enable nil))
        (custom-theme-set-faces
         'amaranth-dark
         '(default ((((type graphic)) (:background "#282c34" :foreground "#e4e4ef"))
                    (t (:background "#000000" :foreground "#e4e4ef")))))))
    (my/setup-font)
    (my/tab-line-remove-borders)
    (my/apply-ui-font-size)))

(add-hook 'enable-theme-functions #'my/after-enable-theme)

(defun my/load-theme (theme)
  "Enable THEME after disabling every currently active theme."
  (dolist (enabled-theme (copy-sequence custom-enabled-themes))
    (disable-theme enabled-theme))
  (my/reset-tab-line-faces)
  (load-theme theme t))

(defun my/toggle-theme ()
  "Switch between the configured night and light themes."
  (interactive)
  (my/load-theme (if (seq-some (lambda (theme) (memq theme custom-enabled-themes))
                               (list my/night-theme my/alternate-night-theme))
                     my/light-theme
                   my/night-theme)))

(use-package chyla-dark-theme
  :ensure t
  :defer t)
(use-package amaranth-dark-theme
  :ensure t
  :defer t)
(use-package flatfluc-theme
  :ensure t
  :defer t)

(my/load-theme my/night-theme)
(global-set-key (kbd "C-c t t") #'my/toggle-theme)

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
