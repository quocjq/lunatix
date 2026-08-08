;;; ui/unicode.el --- doom ui/unicode port  -*- lexical-binding: t; -*-
;;; Commentary:
;;; Ported from doom-modules/modules/ui/unicode.
;;; Code:

;;; :ui unicode (ui/unicode has no config.el; doom's autoload only hooked
;;; doom-core's `after-setting-font-hook'). Keep vanilla unicode-fonts setup.
(leaf unicode-fonts
  :ensure t
  :defer t
  :config
  (unicode-fonts-setup))

;;; ui/unicode.el ends here
