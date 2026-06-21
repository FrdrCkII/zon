(use-package neotree
  :config
  (global-set-key [f8] 'neotree-toggle)
  (setq neo-theme 'ascii)
  :hook
  (neotree-mode . (lambda () (display-line-numbers-mode -1))))

(provide 'tree)
