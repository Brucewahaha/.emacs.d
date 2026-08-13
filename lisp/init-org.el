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

(defun my/org-missing-files ()
  "Return configured Org workflow files that do not exist."
  (seq-filter (lambda (entry) (not (file-exists-p (car entry))))
              my/org-initial-files))

(defun my/org-initialize-files ()
  "Create the configured Org directory and missing workflow files."
  (interactive)
  (make-directory org-directory t)
  (make-directory my/org-archive-directory t)
  (dolist (entry (my/org-missing-files))
    (with-temp-file (car entry)
      (insert (cdr entry)))))

(defun my/org-ensure-files-for-use (&rest _)
  "Offer to initialize missing Org workflow files before use."
  (let ((missing (my/org-missing-files))
        (archive-missing (not (file-directory-p my/org-archive-directory))))
    (when (or missing archive-missing)
      (unless (yes-or-no-p
               (format "Org 工作流缺少 %s，是否按默认结构初始化？ "
                       (string-join
                        (append
                         (mapcar (lambda (entry)
                                   (file-name-nondirectory (car entry)))
                                 missing)
                         (and archive-missing '("archive/")))
                        ", ")))
        (user-error "Org 工作流尚未初始化"))
      (my/org-initialize-files)))
  (my/org-start-appt-reminders))

(advice-add 'org-agenda :before #'my/org-ensure-files-for-use)
(advice-add 'org-capture :before #'my/org-ensure-files-for-use)

(setq org-agenda-files (list my/org-inbox-file
                              my/org-work-file
                              my/org-personal-file
                              my/org-calendar-file)
      org-todo-keywords
      '((sequence "TODO(t)" "NEXT(n)" "WAITING(w@/!)"
                  "|" "DONE(d!)" "CANCELLED(c@/!)"))
      org-log-done 'time
      org-log-into-drawer t
      org-tags-column 0
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
      org-agenda-breadcrumbs-separator " › "
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
  "Return a plain inactive creation timestamp with minute precision."
  (format-time-string "[%Y-%m-%d %a %H:%M]"))

(defvar vertico-preselect)

(defun my/org-read-tags ()
  "Prompt for optional tags and return them in Org headline syntax."
  (let* ((vertico-preselect 'prompt)
         (tags
          (seq-remove
           #'string-empty-p
           (mapcar #'string-trim
                   (completing-read-multiple
                    "Tags (empty to skip): "
                    (org-global-tags-completion-table) nil nil)))))
    (if tags (concat " :" (string-join tags ":") ":") "")))

(defun my/org-agenda-relative-indent ()
  "Indent Agenda items four spaces per level below a top-level task."
  (make-string (* 4 (max 0 (- (org-outline-level) 2))) ?\s))

(defun my/org-capture-properties (&optional source)
  "Return the common property drawer, optionally including SOURCE."
  (concat "  :PROPERTIES:\n"
          (format "  :CREATED: %s\n" (my/org-created-at))
          (if source (format "  :SOURCE: %s\n" source) "")
          "  :END:\n"))

(defun my/org-task-template ()
  "Build the common task template."
  (concat "* TODO " (read-string "Title: ") (my/org-read-tags) "\n"
          (my/org-capture-properties)
          "\n  %?\n"))

(defun my/org-project-template ()
  "Build a TODO or NEXT project, optionally with its first action."
  (let* ((state (completing-read "Project state: " '("TODO" "NEXT") nil t))
         (title (read-string "Project: "))
         (tags (my/org-read-tags))
         (first-action (and (string= state "NEXT")
                            (string-trim
                             (read-string "First next action (empty to skip): ")))))
    (when (string-empty-p (or first-action ""))
      (setq first-action nil))
    (concat "* " state " " title (if first-action " [/]" "") tags "\n"
            (my/org-capture-properties)
            "\n  %?\n"
            (if first-action (concat "** NEXT " first-action "\n") ""))))

(defun my/org-note-template (&optional quote)
  "Build the common note template; when QUOTE is non-nil, prompt for source."
  (let ((title (read-string "Title: "))
        (tags (my/org-read-tags))
        (source (and quote (read-string "Source: "))))
    (concat "* " title tags "\n"
            (my/org-capture-properties source)
            "\n  %?\n")))

(defun my/org-quote-template ()
  "Build a quote template with source metadata."
  (my/org-note-template t))

(defun my/org-next-projects ()
  "Return completion candidates for NEXT projects in Work and Personal."
  (let (projects)
    (dolist (file (list my/org-work-file my/org-personal-file))
      (when (file-readable-p file)
        (with-current-buffer (find-file-noselect file)
          (org-with-wide-buffer
           (org-map-entries
            (lambda ()
              (when (and (string= (org-get-todo-state) "NEXT")
                         (save-excursion
                           (org-up-heading-safe)
                           (string= (org-get-heading t t t t) "Projects")))
                (let ((marker (copy-marker (point)))
                      (title (org-get-heading t t t t)))
                  (push (cons (format "%s — %s"
                                      (file-name-base file) title)
                              marker)
                        projects))))
            nil 'file)))))
    (nreverse projects)))

(defun my/org-capture-next-project-target ()
  "Move point to the end of a selected NEXT project for Org Capture."
  (let* ((projects (my/org-next-projects))
         (choice (completing-read "NEXT project: " projects nil t))
         (marker (cdr (assoc choice projects))))
    (unless marker
      (user-error "没有可用的 NEXT 项目"))
    (set-buffer (marker-buffer marker))
    (goto-char marker)))

(defun my/org-read-checkboxes ()
  "Read checkbox items until an empty value is entered."
  (let (items item)
    (while (not (string-empty-p
                 (setq item (string-trim
                             (read-string "Checkbox (empty to finish): ")))))
      (push (format "   - [ ] %s" item) items))
    (if items (concat "\n" (string-join (nreverse items) "\n") "\n") "")))

(defun my/org-project-subtask-template ()
  "Build a subtask with state, title and optional checkbox items."
  (let ((state (completing-read "Task state: "
                                '("TODO" "NEXT" "WAITING") nil t))
        (title (read-string "Title: ")))
    (concat "* " state " " title "\n"
            (my/org-read-checkboxes)
            "\n  %?\n")))

(setq org-capture-templates
      `(("i" "Inbox")
        ("it" "Task" entry (file+headline ,my/org-inbox-file "Tasks")
          (function my/org-task-template)
          :prepend t)
        ("in" "Thought" entry (file+headline ,my/org-inbox-file "Thoughts")
          (function my/org-note-template) :prepend t)
        ("w" "Work")
        ("wt" "Task" entry (file+headline ,my/org-work-file "Tasks")
          (function my/org-task-template) :prepend t)
        ("wp" "Project" entry (file+headline ,my/org-work-file "Projects")
          (function my/org-project-template) :prepend t)
        ("p" "Personal")
        ("pl" "Life" entry (file+headline ,my/org-personal-file "Life")
          (function my/org-task-template) :prepend t)
        ("pp" "Project" entry (file+headline ,my/org-personal-file "Projects")
          (function my/org-project-template) :prepend t)
        ("ps" "Someday" entry (file+headline ,my/org-personal-file "Someday")
          (function my/org-task-template) :prepend t)
        ("s" "Subtask for NEXT project" entry
         (function my/org-capture-next-project-target)
         (function my/org-project-subtask-template)
         :empty-lines 1)
        ("n" "Notes")
        ("ni" "Idea" entry (file+headline ,my/org-notes-file "Ideas")
          (function my/org-note-template) :prepend t)
        ("nq" "Quote" entry (file+headline ,my/org-notes-file "Quotes")
          (function my/org-quote-template) :prepend t)
        ("nv" "Insight" entry (file+headline ,my/org-notes-file "Insights")
          (function my/org-note-template) :prepend t)
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
                         (org-agenda-prefix-format
                          "  %-10:c%(my/org-agenda-relative-indent)")
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
                         (org-agenda-prefix-format
                          "  %-10:c%(my/org-agenda-relative-indent)")
                         (org-agenda-overriding-header "下一步行动")))
           (todo "WAITING" ((org-agenda-files ',my/org-action-files)
                            (org-agenda-prefix-format
                             "  %-10:c%(my/org-agenda-relative-indent)")
                            (org-agenda-overriding-header "等待中")))
           (todo "TODO" ((org-agenda-files ',my/org-action-files)
                         (org-agenda-prefix-format
                          "  %-10:c%(my/org-agenda-relative-indent)")
                         (org-agenda-overriding-header "待拆分或待安排")))))))

(defun my/org-agenda-enter-evil-normal-state ()
  "Enter Evil Normal state when an Org Agenda buffer is created."
  (evil-normal-state))

(defun my/org-agenda-setup-evil ()
  "Configure Agenda navigation after both Evil and Org Agenda are available."
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

(with-eval-after-load 'evil
  (with-eval-after-load 'org-agenda
    (my/org-agenda-setup-evil)))

(with-eval-after-load 'org-capture
  (with-eval-after-load 'evil
    (add-hook 'org-capture-mode-hook #'evil-insert-state)
    (evil-define-key 'normal org-capture-mode-map
      (kbd "q") #'org-capture-kill)))

(defun my/calendar-show-agenda-at-mouse (event)
  "Show the daily Agenda for the Calendar date clicked in EVENT."
  (interactive "e")
  (mouse-set-point event)
  (my/org-ensure-files-for-use)
  (org-agenda-list
   nil (calendar-absolute-from-gregorian (calendar-cursor-to-date)) 1))

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
  (my/org-ensure-files-for-use)
  (require 'calfw-org)
  (org-agenda-prepare-buffers org-agenda-files)
  (calfw-org-open-calendar
   nil "Org"
   (or (face-foreground 'font-lock-keyword-face nil t) "SteelBlue")
   :view 'month)
  (my/calfw-enter-evil-motion-state))

(defun my/calfw-enter-evil-motion-state ()
  "Ensure every Calfw calendar Buffer uses Evil Motion state."
  (when (fboundp 'evil-motion-state)
    (evil-motion-state)))

(defun my/calfw-setup-evil ()
  "Configure Evil navigation after both Evil and Calfw are available."
  (evil-set-initial-state 'calfw-calendar-mode 'motion)
  (add-hook 'calfw-calendar-mode-hook #'my/calfw-enter-evil-motion-state)
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
    (kbd "q") #'bury-buffer))

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
  (advice-add 'my/load-theme :after #'my/calfw-apply-theme-colors))

(use-package calfw-org
  :ensure t
  :after calfw
  :defer t)

(with-eval-after-load 'evil
  (with-eval-after-load 'calfw
    (my/calfw-setup-evil)))

(use-package org-modern
  :ensure t
  :hook ((org-mode . org-modern-mode)
         (org-agenda-finalize . org-modern-agenda))
  :custom
  (org-modern-star 'replace)
  (org-modern-replace-stars '("●" "◉" "○" "•" "·"))
  (org-modern-cycle-stars t))

(defun my/org-appt-display (minutes time message)
  "Display an appointment notification MINUTES before TIME with MESSAGE."
  (my/notify (format "%s 分钟后有日程" minutes)
             (format "%s (%s)" message time))
  (appt-disp-window minutes time message))

(defun my/org-refresh-appts ()
  "Refresh appointment reminders from the configured agenda files."
  (interactive)
  (when (null (my/org-missing-files))
    (org-agenda-to-appt t)))

(defvar my/org-appt-refresh-timer nil
  "Timer used to refresh appointments from Org Agenda files.")

(defvar my/org-appt-reminders-starting nil
  "Non-nil while Org appointment reminders are being initialized.")

(defun my/org-start-appt-reminders (&rest _)
  "Start Org appointment reminders after the first Org workflow use."
  (unless (or my/org-appt-reminders-starting
              (timerp my/org-appt-refresh-timer))
    (let ((my/org-appt-reminders-starting t))
      (appt-activate 1)
      (my/org-refresh-appts)
      (setq my/org-appt-refresh-timer
            (run-at-time 600 600 #'my/org-refresh-appts)))))

(add-hook 'org-mode-hook #'my/org-start-appt-reminders)

(defun my/org-refresh-after-revert ()
  "Refresh generated Org views after a synced Org file is reverted."
  (when (derived-mode-p 'org-mode)
    (dolist (buffer (buffer-list))
      (with-current-buffer buffer
        (when (derived-mode-p 'org-agenda-mode)
          (org-agenda-redo))))
    (my/org-refresh-appts)))

(add-hook 'after-revert-hook #'my/org-refresh-after-revert)

(setq appt-message-warning-time 30
      appt-display-interval 10
      appt-display-mode-line t
      appt-display-diary nil
      appt-disp-window-function #'my/org-appt-display)

(global-set-key (kbd "C-c l") #'org-store-link)
(global-set-key (kbd "C-c a") #'org-agenda)
(global-set-key (kbd "C-c c") #'my/org-capture)
(global-set-key (kbd "C-c C") #'my/org-open-visual-calendar)

(provide 'init-org)
;;; init-org.el ends here
