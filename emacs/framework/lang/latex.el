;;; lang/latex.el --- doom lang/latex port  -*- lexical-binding: t; -*-
;;; Commentary:
;;; Ported from doom-modules/modules/lang/latex.
;;; Code:

;;; lang/latex
(defcustom +latex-indent-item-continuation-offset 'align
  "Level to indent continuation of enumeration-type environments.

I.e., this affects \\item, \\enumerate, and \\description.

Set this to `align' for:

  \\item lines aligned
         like this.

Set to `auto' for continuation lines to be offset by `LaTeX-indent-line':

  \\item lines aligned
    like this, assuming `LaTeX-indent-line' == 2

Any other fixed integer will be added to `LaTeX-item-indent' and the current
indentation level.

Set this to `nil' to disable all this behavior.

You'll need to adjust `LaTeX-item-indent' to control indentation of \\item
itself."
  :type 'symbol)

(defcustom +latex-viewers '(skim evince sumatrapdf zathura okular pdf-tools)
  "A list of enabled LaTeX viewers to use, in this order.

If they don't exist, they will be ignored. Recognized viewers are skim, evince,
sumatrapdf, zathura, okular and pdf-tools."
  :type '(repeat (choice skim evince sumatrapdf zathura okular pdf-tools)))

;; HACK: doom sets `custom-dont-initialize' during the early parts of its
;;   startup process. This stops tex-site's setter on `TeX-modes' from
;;   activating in `tex-site', which auctex loads *very early* from its
;;   autoloads file. `tex-site's existence is hacky, so fix it as a one-off.
(after! tex-site
  (TeX-modes-set 'TeX-modes TeX-modes))

(after! tex
  ;; doom sets these at top level; they are moved here so the AUCTeX variables
  ;; exist (they are not autoloaded).
  (setq TeX-parse-self t ; parse on load
        TeX-auto-save t  ; parse on save
        ;; Use hidden directories for AUCTeX files.
        TeX-auto-local ".auctex-auto"
        TeX-style-local ".auctex-style"
        TeX-source-correlate-mode t
        TeX-source-correlate-method 'synctex
        ;; Don't start the Emacs server when correlating sources.
        TeX-source-correlate-start-server nil
        ;; Just save, don't ask before each compilation.
        TeX-save-query nil)

  ;; Fontify common LaTeX commands (doom +fontification.el).
  (setq font-latex-match-reference-keywords
        '(;; BibLaTeX.
          ("printbibliography" "[{")
          ("addbibresource" "[{")
          ;; Standard commands.
          ("cite" "[{")
          ("citep" "[{")
          ("citet" "[{")
          ("Cite" "[{")
          ("parencite" "[{")
          ("Parencite" "[{")
          ("footcite" "[{")
          ("footcitetext" "[{")
          ;; Style-specific commands.
          ("textcite" "[{")
          ("Textcite" "[{")
          ("smartcite" "[{")
          ("Smartcite" "[{")
          ("cite*" "[{")
          ("parencite*" "[{")
          ("supercite" "[{")
          ;; Qualified citation lists.
          ("cites" "[{")
          ("Cites" "[{")
          ("parencites" "[{")
          ("Parencites" "[{")
          ("footcites" "[{")
          ("footcitetexts" "[{")
          ("smartcites" "[{")
          ("Smartcites" "[{")
          ("textcites" "[{")
          ("Textcites" "[{")
          ("supercites" "[{")
          ;; Style-independent commands.
          ("autocite" "[{")
          ("Autocite" "[{")
          ("autocite*" "[{")
          ("Autocite*" "[{")
          ("autocites" "[{")
          ("Autocites" "[{")
          ;; Text commands.
          ("citeauthor" "[{")
          ("Citeauthor" "[{")
          ("citetitle" "[{")
          ("citetitle*" "[{")
          ("citeyear" "[{")
          ("citedate" "[{")
          ("citeurl" "[{")
          ;; Special commands.
          ("fullcite" "[{")
          ;; Cleveref.
          ("cref" "{")
          ("Cref" "{")
          ("cpageref" "{")
          ("Cpageref" "{")
          ("cpagerefrange" "{")
          ("Cpagerefrange" "{")
          ("crefrange" "{")
          ("Crefrange" "{")
          ("labelcref" "{")))
  (setq font-latex-match-textual-keywords
        '(;; BibLaTeX brackets.
          ("parentext" "{")
          ("brackettext" "{")
          ("hybridblockquote" "[{")
          ;; Auxiliary commands.
          ("textelp" "{")
          ("textelp*" "{")
          ("textins" "{")
          ("textins*" "{")
          ;; Subcaption.
          ("subcaption" "[{")))
  (setq font-latex-match-variable-keywords
        '(;; Amsmath.
          ("numberwithin" "{")
          ;; Enumitem.
          ("setlist" "[{")
          ("setlist*" "[{")
          ("newlist" "{")
          ("renewlist" "{")
          ("setlistdepth" "{")
          ("restartlist" "{")
          ("crefname" "{")))

  ;; Select viewer (doom +viewers.el; `letf!' not available, so a plain
  ;; helper is used instead).
  (let ((prepend (lambda (value)
                   (setq TeX-view-program-selection
                         (delete value TeX-view-program-selection))
                   (add-to-list 'TeX-view-program-selection value))))
    (dolist (viewer (reverse +latex-viewers))
      (pcase viewer
        (`skim
         (when (memq system-type '(darwin))
           (let ((app-path
                  (or (and (file-exists-p "/Applications/Skim.app") "/Applications/Skim.app")
                      (and (file-exists-p "~/Applications/Skim.app") "~/Applications/Skim.app"))))
             (when app-path
               (funcall prepend '(output-pdf "Skim"))
               (add-to-list 'TeX-view-program-list
                            (list "Skim" (format "%s/Contents/SharedSupport/displayline -r -b %%n %%o %%b"
                                                 app-path)))))))
        (`sumatrapdf
         (when (and (memq system-type '(windows-nt))
                    (executable-find "SumatraPDF"))
           (funcall prepend '(output-pdf "SumatraPDF"))))
        (`okular
         (when (executable-find "okular")
           ;; Configure Okular as viewer. Including a bug fix
           ;; (https://bugs.kde.org/show_bug.cgi?id=373855).
           (add-to-list 'TeX-view-program-list
                        '("Okular" ("okular --noraise --unique file:%o" (mode-io-correlate "#src:%n%a"))))
           (funcall prepend '(output-pdf "Okular"))))
        (`zathura
         (when (executable-find "zathura")
           (funcall prepend '(output-pdf "Zathura"))))
        (`evince
         (when (executable-find "evince")
           (funcall prepend '(output-pdf "Evince"))))
        (`pdf-tools
         (when (modulep! :tools pdf)
           (funcall prepend '(output-pdf "PDF Tools"))
           (when (memq system-type '(darwin))
             (add-to-list 'TeX-view-program-list '("PDF Tools" TeX-pdf-tools-sync-view)))
           (add-hook 'TeX-after-compilation-finished-functions #'TeX-revert-document-buffer))))))

  ;; Do not prompt for a master file.
  (setq-default TeX-master t)
  ;; Set-up chktex.
  (setcar (cdr (assoc "Check" TeX-command-list)) "chktex -v6 -H %s")
  ;; Tell Emacs how to parse TeX files and not to auto-fill in math blocks.
  ;; (doom's `setq-hook!' was replaced with a plain lambda.)
  (add-hook 'TeX-mode-hook
            (lambda ()
              (setq-local fill-nobreak-predicate
                          (cons #'texmathp fill-nobreak-predicate))
              (when (boundp 'ispell-parser)
                (setq-local ispell-parser 'tex))))
  ;; Enable word wrapping.
  (add-hook 'TeX-mode-hook #'visual-line-mode)
  ;; Define a function to compile the project.
  (defun +latex/compile ()
    (interactive)
    (TeX-save-document (TeX-master-file))
    (TeX-command TeX-command-default 'TeX-master-file -1))
)

(after! latex
  ;; Add the TOC entry to the sectioning hooks.
  (setq LaTeX-section-hook
        '(LaTeX-section-heading
          LaTeX-section-title
          LaTeX-section-toc
          LaTeX-section-section
          LaTeX-section-label)
        LaTeX-fill-break-at-separators nil
        LaTeX-item-indent 0)
  ;; Provide proper indentation for LaTeX 'itemize', 'enumerate', and
  ;; 'description' environments.
  (dolist (env '("itemize" "enumerate" "description"))
    (add-to-list 'LaTeX-indent-environment-list `(,env +latex-indent-item-fn)))
  ;; Fix doomemacs/core#1849: allow fill-paragraph in itemize, enumerate, &
  ;; description.
  (defadvice! +latex--re-indent-itemize-and-enumerate-and-description-a (fn &rest args)
    :around #'LaTeX-fill-region-as-para-do
    (let ((LaTeX-indent-environment-list
           (append LaTeX-indent-environment-list
                   '(("itemize"     +latex-indent-item-fn)
                     ("enumerate"   +latex-indent-item-fn)
                     ("description" +latex-indent-item-fn)))))
      (apply fn args)))
  (defadvice! +latex--dont-indent-itemize-and-enumerate-and-description-a (fn &rest args)
    :around #'LaTeX-fill-region-as-paragraph
    (let ((LaTeX-indent-environment-list LaTeX-indent-environment-list))
      (dolist (item '("itemize" "enumerate" "description"))
        (setf (alist-get item LaTeX-indent-environment-list nil t #'equal) nil))
      (apply fn args))))

(defun +latex-indent-item-fn ()
  "Indent LaTeX \"itemize\",\"enumerate\", and \"description\" environments.

\"\\item\" is indented `LaTeX-indent-level' spaces relative to the beginning
of the environment.

See `LaTeX-indent-level-item-continuation' for the indentation strategy this
function uses."
  (save-match-data
    (let* ((re-beg "\\\\begin{")
           (re-end "\\\\end{")
           (re-env "\\(?:itemize\\|\\enumerate\\|description\\)")
           (indent (save-excursion
                     (when (looking-at (concat re-beg re-env "}"))
                       (end-of-line))
                     (LaTeX-find-matching-begin)
                     (+ LaTeX-item-indent (current-column))))
           (contin (pcase +latex-indent-item-continuation-offset
                     (`auto LaTeX-indent-level)
                     (`align 6)
                     (`nil (- LaTeX-indent-level))
                     (x x))))
      (cond ((looking-at (concat re-beg re-env "}"))
             (or (save-excursion
                   (beginning-of-line)
                   (ignore-errors
                     (LaTeX-find-matching-begin)
                     (+ (current-column)
                        LaTeX-item-indent
                        LaTeX-indent-level
                        (if (looking-at (concat re-beg re-env "}"))
                            contin
                          0))))
                 indent))
            ((looking-at (concat re-end re-env "}"))
             (save-excursion
               (beginning-of-line)
               (ignore-errors
                 (LaTeX-find-matching-begin)
                 (current-column))))
            ((looking-at "\\\\item")
             (+ LaTeX-indent-level indent))
            ((+ contin LaTeX-indent-level indent))))))

;; tex-fold: gated on `+fold` (nil in compat); dropped.

(leaf preview
  :ensure nil
  :hook ((LaTeX-mode . LaTeX-preview-setup))
  :config
  (setq-default preview-scale 1.4
                preview-scale-function
                (lambda () (* (/ 10.0 (preview-document-pt)) preview-scale)))
  ;; Don't cache preamble, it creates issues with SyncTeX. Let users enable
  ;; caching if they have compilation times that long.
  (setq preview-auto-cache-preamble nil)
)

(leaf cdlatex
  :ensure t
  ;; doom gates this on `+cdlatex`; the compat resolves the bare flag to nil,
  ;; but +cdlatex is enabled in the registry and the task requires cdlatex.
  :hook (LaTeX-mode . cdlatex-mode)
  :hook (org-mode . org-cdlatex-mode)
  :config
  ;; Use \( ... \) instead of $ ... $.
  (setq cdlatex-use-dollar-to-ensure-math nil)
)
  ;; Disable keys that have overlapping functionality with other parts of the
  ;; config.

;; Nicely indent lines that have wrapped when visual line mode is activated.
(leaf adaptive-wrap
  :ensure t
  :hook (LaTeX-mode . adaptive-wrap-prefix-mode)
  :init (setq-default adaptive-wrap-extra-indent 0))

(leaf evil-tex
  :ensure t
  :when (modulep! :editor evil +everywhere)
  :hook (LaTeX-mode . evil-tex-mode))

;; company-auctex / company-math / company-reftex: gated on `:completion
;; company` (nil in compat); dropped.

;;; BibTeX + RefTeX.
(leaf reftex
  :ensure nil
  :hook (LaTeX-mode . reftex-mode)
  :config
  ;; Get RefTeX working with BibLaTeX, see
  ;; http://tex.stackexchange.com/questions/31966/setting-up-reftex-with-biblatex-citation-commands/31992#31992.
  (setq reftex-cite-format
        '((?a . "\\autocite[]{%l}")
          (?b . "\\blockcquote[]{%l}{}")
          (?c . "\\cite[]{%l}")
          (?f . "\\footcite[]{%l}")
          (?n . "\\nocite{%l}")
          (?p . "\\parencite[]{%l}")
          (?s . "\\smartcite[]{%l}")
          (?t . "\\textcite[]{%l}"))
        reftex-plug-into-AUCTeX t
        reftex-toc-split-windows-fraction 0.3
        ;; This is needed when `reftex-cite-format' is set. See
        ;; https://superuser.com/a/1386206
        LaTeX-reftex-cite-format-auto-activate nil)
  (when (modulep! :editor evil)
    (add-hook 'reftex-mode-hook #'evil-normalize-keymaps))
  (add-hook 'reftex-toc-mode-hook
            (lambda ()
              (reftex-toc-rescan))))

;; Set up mode for bib files.
(after! bibtex
  (setq bibtex-dialect 'biblatex
        bibtex-align-at-equal-sign t
        bibtex-text-indentation 20))

;;; lang/latex.el ends here