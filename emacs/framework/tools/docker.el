;;; tools/docker.el --- doom tools/docker port  -*- lexical-binding: t; -*-
;;; Commentary:
;;; Ported from doom-modules/modules/tools/docker. Uses the lunatix-doom compat layer.
;;; Code:

;;; tools/docker

(leaf docker
  :ensure t
  :defer t)

(leaf dockerfile-mode
  :ensure t
  :defer t
  :mode "Dockerfile\\'")

(after! dockerfile-mode
  (set-docsets! 'dockerfile-mode "Docker")
  (set-formatter! 'dockfmt '("dockfmt" "fmt" filepath) :modes '(dockerfile-mode))
  (when (modulep! :tools docker +lsp)
    (add-hook 'dockerfile-mode-local-vars-hook #'lsp! 'append)))

(leaf dockerfile-ts-mode
  :ensure nil
  :when (modulep! :tools docker +tree-sitter)
  :defer t
  :init
  (set-tree-sitter! 'dockerfile-mode 'dockerfile-ts-mode 'dockerfile))

;;

;;; tools/docker.el ends here
