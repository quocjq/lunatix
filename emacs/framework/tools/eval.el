;;; tools/eval.el --- doom tools/eval port  -*- lexical-binding: t; -*-
;;; Commentary:
;;; Ported from doom-modules/modules/tools/eval. Uses the lunatix-doom compat layer.
;;; Code:

;;; tools/eval

(defgroup +eval nil
  "Tools and commands for evaluating code universally and managing REPLs."
  :group 'tools)

(defcustom +eval-handler-functions
  '(+eval-with-repl-fn
    +eval-with-mode-handler-fn
    +eval-with-quickrun-fn)
  "A list of functions to execute when evaluating a region/buffer.
Stops at the first function to return non-nil."
  :type 'hook
  :group '+eval)

(defcustom +eval-popup-min-lines 4
  "The output height threshold (inclusive) before output is displayed in a
popup buffer rather than an overlay on the line at point."
  :type 'integer
  :group '+eval)

(setq eval-expression-print-length nil
      eval-expression-print-level  nil)

(global-set-key [remap eval-region] #'+eval/region)
(global-set-key [remap eval-buffer] #'+eval/buffer)

(defvar +eval-repl-handler-alist nil
  "An alist mapping major modes to plists that describe REPLs.")

(defun set-repl-handler! (modes command &rest plist)
  "Defines a REPL for MODES."
  (declare (indent defun))
  (dolist (mode (ensure-list modes))
    (setf (alist-get mode +eval-repl-handler-alist)
          (cons command plist))))

(defvar +eval-handler-alist nil
  "Alist mapping major modes to interactive runner functions.")

(defun set-eval-handler! (modes command)
  "Define a code evaluator for major mode MODES with `quickrun'."
  (declare (indent defun))
  (dolist (mode (ensure-list modes))
    (cond ((symbolp command)
           (setf (alist-get mode +eval-handler-alist nil t)
                 command))
          ((stringp command)
           (after! quickrun
             (setf (alist-get mode (if (stringp mode)
                                       quickrun-file-alist
                                     quickrun--major-mode-alist)
                              nil t)
                   command)))
          ((listp command)
           (after! quickrun
             (quickrun-add-command
               (or (alist-get mode quickrun--major-mode-alist)
                   (string-remove-suffix "-mode" (symbol-name mode)))
               command :mode mode))))))

(defvar +eval-repl-buffers (make-hash-table :test 'equal)
  "The buffer of the last open repl.")

(defvar +eval-repl-plist nil)

(defun +eval-current-repl-buffer (&optional mode)
  "Return the last active REPL buffer associated with this major mode."
  (when-let* ((project-root (luna-project-root))
              (key (cons (or mode major-mode) project-root))
              (buffer (gethash key +eval-repl-buffers)))
    (and (bufferp buffer)
         (buffer-live-p buffer)
         (buffer-local-value '+eval-repl-plist buffer)
         buffer)))

(defun +eval-repl-select (prompt)
  "Prompt the user to select a REPL."
  (let* ((knowns
          (mapcar
           (lambda (spec)
             (unless (fboundp (car spec))
               (error "Given string/symbol is not a major mode: %s" (car spec)))
             (list (string-join
                    (split-string
                     (capitalize (string-remove-suffix "-mode" (symbol-name (car spec))))
                     "-")
                    " ")
                   (cadr spec)))
           +eval-repl-handler-alist))
         (founds
          (mapcar
           (lambda (spec)
             (list (string-join (split-string (capitalize (cadr spec)) "-") " ")
                   (car spec)))
           (cl-loop for sym being the symbols
                    for sym-name = (symbol-name sym)
                    if (string-match "^\\(?:\\+\\)?\\([^/]+\\)/open-\\(?:\\(.+\\)-\\)?repl$" sym-name)
                    collect (list sym (match-string-no-properties 1 sym-name)))))
         (repls (cl-delete-duplicates (append knowns founds) :test #'equal)))
    (or (assoc (or (completing-read (or prompt "Open a REPL for: ")
                                    (mapcar #'car repls))
                   (user-error "aborting"))
               repls)
        (error "couldn't find a valid repl for %s" major-mode))))

(defun +eval--repl-open (spec &optional displayfn input)
  "Open a repl via the given DISPLAYFN."
  (maphash (lambda (key buffer)
             (unless (buffer-live-p buffer)
               (remhash key +eval-repl-buffers)))
           +eval-repl-buffers)
  (pcase-let ((`(_ ,fn . ,plist) spec))
    (unless (commandp fn)
      (error "couldn't find a valid REPL handler for %s" major-mode))
    (let* ((project-root (luna-project-root))
           (key (cons major-mode project-root))
           buffer)
      (setq buffer
            (funcall (or displayfn #'get-buffer-create)
                     (if (buffer-live-p buffer)
                         buffer
                       (setq buffer
                             (save-window-excursion
                               (if (commandp fn)
                                   (call-interactively fn)
                                 (funcall fn))))
                       (unless buffer
                         (error "REPL handler %S couldn't open the REPL buffer" fn))
                       (unless (bufferp buffer)
                         (error "REPL handler %S failed to return a buffer" fn))
                       (with-current-buffer buffer
                         (setq-local +eval-repl-plist (append (list :repl t) plist)))
                       (puthash key buffer +eval-repl-buffers)
                       buffer)))
      (when (bufferp buffer)
        (with-current-buffer buffer
          (unless (or (derived-mode-p 'term-mode)
                      (eq (current-local-map) (bound-and-true-p term-raw-map)))
            (goto-char (if (and (derived-mode-p 'comint-mode)
                                (cdr comint-last-prompt))
                           (cdr comint-last-prompt)
                         (point-max))))
          (when (bound-and-true-p evil-local-mode)
            (call-interactively #'evil-append-line))
          (when input
            (insert input))
          t)))))

(defun +eval--repl-sender-for (mode &optional beg end)
  (when-let*
      ((plist (cdr (alist-get mode +eval-repl-handler-alist)))
       (fn (or (plist-get plist (if (and beg end) :send-region :send-buffer))
               (unless (and beg end) (plist-get plist :send-region)))))
    (if (and beg end)
        (lambda () (funcall fn beg end))
      fn)))

(defun +eval-with-repl-fn (beg end &optional type)
  "Evaluate the region between BEG and END (inclusive) in an open REPL."
  (when-let* ((buf (+eval-current-repl-buffer))
              ((get-buffer-window buf)))
    (if-let* ((fn (if (eq type 'buffer)
                      (+eval--repl-sender-for major-mode)
                    (+eval--repl-sender-for major-mode beg end))))
        (funcall fn)
      ;; Manually feed selection line-by-line if this repl has no
      ;; :send-buffer/:send-region properties.
      (let* ((region (buffer-substring-no-properties beg end))
             (region
              (with-temp-buffer
                (save-excursion (insert region))
                (when (> (skip-chars-forward "\n") 0)
                  (delete-region (point-min) (point)))
                (indent-rigidly (point-min) (point-max) (- (current-indentation)))
                (buffer-string))))
        (with-selected-window (get-buffer-window buf)
          (with-current-buffer buf
            (goto-char (point-max))
            (dolist (line (split-string region "\n"))
              (insert line)
              (if (bound-and-true-p evil-local-mode)
                  (dlet (evil-move-cursor-back)
                    (evil-save-state
                      (evil-append-line 1)
                      (call-interactively (doom-lookup-key (kbd "RET")))))
                (call-interactively (doom-lookup-key (kbd "RET"))))))))
      t)))

(defun +eval-with-mode-handler-fn (beg end &optional _type mode)
  "Evaluate the selection/buffer using a mode appropriate handler."
  (when-let* ((fn (alist-get (or mode major-mode) +eval-handler-alist)))
    (funcall fn beg end)))

(defun +eval-with-quickrun-fn (beg end &optional type)
  "Evaluate the region or buffer with `quickrun'."
  (when (require 'quickrun nil t)
    (pcase type
      (`buffer (quickrun))
      (`region (quickrun-region beg end))
      (`replace (quickrun-replace-region beg end)))
    t))

(defun +eval/buffer ()
  "Evaluate the whole buffer and display the output."
  (interactive)
  (run-hook-with-args-until-success
   '+eval-handler-functions (point-min) (point-max) 'buffer))

(defun +eval/region (beg end)
  "Evaluate a region between BEG and END and display the output."
  (interactive "r")
  (run-hook-with-args-until-success
   '+eval-handler-functions beg end 'region))

(defun +eval/line-or-region ()
  "Evaluate the current line or selected region."
  (interactive)
  (if (use-region-p)
      (call-interactively #'+eval/region)
    (+eval/region (pos-bol) (pos-eol))))

(defun +eval/buffer-or-region ()
  "Execute `+eval/region' if a selection is active, otherwise `+eval/buffer'."
  (interactive)
  (call-interactively
   (if (luna-region-active-p)
       #'+eval/region
     #'+eval/buffer)))

(defun +eval/region-and-replace (beg end)
  "Evaluate a region between BEG and END, and replace it with the result."
  (interactive "r")
  (if (not (derived-mode-p 'emacs-lisp-mode))
      (quickrun-replace-region beg end)
    (kill-region beg end)
    (condition-case nil
        (prin1 (eval (read (current-kill 0)))
               (current-buffer))
      (error (message "Invalid expression")
             (insert (current-kill 0))))))

(defun +eval-display-results-in-popup (output &optional _source-buffer)
  "Display OUTPUT in a popup buffer at the bottom of the screen."
  (let ((output-buffer (get-buffer-create "*doom eval*")))
    (with-current-buffer output-buffer
      (setq-local scroll-margin 0)
      (erase-buffer)
      (save-excursion (insert output))
      (if (fboundp '+word-wrap-mode)
          (+word-wrap-mode +1)
        (visual-line-mode +1)))
    (when-let* ((win (display-buffer output-buffer)))
      (fit-window-to-buffer win (/ (frame-height) 2)
                            nil (/ (frame-width) 2)))
    output-buffer))

(defun +eval-display-results-in-overlay (output &optional source-buffer)
  "Display OUTPUT in a floating overlay next to or below the cursor."
  (require 'eros)
  (with-current-buffer (or source-buffer (current-buffer))
    (let* ((this-command #'+eval/buffer-or-region)
           (prefix eros-eval-result-prefix)
           (lines (split-string output "\n"))
           (prefixlen (length prefix))
           (len (+ (apply #'max (mapcar #'length lines))
                   prefixlen))
           (next-line? (or (cdr lines)
                           (< (- (window-width)
                                 (save-excursion (goto-char (line-end-position))
                                                 (- (current-column)
                                                    (window-hscroll))))
                              len)))
           (pad (if next-line?
                    (+ (window-hscroll) prefixlen)
                  0)))
      (dlet (eros-overlays-use-font-lock)
        (eros--make-result-overlay
            (concat (make-string (max 0 (- pad prefixlen)) ?\s)
                    prefix
                    (string-join lines (concat hard-newline (make-string pad ?\s))))
          :where (if next-line?
                     (line-beginning-position 2)
                   (line-end-position))
          :duration eros-eval-result-duration
          :format "%s")))))

(defun +eval-display-results (output &optional source-buffer)
  "Display OUTPUT in an overlay or a popup buffer."
  (funcall (if (or current-prefix-arg
                   (with-temp-buffer
                     (insert output)
                     (or (>= (count-lines (point-min) (point-max))
                             +eval-popup-min-lines)
                         (>= (string-width
                              (buffer-substring (point-min)
                                                (save-excursion
                                                  (goto-char (point-min))
                                                  (line-end-position))))
                             (window-width))))
                   (not (require 'eros nil t)))
               #'+eval-display-results-in-popup
             #'+eval-display-results-in-overlay)
           output source-buffer)
  output)

(defun +eval/open-repl-same-window (&optional spec input)
  "Open (or reopen) the REPL for the current major-mode in this window."
  (interactive
   (list (or (unless current-prefix-arg
               (assq major-mode +eval-repl-handler-alist))
             (+eval-repl-select "Open REPL in this window: "))
         (doom-region)))
  (+eval--repl-open spec #'switch-to-buffer input))

(defun +eval/open-repl-other-window (&optional spec input)
  "Open (or reopen) the REPL for the current major-mode in another window."
  (interactive
   (list (or (unless current-prefix-arg
               (assq major-mode +eval-repl-handler-alist))
             (+eval-repl-select "Open REPL in popup: "))
         (doom-region)))
  (+eval--repl-open spec #'pop-to-buffer input))

(defun +eval/buffer-or-region-in-repl (&optional beg end buffer?)
  "Execute the selected region or whole buffer in the REPL."
  (interactive "rP")
  (unless (+eval-current-repl-buffer)
    (call-interactively #'+eval/open-repl-other-window))
  (let* ((region? (and (not buffer?) (luna-region-active-p)))
         (type (if region? 'region 'buffer))
         (beg (if region? beg (point-min)))
         (end (if region? end (point-max))))
    (+eval-with-repl-fn beg end type)))

(when (modulep! :editor evil)
  (evil-define-operator +eval:region (beg end)
    "Evaluate selection or sends it to the open REPL, if available."
    :move-point nil
    (interactive "<r>")
    (+eval/region beg end))

  (evil-define-operator +eval:replace-region (beg end)
    "Evaluate selection and replace it with its result."
    :move-point nil
    (interactive "<r>")
    (+eval/region-and-replace beg end))

  (evil-define-operator +eval:repl (_beg _end)
    "Open REPL and send the current selection to it."
    :move-point nil
    (interactive "<r>")
    (+eval/open-repl-other-window)))

(leaf quickrun
  :ensure t
  :defer t
  :config
  (setq quickrun-focus-p nil)

  (defadvice! +eval--quickrun-fix-evil-visual-region-a ()
    :override #'quickrun--outputter-replace-region
    (let ((output (buffer-substring-no-properties (point-min) (point-max))))
      (with-current-buffer quickrun--original-buffer
        (cl-destructuring-bind (beg . end)
            (if (bound-and-true-p evil-local-mode)
                (cons evil-visual-beginning evil-visual-end)
              (cons (region-beginning) (region-end)))
          (delete-region beg end)
          (insert output))
        (setq quickrun-option-outputter quickrun--original-outputter))))

  (defun +eval--quickrun-auto-close-a (&rest _)
    "Silently re-create the quickrun popup when re-evaluating."
    (when-let* ((win (get-buffer-window quickrun--buffer-name)))
      (let ((inhibit-message t))
        (quickrun--kill-running-process)
        (message ""))
      (delete-window win)))
  (advice-add #'quickrun :before #'+eval--quickrun-auto-close-a)
  (advice-add #'quickrun-region :before #'+eval--quickrun-auto-close-a)

  (defun +eval-quickrun-shrink-window-h ()
    "Shrink the quickrun output window once code evaluation is complete."
    (when-let* ((win (get-buffer-window quickrun--buffer-name)))
      (with-selected-window win
        (let ((ignore-window-parameters t))
          (shrink-window-if-larger-than-buffer)))))
  (defun +eval-quickrun-scroll-to-bof-h ()
    "Ensures cursor is at beginning of output window when displayed."
    (when-let* ((win (get-buffer-window quickrun--buffer-name)))
      (with-selected-window win
        (goto-char (point-min)))))
  (add-hook 'quickrun-after-run-hook #'+eval-quickrun-shrink-window-h)
  (add-hook 'quickrun-after-run-hook #'+eval-quickrun-scroll-to-bof-h)

  (when (modulep! :tools eval +overlay)
    (defadvice! +eval--show-output-in-overlay-a (fn)
      :filter-return #'quickrun--make-sentinel
      (lambda (process event)
        (funcall fn process event)
        (with-current-buffer quickrun--buffer-name
          (when (> (buffer-size) 0)
            (+eval-display-results
             (string-trim (buffer-string))
             quickrun--original-buffer)))))

    (defadvice! +eval--inhibit-quickrun-popup-a (buf cb)
      :override #'quickrun--pop-to-buffer
      (setq quickrun--original-buffer (current-buffer))
      (save-window-excursion
        (with-current-buffer (pop-to-buffer buf)
          (setq quickrun-option-outputter #'ignore)
          (funcall cb))))

    (advice-add #'quickrun--recenter :override #'ignore)))

(leaf eros
  :ensure t
  :when (modulep! :tools eval +overlay)
  :hook (emacs-lisp-mode . eros-mode))

;;

;;; tools/eval.el ends here
