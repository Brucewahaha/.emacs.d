;;; local.example.el --- Machine-local configuration example -*- lexical-binding: t -*-

;; Copy this file to local.el and adjust it for the current machine.
;; local.el is intentionally ignored by Git.

;; Use official archives when the Tsinghua mirror is unavailable.
;; (setq my/package-archives-override
;;       '(("gnu" . "https://elpa.gnu.org/packages/")
;;         ("nongnu" . "https://elpa.nongnu.org/nongnu/")
;;         ("melpa" . "https://melpa.org/packages/")))

;; Add machine-specific tools such as LLVM, Git, Node, or a package manager.
;; (setq my/extra-exec-paths
;;       '("/opt/homebrew/opt/llvm/bin"
;;         "C:/Program Files/LLVM/bin"))

;; Provide a Windows Toast notification backend when BurntToast is installed.
;; (setq my/notification-function
;;       (lambda (title body)
;;         (when (executable-find "powershell.exe")
;;           (start-process
;;            "emacs-notification" nil "powershell.exe" "-NoProfile" "-Command"
;;            (format "New-BurntToastNotification -Text %S, %S" title body))
;;           t)))

;;; local.example.el ends here
