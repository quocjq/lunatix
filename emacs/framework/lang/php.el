;;; lang/php.el --- doom lang/php port  -*- lexical-binding: t; -*-
;;; Commentary:
;;; Ported from doom-modules/modules/lang/php.
;;; Code:

;;; lang/php
(defvar +php-default-docker-container "php-fpm"
  "The default docker container to run commands in.")

(defvar +php-default-docker-compose "docker-compose.yml"
  "Path to docker-compose file.")

(defvar +php-run-tests-in-docker nil
  "Whether or not to run tests in a docker environment")

;; DEPRECATED: Remove when projectile is replaced with project.el
(after! projectile
  (add-to-list 'projectile-project-root-files "composer.json"))

(defun +php-common-config (mode)
  (let ((mode-hook (intern (format "%s-hook" mode)))
        (mode-map (intern (format "%s-map" mode))))
    (lnav-local-pair (ensure-list mode) "<?"    "?>")
    (lnav-local-pair (ensure-list mode) "<?php" "?>")
    (when (modulep! +lsp)
      (when (executable-find "php-language-server.php")
        (setq lsp-clients-php-server-command "php-language-server.php"))
      (add-hook mode-hook #'lsp))))

(leaf php-mode
  :ensure t
  :config
  (+php-common-config 'php-mode)
  ;; Disable HTML compatibility in php-mode. `web-mode' has superior support for
  ;; php+html. Use the .phtml extension instead.
  (setq php-mode-template-compatibility nil))

;; php-ts-mode: gated on `+tree-sitter` (nil in compat); dropped.

(leaf php-refactor-mode
  :ensure t
  :hook (php-mode . php-refactor-mode))

;; hack-mode: gated on `+hack` (nil in compat); dropped.

(leaf composer
  :ensure t
  :init
  (defvar +php-common-mode-map (make-sparse-keymap))
  :config
  (setq composer-directory-to-managed-file (expand-file-name "composer/" lunaris-cache-dir)))

(leaf phpunit
  :ensure t
  :defer t)

(leaf psysh
  :ensure t
  :defer t)

;; `+php/open-repl' and the Laravel/composer project modes (`def-project-mode!')
;; are not portable; dropped.

;;; lang/php.el ends here