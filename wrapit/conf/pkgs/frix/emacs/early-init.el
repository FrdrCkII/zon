(let ((base (expand-file-name "~/.config/emacs/")))
  (setq backup-directory-alist
        `(("." . ,(expand-file-name "backups" base))))
  (ignore-errors
    (make-directory (expand-file-name "backups" base) t))

  (setq auto-save-file-name-transforms
        `((".*" ,(expand-file-name "auto-saves/" base) t)))
  (ignore-errors
    (make-directory (expand-file-name "auto-saves" base) t))

  (when (fboundp 'startup-redirect-eln-cache)
    (startup-redirect-eln-cache
     (expand-file-name "eln-cache" base))))

(defvar default-file-name-handler-alist file-name-handler-alist)
(defvar default-gc-cons-threshold gc-cons-threshold)
(defvar default-gc-cons-percentage gc-cons-percentage)

(setq file-name-handler-alist nil)
(setq gc-cons-threshold most-positive-fixnum)
(setq gc-cons-percentage 1.0)

(add-hook 'after-init-hook (lambda ()
                             (setq file-name-handler-alist
                                   default-file-name-handler-alist)
                             (setq gc-cons-threshold default-gc-cons-threshold)
                             (setq gc-cons-percentage default-gc-cons-percentage)))

(setq inhibit-startup-screen t)
(setq inhibit-startup-echo-area-message user-login-name)
(setq initial-scratch-message nil)
(setq inhibit-compacting-font-caches t)
(setq idle-update-delay 1.0)

(push '(tool-bar-lines . 0) default-frame-alist)
(push '(menu-bar-lines . 0) default-frame-alist)
(push '(vertical-scroll-bars) default-frame-alist)
(push '(horizontal-scroll-bars) default-frame-alist)

(tool-bar-mode -1)
(menu-bar-mode -1)
(scroll-bar-mode -1)
(blink-cursor-mode 0)

(set-language-environment "UTF-8")
(set-default-coding-systems 'utf-8)
(when (boundp 'native-comp-async-report-warnings-errors)
  (setq native-comp-async-report-warnings-errors 'silent))
(setq frame-inhibit-implied-resize t)
(setq package-enable-at-startup nil)
