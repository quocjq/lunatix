;;; lang/java.el --- doom lang/java port  -*- lexical-binding: t; -*-
;;; Commentary:
;;; Ported from doom-modules/modules/lang/java.
;;; Code:

;;; lang/java
(defvar +java-project-package-roots (list "java/" "test/" "main/" "src/" 1)
  "A list of relative directories (strings) or depths (integers) used by
`+java-current-package' to delimit the namespace from the current buffer's full
file path. Each root is tried in sequence until one is found.

If a directory is encountered in the file path, everything before it (including
it) will be ignored when converting the path into a namespace.

An integer depth is how many directories to pop off the start of the relative
file path (relative to the project root). e.g.

Say the absolute path is ~/some/project/src/java/net/lissner/game/MyClass.java
The project root is ~/some/project
If the depth is 1, the first directory in src/java/net/lissner/game/MyClass.java
  is removed: java.net.lissner.game.
If the depth is 2, the first two directories are removed: net.lissner.game.")

(after! projectile
  (add-to-list 'projectile-project-root-files "gradlew")
  (add-to-list 'projectile-project-root-files "settings.gradle"))

(defun +java-android-mode-maybe-h ()
  "Enable `android-mode' if this looks like an android project.

It determines this by the existence of AndroidManifest.xml or
src/main/AndroidManifest.xml."
  (when-let* ((root (luna-project-root)))
    (when (or (file-exists-p (expand-file-name "AndroidManifest.xml" root))
              (file-exists-p (expand-file-name "src/main/AndroidManifest.xml" root)))
      (android-mode +1))))

;;; java-mode (lsp-java)
;; doom gates this on `(modulep! +lsp) (modulep! :tools lsp -eglot)`; the compat
;; layer resolves those bare flags to nil today, but the task requires lsp-java,
;; so it is declared unconditionally. `set-indent-vars!' (doom) is dropped;
;; java-mode indents via `c-basic-offset' by default.
(leaf lsp-java
  :ensure t
  :defer t
  :config
  (setq lsp-java-workspace-dir (luna-profile-data-dir t "java-workspace"))
  (add-hook 'java-mode-hook #'lsp)
  (add-hook 'java-ts-mode-hook #'lsp)
  (when (modulep! :tools debugger +lsp)
    (setq lsp-jt-root (concat lsp-java-server-install-dir "java-test/server/")
          dap-java-test-runner (concat lsp-java-server-install-dir "test-runner/junit-platform-console-standalone.jar"))))

;; dap-java: gated on `:tools debugger +lsp` (nil in compat); dropped.

(leaf android-mode
  :ensure t
  :commands android-mode
  :init
  (dolist (hook '(java-mode-hook groovy-mode-hook nxml-mode-hook))
    (add-hook hook #'+java-android-mode-maybe-h)))

(leaf groovy-mode
  :ensure t
  :defer t
  :mode "\\.g\\(?:radle\\|roovy\\)\\'")

;;; lang/java.el ends here