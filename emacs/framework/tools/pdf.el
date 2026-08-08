;;; tools/pdf.el --- doom tools/pdf port  -*- lexical-binding: t; -*-
;;; Commentary:
;;; Ported from doom-modules/modules/tools/pdf. Uses the lunatix-doom compat layer.
;;; Code:

(leaf pdf-tools
  :ensure t
  :defer t
  :mode ("\\.pdf\\'" . pdf-view-mode)
  :magic ("%PDF" . pdf-view-mode)
  :init
  (after! pdf-annot
    (defun +pdf-cleanup-windows-h ()
      "Kill left-over annotation buffers when the document is killed."
      (when (buffer-live-p pdf-annot-list-document-buffer)
        (pdf-info-close pdf-annot-list-document-buffer))
      (when (buffer-live-p pdf-annot-list-buffer)
        (kill-buffer pdf-annot-list-buffer))
      (let ((contents-buffer (get-buffer "*Contents*")))
        (when (and contents-buffer (buffer-live-p contents-buffer))
          (kill-buffer contents-buffer))))
    (add-hook 'pdf-view-mode-hook
              (lambda ()
                (add-hook 'kill-buffer-hook #'+pdf-cleanup-windows-h nil t))))
  :config
  ;; Install epdfinfo after the first PDF file, if needed.
  (defadvice! +pdf--install-epdfinfo-a (fn &rest args)
    :around #'pdf-view-mode
    (if (and (require 'pdf-info nil t)
             (or (pdf-info-running-p)
                 (ignore-errors (pdf-info-check-epdfinfo) t)))
        (apply fn args)
      (fundamental-mode)
      (message "Viewing PDFs in Emacs requires epdfinfo. Use `M-x pdf-tools-install' to build it")))

  ;; Unlike `pdf-tools-install', this only sets up hooks/alists/global modes
  ;; and never builds the epdfinfo binary (which can block Emacs with compiler
  ;; output).  The advice above degrades gracefully if it's missing.
  (pdf-tools-install-noverify)

  (map! :map pdf-view-mode-map :gn "q" #'kill-current-buffer)

  (setq-default pdf-view-display-size 'fit-page)
  ;; Enable hiDPI support, but at the cost of memory! See politza/pdf-tools#51.
  (setq pdf-view-use-scaling t
        pdf-view-use-imagemagick nil)

  ;; The mode-line doesn't serve any useful purpose in annotation windows.
  (when (fboundp 'mode-line-invisible-mode)
    (add-hook 'pdf-annot-list-mode-hook #'mode-line-invisible-mode))
  (add-hook 'pdf-annot-list-mode-hook #'luna-disable-line-numbers-h)

  ;; HACK: Fix doomemacs/core#1107: flickering pdfs when evil-mode is enabled.
  ;;   We need (list nil) as a workaround for emacs-evil/evil#2016.
  (add-hook 'pdf-view-mode-hook (lambda () (setq-local evil-normal-state-cursor (list nil))))

  ;; Refresh FG/BG for pdfs when `pdf-view-midnight-colors' is changed.
  (defun +pdf-reload-midnight-minor-mode-h ()
    (when pdf-view-midnight-minor-mode
      (pdf-info-setoptions
       :render/foreground (car pdf-view-midnight-colors)
       :render/background (cdr pdf-view-midnight-colors)
       :render/usecolors t)
      (pdf-cache-clear-images)
      (pdf-view-redisplay t)))
  (put 'pdf-view-midnight-colors 'custom-set
       (lambda (sym value)
         (set-default sym value)
         (dolist (buffer (doom-buffers-in-mode 'pdf-view-mode))
           (with-current-buffer buffer
             (if (get-buffer-window buffer)
                 (+pdf-reload-midnight-minor-mode-h)
               (add-hook 'luna-switch-buffer-hook #'+pdf-reload-midnight-minor-mode-h
                         nil 'local))))))

  ;; Silence "File *.pdf is large (X MiB), really open?" prompts for pdfs.
  (defadvice! +pdf-suppress-large-file-prompts-a (fn size op-type filename &optional offer-raw)
    :around #'abort-if-file-too-large
    (unless (string-match-p "\\.pdf\\'" filename)
      (funcall fn size op-type filename offer-raw))))

(leaf saveplace-pdf-view
  :ensure t
  :defer t
  :after pdf-view)

;; org-pdftools needs `:lang org' (not enabled in this config); dropped.

;;
;;; tools/tree-sitter

;; Doom builds on the builtin `treesit'; the recipe list below is its grammar

;;; tools/pdf.el ends here
