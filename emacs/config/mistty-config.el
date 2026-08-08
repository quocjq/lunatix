;;; mistty-config.el --- in-Emacs terminal via comint (live config.org Mistty)  -*- lexical-binding: t; -*-

(leaf mistty
  :ensure t
  :commands (mistty mistty-in-project mistty-sudo mistty-ssh)
  :config
  (setq mistty-process-type 'emulator
        mistty-shell-command "nu"
        mistty-shell "/usr/bin/env nu"
        mistty-shell-arg '("-i")
        mistty-width 80
        mistty-height 24))

;; SPC v — Term
(after! mistty
  (lunatix-leader
    "v"   '("Term")
    "vt"  #'mistty-in-project
    "vo"  #'mistty
    "vs"  #'mistty-sudo
    "vh"  #'mistty-ssh
    "vq"  #'mistty-send-key
    "vc"  #'mistty-clear
    "vn"  #'mistty-next-input
    "vp"  #'mistty-previous-input))

;;; mistty-config.el ends here

(provide 'mistty-config)
