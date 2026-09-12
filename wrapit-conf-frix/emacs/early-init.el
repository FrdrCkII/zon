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
