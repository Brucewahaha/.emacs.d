;;; local.example.el --- Machine-local configuration example -*- lexical-binding: t -*-

;; Copy this file to local.el and adjust it for the current machine.
;; local.el is intentionally ignored by Git.
;; It loads before the configuration modules.  Uncomment only the overrides
;; needed on this machine, then restart Emacs (including the daemon, if used).

;; Font heights are in 1/10 point: 140 = 14 pt, 130 = 13 pt.
;; Main editing text:
;; (setq my/buffer-font-height 140)
;; Mode-line, buffer tabs, header-line, minibuffer, and tooltip text:
;; (setq my/ui-font-height 130)
;; The operating system's window title bar is not controlled by these settings.

;; Font lists replace the defaults; the first installed font in each list wins.
;; Keep fallback fonts if this machine uses several GUI environments.
;; (setq my/programming-font-families '("JetBrains Mono" "monospace")
;;       my/cjk-font-families '("Noto Sans SC" "Microsoft YaHei")
;;       my/nerd-font-families '("Symbols Nerd Font Mono")
;;       my/symbol-font-families '("Noto Sans Symbols 2" "DejaVu Sans")
;;       my/emoji-font-families '("Noto Color Emoji" "Segoe UI Emoji"))
;; Font settings apply to GUI frames; terminal fonts are set in the terminal app.

;; Initial size of each new GUI frame, including daemon clients.
;; Width is in character columns; height is in text rows, not pixels.
;; (setq my/initial-frame-settings '((width . 120) (height . 40)))
;; Alternatively, start maximized (not operating-system fullscreen):
;; (setq my/initial-frame-settings '((fullscreen . maximized)))
;; Leave unset to let Emacs/the window manager choose.  Existing frames are not
;; resized again by configuration reloads; terminal frames are not resized.


;; Use official archives when the Tsinghua mirror is unavailable.
;; (setq my/package-archives-override
;;       '(("gnu" . "https://elpa.gnu.org/packages/")
;;         ("nongnu" . "https://elpa.nongnu.org/nongnu/")
;;         ("melpa" . "https://melpa.org/packages/")))

;; Override the local folder used for the synchronized Org files.  The default
;; is %USERPROFILE%/org on Windows and ~/org on Linux/macOS.
;; (setq my/org-directory "D:/Documents/org")

;; Add machine-specific tools such as LLVM, Git, Node, or a package manager.
;; (setq my/extra-exec-paths
;;       (cond
;;        ((eq system-type 'darwin)
;;         '("/opt/homebrew/bin" "/opt/homebrew/opt/llvm/bin"))
;;        ((eq system-type 'windows-nt)
;;         '("C:/Program Files/LLVM/bin"))
;;        (t
;;         '("~/.local/bin"))))

;; Choose the shell launched by Eat on Linux, WSL, or macOS.
;; Native Windows uses Eshell instead of Eat.
;; (setq my/preferred-shell "/bin/zsh")

;; Provide a Windows Toast notification backend when BurntToast is installed.
;; (setq my/notification-function
;;       (lambda (title body)
;;         (when (executable-find "powershell.exe")
;;           (start-process
;;            "emacs-notification" nil "powershell.exe" "-NoProfile" "-Command"
;;            (format "New-BurntToastNotification -Text %S, %S" title body))
;;           t)))

;; Inspect local settings and tool paths with M-x my/check-local-environment.


;;; local.example.el ends here
