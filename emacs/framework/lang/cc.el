;;; lang/cc.el --- doom lang/cc port  -*- lexical-binding: t; -*-
;;; Commentary:
;;; Ported from doom-modules/modules/lang/cc.
;;; Code:

;;; -- cc helpers (autoload.el) ----------------------------------------------

(defun +cc--re-search-for (regexp)
  (save-excursion
    (save-restriction
      (save-match-data
        (widen)
        (goto-char (point-min))
        (re-search-forward regexp magic-mode-regexp-match-limit t)))))

(defun +cc-c-c++-objc-mode ()
  "Uses heuristics to detect `c-mode', `objc-mode' or `c++-mode'.

1. Checks if there are nearby cpp/cc/m/mm files with the same name.
2. Checks for ObjC and C++-specific keywords and libraries.
3. Falls back to `+cc-default-header-file-mode', if set.
4. Otherwise, activates `c-mode'.

This is meant to replace `c-or-c++-mode' (introduced in Emacs 26.1)."
  (funcall
   (major-mode-remap
    (let ((base (file-name-sans-extension (buffer-file-name (buffer-base-buffer)))))
      (cond ((or (file-exists-p (concat base ".cpp"))
                 (file-exists-p (concat base ".cc")))
             'c++-mode)
            ((or (file-exists-p (concat base ".m"))
                 (file-exists-p (concat base ".mm"))
                 (+cc--re-search-for
                  (concat "^[ \t\r]*\\(?:"
                          "@\\(?:class\\|interface\\|property\\|end\\)\\_>"
                          "\\|#import +<Foundation/Foundation.h>"
                          "\\|[-+] ([a-zA-Z0-9_]+)"
                          "\\)")))
             'objc-mode)
            ((+cc--re-search-for
              (let ((id "[a-zA-Z0-9_]+") (ws "[ \t\r]+") (ws-maybe "[ \t\r]*"))
                (concat "^" ws-maybe "\\(?:"
                        "using" ws "\\(?:namespace" ws "std;\\|std::\\)"
                        "\\|" "namespace" "\\(?:" ws id "\\)?" ws-maybe "{"
                        "\\|" "class"     ws id ws-maybe "[:{\n]"
                        "\\|" "template"  ws-maybe "<.*>"
                        "\\|" "#include"  ws-maybe "<\\(?:string\\|iostream\\|map\\)>"
                        "\\)")))
             'c++-mode)
            ((functionp +cc-default-header-file-mode)
             +cc-default-header-file-mode)
            ('c-mode))))))

(defun +cc-resolve-include-paths ()
  (cl-loop with path = (or buffer-file-name default-directory)
           for dir in +cc-default-include-paths
           if (file-name-absolute-p dir)
           collect dir
           else if (locate-dominating-file
                    path (lambda (d) (file-exists-p (expand-file-name dir d))))
           collect (expand-file-name dir it)))

(defvar +cc--project-includes-alist nil)
(defun +cc-init-ffap-integration-h ()
  "Takes the local project include paths and registers them with ffap.
This way, `find-file-at-point' will know where to find most header files."
  (when-let* ((project-root (or (and (fboundp 'lsp-workspace-root)
                                     (lsp-workspace-root))
                                (luna-project-root))))
    (require 'ffap)
    (make-local-variable 'ffap-c-path)
    (make-local-variable 'ffap-c++-path)
    (cl-loop for dir in (or (cdr (assoc project-root +cc--project-includes-alist))
                            (+cc-resolve-include-paths))
             do (add-to-list (pcase major-mode
                               ((or `c-mode `c-ts-mode) 'ffap-c-path)
                               ((or `c++-mode `c++-ts-mode) 'ffap-c++-path))
                             (expand-file-name dir project-root)))))

(defun +cc-c++-lineup-inclass (langelem)
  "Indent inclass lines one level further than access modifier keywords."
  (and (eq major-mode 'c++-mode)
       (or (assoc 'access-label c-syntactic-context)
           (save-excursion
             (save-match-data
               (re-search-backward
                "\\(?:p\\(?:ublic\\|r\\(?:otected\\|ivate\\)\\)\\)"
                (c-langelem-pos langelem) t))))
       '++))

(defun +cc-lineup-arglist-close (langelem)
  "Line up the closing brace in an arglist with the opening brace IF cursor is
preceded by the opening brace or a comma (disregarding whitespace in between)."
  (when (save-excursion
          (save-match-data
            (skip-chars-backward " \t\n" (c-langelem-pos langelem))
            (memq (char-before) (list ?, ?\( ?\;))))
    (c-lineup-arglist langelem)))

;;; lang/cc.el ends here