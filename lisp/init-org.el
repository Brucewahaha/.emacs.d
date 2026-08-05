;;; init-org.el --- Org agenda and project workflow -*- lexical-binding: t -*-

(require 'cl-lib)
(require 'appt)
(require 'notifications nil t)
(require 'subr-x)

(defvar my/org-directory nil
  "Optional machine-local path to the synchronized Org directory.")

(setq org-directory
      (file-name-as-directory
       (expand-file-name
        (or my/org-directory
            (if my/windows-p
                (expand-file-name
                 "org" (or (getenv "USERPROFILE") (getenv "HOME") "~"))
              "~/org")))))

(defconst my/org-inbox-file (expand-file-name "inbox.org" org-directory))
(defconst my/org-work-file (expand-file-name "work.org" org-directory))
(defconst my/org-personal-file (expand-file-name "personal.org" org-directory))
(defconst my/org-calendar-file (expand-file-name "calendar.org" org-directory))
(defconst my/org-journal-file (expand-file-name "journal.org" org-directory))
(defconst my/org-notes-file (expand-file-name "notes.org" org-directory))
(defconst my/org-archive-directory
  (file-name-as-directory (expand-file-name "archive" org-directory)))
(defconst my/org-action-files (list my/org-work-file my/org-personal-file))

(defconst my/org-initial-files
  `((,my/org-inbox-file . "#+TITLE: Inbox\n\n* Tasks\n\n* Thoughts\n")
    (,my/org-work-file . "#+TITLE: Work\n\n* Tasks\n\n* Projects\n")
    (,my/org-personal-file . "#+TITLE: Personal\n\n* Projects\n\n* Life\n\n* Someday\n")
    (,my/org-calendar-file . "#+TITLE: Calendar\n\n* Events\n")
    (,my/org-journal-file . "#+TITLE: Journal\n")
    (,my/org-notes-file . "#+TITLE: Notes\n\n* Ideas\n\n* Quotes\n\n* Insights\n"))
  "Org files and their initial contents.")

(defun my/org-ensure-files ()
  "Create the configured Org directory and missing workflow files."
  (make-directory org-directory t)
  (make-directory my/org-archive-directory t)
  (dolist (entry my/org-initial-files)
    (unless (file-exists-p (car entry))
      (with-temp-file (car entry)
        (insert (cdr entry))))))

(my/org-ensure-files)

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
                           (,my/org-calendar-file :maxlevel . 2)
                           (,my/org-notes-file :maxlevel . 2))
      org-refile-use-outline-path 'file
      org-outline-path-complete-in-steps nil
      org-refile-allow-creating-parent-nodes 'confirm
      org-archive-location
      (concat my/org-archive-directory "%s_archive::")
      org-agenda-span 1
      org-agenda-start-on-weekday nil
      org-agenda-format-date "%Y-%m-%d %A"
      org-agenda-time-leading-zero t
      org-agenda-prefix-format
      '((agenda . "  %?-5t %-10:c %s")
        (todo . "  %-10:c")
        (tags . "  %-10:c")
        (search . "  %-10:c"))
      org-agenda-time-grid
      '((daily today require-timed remove-match)
        (800 1000 1200 1400 1600 1800 2000)
        "......" "----------------")
      org-agenda-scheduled-leaders '("计划: " "已延期 %2d 天: ")
      org-agenda-deadline-leaders
      '("今天截止: " "剩余 %2d 天: " "逾期 %2d 天: ")
      org-agenda-skip-scheduled-if-done t
      org-agenda-skip-deadline-if-done t
      org-deadline-warning-days 7)

(defun my/org-refile-with-heading-only (targets)
  "Remove file-root entries that cannot receive a refiled subtree."
  (cl-remove-if-not (lambda (target) (nth 3 target)) targets))

(advice-add 'org-refile-get-targets :filter-return
            #'my/org-refile-with-heading-only)

(defun my/org-created-at ()
  "Return a plain inactive creation timestamp including seconds."
  (format-time-string "[%Y-%m-%d %a %H:%M:%S]"))

(defun my/org-read-tags ()
  "Prompt for optional tags and return them in Org headline syntax."
  (let ((tags
         (seq-remove
          #'string-empty-p
          (mapcar #'string-trim
                  (completing-read-multiple
                   "Tags (empty to skip): "
                   (org-global-tags-completion-table) nil nil)))))
    (if tags (concat " :" (string-join tags ":") ":") "")))

(defun my/org-read-optional-date (prompt)
  "Read an optional Org date using PROMPT and return an active timestamp."
  (let ((input (string-trim
                (read-string (format "%s (empty to skip): " prompt)))))
    (unless (string-empty-p input)
      (format "<%s>" (org-read-date nil nil input)))))

(defun my/org-inbox-template ()
  "Build an Inbox task template with optional tags and planning dates."
  (let ((title (read-string "Title: "))
        (tags (my/org-read-tags))
        (scheduled (my/org-read-optional-date "Scheduled"))
        (deadline (my/org-read-optional-date "Deadline")))
    (concat
     "* TODO " title tags "\n"
     (string-join
      (delq nil
            (list (and scheduled (format "  SCHEDULED: %s" scheduled))
                  (and deadline (format "  DEADLINE: %s" deadline))
                  (format "  %s" (my/org-created-at))))
      "\n")
     "\n\n  %?\n")))

(setq org-capture-templates
      `(("i" "Inbox")
        ("it" "Task" entry (file+headline ,my/org-inbox-file "Tasks")
         (function my/org-inbox-template)
         :prepend t)
        ("in" "Thought" entry (file+headline ,my/org-inbox-file "Thoughts")
         "* %^{标题}\n  %(my/org-created-at)\n\n  %?\n" :prepend t)
        ("w" "Work")
        ("wt" "Task" entry (file+headline ,my/org-work-file "Tasks")
         "* TODO %^{标题}\n  :PROPERTIES:\n  :CREATED: %U\n  :END:\n\n  %?\n" :prepend t)
        ("wp" "Project" entry (file+headline ,my/org-work-file "Projects")
         "* TODO %^{项目名称} [0/0]\n  :PROPERTIES:\n  :CREATED: %U\n  :END:\n\n  %?\n" :prepend t)
        ("p" "Personal")
        ("pl" "Life" entry (file+headline ,my/org-personal-file "Life")
         "* TODO %^{标题}\n  :PROPERTIES:\n  :CREATED: %U\n  :END:\n\n  %?\n" :prepend t)
        ("pp" "Project" entry (file+headline ,my/org-personal-file "Projects")
         "* TODO %^{项目名称} [0/0]\n  :PROPERTIES:\n  :CREATED: %U\n  :END:\n\n  %?\n" :prepend t)
        ("ps" "Someday" entry (file+headline ,my/org-personal-file "Someday")
         "* TODO %^{标题}\n  :PROPERTIES:\n  :CREATED: %U\n  :END:\n\n  %?\n" :prepend t)
        ("n" "Notes")
        ("ni" "Idea" entry (file+headline ,my/org-notes-file "Ideas")
         "* %^{标题}\n  %(my/org-created-at)\n\n  %?\n" :prepend t)
        ("nq" "Quote" entry (file+headline ,my/org-notes-file "Quotes")
         "* %^{标题}\n  %(my/org-created-at)\n\n  %?\n" :prepend t)
        ("nv" "Insight" entry (file+headline ,my/org-notes-file "Insights")
         "* %^{标题}\n  %(my/org-created-at)\n\n  %?\n" :prepend t)
        ("c" "Calendar")
        ("ce" "Event" entry (file+headline ,my/org-calendar-file "Events")
         "* %^{日程名称}\n  %^{日期与时间（可输入时间段）}T\n\n  %?\n" :prepend t)
        ("j" "Journal")
        ("je" "Entry" plain (file+olp+datetree ,my/org-journal-file)
         "%U\n%?\n" :empty-lines 1)))

(defun my/org-capture ()
  "Open the grouped Org Capture menu and focus its editing buffer."
  (interactive)
  (org-capture)
  (when-let* ((marker (org-capture-get :begin-marker))
              (buffer (marker-buffer marker)))
    (switch-to-buffer buffer)))

(defun my/org-inbox-count ()
  "Return the number of unprocessed task and thought entries in the Inbox."
  (let ((count 0))
    (with-current-buffer (find-file-noselect my/org-inbox-file)
      (org-with-wide-buffer
       (org-element-map (org-element-parse-buffer) 'headline
         (lambda (headline)
           (when (and (= (org-element-property :level headline) 2)
                      (not (member (org-element-property :todo-keyword headline)
                                   org-done-keywords)))
             (cl-incf count))))))
    count))

(defun my/org-agenda-skip-completed-entry ()
  "Skip the current Agenda entry when its TODO state is completed."
  (when (member (org-get-todo-state) org-done-keywords)
    (org-end-of-subtree t)))

(defun my/org-agenda-skip-unless-under-heading (heading)
  "Skip the current Agenda entry unless it is below HEADING."
  (unless (member heading (org-get-outline-path))
    (org-end-of-subtree t)))

(setq org-agenda-custom-commands
      `(("d" "今日日程与下一步"
         ((agenda "" ((org-agenda-span 1)
                      (org-agenda-overriding-header
                       (format "今日日程（Inbox: %d 条待处理）" (my/org-inbox-count)))))
          (todo "NEXT" ((org-agenda-files ',my/org-action-files)
                        (org-agenda-overriding-header "下一步行动")))))
        ("w" "本周任务与日程" agenda ""
         ((org-agenda-span 'week)
          (org-agenda-start-on-weekday 1)
          (org-agenda-use-time-grid nil)
          (org-deadline-warning-days 0)
          (org-agenda-overriding-header "本周任务与日程")))
        ("o" "本月任务与日程" agenda ""
         ((org-agenda-span 'month)
          (org-agenda-start-day (format-time-string "%Y-%m-01"))
          (org-agenda-start-on-weekday nil)
          (org-agenda-show-all-dates nil)
          (org-agenda-use-time-grid nil)
          (org-deadline-warning-days 0)
          (org-agenda-overriding-header "本月任务与日程")))
        ("i" "收件箱"
         ((tags "LEVEL=2"
                ((org-agenda-files ',(list my/org-inbox-file))
                 (org-agenda-skip-function #'my/org-agenda-skip-completed-entry)
                 (org-agenda-overriding-header "待分类任务与想法")))))
        ("f" "未来计划"
         ((search "."
                  ((org-agenda-files ',(list my/org-notes-file))
                   (org-agenda-skip-function
                    '(my/org-agenda-skip-unless-under-heading "Ideas"))
                   (org-agenda-overriding-header "未来计划")))))
        ("p" "工作与个人任务回顾"
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
    (kbd "h") #'org-agenda-earlier
    (kbd "l") #'org-agenda-later
    (kbd ".") #'org-agenda-goto-today
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

(defun my/calfw-apply-theme-colors (&rest _)
  "Apply semantic colors from the current theme to Calfw."
  (when (featurep 'calfw)
    (set-face-attribute 'calfw-title-face nil
                        :inherit 'org-level-1
                        :foreground 'unspecified
                        :background 'unspecified
                        :height 1.2)
    (set-face-attribute 'calfw-header-face nil
                        :inherit 'font-lock-keyword-face
                        :foreground 'unspecified
                        :background 'unspecified
                        :weight 'bold)
    (set-face-attribute 'calfw-sunday-face nil
                        :inherit 'error
                        :foreground 'unspecified
                        :background 'unspecified)
    (set-face-attribute 'calfw-saturday-face nil
                        :inherit 'font-lock-constant-face
                        :foreground 'unspecified
                        :background 'unspecified)
    (set-face-attribute 'calfw-holiday-face nil
                        :inherit 'warning
                        :foreground 'unspecified
                        :background 'unspecified)
    (set-face-attribute 'calfw-grid-face nil
                        :inherit 'shadow
                        :foreground 'unspecified
                        :background 'unspecified)
    (set-face-attribute 'calfw-default-content-face nil
                        :inherit 'default
                        :foreground 'unspecified
                        :background 'unspecified)
    (set-face-attribute 'calfw-periods-face nil
                        :inherit 'font-lock-keyword-face
                        :foreground 'unspecified
                        :background 'unspecified)
    (set-face-attribute 'calfw-today-title-face nil
                        :inherit 'highlight
                        :foreground 'unspecified
                        :background 'unspecified
                        :weight 'bold)
    (set-face-attribute 'calfw-today-face nil
                        :inherit 'highlight
                        :foreground 'unspecified
                        :background 'unspecified)
    (set-face-attribute 'calfw-toolbar-face nil
                        :inherit 'mode-line-inactive
                        :foreground 'unspecified
                        :background 'unspecified)
    (set-face-attribute 'calfw-toolbar-button-off-face nil
                        :inherit 'mode-line-inactive
                        :foreground 'unspecified
                        :background 'unspecified)
    (set-face-attribute 'calfw-toolbar-button-on-face nil
                        :inherit 'mode-line
                        :foreground 'unspecified
                        :background 'unspecified
                        :weight 'bold)))

(defun my/calfw-align-cell-pixels (render-function width &rest arguments)
  "Pad a Calfw cell rendered by RENDER-FUNCTION to WIDTH in pixels."
  (let ((text (apply render-function width arguments)))
    (if (and (display-graphic-p)
             (derived-mode-p 'calfw-calendar-mode))
        (let ((missing (- (string-pixel-width (make-string width ?\s))
                          (string-pixel-width text))))
          (if (> missing 0)
              (concat text
                      (propertize " " 'display
                                  `(space :width (,missing))))
            text))
      text)))

(defun my/org-open-visual-calendar ()
  "Open a theme-aware monthly calendar sourced from Org Agenda files."
  (interactive)
  (require 'calfw-org)
  (org-agenda-prepare-buffers org-agenda-files)
  (calfw-org-open-calendar
   nil "Org"
   (or (face-foreground 'font-lock-keyword-face nil t) "SteelBlue")
   :view 'month))

(use-package calfw
  :ensure t
  :defer t
  :init
  (setq calfw-org-overwrite-default-keybinding t)
  :config
  (dolist (function '(calfw--render-center calfw--render-left
                      calfw--render-right calfw--render-add-right))
    (advice-add function :around #'my/calfw-align-cell-pixels))
  (my/calfw-apply-theme-colors)
  (advice-add 'my/load-theme :after #'my/calfw-apply-theme-colors)
  (with-eval-after-load 'evil
    (when (fboundp 'evil-set-initial-state)
      (evil-set-initial-state 'calfw-calendar-mode 'motion)
      (evil-define-key 'motion calfw-calendar-mode-map
        (kbd "h") #'calfw-navi-previous-day-command
        (kbd "l") #'calfw-navi-next-day-command
        (kbd "k") #'calfw-navi-previous-week-command
        (kbd "j") #'calfw-navi-next-week-command
        (kbd "g j") #'calfw-org-goto-date
        (kbd "g t") #'calfw-navi-goto-today-command
        (kbd "v d") #'calfw-change-view-day
        (kbd "v w") #'calfw-change-view-week
        (kbd "v m") #'calfw-change-view-month
        (kbd "SPC") #'calfw-org-open-agenda-day
        (kbd "RET") #'calfw-org-onclick
        (kbd "r") #'calfw-refresh-calendar-buffer
        (kbd "q") #'bury-buffer))))

(use-package calfw-org
  :ensure t
  :after calfw
  :defer t)

(use-package org-modern
  :ensure t
  :hook ((org-mode . org-modern-mode)
         (org-agenda-finalize . org-modern-agenda)))

(defun my/org-appt-display (minutes time message)
  "Display an appointment notification MINUTES before TIME with MESSAGE."
  (my/notify (format "%s 分钟后有日程" minutes)
             (format "%s (%s)" message time))
  (appt-disp-window minutes time message))

(defun my/org-refresh-appts ()
  "Refresh appointment reminders from the configured agenda files."
  (interactive)
  (org-agenda-to-appt t))

(defun my/org-refresh-after-revert ()
  "Refresh generated Org views after a synced Org file is reverted."
  (when (derived-mode-p 'org-mode)
    (when (get-buffer "*Org Agenda*")
      (org-agenda-redo-all))
    (my/org-refresh-appts)))

(add-hook 'after-revert-hook #'my/org-refresh-after-revert)

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
(global-set-key (kbd "C-c c") #'my/org-capture)
(global-set-key (kbd "C-c C") #'my/org-open-visual-calendar)

(provide 'init-org)
;;; init-org.el ends here
