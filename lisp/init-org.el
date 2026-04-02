;;; init-org.el --- org settings -*- lexical-binding: t -*-

;; 1. 基础路径设置 (请根据你的同步盘实际路径修改)
(setq org-directory "~/org")
(setq org-agenda-files '("~/org")) ;; 扫描整个文件夹下的org文件

;; 2. 状态设定 (兼容 Orgzly 的默认状态)
;; 建议使用简单的状态流，避免 Orgzly 无法解析复杂的转换规则
(setq org-todo-keywords
      '((sequence "TODO(t)" "STARTED(s)" "NEXT(n)" "|" "DONE(d)" "CANCELLED(c)")))

;; 3. Capture 模板：快速收集灵感和任务
(setq org-capture-templates
      '(("t" "Todo" entry (file+headline "~/org/inbox.org" "Tasks")
         "* TODO %?\n  Created: %U\n  %i" :prepend t)
        ("n" "Notes" entry (file+headline "~/org/notes.org" "Notes")
         "* %?\n  Created: %U\n  %i" :prepend t)))

;; 4. 优化 Agenda 视图 (参考 Aaron Bieber 的理念)
(setq org-agenda-custom-commands
      '(("d" "今日日程与待办"
         ((agenda "" ((org-agenda-span 1)))
          (todo "NEXT" ((org-agenda-overriding-header "优先执行 (Next)")))
          (todo "TODO" ((org-agenda-overriding-header "待办池 (Inbox)")))))))

;; 5. 快捷键设定 (全局 + Org-mode 内)
;; 使用全局快捷键以便在任何缓冲区都能快速记录
(global-set-key (kbd "C-c l") 'org-store-link)
(global-set-key (kbd "C-c a") 'org-agenda)
(global-set-key (kbd "C-c c") 'org-capture)

;; Org-mode 内部的高频快捷键提示：
;; Tab     : 循环展开/折叠
;; C-c C-t : 循环切换 TODO 状态
;; C-c C-s : 设置排期 (Schedule)
;; C-c C-d : 设置截止日期 (Deadline)

;; 6. 自动保存与兼容性
(setq org-log-done 'time)         ; 完成任务时记录时间
(setq org-blank-before-new-entry '((heading . t) (plain-list-item . nil))) ; 格式整洁

(provide 'init-org)
