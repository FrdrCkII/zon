;;; Early Init ;;;

;; 目录设置
(setopt user-emacs-directory (expand-file-name "~/.config/emacs/"))
(setopt backup-directory-alist
        `(("." . ,(expand-file-name "backups" user-emacs-directory))))
(ignore-errors
  (make-directory (expand-file-name "backups" user-emacs-directory) t))
(setopt auto-save-file-name-transforms
        `((".*" ,(expand-file-name "auto-saves/" user-emacs-directory) t)))
(ignore-errors
  (make-directory (expand-file-name "auto-saves/" user-emacs-directory) t))

;; 原生编译缓存
(when (fboundp 'startup-redirect-eln-cache)
  (startup-redirect-eln-cache
   (expand-file-name "eln-cache" user-emacs-directory)))

(setopt custom-file (expand-file-name "custom.el" user-emacs-directory))
(setopt package-user-dir (expand-file-name "elpa" user-emacs-directory))

;; ---- 启动性能优化 ----
(defvar mis/default-file-name-handler-alist file-name-handler-alist)
(defvar mis/default-gc-cons-threshold gc-cons-threshold)
(defvar mis/default-gc-cons-percentage gc-cons-percentage)

;; 保留 tramp / epa 关键 handler
(setq file-name-handler-alist
      (seq-filter
       (lambda (x)
         (memq (cdr x) '(tramp-completion-file-name-handler
                         epa-file-handler)))
       mis/default-file-name-handler-alist))
(setq gc-cons-threshold most-positive-fixnum
      gc-cons-percentage 1.0)

(defun mis/restore-startup-optimizations ()
  "启动完成后恢复文件处理器与 GC 相关设置。"
  (setq file-name-handler-alist mis/default-file-name-handler-alist
        gc-cons-threshold mis/default-gc-cons-threshold
        gc-cons-percentage mis/default-gc-cons-percentage))
(add-hook 'after-init-hook #'mis/restore-startup-optimizations)

;; 启动界面
(setq inhibit-startup-screen t
      inhibit-startup-echo-area-message user-login-name
      initial-scratch-message nil)

;; 其他性能设置
(setopt inhibit-compacting-font-caches t)
(setopt idle-update-delay 1.0)
(setopt redisplay-skip-fontification-on-input t)
(setopt read-process-output-max (* 4 1024 1024))   ; LSP 关键
(setopt bidi-inhibit-bpa t)
(setq-default bidi-display-reordering 'left-to-right
              bidi-paragraph-direction 'left-to-right)

;; GUI 元素
(push '(tool-bar-lines . 0) default-frame-alist)
(push '(menu-bar-lines . 0) default-frame-alist)
(push '(vertical-scroll-bars . nil) default-frame-alist)
(push '(horizontal-scroll-bars . nil) default-frame-alist)
(tool-bar-mode -1)
(menu-bar-mode -1)
(scroll-bar-mode -1)
(blink-cursor-mode -1)
(setopt frame-inhibit-implied-resize t)

;; 编码与环境
(set-language-environment "UTF-8")
(set-default-coding-systems 'utf-8)
(setopt native-comp-async-report-warnings-errors 'silent)

;; 包管理器初始化前抑制自动加载
(setq package-enable-at-startup nil)

;;; Packages ;;;

(require 'package)
(require 'use-package)

(setopt package-archives
        '(("gnu"    . "https://mirrors.tuna.tsinghua.edu.cn/elpa/gnu/")
          ("nongnu" . "https://mirrors.tuna.tsinghua.edu.cn/elpa/nongnu/")
          ("melpa"  . "https://mirrors.tuna.tsinghua.edu.cn/elpa/melpa/")
          ("org"    . "https://mirrors.tuna.tsinghua.edu.cn/elpa/org/")))

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

(setopt treesit-font-lock-level 4)

(use-package treesit-auto
  :custom
  (treesit-auto-install nil)
  :config
  (treesit-auto-add-to-auto-mode-alist 'all)
  (global-treesit-auto-mode 1))

(use-package apheleia
  :config
  (setq apheleia-mode-lighter " fmt")
  (apheleia-global-mode 1))

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
   (css-ts-mode        . eglot-ensure))
  :custom
  (eglot-server-programs
   '(((rust-ts-mode rust-mode) . ("rust-analyzer"))
     ((nix-ts-mode nix-mode)   . ("nil"))
     ((java-ts-mode java-mode) . ("jdtls"))
     ((js-ts-mode)             . ("typescript-language-server" "--stdio"))
     ((typescript-ts-mode)     . ("typescript-language-server" "--stdio"))
     ((tsx-ts-mode)            . ("typescript-language-server" "--stdio"))
     ((c-ts-mode c-mode)       . ("clangd"))
     ((c++-ts-mode c++-mode)   . ("clangd"))))
  (eglot-code-action-indications '(eldoc-hint))
  :bind (:map eglot-mode-map
              ("C-c r" . eglot-rename)
              ("C-c f" . eglot-format)))

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
  :config
  (add-to-list 'auto-mode-alist '("\\.org\\'" . org-mode))
  (add-hook 'org-mode-hook (lambda () (setq truncate-lines nil)))
  :bind
  (("C-c l" . org-store-link)
   ("C-c a" . org-agenda)
   ("C-c c" . org-capture)))

(use-package ghostel)

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
