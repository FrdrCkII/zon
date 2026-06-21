(setq custom-file (expand-file-name "custom.el" user-emacs-directory))

(setq display-line-numbers-type 'relative)
(global-display-line-numbers-mode t)

(dolist
    (mode
     '(org-mode-hook
       term-mode-hook
       shell-mode-hook
       eshell-mode-hook))
  (add-hook mode
            (lambda () (display-line-numbers-mode 0))))

(setq-default indent-tabs-mode nil)
(setq-default tab-width 2)
(setq-default standard-indent 2)
(setq-default c-basic-offset 2)

(electric-pair-mode t)
(show-paren-mode t)

(setq-default buffer-file-coding-system 'utf-8-unix)
(setq-default fill-column 80)
(global-auto-revert-mode t)

(setq search-highlight t)
(setq query-replace-highlight t)
(setq isearch-lazy-highlight t)
(setq-default case-fold-search t)

(setq use-short-answer t)

(setq scroll-step 1)
(setq scroll-conservatively 10000)

(use-package which-key
  :config
  (setq which-key-idle-secondary-delay 0.05)
  (which-key-mode))

(setopt select-active-regions nil)
(setopt select-enable-clipboard 't)
(setopt select-enable-primary nil)
(setopt interprogram-cut-function #'gui-select-text)

(setq-default bidi-display-reordering 'left-to-right
              bidi-paragraph-direction 'left-to-right)
(setq bidi-inhibit-bpa t)

(setq redisplay-skip-fontification-on-input t)

(setq read-process-output-max (* 4 1024 1024))

(setq-default cursor-in-non-selected-windows nil)
(setq highlight-nonselected-windows nil)

(setq save-interprogram-paste-before-kill t)
(setq kill-do-not-save-duplicates t)

(setq savehist-additional-variables
      '(search-ring regexp-search-ring kill-ring))

(add-hook 'savehist-save-hook
          (lambda ()
            (setq kill-ring
                  (mapcar #'substring-no-properties
                          (cl-remove-if-not #'stringp kill-ring)))))

(setq reb-re-syntax 'string)

(setq ffap-machine-p-known 'reject)

(setq window-combination-resize t)

(winner-mode +1)

(defun toggle-delete-other-windows ()
  "Delete other windows in frame if any, or restore previous window config."
  (interactive)
  (if (and winner-mode
           (equal (selected-window) (next-window)))
      (winner-undo)
    (delete-other-windows)))

(global-set-key (kbd "C-x 1") #'toggle-delete-other-windows)

(setq set-mark-command-repeat-pop t)

(advice-add 'save-place-find-file-hook :after
            (lambda (&rest _)
              (when buffer-file-name (ignore-errors (recenter)))))

(setq help-window-select t)

(provide 'core)
