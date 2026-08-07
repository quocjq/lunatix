;;; eaf.el --- EAF apps config (live config.org EAF)  -*- lexical-binding: t; -*-

(leaf eaf
  :ensure nil
  :config
  (defalias 'browse-web #'eaf-open-browser)
  (setq eaf-browser-continue-where-left-off t
        eaf-browser-enable-adblocker t
        browse-url-browser-function 'eaf-open-browser))

;;; eaf.el ends here
(provide 'eaf)
