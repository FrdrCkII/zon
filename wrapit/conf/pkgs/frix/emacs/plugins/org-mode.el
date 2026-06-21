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
	          (lambda()
	            (setq truncate-lines nil))))

(provide 'org-mode)
