(setq treesit-font-lock-level 4)

(use-package treesit-auto
  :custom
  (treesit-auto-install nil)
  :config
  (treesit-auto-add-to-auto-mode-alist 'all)
  (global-treesit-auto-mode))

(use-package lsp-bridge
  :config
  (global-lsp-bridge-mode))

(use-package apheleia
  :config
  (setq apheleia-mode-light '(" fmt"))
  (apheleia-global-mode +1))

(provide 'lsp-mode)
