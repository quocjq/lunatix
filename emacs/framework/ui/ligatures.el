;;; ui/ligatures.el --- doom ui/ligatures port  -*- lexical-binding: t; -*-
;;; Commentary:
;;; Ported from doom-modules/modules/ui/ligatures.
;;; Code:

;;; :ui ligatures
(defvar +ligatures-extra-symbols
  '(;; org
    :name          "»"
    :src_block     "»"
    :src_block_end "«"
    :quote         "“"
    :quote_end     "”"
    ;; Functional
    :lambda        "λ"
    :def           "ƒ"
    :composition   "∘"
    :map           "↦"
    ;; Types
    :null          "∅"
    :true          "𝕋"
    :false         "𝔽"
    :int           "ℤ"
    :float         "ℝ"
    :str           "𝕊"
    :bool          "𝔹"
    :list          "𝕃"
    ;; Flow
    :not           "￢"
    :in            "∈"
    :not-in        "∉"
    :and           "∧"
    :or            "∨"
    :for           "∀"
    :some          "∃"
    :return        "⟼"
    :yield         "⟻"
    ;; Other
    :union         "⋃"
    :intersect     "∩"
    :diff          "∖"
    :tuple         "⨂"
    :pipe          "" ;; FIXME: find a non-private char
    :dot           "•")
  "Maps identifiers to symbols, recognized by `set-ligatures'.")

(defvar +ligatures-alist
  '((prog-mode "|||>" "<|||" "<==>" "<!--" "####" "~~>" "***" "||=" "||>"
               ":::" "::=" "=:=" "===" "==>" "=!=" "=>>" "=<<" "=/=" "!=="
               "!!." ">=>" ">>=" ">>>" ">>-" ">->" "->>" "-->" "---" "-<<"
               "<~~" "<~>" "<*>" "<||" "<|>" "<$>" "<==" "<=>" "<=<" "<->"
               "<--" "<-<" "<<=" "<<-" "<<<" "<+>" "</>" "###" "#_(" "..<"
               "..." "+++" "/==" "///" "_|_" "www" "&&" "^=" "~~" "~@" "~="
               "~>" "~-" "**" "*>" "*/" "||" "|}" "|]" "|=" "|>" "|-" "{|"
               "[|" "]#" "::" ":=" ":>" ":<" "$>" "==" "=>" "!=" "!!" ">:"
               ">=" ">>" ">-" "-~" "-|" "->" "--" "-<" "<~" "<*" "<|" "<:"
               "<$" "<=" "<>" "<-" "<<" "<+" "</" "#{" "#[" "#:" "#=" "#!"
               "##" "#(" "#?" "#_" "%%" ".=" ".-" ".." ".?" "+>" "++" "?:"
               "?=" "?." "??" ";;" "/*" "/=" "/>" "//" "__" "~~" "(*" "*)"
               "\\\\" "://")
    (t))
  "An alist of ligatures to enable in specific modes.

To configure this variable, use `set-ligatures!'.")

(defvar +ligatures-prog-mode-list nil
  "A list of ligatures to enable in all `prog-mode' buffers.")
(make-obsolete-variable '+ligatures-prog-mode-list "Use `+ligatures-alist' instead" "24.09.0")

(defvar +ligatures-all-modes-list nil
  "A list of ligatures to enable in all buffers.")
(make-obsolete-variable '+ligatures-all-modes-list "Use `+ligatures-alist' instead" "24.09.0")

(defvar +ligatures-extra-alist '((t))
  "A map of major modes to symbol lists (for `prettify-symbols-alist').

To configure this variable, use `set-ligatures!'.")

(defvar +ligatures-extras-in-modes t
  "List of major modes where extra ligatures should be enabled.

Extra ligatures are mode-specific substitutions, defined in
`+ligatures-extra-symbols' and assigned with `set-ligatures!'. This variable
controls where these are enabled.

If t, enable it everywhere (except `fundamental-mode').
If the first element is not, enable it in any mode besides what is listed.
If nil, don't enable these extra ligatures anywhere.")

(defun +ligatures--enable-p (modes)
  "Return t if ligatures should be enabled in this buffer depending on MODES."
  (unless (eq major-mode 'fundamental-mode)
    (or (eq modes t)
        (if (eq (car modes) 'not)
            (not (apply #'derived-mode-p (cdr modes)))
          (apply #'derived-mode-p modes)))))

(defun +ligatures-init-extra-symbols-h ()
  "Set up `prettify-symbols-mode' for the current buffer.

Overwrites `prettify-symbols-alist' and activates `prettify-symbols-mode' if
(and only if) there is an associated entry for the current major mode (or a
parent mode) in `+ligatures-extra-alist' AND the current mode (or a parent mode)
isn't disabled in `+ligatures-extras-in-modes'."
  (when after-init-time
    (when-let*
        (((+ligatures--enable-p +ligatures-extras-in-modes))
         (symbols
          (if-let* ((symbols (assq major-mode +ligatures-extra-alist)))
              (cdr symbols)
            (cl-loop for (mode . symbols) in +ligatures-extra-alist
                     if (derived-mode-p mode)
                     return symbols))))
      (setq prettify-symbols-alist
            (append symbols
                    ;; Don't overwrite global defaults
                    (default-value 'prettify-symbols-alist)))
      (when (bound-and-true-p prettify-symbols-mode)
        (prettify-symbols-mode -1))
      (prettify-symbols-mode +1))))

;; When you get to the right edge, it goes back to how it normally prints
(setq prettify-symbols-unprettify-at-point 'right-edge)

(when (modulep! +extra)
  (add-hook 'after-change-major-mode-hook #'+ligatures-init-extra-symbols-h))

;; APROX: doom's cond used emacs-mac/harfbuzz feature detection; this config
;; just uses the ligature package directly (works on harfbuzz builds).
(leaf ligature
  :ensure t
  :defer t
  :config
  (with-no-warnings
    (when +ligatures-prog-mode-list
      (setf (alist-get 'prog-mode +ligatures-alist) +ligatures-prog-mode-list))
    (when +ligatures-all-modes-list
      (setf (alist-get t +ligatures-alist) +ligatures-all-modes-list)))
  (dolist (lig +ligatures-alist)
    (ligature-set-ligatures (car lig) (cdr lig)))
  (global-ligature-mode 1))

(defun set-ligatures! (modes &rest plist)
  "Associate string patterns with icons in certain major-modes.

MODES is a major mode symbol or a list of them.
PLIST is a property list whose keys must match keys in
`+ligatures-extra-symbols', and whose values are strings representing the text
to be replaced with that symbol.

If the car of PLIST is nil, then unset any pretty symbols and ligatures
previously defined for MODES."
  (declare (indent defun))
  (if (null (car-safe plist))
      (dolist (mode (ensure-list modes))
        (setf (alist-get mode +ligatures-extra-alist nil t) nil))
    (let ((results))
      (while plist
        (let ((key (pop plist)))
          (when-let* ((char (plist-get +ligatures-extra-symbols key)))
            (push (cons (pop plist) char) results))))
      (dolist (mode (ensure-list modes))
        (setf (alist-get mode +ligatures-extra-alist)
              (if-let* ((old-results (alist-get mode +ligatures-extra-alist)))
                  (dolist (cell results old-results)
                    (setf (alist-get (car cell) old-results) (cdr cell)))
                results))))))

(defun set-font-ligatures! (modes &rest ligatures)
  "Associate string patterns with ligatures in certain major-modes.

MODES is a major mode symbol or a list of them.
LIGATURES is a list of ligatures that should be handled by the font, like \"==\"
or \"-->\"."
  (declare (indent defun))
  (after! ligature
    (if (or (null ligatures) (equal ligatures '(nil)))
        (dolist (table ligature-composition-table)
          (let ((modes (ensure-list modes))
                (tmodes (car table)))
            (cond ((and (listp tmodes) (cl-intersection modes tmodes))
                   (let ((tmodes (cl-nset-difference tmodes modes)))
                     (setq ligature-composition-table
                           (if tmodes
                               (cons tmodes (cdr table))
                             (delete table ligature-composition-table)))))
                  ((memq tmodes modes)
                   (setq ligature-composition-table (delete table ligature-composition-table))))))
      (ligature-set-ligatures modes ligatures))))

;;; ui/ligatures.el ends here
