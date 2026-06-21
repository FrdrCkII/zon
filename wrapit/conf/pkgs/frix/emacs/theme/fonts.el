(add-to-list 'default-frame-alist '(font . "monospace"))

(when (display-graphic-p)
  (set-face-attribute 'default nil
                      :family "monospace"
                      :height 140)
  (set-face-attribute 'fixed-pitch nil
                      :family "monospace"
                      :height 140))

(provide 'fonts)
