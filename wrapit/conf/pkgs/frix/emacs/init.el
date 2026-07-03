;;; Early Init ;;;

;; 目录设置
(setq user-emacs-directory (expand-file-name "~/.config/emacs/"))
(setq backup-directory-alist
      `(("." . ,(expand-file-name "backups" user-emacs-directory))))
(ignore-errors
  (make-directory (expand-file-name "backups" user-emacs-directory) t))
(setq auto-save-file-name-transforms
      `((".*" ,(expand-file-name "auto-saves/" user-emacs-directory) t)))
(ignore-errors
  (make-directory (expand-file-name "auto-saves" user-emacs-directory) t))

;; 原生编译缓存
(when (fboundp 'startup-redirect-eln-cache)
  (startup-redirect-eln-cache
   (expand-file-name "eln-cache" user-emacs-directory)))

(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
(setq package-user-dir (expand-file-name "elpa" user-emacs-directory))

;; ---- 启动性能优化 ----
(defvar default-file-name-handler-alist file-name-handler-alist)
(defvar default-gc-cons-threshold gc-cons-threshold)
(defvar default-gc-cons-percentage gc-cons-percentage)

;; 保留 tramp 等关键 handler，避免完全清空导致的加载问题
(setq file-name-handler-alist
      (seq-filter
       (lambda (x) (memq (cdr x) '(tramp-completion-file-name-handler
                                   epa-file-handler)))
       default-file-name-handler-alist))
(setq gc-cons-threshold most-positive-fixnum)
(setq gc-cons-percentage 1.0)

(add-hook 'after-init-hook
          (lambda ()
            (setq file-name-handler-alist default-file-name-handler-alist)
            (setq gc-cons-threshold default-gc-cons-threshold)
            (setq gc-cons-percentage default-gc-cons-percentage)))

;; 启动界面
(setq inhibit-startup-screen t)
(setq inhibit-startup-echo-area-message user-login-name)
(setq initial-scratch-message nil)

;; 其他性能设置
(setq inhibit-compacting-font-caches t)
(setq idle-update-delay 1.0)
(setq redisplay-skip-fontification-on-input t)
(setq read-process-output-max (* 4 1024 1024))   ; LSP 性能关键
(setq bidi-inhibit-bpa t)                         ; 禁用双向文本检测
(setq-default bidi-display-reordering 'left-to-right
              bidi-paragraph-direction 'left-to-right)

;; GUI 元素
(push '(tool-bar-lines . 0) default-frame-alist)
(push '(menu-bar-lines . 0) default-frame-alist)
(push '(vertical-scroll-bars . nil) default-frame-alist)   ; 修正：原为 (vertical-scroll-bars) 缺少值
(push '(horizontal-scroll-bars . nil) default-frame-alist)
(tool-bar-mode -1)
(menu-bar-mode -1)
(scroll-bar-mode -1)
(blink-cursor-mode 0)

(setq frame-inhibit-implied-resize t)

;; 编码与环境
(set-language-environment "UTF-8")
(set-default-coding-systems 'utf-8)
(when (boundp 'native-comp-async-report-warnings-errors)
  (setq native-comp-async-report-warnings-errors 'silent))

;; 包管理器初始化前抑制自动加载
(setq package-enable-at-startup nil)

;;; Packages ;;;

(require 'package)
(require 'use-package)

(setq package-archives
      '(("gnu" . "https://mirrors.cernet.edu.cn/elpa/gnu/")
        ("nongnu" . "https://mirrors.cernet.edu.cn/elpa/nongnu/")
        ("melpa" . "https://mirrors.cernet.edu.cn/elpa/melpa/")
        ("org" . "https://mirrors.cernet.edu.cn/elpa/org/")))

(package-initialize)
(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

(eval-and-compile
  (setq use-package-always-ensure t)
  (setq use-package-expand-minimally t))

;;; Core Editing ;;;

;; 相对行号
(setq display-line-numbers-type 'relative)
(global-display-line-numbers-mode t)

(dolist (mode '(org-mode-hook term-mode-hook shell-mode-hook eshell-mode-hook))
  (add-hook mode (lambda () (display-line-numbers-mode 0))))

;; 缩进
(setq-default indent-tabs-mode nil)
(setq-default tab-width 2)
(setq-default standard-indent 2)
(setq-default c-basic-offset 2)

;; 括号与配对
(electric-pair-mode t)
(show-paren-mode t)

;; 编码与填充
(setq-default buffer-file-coding-system 'utf-8-unix)
(setq-default fill-column 80)
(global-auto-revert-mode t)

;; 搜索高亮
(setq search-highlight t)
(setq query-replace-highlight t)
(setq isearch-lazy-highlight t)
(setq-default case-fold-search t)

;; 简化 yes/no 询问
(setq use-short-answer t)

;; 平滑滚动
(setq scroll-step 1)
(setq scroll-conservatively 10000)

;; 剪贴板与选区
(setopt select-active-regions nil)
(setopt select-enable-clipboard t)
(setopt select-enable-primary nil)
(setopt interprogram-cut-function #'gui-select-text)
(setq save-interprogram-paste-before-kill t)
(setq kill-do-not-save-duplicates t)

;; 历史与撤销
(setq set-mark-command-repeat-pop t)
(global-set-key (kbd "C-/") 'comment-line)
(global-set-key (kbd "C-,") 'undo)
(global-set-key (kbd "C-.") 'redo)   ; 需要 undo-redo 功能支持

;; 窗口管理
(setq window-combination-resize t)
(winner-mode +1)

(defun toggle-delete-other-windows ()
  "Delete other windows if any, or restore previous window configuration."
  (interactive)
  (if (and winner-mode
           (equal (selected-window) (next-window)))
      (winner-undo)
    (delete-other-windows)))
(global-set-key (kbd "C-x 1") #'toggle-delete-other-windows)

;; 恢复文件位置
(advice-add 'save-place-find-file-hook :after
            (lambda (&rest _)
              (when buffer-file-name (ignore-errors (recenter)))))

;; 帮助窗口选中
(setq help-window-select t)

;;; Minibuffer & Completion ;;;

(use-package which-key
  :config
  (setq which-key-idle-secondary-delay 0.05)
  (which-key-mode))

;; 补全框架（如果你希望增强 minibuffer 补全，可以取消下面几行的注释）
;; (use-package vertico
;;   :init (vertico-mode))
;; (use-package orderless
;;   :custom (completion-styles '(orderless)))
;; (use-package marginalia
;;   :init (marginalia-mode))
;; (use-package consult
;;   :bind (("C-c s" . consult-line)
;;          ("C-c i" . consult-imenu)))

;; 保存 minibuffer 历史
(use-package savehist
  :init (savehist-mode)
  :custom
  (savehist-file (expand-file-name "savehist" user-emacs-directory))
  (savehist-additional-variables
   '(search-ring regexp-search-ring kill-ring))
  :config
  (add-hook 'savehist-save-hook
            (lambda ()
              (setq kill-ring
                    (mapcar #'substring-no-properties
                            (cl-remove-if-not #'stringp kill-ring))))))

;; 最近打开的文件
(use-package recentf
  :init (recentf-mode)
  :custom
  (recentf-max-saved-items 100)
  (recentf-exclude '("/auto-saves/" "/backups/" "/eln-cache/")))

;;; LSP & Tree-sitter ;;;

(setq treesit-font-lock-level 4)

(use-package treesit-auto
  :custom
  (treesit-auto-install nil)
  :config
  (treesit-auto-add-to-auto-mode-alist 'all)
  (global-treesit-auto-mode))

(use-package apheleia
  :config
  ;; 修正：变量名应为 apheleia-mode-lighter
  (setq apheleia-mode-lighter " fmt")
  (apheleia-global-mode +1))

(use-package eglot
  :defer t
  :hook
  ((rust-ts-mode . eglot-ensure)
   (nix-ts-mode . eglot-ensure)
   (toml-ts-mode . eglot-ensure)
   (json-ts-mode . eglot-ensure)
   (css-ts-mode . eglot-ensure))
  :config
  (setq eglot-server-programs
        '(((rust-ts-mode rust-mode) . ("rust-analyzer"))
          ((nix-ts-mode nix-mode) . ("nil"))))
  (setq eglot-code-action-indications '(eldoc-hint))
  :bind (:map eglot-mode-map
              ("C-c r" . eglot-rename)
              ("C-c f" . eglot-format)))

;; 补全前端
(use-package corfu
  :init
  (setq corfu-auto t
        corfu-auto-delay 0.2
        corfu-auto-trigger "."
        corfu-quit-no-match 'separator)
  (global-corfu-mode)
  (corfu-history-mode))

;;; Org Mode ;;;

(use-package htmlize
  :defer t)

(use-package org
  :defer t
  :config
  (setq org-log-done t)
  (setq org-src-fontify-natively t)
  (add-to-list 'auto-mode-alist '("\\.org$" . org-mode))
  (global-set-key (kbd "C-c l") 'org-store-link)
  (global-set-key (kbd "C-c a") 'org-agenda)
  (global-set-key (kbd "C-c c") 'org-capture)
  (add-hook 'org-mode-hook
            (lambda ()
              (setq truncate-lines nil)))
  :custom
  (org-modules nil)
  ;; 修正：nn-fold-string 应为字符或字符串
  (org-ellipsis (if (char-displayable-p ?⏷) " ⏷" "...")))

;;; Theme & UI ;;;

(load-theme 'modus-vivendi t)

(use-package diff-hl
  :defer t
  :hook
  ((dired-mode . diff-hl-dired-mode)
   (prog-mode . turn-on-diff-hl-mode))
  :config
  (global-diff-hl-mode 1)
  (diff-hl-flydiff-mode 1))

;; 字体设置
(add-to-list 'default-frame-alist '(font . "monospace"))
(when (display-graphic-p)
  (set-face-attribute 'default nil
                      :family "monospace"
                      :height 140)
  (set-face-attribute 'fixed-pitch nil
                      :family "monospace"
                      :height 140))

(use-package neotree
  :config
  (global-set-key [f8] 'neotree-toggle)
  (setq neo-theme 'ascii)
  :hook
  (neotree-mode . (lambda () (display-line-numbers-mode -1))))

