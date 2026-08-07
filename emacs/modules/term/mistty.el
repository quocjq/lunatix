;;; mistty.el --- in-Emacs terminal via comint (live config.org Mistty)  -*- lexical-binding: t; -*-

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
(map! :leader
      (:prefix ("v" . "Term")
       "t"   #'mistty-in-project
       "o"   #'mistty
       "s"   #'mistty-sudo
       "h"   #'mistty-ssh
       "q"   #'mistty-send-key
       "c"   #'mistty-clear
       "n"   #'mistty-next-input
       "p"   #'mistty-previous-input))

;;; mistty.el ends here
(provide 'mistty)
