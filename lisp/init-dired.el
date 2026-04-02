;;; init-dired.el --- Dired configuration with Wdired and enhancements -*- lexical-binding: t -*-

;;; Commentary:
;; 1. 提供像编辑文本一样重命名文件的能力 (Wdired)
;; 2. 增强多光标和批量处理支持
;; 3. 实现文件与目录 Buffer 的双向实时同步

;;; Code:

(use-package dired
  :ensure nil ; 内置功能
  :config
  ;; --- 1. 基础行为设置 ---
  ;; 让 Dired 能够递归地拷贝和删除目录 
  (setq dired-recursive-copies 'always)
  (setq dired-recursive-deletes 'always)
  
  ;; 允许 Dired 缓冲区在文件系统发生变化时自动刷新 
  (setq dired-auto-revert-buffer t)
  
  ;; 优化：使 Dired 在左右分屏时，拷贝目标默认为另一个窗口的路径
  (setq dired-dwim-target t)

  ;; --- 2. 实时同步优化 ---
  ;; 确保 Global Auto Revert 也能作用于 Dired 
  (add-hook 'dired-mode-hook 'auto-revert-mode)

  ;; --- 3. Wdired (可编辑模式) 设置 ---
  ;; 允许修改文件权限
  (setq wdired-allow-to-change-permissions t)
  ;; 修改完文件名后，按 C-c C-c 保存，按 C-c C-k 取消

  :bind (:map dired-mode-map
              ;; 将 C-c C-e 绑定为进入“编辑模式”
              ("C-c C-e" . dired-toggle-read-only)
              ;; 习惯 Evil 的用户可以映射 "i" 进入编辑模式
              ("i" . dired-toggle-read-only)))

;; --- 4. 目录树状视图 (可选增强) ---
;; 允许在当前 Dired 缓冲区内像树状图一样展开子目录
(use-package dired-subtree
  :ensure t
  :after dired
  :bind (:map dired-mode-map
              ("<tab>" . dired-subtree-toggle)
              ("TAB" . dired-subtree-toggle)))

;; --- 5. 多光标批量处理逻辑 ---
;; 当进入 Wdired 模式时，你可以直接使用你已有的 evil-multiedit 或 iedit
;; 例如：
;; 1. C-x d 进入目录
;; 2. C-c C-e 进入编辑状态
;; 3. M-i (iedit) 选中所有想改的文件名部分并统一修改 
;; 4. C-c C-c 提交修改

(provide 'init-dired)

;;; init-dired.el ends
