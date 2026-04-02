;; init-treesitter.el --- Native Treesitter Configuration -*- lexical-binding: t -*-
;; 1. 配置 treesit-auto 插件
;; 它会自动管理语法解析器的下载地址和 Mode 的映射
(when (maybe-require-package 'treesit-auto)
  (require 'treesit-auto)
  
 (setq treesit-auto-install t)
  ;; 如果你有特定的解析器源码需求（比如默认地址连不上），可以在这里补充，否则不需要写。
 (setq treesit-language-source-alist
      '(;; --- 官方 Tree-sitter 组织提供的解析器 ---
        (c "https://github.com/tree-sitter/tree-sitter-c")
        (cpp "https://github.com/tree-sitter/tree-sitter-cpp")
        (c-sharp "https://github.com/tree-sitter/tree-sitter-c-sharp")
        (bash "https://github.com/tree-sitter/tree-sitter-bash")
        (css "https://github.com/tree-sitter/tree-sitter-css")
        (go "https://github.com/tree-sitter/tree-sitter-go")
        (gomod "https://github.com/camdencheek/tree-sitter-go-mod")
        (haskell "https://github.com/tree-sitter/tree-sitter-haskell")
        (html "https://github.com/tree-sitter/tree-sitter-html")
        (java "https://github.com/tree-sitter/tree-sitter-java")
        (javascript "https://github.com/tree-sitter/tree-sitter-javascript" "master" "src")
        (json "https://github.com/tree-sitter/tree-sitter-json")
        (julia "https://github.com/tree-sitter/tree-sitter-julia")
        (lua "https://github.com/tree-sitter/tree-sitter-lua")
        (ocaml "https://github.com/tree-sitter/tree-sitter-ocaml" "master" "ocaml/src")
        (php "https://github.com/tree-sitter/tree-sitter-php" "master" "php/src")
        (python "https://github.com/tree-sitter/tree-sitter-python")
        (ruby "https://github.com/tree-sitter/tree-sitter-ruby")
        (rust "https://github.com/tree-sitter/tree-sitter-rust")
        (scala "https://github.com/tree-sitter/tree-sitter-scala")
        (swift "https://github.com/tree-sitter/tree-sitter-swift")
        (tsx "https://github.com/tree-sitter/tree-sitter-typescript" "master" "tsx/src")
        (typescript "https://github.com/tree-sitter/tree-sitter-typescript" "master" "typescript/src")
        ;; --- 实用解析器 (Regex, SQL, JSDoc 等) ---
        (regex "https://github.com/tree-sitter/tree-sitter-regex")
        (jsdoc "https://github.com/tree-sitter/tree-sitter-jsdoc")
        (sql "https://github.com/lo-tp/tree-sitter-sql")
        ;; --- 社区维护的解析器 ---
        (cmake "https://github.com/uyha/tree-sitter-cmake")
        (common-lisp "https://github.com/theHamsta/tree-sitter-commonlisp")
        (dockerfile "https://github.com/camdencheek/tree-sitter-dockerfile")
        (elisp "https://github.com/Wilfred/tree-sitter-elisp")
        (make "https://github.com/alemuller/tree-sitter-make")
        (markdown "https://github.com/ikatyang/tree-sitter-markdown")
        (markdown-inline "https://github.com/ikatyang/tree-sitter-markdown")
        (mermaid "https://github.com/monaqa/tree-sitter-mermaid")
        (toml "https://github.com/ikatyang/tree-sitter-toml")
        (vue "https://github.com/ikatyang/tree-sitter-vue")
        (yaml "https://github.com/ikatyang/tree-sitter-yaml")))  ;; 默认安装所有支持的语言
  ;; (setq treesit-auto-install 'prompt) ; 如果缺解析器，打开文件时会询问是否安装
  ;; 强制重映射（解决询问问题的核心）
  (setq major-mode-remap-alist
        '((c-mode          . c-ts-mode)
          (c++-mode        . c++-ts-mode)
          (c-or-c++-mode   . c-ts-mode) 
          (python-mode     . python-ts-mode)
          (bash-mode       . bash-ts-mode)
          (js-mode         . js-ts-mode)
          (typescript-mode . typescript-ts-mode)
          (json-mode       . json-ts-mode)
          (cmake-mode      . cmake-ts-mode)))

  ;; 显式文件后缀关联
  (add-to-list 'auto-mode-alist '("\\.cpp\\'" . c++-ts-mode))
  (add-to-list 'auto-mode-alist '("\\.hpp\\'" . c++-ts-mode))
  (add-to-list 'auto-mode-alist '("\\.c\\'"   . c-ts-mode))
  ;; 如果你的 .h 也是 C++，可以把下面这行改为 c++-ts-mode
  (add-to-list 'auto-mode-alist '("\\.h\\'"   . c-ts-mode))
  ;; 开启全局模式：自动将 python-mode 映射到 python-ts-mode 等
  (global-treesit-auto-mode t))
;; 2. 界面美化设置
;; 设置语法高亮等级 (1-4)，4 最为丰富
(setq treesit-font-lock-level 4)
;; 3. 兼容性补丁（可选）
;; 某些插件（如某些开发工具）可能还在寻找旧的模式名，这里做一个后备
(setq treesit-extra-load-path `(,(expand-file-name "tree-sitter" user-emacs-directory)))
(provide 'init-treesitter)
;;; init-treesitter.el ends here
