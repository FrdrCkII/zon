(use-package doom-themes
  :custom
  (doom-themes-enable-bold t)
  (doom-themes-enable-italic t)
  (doom-themes-treemacs-theme "doom-atom")
  :config
  (load-theme 'doom-one t))

(use-package diff-hl
  :defer t
  :hook
  ((dired-mode . diff-hl-dired-mode)
   (prog-mode . turn-on-diff-hl-mode))
  :config
  (global-diff-hl-mode 1)
  (diff-hl-flydiff-mode 1))

(provide 'theme-doom-atom)
