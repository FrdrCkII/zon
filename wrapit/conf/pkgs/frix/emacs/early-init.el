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

