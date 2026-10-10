;; -*- lexical-binding: t; -*-

;;; Packages ;;;

(require 'package)
(require 'use-package)

(setopt package-archives
        '(("gnu"    . "https://mirrors.bfsu.edu.cn/elpa/gnu/")
          ("nongnu" . "https://mirrors.bfsu.edu.cn/elpa/nongnu/")
          ("melpa"  . "https://mirrors.bfsu.edu.cn/elpa/melpa/")
          ("org"    . "https://mirrors.bfsu.edu.cn/elpa/org/")))

(package-initialize)
(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

(eval-and-compile
  (setopt use-package-always-ensure t)
  (setopt use-package-expand-minimally t))

;;; Core Editing ;;;

;; 相对行号
(setopt display-line-numbers-type 'relative)
(global-display-line-numbers-mode 1)

(defun mis/disable-line-numbers ()
  "在当前缓冲区禁用行号显示。"
  (display-line-numbers-mode -1))

(dolist (mode '(org-mode-hook term-mode-hook shell-mode-hook eshell-mode-hook))
  (add-hook mode #'mis/disable-line-numbers))

;; 末尾换行
(setopt require-final-newline t)

;; 缩进
(setq-default indent-tabs-mode nil
              tab-width 2
              standard-indent 2
              c-basic-offset 2)

;; 括号与配对
(electric-pair-mode 1)
(show-paren-mode 1)

;; 编码与填充
(setq-default buffer-file-coding-system 'utf-8-unix
              fill-column 80)
(global-auto-revert-mode 1)

;; 搜索高亮
(setopt search-highlight t)
(setopt query-replace-highlight t)
(setopt isearch-lazy-highlight t)
(setq-default case-fold-search t)

;; 简化 yes/no 询问
(setopt use-short-answer t)

;; 平滑滚动
(setopt scroll-step 1)
(setopt scroll-conservatively 10000)

;; 剪贴板与选区
(setopt select-active-regions nil)
(setopt select-enable-clipboard t)
(setopt select-enable-primary nil)
(setopt interprogram-cut-function #'gui-select-text)
(setopt save-interprogram-paste-before-kill t)
(setopt kill-do-not-save-duplicates t)

;; 历史与撤销
(setopt set-mark-command-repeat-pop t)
(global-set-key (kbd "C-/") #'comment-line)
(global-set-key (kbd "C-,") #'undo)
(global-set-key (kbd "C-.") #'redo)

;; 窗口管理
(setopt window-combination-resize t)
(winner-mode 1)

(defun mis/toggle-delete-other-windows ()
  "若有其他窗口则删除，否则恢复上一次窗口配置。"
  (interactive)
  (if (and winner-mode
           (equal (selected-window) (next-window)))
      (winner-undo)
    (delete-other-windows)))
(global-set-key (kbd "C-x 1") #'mis/toggle-delete-other-windows)

;; 恢复文件位置后居中
(defun mis/recenter-after-save-place (&rest _)
  "save-place 恢复位置后将光标居中。"
  (when buffer-file-name
    (ignore-errors (recenter))))
(advice-add 'save-place-find-file-hook :after #'mis/recenter-after-save-place)

;; 帮助窗口选中
(setopt help-window-select t)

;;; Minibuffer & Completion ;;;

(use-package which-key
  :init (which-key-mode 1)
  :custom
  (which-key-idle-secondary-delay 0.05))

;; 保存 minibuffer 历史
(defun mis/savehist-trim-kill-ring ()
  "保存前去除 kill-ring 中的文本属性，避免污染。"
  (setq kill-ring
        (mapcar #'substring-no-properties
                (cl-remove-if-not #'stringp kill-ring))))

(use-package savehist
  :init (savehist-mode 1)
  :custom
  (savehist-file (expand-file-name "savehist" user-emacs-directory))
  (savehist-additional-variables '(search-ring regexp-search-ring kill-ring))
  :config
  (add-hook 'savehist-save-hook #'mis/savehist-trim-kill-ring))

;; 最近打开的文件
(use-package recentf
  :init (recentf-mode 1)
  :custom
  (recentf-max-saved-items 100)
  (recentf-exclude '("/auto-saves/" "/backups/" "/eln-cache/")))

;;; LSP & Tree-sitter ;;;

(use-package treesit
  :ensure nil
  :custom
  (treesit-font-lock-level 4)
  :config
  (add-to-list 'treesit-language-source-alist
               '(kotlin "https://github.com/fwcd/tree-sitter-kotlin" "v0.3.8")))

(use-package treesit-auto
  :custom
  (treesit-auto-install nil)
  :config
  ;; Kotlin
  (add-to-list 'treesit-auto-recipe-list
               (make-treesit-auto-recipe
                :lang 'kotlin
                :ts-mode 'kotlin-ts-mode
                :remap 'kotlin-mode
                :url "https://github.com/fwcd/tree-sitter-kotlin"
                :ext "\\.kts?\\'"))

  ;; Nix
  (add-to-list 'treesit-auto-recipe-list
               (make-treesit-auto-recipe
                :lang 'nix
                :ts-mode 'nix-ts-mode
                :remap 'nix-mode
                :url "https://github.com/nix-community/tree-sitter-nix"
                :ext "\\.nix\\'"))

  ;; Just
  (add-to-list 'treesit-auto-recipe-list
               (make-treesit-auto-recipe
                :lang 'just
                :ts-mode 'just-ts-mode
                :remap 'just-mode
                :url "https://github.com/IndianBoy42/tree-sitter-just"
                :ext "\\(?:Justfile\\|\\.just\\|\\.justfile\\)\\'"))

  (treesit-auto-add-to-auto-mode-alist 'all)
  (global-treesit-auto-mode 1))
(use-package apheleia
  :config
  (setq apheleia-mode-lighter " fmt")

  ;; nixfmt
  (add-to-list 'apheleia-formatters
               '(nixfmt "nixfmt" "--strict"))

  ;; rustfmt
  (add-to-list 'apheleia-formatters
               '(rustfmt "rustfmt"
                         "--config" "skip_children=true"
                         "--edition" "2024"))

  ;; google-java-format
  (add-to-list 'apheleia-formatters
               '(google-java-format "google-java-format" "-"))

  ;; taplo
  (add-to-list 'apheleia-formatters
               '(taplo "taplo" "format" "-"))

  ;; prettier
  (add-to-list 'apheleia-formatters
               '(prettier "prettier" "--stdin-filepath" filepath))

  ;; yamlfmt
  (add-to-list 'apheleia-formatters
               '(yamlfmt "yamlfmt" "-"))

  ;; ktlint
  (add-to-list 'apheleia-formatters
               '(ktlint "ktlint" "--log-level=none" "--stdin" "-F" "-"))

  (add-to-list 'apheleia-mode-alist '(nix-ts-mode        . nixfmt))
  (add-to-list 'apheleia-mode-alist '(rust-ts-mode       . rustfmt))
  (add-to-list 'apheleia-mode-alist '(java-ts-mode       . google-java-format))
  (add-to-list 'apheleia-mode-alist '(toml-ts-mode       . taplo))
  (add-to-list 'apheleia-mode-alist '(json-ts-mode       . prettier))
  (add-to-list 'apheleia-mode-alist '(json5-ts-mode      . prettier))
  (add-to-list 'apheleia-mode-alist '(yaml-ts-mode       . yamlfmt))
  (add-to-list 'apheleia-mode-alist '(kotlin-ts-mode     . ktlint))

  (apheleia-global-mode 1))

(use-package trust-manager
  :config
  (trust-manager-mode 1))

(use-package eglot
  :hook
  ((rust-ts-mode       . eglot-ensure)
   (nix-ts-mode        . eglot-ensure)
   (java-ts-mode       . eglot-ensure)
   (js-ts-mode         . eglot-ensure)
   (typescript-ts-mode . eglot-ensure)
   (tsx-ts-mode        . eglot-ensure)
   (c-ts-mode          . eglot-ensure)
   (c++-ts-mode        . eglot-ensure)
   (bazel-ts-mode      . eglot-ensure)
   (toml-ts-mode       . eglot-ensure)
   (json-ts-mode       . eglot-ensure)
   (css-ts-mode        . eglot-ensure)
   (kotlin-ts-mode     . eglot-ensure))
  
  :custom
  (eglot-server-programs
   '(((rust-ts-mode rust-mode) . ("rust-analyzer"))
     ((nix-ts-mode nix-mode)   . ("nil"))
     ((java-ts-mode java-mode) . ("jdtls"))
     ((kotlin-ts-mode)         . ("kotlin-language-server"))
     ((js-ts-mode)             . ("typescript-language-server" "--stdio"))
     ((typescript-ts-mode)     . ("typescript-language-server" "--stdio"))
     ((tsx-ts-mode)            . ("typescript-language-server" "--stdio"))
     ((c-ts-mode c-mode)       . ("clangd"))
     ((c++-ts-mode c++-mode)   . ("clangd"))))
  (eglot-code-action-indications '(eldoc-hint))
  
  :bind (:map eglot-mode-map
              ("C-c r" . eglot-rename)
              ("C-c f" . eglot-format)))

(add-hook 'java-ts-mode-hook
          (lambda ()
            (setq-local lsp-java-format-tab-size 2)
            (setq-local java-ts-mode-indent-offset 2)
            (setq-local tab-width 2)
            (setq-local indent-tabs-mode nil)))

;; 补全前端
(use-package corfu
  :init
  (global-corfu-mode 1)
  (corfu-history-mode 1)
  :custom
  (corfu-auto t)
  (corfu-auto-delay 0.2)
  (corfu-auto-trigger ".")
  (corfu-quit-no-match 'separator))

;;; Org Mode ;;;

(use-package htmlize
  :defer t)

(use-package org
  :defer t
  :custom
  (org-log-done t)
  (org-src-fontify-natively t)
  ;; 注意：nil 会禁用所有可选模块，如果不需要这些模块请显式列出
  (org-modules '(org-tempo org-protocol))
  ;; 只做一次判定即可，避免在无图形时也访问字符表
  (org-ellipsis (if (char-displayable-p ?⏷) " ⏷" "..."))
  (org-support-shift-select t)
  :config
  (add-to-list 'auto-mode-alist '("\\.org\\'" . org-mode))
  (add-hook 'org-mode-hook (lambda () (setq truncate-lines nil)))
  :bind
  (("C-c l" . org-store-link)
   ("C-c a" . org-agenda)
   ("C-c c" . org-capture)))

;;; Theme & UI ;;;

(load-theme 'modus-vivendi t)

(use-package diff-hl
  :hook
  ((dired-mode . diff-hl-dired-mode)
   (prog-mode  . turn-on-diff-hl-mode))
  :config
  (global-diff-hl-mode 1)
  (diff-hl-flydiff-mode 1))

;; 字体设置
(add-to-list 'default-frame-alist '(font . "monospace"))
(when (display-graphic-p)
  (set-face-attribute 'default nil :family "monospace" :height 140)
  (set-face-attribute 'fixed-pitch nil :family "monospace" :height 140))

(use-package neotree
  :custom
  (neo-theme 'ascii)
  :hook
  (neotree-mode . (lambda () (display-line-numbers-mode -1)))
  :bind
  ("C-c t" . neotree-toggle))
