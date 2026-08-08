;;; splash.el --- custom dashboard banner + welcome widget (live config.org)  -*- lexical-binding: t; -*-

(defun my-custom-ascii-banner-fn ()
  (propertize
   "
 _                           _     
| |   _   _ _ __   __ _ _ __(_)___ 
| |  | | | | '_ \\ / _` | '__| / __|
| |__| |_| | | | | (_| | |  | \\__ \\
|_____\\__,_|_| |_|\\__,_|_|  |_|___/
"
   'face '+dashboard-banner))
(setq +dashboard-ascii-banner-fn #'my-custom-ascii-banner-fn)

(defun my-dashboard-widget-welcome ()
  "Inserts a welcome message into the dashboard."
  (insert "\n")
  (+dashboard-insert
   (propertize "Welcome home, Lunixose!"
               'face 'font-lock-keyword-face)))

(setq +dashboard-functions
      '(+dashboard-widget-banner
        my-dashboard-widget-welcome
        +dashboard-widget-footer
        +dashboard-widget-loaded))

;;; splash.el ends here
(provide 'splash)
