;;; ui/window-select.el --- doom ui/window-select port  -*- lexical-binding: t; -*-
;;; Commentary:
;;; Ported from doom-modules/modules/ui/window-select.
;;; Code:

;;; :ui window-select
;; doom uses `switch-window' only with the +switch-window flag (off here), so
;; ace-window handles `other-window'.
(leaf ace-window
  :ensure t
  :defer t
  :config
  ;; +numbers is on, so winum provides number-jumping; leave `aw-keys' default.
  (unless (modulep! +numbers)
    (setq aw-keys '(?a ?s ?d ?f ?g ?h ?j ?k ?l)))
  (setq aw-scope 'frame
        aw-background t))

(leaf winum
  :ensure t
  :defer t
  :config
  ;; winum modifies `mode-line-format' in a destructive manner. I'd rather leave
  ;; it to modeline plugins (or the user) to add this if they want it.
  (setq winum-auto-setup-mode-line nil)
  (winum-mode +1)
  (map! :map evil-window-map
        "0" #'winum-select-window-0-or-10
        "1" #'winum-select-window-1
        "2" #'winum-select-window-2
        "3" #'winum-select-window-3
        "4" #'winum-select-window-4
        "5" #'winum-select-window-5
        "6" #'winum-select-window-6
        "7" #'winum-select-window-7
        "8" #'winum-select-window-8
        "9" #'winum-select-window-9))

;;; ui/window-select.el ends here
