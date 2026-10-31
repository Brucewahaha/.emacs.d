;;; init-site-lisp.el --- Load path for manually installed libraries -*- lexical-binding: t -*-
;;; Commentary:

;; Put a library in site-lisp/ or in its own subdirectory, site-lisp/NAME/.
;; Git does not track empty directories, so a fresh clone creates it here.

;;; Code:

(let ((site-lisp-dir (expand-file-name "site-lisp/" user-emacs-directory)))
  (make-directory site-lisp-dir t)
  (push site-lisp-dir load-path)
  (dolist (directory (directory-files site-lisp-dir t "\\`[^.]"))
    (when (file-directory-p directory)
      (push directory load-path))))

(provide 'init-site-lisp)
;;; init-site-lisp.el ends here
