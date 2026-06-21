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

(provide 'elpa)
