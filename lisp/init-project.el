;;; init-project.el --- Project management and Git -*- lexical-binding: t -*-
;;; Commentary:
;;; Code:

(require 'project)

(defconst my/build-system-commands
  '(("CMakeLists.txt" . "cmake -S . -B build && cmake --build build")
    ("Makefile" . "make")
    ("makefile" . "make")
    ("GNUmakefile" . "make")
    ("Cargo.toml" . "cargo build")
    ("go.mod" . "go build ./..."))
  "Build files and the command that builds from the directory holding them.")

(defvar-local my/compile-directory nil
  "Directory where this buffer's `compile-command' runs.")

(defun my/build-system-command (directory)
  "Return the build command for the build file in DIRECTORY, if any."
  (seq-some (lambda (entry)
              (and (file-exists-p (expand-file-name (car entry) directory))
                   (cdr entry)))
            my/build-system-commands))

(defun my/single-file-compile-command ()
  "Return a command that builds and runs the current file on its own."
  (when buffer-file-name
    (let ((file (shell-quote-argument
                 (file-name-nondirectory buffer-file-name)))
          (program (shell-quote-argument
                    (concat "./" (file-name-base buffer-file-name)))))
      ;; C++ first: Emacs 30 treats `c++-ts-mode' as derived from `c++-mode',
      ;; and `c-ts-mode' as derived from `c-mode'.
      (cond
       ((derived-mode-p 'c++-mode)
        (format "g++ -std=c++17 -Wall -Wextra -g %s -o %s && %s"
                file program program))
       ((derived-mode-p 'c-mode)
        (format "gcc -std=c17 -Wall -Wextra -g %s -o %s && %s"
                file program program))
       ((derived-mode-p 'rust-mode 'rust-ts-mode)
        (format "rustc -g %s -o %s && %s" file program program))
       ((derived-mode-p 'go-mode 'go-ts-mode)
        (format "go run %s" file))
       ((derived-mode-p 'python-base-mode)
        (format "python3 %s" file))
       ((derived-mode-p 'sh-base-mode)
        (format "bash %s" file))))))

(defun my/setup-compile-command ()
  "Pick a default `compile-command' for this buffer.
Prefer a build file at the project root, then one beside the file, then a
command for the file alone."
  (let* ((project (project-current nil))
         (root (and project (project-root project)))
         (here default-directory)
         command directory)
    (cond
     ((and root (setq command (my/build-system-command root)))
      (setq directory root))
     ((setq command (my/build-system-command here))
      (setq directory here))
     ((setq command (my/single-file-compile-command))
      (setq directory here)))
    (when command
      (setq-local compile-command command
                  my/compile-directory directory))))

(defun my/compile-directory ()
  "Return the directory compilation of the current buffer runs in."
  (or my/compile-directory
      (when-let ((project (project-current nil)))
        (project-root project))
      default-directory))

(defun my/project-compilation-buffer ()
  "Return the compilation buffer for the current buffer's build, if any."
  (let ((directory (my/compile-directory)))
    (seq-find
     (lambda (buffer)
       (with-current-buffer buffer
         (and (eq major-mode 'compilation-mode)
              (file-equal-p default-directory directory))))
     (buffer-list))))

(defun my/project-compile ()
  "Save modified buffers and compile with this buffer's build command.
A `compile-command' from `.dir-locals.el', a file-local variable or an
earlier run in this buffer is kept; otherwise a default is chosen once."
  (interactive)
  (save-some-buffers t)
  (unless (local-variable-p 'compile-command)
    (my/setup-compile-command))
  (let ((default-directory (my/compile-directory)))
    (call-interactively #'compile)))

(defun my/project-recompile ()
  "Save modified buffers and repeat the current project's last compilation."
  (interactive)
  (save-some-buffers t)
  (if-let ((buffer (my/project-compilation-buffer)))
      (with-current-buffer buffer
        (recompile))
    (my/project-compile)))

(defun my/compilation-reuse-source-window (original msg mk end-mk)
  "Visit compilation locations in an existing source window when possible."
  (let* ((source (marker-buffer mk))
         ;; Scope this rule to the destination, leaving Popper's compilation
         ;; output placement alone.  Split only if no usable window exists.
         (display-buffer-alist
          (cons (list (lambda (buffer _action) (eq buffer source))
                      '(display-buffer-reuse-window
                        display-buffer-use-some-window
                        display-buffer-pop-up-window)
                      '(some-window . mru)
                      '(inhibit-same-window . t))
                display-buffer-alist)))
    (funcall original msg mk end-mk)))

(use-package compile
  :ensure nil
  :bind (("C-c b c" . my/project-compile)
         ("C-c b r" . my/project-recompile))
  :hook (compilation-filter . ansi-color-compilation-filter)
  :custom
  ;; Leave plain M-x compile empty until a command has been used or supplied
  ;; by local variables.  C-c b c still suggests a project/single-file build.
  (compile-command "")
  (compilation-always-kill t)
  (compilation-scroll-output t)
  :config
  (advice-add 'compilation-goto-locus :around
              #'my/compilation-reuse-source-window))

;; Keep the familiar prefix while using Emacs' built-in project commands.
(global-set-key (kbd "C-c p") project-prefix-map)

;; Magit: 最好的 Git 客户端
(use-package magit
  :ensure t
  :bind ("C-x g" . magit-status))

(provide 'init-project)
;;; init-project.el ends here
