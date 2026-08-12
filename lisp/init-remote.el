;;; init-remote.el --- Fast remote development -*- lexical-binding: t -*-
;;; Code:

(use-package tramp
  :ensure t
  :demand t
  :config
  (when (version< tramp-version "2.8.1.4")
    (error "tramp-rpc requires TRAMP >= 2.8.1.4; loaded %s from %s"
           tramp-version (symbol-file 'tramp-version))))

(use-package msgpack
  :ensure t
  :defer t)

(use-package tramp-rpc
  :after tramp
  :vc (:url "https://github.com/ArthurHeymans/emacs-tramp-rpc"
       :rev :newest
       :lisp-dir "lisp")
  :init
  ;; VC checkouts otherwise require a local Rust toolchain for deployment.
  (setq tramp-rpc-deploy-git-build-policy 'release)
  :custom
  ;; Native Windows OpenSSH does not support Unix ControlMaster sockets.
  (tramp-rpc-use-controlmaster (not my/windows-p)))

(provide 'init-remote)
;;; init-remote.el ends here
