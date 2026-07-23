;;; init-org.el --- Org agenda and project workflow -*- lexical-binding: t -*-

(require 'appt)
(require 'notifications nil t)

(setq org-directory (expand-file-name "org" (getenv "HOME")))

(defconst my/org-inbox-file (expand-file-name "inbox.org" org-directory))
(defconst my/org-projects-file (expand-file-name "projects.org" org-directory))
(defconst my/org-calendar-file (expand-file-name "calendar.org" org-directory))

(setq org-agenda-files (list my/org-inbox-file
                             my/org-projects-file
                             my/org-calendar-file)
      org-todo-keywords
      '((sequence "TODO(t)" "NEXT(n)" "STARTED(s)" "WAITING(w@/!)"
                  "|" "DONE(d!)" "CANCELLED(c@/!)"))
      org-log-done 'time
      org-log-into-drawer t
      org-blank-before-new-entry '((heading . t) (plain-list-item . nil))
      org-refile-targets '((org-agenda-files :maxlevel . 3))
      org-refile-use-outline-path 'file
      org-refile-allow-creating-parent-nodes 'confirm
      org-archive-location "%s_archive::"
      org-agenda-span 1
      org-agenda-start-on-weekday nil
      org-agenda-skip-scheduled-if-done t
      org-agenda-skip-deadline-if-done t
      org-deadline-warning-days 7)

(setq org-capture-templates
      `(("t" "Inbox 任务" entry (file+headline ,my/org-inbox-file "Tasks")
         "* TODO %?\n  :PROPERTIES:\n  :CREATED: %U\n  :END:\n" :prepend t)
        ("p" "项目与下一步" entry (file+headline ,my/org-projects-file "Projects")
         "* TODO %^{项目名称} [0/0]\n  :PROPERTIES:\n  :CREATED: %U\n  :END:\n\n** NEXT %?\n" :prepend t)
        ("e" "日程或约会" entry (file+headline ,my/org-calendar-file "Events")
         "* %^{日程名称}\n  %^T\n\n  %?\n" :prepend t)))

(defun my/org-capture-template (key)
  "Capture with template KEY in a focused bottom window."
  (org-capture nil key)
  (when-let* ((marker (org-capture-get :begin-marker))
              (buffer (marker-buffer marker)))
    (pop-to-buffer buffer)))

(defun my/org-capture-task ()
  "Capture a task in the inbox."
  (interactive)
  (my/org-capture-template "t"))

(defun my/org-capture-project ()
  "Capture a project."
  (interactive)
  (my/org-capture-template "p"))

(defun my/org-capture-event ()
  "Capture a calendar event."
  (interactive)
  (my/org-capture-template "e"))

(defvar my/org-capture-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "t") #'my/org-capture-task)
    (define-key map (kbd "p") #'my/org-capture-project)
    (define-key map (kbd "e") #'my/org-capture-event)
    map)
  "Prefix map for direct Org capture templates.")

(add-to-list 'display-buffer-alist
             '("\\`CAPTURE-.*\\'"
               (display-buffer-reuse-window display-buffer-at-bottom)
               (window-height . 0.35)))

(setq org-agenda-custom-commands
      `(("d" "今日日程与下一步"
         ((agenda "" ((org-agenda-span 1)
                      (org-agenda-overriding-header "今日日程")))
          (todo "NEXT" ((org-agenda-overriding-header "下一步行动")))
          (todo "STARTED" ((org-agenda-overriding-header "进行中")))))
        ("i" "收件箱"
         todo "TODO"
         ((org-agenda-files ',(list my/org-inbox-file))
          (org-agenda-overriding-header "待分类任务")))
        ("p" "项目回顾"
         ((todo "NEXT" ((org-agenda-files ',(list my/org-projects-file))
                        (org-agenda-overriding-header "下一步行动")))
          (todo "STARTED" ((org-agenda-files ',(list my/org-projects-file))
                           (org-agenda-overriding-header "进行中")))
          (todo "WAITING" ((org-agenda-files ',(list my/org-projects-file))
                           (org-agenda-overriding-header "等待中")))
          (todo "TODO" ((org-agenda-files ',(list my/org-projects-file))
                        (org-agenda-overriding-header "待拆分或待安排")))))))

(defun my/org-agenda-enter-evil-normal-state ()
  "Enter Evil Normal state when an Org Agenda buffer is created."
  (evil-normal-state))

(with-eval-after-load 'org-agenda
  (evil-set-initial-state 'org-agenda-mode 'normal)
  (add-hook 'org-agenda-mode-hook #'my/org-agenda-enter-evil-normal-state)
  (evil-define-key 'normal org-agenda-mode-map
    (kbd "g j") #'org-agenda-goto-date
    (kbd "g t") #'org-agenda-goto-today
    (kbd "t") #'org-agenda-todo
    (kbd "s") #'org-agenda-schedule
    (kbd "r") #'org-agenda-redo
    (kbd "a") #'org-agenda-archive-default
    (kbd "RET") #'org-agenda-switch-to
    (kbd "TAB") #'org-agenda-goto
    (kbd "q") #'org-agenda-quit))

(defun my/org-appt-display (minutes time message)
  "Display an appointment notification MINUTES before TIME with MESSAGE."
  (when (fboundp 'notifications-notify)
    (notifications-notify
     :title (format "%s 分钟后有日程" minutes)
     :body (format "%s (%s)" message time)
     :urgency 'normal))
  (appt-disp-window minutes time message))

(defun my/org-refresh-appts ()
  "Refresh appointment reminders from the configured agenda files."
  (interactive)
  (org-agenda-to-appt t))

(setq appt-message-warning-time 30
      appt-display-interval 10
      appt-display-mode-line t
      appt-display-diary nil
      appt-disp-window-function #'my/org-appt-display)
(appt-activate 1)
(add-hook 'after-init-hook #'my/org-refresh-appts)
(run-at-time 300 600 #'my/org-refresh-appts)

(global-set-key (kbd "C-c l") #'org-store-link)
(global-set-key (kbd "C-c a") #'org-agenda)
(global-set-key (kbd "C-c c") my/org-capture-map)

(provide 'init-org)
;;; init-org.el ends here
