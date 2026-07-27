;;; init-org.el --- Org agenda and project workflow -*- lexical-binding: t -*-

(require 'cl-lib)
(require 'appt)
(require 'notifications nil t)

(setq org-directory (expand-file-name "org" (getenv "HOME")))

(defconst my/org-inbox-file (expand-file-name "inbox.org" org-directory))
(defconst my/org-work-file (expand-file-name "work.org" org-directory))
(defconst my/org-personal-file (expand-file-name "personal.org" org-directory))
(defconst my/org-calendar-file (expand-file-name "calendar.org" org-directory))
(defconst my/org-journal-file (expand-file-name "journal.org" org-directory))
(defconst my/org-action-files (list my/org-work-file my/org-personal-file))

(setq org-agenda-files (list my/org-inbox-file
                              my/org-work-file
                              my/org-personal-file
                              my/org-calendar-file)
      org-todo-keywords
      '((sequence "TODO(t)" "NEXT(n)" "WAITING(w@/!)"
                  "|" "DONE(d!)" "CANCELLED(c@/!)"))
      org-log-done 'time
      org-log-into-drawer t
      org-blank-before-new-entry '((heading . t) (plain-list-item . nil))
      org-refile-targets `((,my/org-work-file :maxlevel . 3)
                           (,my/org-personal-file :maxlevel . 3)
                           (,my/org-calendar-file :maxlevel . 2))
      org-refile-use-outline-path 'file
      org-outline-path-complete-in-steps nil
      org-refile-allow-creating-parent-nodes 'confirm
      org-archive-location "%s_archive::"
      org-agenda-span 1
      org-agenda-start-on-weekday nil
      org-agenda-skip-scheduled-if-done t
      org-agenda-skip-deadline-if-done t
      org-deadline-warning-days 7)

(defun my/org-refile-with-heading-only (targets)
  "Remove file-root entries that cannot receive a refiled subtree."
  (cl-remove-if-not (lambda (target) (nth 3 target)) targets))

(advice-add 'org-refile-get-targets :filter-return
            #'my/org-refile-with-heading-only)

(setq org-capture-templates
      `(("t" "Inbox" entry (file+headline ,my/org-inbox-file "Tasks")
         "* TODO %^{标题}\n  :PROPERTIES:\n  :CREATED: %U\n  :END:\n\n  %?\n" :prepend t)
        ("w" "工作任务" entry (file+headline ,my/org-work-file "Tasks")
         "* TODO %^{标题}\n  :PROPERTIES:\n  :CREATED: %U\n  :END:\n\n  %?\n" :prepend t)
        ("p" "个人任务" entry (file+headline ,my/org-personal-file "Life")
         "* TODO %^{标题}\n  :PROPERTIES:\n  :CREATED: %U\n  :END:\n\n  %?\n" :prepend t)
        ("W" "工作项目" entry (file+headline ,my/org-work-file "Projects")
         "* TODO %^{项目名称} [0/0]\n  :PROPERTIES:\n  :CREATED: %U\n  :END:\n\n  %?\n" :prepend t)
        ("P" "个人项目" entry (file+headline ,my/org-personal-file "Projects")
         "* TODO %^{项目名称} [0/0]\n  :PROPERTIES:\n  :CREATED: %U\n  :END:\n\n  %?\n" :prepend t)
        ("e" "日程或约会" entry (file+headline ,my/org-calendar-file "Events")
         "* %^{日程名称}\n  %^{开始时间}T\n\n  %?\n" :prepend t)
        ("j" "日记" entry (file+datetree ,my/org-journal-file)
         "* %?\n  %U\n" :empty-lines 1)))

(defun my/org-capture-template (key)
  "Capture with template KEY and focus its temporary editing buffer."
  (let ((my/tab-line-suspend-recording t))
    (org-capture nil key)
    (when-let* ((marker (org-capture-get :begin-marker))
                (buffer (marker-buffer marker)))
      (switch-to-buffer buffer))))

(defun my/org-capture-task ()
  "Capture a task in the inbox."
  (interactive)
  (my/org-capture-template "t"))

(defun my/org-capture-work-task ()
  "Capture a work task."
  (interactive)
  (my/org-capture-template "w"))

(defun my/org-capture-personal-task ()
  "Capture a personal task."
  (interactive)
  (my/org-capture-template "p"))

(defun my/org-capture-work-project ()
  "Capture a work project."
  (interactive)
  (my/org-capture-template "W"))

(defun my/org-capture-personal-project ()
  "Capture a personal project."
  (interactive)
  (my/org-capture-template "P"))

(defun my/org-capture-journal ()
  "Capture a journal entry."
  (interactive)
  (my/org-capture-template "j"))

(defun my/org-capture-event ()
  "Capture a calendar event."
  (interactive)
  (my/org-capture-template "e"))

(defvar my/org-capture-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "t") #'my/org-capture-task)
    (define-key map (kbd "w") #'my/org-capture-work-task)
    (define-key map (kbd "p") #'my/org-capture-personal-task)
    (define-key map (kbd "W") #'my/org-capture-work-project)
    (define-key map (kbd "P") #'my/org-capture-personal-project)
    (define-key map (kbd "e") #'my/org-capture-event)
    (define-key map (kbd "j") #'my/org-capture-journal)
    map)
  "Prefix map for direct Org capture templates.")

(defun my/org-inbox-count ()
  "Return the number of unfinished entries in the Inbox."
  (let ((count 0))
    (with-current-buffer (find-file-noselect my/org-inbox-file)
      (org-with-wide-buffer
       (org-element-map (org-element-parse-buffer) 'headline
         (lambda (headline)
           (when (member (org-element-property :todo-keyword headline)
                         org-not-done-keywords)
             (cl-incf count))))))
    count))

(setq org-agenda-custom-commands
      `(("d" "今日日程与下一步"
         ((agenda "" ((org-agenda-span 1)
                      (org-agenda-overriding-header
                       (format "今日日程（Inbox: %d 条待处理）" (my/org-inbox-count)))))
          (todo "NEXT" ((org-agenda-files ',my/org-action-files)
                        (org-agenda-overriding-header "下一步行动")))))
        ("i" "收件箱"
         ((alltodo "" ((org-agenda-files ',(list my/org-inbox-file))
                       (org-agenda-overriding-header "待分类内容")))))
        ("u" "未排期项目任务"
         ((todo "TODO" ((org-agenda-files ',my/org-action-files)
                        (org-agenda-skip-function '(org-agenda-skip-entry-if 'scheduled 'deadline))
                        (org-agenda-overriding-header "待拆分或待安排")))
          (todo "NEXT" ((org-agenda-files ',my/org-action-files)
                        (org-agenda-skip-function '(org-agenda-skip-entry-if 'scheduled 'deadline))
                        (org-agenda-overriding-header "可立即执行")))))
        ("p" "工作与个人回顾"
         ((todo "NEXT" ((org-agenda-files ',my/org-action-files)
                         (org-agenda-overriding-header "下一步行动")))
          (todo "WAITING" ((org-agenda-files ',my/org-action-files)
                            (org-agenda-overriding-header "等待中")))
          (todo "TODO" ((org-agenda-files ',my/org-action-files)
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

(with-eval-after-load 'org-capture
  (with-eval-after-load 'evil
    (add-hook 'org-capture-mode-hook #'evil-insert-state)
    (evil-define-key 'normal org-capture-mode-map
      (kbd "q") #'org-capture-kill)))

(defun my/calendar-show-agenda-at-mouse (event)
  "Show the daily Agenda for the Calendar date clicked in EVENT."
  (interactive "e")
  (mouse-set-point event)
  (org-agenda-list nil (calendar-cursor-to-date) 1))

(use-package calendar
  :ensure nil
  :demand t
  :custom
  (calendar-week-start-day 1)
  (calendar-mark-holidays-flag t)
  :config
  (define-key calendar-mode-map (kbd "<double-mouse-1>")
              #'my/calendar-show-agenda-at-mouse))

(use-package cal-china-x
  :ensure t
  :after calendar
  :config
  (setq cal-china-x-important-holidays cal-china-x-chinese-holidays
        calendar-holidays (append cal-china-x-important-holidays
                                  cal-china-x-general-holidays
                                  calendar-holidays)))

(ensure-lib-from-url
 'org-modern
 "https://raw.githubusercontent.com/minad/org-modern/1.6/org-modern.el")
(require 'org-modern)
(add-hook 'org-mode-hook #'org-modern-mode)
(add-hook 'org-agenda-finalize-hook #'org-modern-agenda)

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
