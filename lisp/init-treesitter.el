;;; init-treesitter.el --- Native Treesitter Configuration -*- lexical-binding: t -*-
;; 1. 配置语法解析器的源码地址
(setq treesit-language-source-alist
   '((bash "https://github.com/tree-sitter/tree-sitter-bash")
     (cmake "https://github.com/uyha/tree-sitter-cmake")
     (css "https://github.com/tree-sitter/tree-sitter-css")
     (elisp "https://github.com/Wilfred/tree-sitter-elisp")
     (go "https://github.com/tree-sitter/tree-sitter-go")
     (html "https://github.com/tree-sitter/tree-sitter-html")
     (javascript "https://github.com/tree-sitter/tree-sitter-javascript" "master" "src")
     (json "https://github.com/tree-sitter/tree-sitter-json")
     (make "https://github.com/alemuller/tree-sitter-make")
     (markdown "https://github.com/ikatyang/tree-sitter-markdown")
     (python "https://github.com/tree-sitter/tree-sitter-python")
     (toml "https://github.com/ikatyang/tree-sitter-toml")
     (tsx "https://github.com/tree-sitter/tree-sitter-typescript" "master" "tsx/src")
     (typescript "https://github.com/tree-sitter/tree-sitter-typescript" "master" "typescript/src")
     (yaml "https://github.com/ikatyang/tree-sitter-yaml")))
;; 2. 自动将原本的 Mode 映射到 TS 版本的 Mode
;; 这样当你打开 .py 文件时，Emacs 会自动调用 python-ts-mode
(setq major-mode-remap-alist
      '((python-mode . python-ts-mode)
        (c-mode . c-ts-mode)
        (c++-mode . c++-ts-mode)
        (c-or-c++-mode . c-or-c++-ts-mode)
        (js-mode . js-ts-mode)
        (typescript-mode . typescript-ts-mode)
        (json-mode . json-ts-mode)
        (css-mode . css-ts-mode)
        (conf-toml-mode . toml-ts-mode)))
;; 3. 字体美化等级
(setq treesit-font-lock-level 4)
(provide 'init-treesitter);;; init-treesitter.el --- Treesitter configuration -*- lexical-binding: t -*-

;; 使用你 init-elpa.el 里的可靠函数来安装
(when (maybe-require-package 'treesit-auto)
  (require 'treesit-auto)
  (setq treesit-auto-install 'prompt)
  ;; global-treesit-auto-mode 会自动处理 major-mode-remap-alist
  ;; 不需要再手动调用 treesit-auto-add-to-alist
  (global-treesit-auto-mode t))

;; 设置字体着色等级（1-4，4最丰富）
(setq treesit-font-lock-level 4)


(provide 'init-treesitter)
;;; init-treesitter.el ends here
