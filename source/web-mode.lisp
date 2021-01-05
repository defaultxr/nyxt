;;;; SPDX-FileCopyrightText: Atlas Engineer LLC
;;;; SPDX-License-Identifier: BSD-3-Clause

(uiop:define-package :nyxt/web-mode
  (:use :common-lisp :trivia :nyxt)
  (:import-from #:keymap #:define-key #:define-scheme)
  (:import-from #:class* #:define-class)
  (:documentation "Mode for web pages"))
(in-package :nyxt/web-mode)
(eval-when (:compile-toplevel :load-toplevel :execute)
  (trivial-package-local-nicknames:add-package-local-nickname :alex :alexandria)
  (trivial-package-local-nicknames:add-package-local-nickname :sera :serapeum))

;; TODO: Remove web-mode from special buffers (e.g. help).
;; This is required because special buffers cannot be part of a history (and it breaks it).
;; Bind C-l to set-url-new-buffer?  Wait: What if we click on a link?  url
;; changes in special buffers should open a new one.
;; Or else we require that all special-buffer-generting commands open a new buffer.

(define-mode web-mode ()
  "Base mode for interacting with documents."
  ((history-blocklist '("https://duckduckgo.com/l/")
                      ;; TODO: Find a more automated way to do it.  WebKitGTK
                      ;; automatically removes such redirections from its
                      ;; history.  How?
                      :type list-of-strings
                      :documentation "URI prefixes to not save in history.
Example: DuckDuckGo redirections should be ignored or else going backward in
history after consulting a result reloads the result, not the duckduckgo
search.")
   (conservative-history-movement-p
    nil
    :type boolean
    :documentation "Whether history navigation is restricted by buffer-local history.")
   (history-forwards-prompting-p
    t
    :type boolean
    :documentation "Whether `history-forwards' is asking the user which history branch to pick when there are several.")
   (history-forwards-to-dead-history-p
    nil
    :type boolean
    :documentation "Whether `history-forwards' considers `id'-less history nodes.")
   (keymap-scheme
    (define-scheme "web"
      scheme:cua
      (list
       "C-M-right" 'history-forwards-all-query
       "C-M-left" 'history-all-query
       "C-shift-h" 'history-all-query
       "C-shift-H" 'history-all-query
       "M-shift-right" 'history-forwards-query
       "M-shift-left" 'history-backwards-query
       "M-right" 'history-forwards
       "M-left" 'history-backwards
       "M-]" 'history-forwards
       "M-[" 'history-backwards
       "C-g" 'follow-hint
       "M-g" 'follow-hint-new-buffer-focus
       "C-u M-g" 'follow-hint-new-buffer
       "C-x C-w" 'copy-hint-url
       "C-c" 'copy
       "button9" 'history-forwards
       "button8" 'history-backwards
       "C-+" 'zoom-in-page
       "C-=" 'zoom-in-page              ; Because + shifted = on QWERTY.
       "C-hyphen" 'zoom-out-page
       "C-0" 'unzoom-page
       "C-button4" 'zoom-in-page
       "C-button5" 'zoom-out-page
       "C-M-c" 'open-inspector
       "C-m g" 'bookmark-hint
       "C-f" 'search-buffer
       "f3" 'search-buffer
       "M-f" 'remove-search-hints
       "C-." 'jump-to-heading
       "end" 'maybe-scroll-to-bottom
       "home" 'maybe-scroll-to-top
       "C-down" 'scroll-to-bottom
       "C-up" 'scroll-to-top
       "C-i" 'autofill
       "C-c '" 'fill-input-from-external-editor
       ;; Leave SPACE and arrow keys unbound so that the renderer decides wether to
       ;; navigate textboxes (arrows), insert or scroll (space).
       "pageup" 'scroll-page-up
       "pagedown" 'scroll-page-down
       "pageend" 'scroll-to-bottom
       "pagehome" 'scroll-to-top
       ;; keypad, gtk:
       "keypadleft" 'scroll-left
       "keypaddown" 'scroll-down
       "keypadup" 'scroll-up
       "keypadright" 'scroll-right
       "keypadend" 'scroll-to-bottom
       "keypadhome" 'scroll-to-top
       "keypadnext" 'scroll-page-down
       "keypadpageup" 'scroll-page-up
       "keypadprior" 'scroll-page-up)
      scheme:emacs
      (list
       "C-M-f" 'history-forwards-all-query
       "C-M-b" 'history-all-query
       "M-f" 'history-forwards-query
       "M-b" 'history-backwards-query
       "C-f" 'history-forwards
       "C-b" 'history-backwards
       "C-g" 'noop                      ; Emacs users may hit C-g out of habit.
       "M-g M-g" 'follow-hint           ; Corresponds to Emacs' `goto-line'.
       "M-g g" 'follow-hint-new-buffer-focus
       "C-u M-g M-g" 'follow-hint-new-buffer
       "C-u M-g g" 'follow-hint-new-buffer
       "C-x C-w" 'copy-hint-url
       "C-y" 'paste
       "M-w" 'copy
       "button9" 'history-forwards
       "button8" 'history-backwards
       "C-p" 'scroll-up
       "C-n" 'scroll-down
       "C-x C-+" 'zoom-in-page
       "C-x C-=" 'zoom-in-page ; Because + shifted = on QWERTY.
       "C-x C-hyphen" 'zoom-out-page
       "C-x C-0" 'unzoom-page
       "C-m g" 'bookmark-hint
       "C-s s" 'search-buffer
       "C-s k" 'remove-search-hints
       "C-." 'jump-to-heading
       "M-s->" 'scroll-to-bottom
       "M-s-<" 'scroll-to-top
       "M->" 'scroll-to-bottom
       "M-<" 'scroll-to-top
       "C-v" 'scroll-page-down
       "M-v" 'scroll-page-up)

      scheme:vi-normal
      (list
       "H" 'history-backwards
       "L" 'history-forwards
       "M-h" 'history-backwards-query
       "M-l" 'history-forwards-query
       "M-H" 'history-all-query
       "M-L" 'history-forwards-all-query
       "f" 'follow-hint
       "F" 'follow-hint-new-buffer-focus
       "; f" 'follow-hint-new-buffer
       "button9" 'history-forwards
       "button8" 'history-backwards
       "+" 'zoom-in-page
       "hyphen" 'zoom-out-page
       "0" 'unzoom-page
       "z i" 'zoom-in-page
       "z o" 'zoom-out-page
       "z z" 'unzoom-page
       "g h" 'jump-to-heading
       "/" 'search-buffer
       "?" 'remove-search-hints
       "m f" 'bookmark-hint
       "h" 'scroll-left
       "j" 'scroll-down
       "k" 'scroll-up
       "l" 'scroll-right
       "G" 'scroll-to-bottom
       "g g" 'scroll-to-top
       "C-f" 'scroll-page-down
       "C-b" 'scroll-page-up
       "space" 'scroll-page-down
       "s-space" 'scroll-page-up
       "pageup" 'scroll-page-up
       "pagedown" 'scroll-page-down)))))

(sera:export-always '%clicked-in-input?)
(define-parenscript %clicked-in-input? ()
  (ps:chain document active-element tag-name))

(sera:export-always 'input-tag-p)
(declaim (ftype (function ((or string null)) boolean) input-tag-p))
(defun input-tag-p (tag)
  (or (string= tag "INPUT")
      (string= tag "TEXTAREA")))

(defun call-non-input-command-or-forward (command &key (buffer (current-buffer))
                                                    (window (current-window)))
  (let ((response (%clicked-in-input?)))
    (if (input-tag-p response)
        (ffi-generate-input-event
         window
         (nyxt::last-event buffer))
        (funcall-safely command))))

(define-command paste-or-set-url (&optional (buffer (current-buffer)))
  "Paste text if active element is an input tag, forward event otherwise."
  (let ((response (%clicked-in-input?)))
    (let ((url-empty (url-empty-p (url-at-point buffer))))
      (if (and (input-tag-p response) url-empty)
          (funcall-safely #'paste)
          (unless url-empty
            (make-buffer-focus :url (url-at-point buffer)))))))

(define-command maybe-scroll-to-bottom (&optional (buffer (current-buffer)))
  "Scroll to bottom if no input element is active, forward event otherwise."
  (call-non-input-command-or-forward #'scroll-to-bottom :buffer buffer))

(define-command maybe-scroll-to-top (&optional (buffer (current-buffer)))
  "Scroll to top if no input element is active, forward event otherwise."
  (call-non-input-command-or-forward #'scroll-to-top :buffer buffer))

(declaim (ftype (function (htree:node &optional buffer)) set-url-from-history))
(defun set-url-from-history (history-node &optional (buffer (current-buffer)))
  "Go to HISTORY-NODE's URL."
  (with-data-access (history (history-path buffer))
    (if (eq history-node (htree:current history))
        (echo "History entry is already the current URL.")
        (progn
          (setf (htree:current history) history-node
                (id (htree:data history-node)) (id buffer))
          (buffer-load (url (htree:data history-node)))))))

(defun conservative-history-filter (web-mode)
  #'(lambda (node)
      (and (conservative-history-movement-p web-mode)
           (string/= (id (htree:data node)) (id (buffer web-mode))))))

(define-command history-backwards (&optional (buffer (current-buffer)))
  "Go to parent URL in history."
  (with-data-access (history (history-path buffer))
    (let ((parents (remove-if (conservative-history-filter (find-mode buffer 'web-mode))
                              (htree:parent-nodes history))))
      (if parents
          (set-url-from-history (first parents) buffer)
          (echo "No backward history.")))))

(defun dead-history-filter (web-mode)
  #'(lambda (node)
      (and (history-forwards-to-dead-history-p web-mode)
           (str:emptyp (id (htree:data node))))))

(define-command history-forwards (&optional (buffer (current-buffer)))
  "Go to forward URL in history."
  (with-data-access (history (history-path buffer))
    (let* ((children (remove-if (alex:compose
                                 (dead-history-filter (find-mode buffer 'web-mode))
                                 (conservative-history-filter (find-mode buffer 'web-mode)))
                                (htree:children (htree:current (get-data (history-path buffer))))))
           (selected-child (if (or (< (length children) 2)
                                   (not (history-forwards-prompting-p
                                         (find-mode buffer 'web-mode))))
                               (first children)
                               (prompt-minibuffer
                                :input-prompt "History branch to follow"
                                :suggestion-function
                                (lambda (minibuffer)
                                  (fuzzy-match (input-buffer minibuffer) children))))))
      (if selected-child
          (set-url-from-history selected-child buffer)
          (echo "No forward history.")))))

(defun history-backwards-suggestion-filter (&optional (buffer (current-buffer)))
  "Suggestion function over all parent URLs."
  (let ((parents (remove-if (conservative-history-filter (find-mode buffer 'web-mode))
                            (htree:parent-nodes (get-data (history-path buffer))))))
    (lambda (minibuffer)
      (if parents
          (fuzzy-match (input-buffer minibuffer) parents)
          (error "Cannot navigate backwards.")))))

(define-command history-backwards-query ()
  "Query parent URL to navigate back to."
  (let ((input (prompt-minibuffer
                :input-prompt "Navigate backwards to"
                :suggestion-function (history-backwards-suggestion-filter))))
    (when input
      (set-url-from-history input))))

(defun history-forwards-suggestion-filter (&optional (buffer (current-buffer)))
  "Suggestion function over forward-children URL."
  (let ((children (remove-if (conservative-history-filter (find-mode buffer 'web-mode))
                             (htree:forward-children-nodes (get-data (history-path buffer))))))
    (lambda (minibuffer)
      (if children
          (fuzzy-match (input-buffer minibuffer) children)
          (error "Cannot navigate forwards.")))))

(define-command history-forwards-query ()
  "Query forward-URL to navigate to."
  (let ((input (prompt-minibuffer
                :input-prompt "Navigate forwards to"
                :suggestion-function (history-forwards-suggestion-filter))))
    (when input
      (set-url-from-history input))))

(define-command history-forwards-maybe-query (&optional (buffer (current-buffer)))
  "If current node has multiple chidren, query forward-URL to navigate to.
Otherwise go forward to the only child."
  (if (<= 2 (length (htree:children-nodes (get-data (history-path buffer)))))
      (history-forwards-all-query)
      (history-forwards)))

(defun history-forwards-all-suggestion-filter (&optional (buffer (current-buffer)))
  "Suggestion function over children URL from all branches."
  (let ((children (remove-if (conservative-history-filter (find-mode buffer 'web-mode))
                             (htree:children-nodes (get-data (history-path buffer))))))
    (lambda (minibuffer)
      (if children
          (fuzzy-match (input-buffer minibuffer) children)
          (error "Cannot navigate forwards.")))))

(define-command history-forwards-all-query ()
  "Query URL to forward to, from all child branches."
  (let ((input (prompt-minibuffer
                :input-prompt "Navigate forwards to (all branches)"
                :suggestion-function (history-forwards-all-suggestion-filter))))
    (when input
      (set-url-from-history input))))

(defun history-all-suggestion-filter (&optional (buffer (current-buffer)))
  "Suggestion function over all history URLs."
  (let ((urls (remove-if (conservative-history-filter (find-mode buffer 'web-mode))
                         (htree:all-nodes (get-data (history-path buffer))))))
    (lambda (minibuffer)
      (if urls
          (fuzzy-match (input-buffer minibuffer) urls)
          (error "No history.")))))

(define-command history-all-query ()
  "Query URL to go to, from the whole history."
  (let ((input (prompt-minibuffer
                :input-prompt "Navigate to"
                :suggestion-function (history-all-suggestion-filter))))
    (when input
      (set-url-from-history input))))

(defun integer->unicode-geometric (string-integer)
  "Return geometric block corresponding to the STRING-INTEGER code-point within
the 25A0-25FF range."
  (let ((code-point (and (stringp string-integer)
                      (parse-integer string-integer :junk-allowed t))))
    (if code-point
        (let* ((code-point-start #x25A0)
               (code-point-end #x25FF)
               (range (1+ (- code-point-end code-point-start))))
          (format nil "&#x~X; " (+ code-point-start (mod code-point range))))
        "")))

(define-command buffer-history-tree (&optional (buffer (current-buffer)))
  "Open a new buffer displaying the whole history tree of a buffer."
  (with-current-html-buffer (output-buffer (format nil "*History-~a*" (id buffer))
                                                 'nyxt/history-tree-mode:history-tree-mode)
    (let* ((markup:*auto-escape* nil)
           (mode (find-submode output-buffer 'nyxt/history-tree-mode:history-tree-mode))
           (history (get-data (history-path buffer)))
           (tree `(:ul ,(htree:map-tree
                         #'(lambda (node)
                             `(:li :class
                                   ,(if (equal (id (htree:data node)) (id buffer))
                                        "current-buffer"
                                        "other-buffer")
                               (:a :href ,(object-string (url (htree:data node)))
                                   ,(when (nyxt/history-tree-mode:display-buffer-id-glyphs-p mode)
                                      (integer->unicode-geometric (id (htree:data node))))
                                   ,(let ((title (or (match (title (htree:data node))
                                                       ((guard e (not (str:emptyp e))) e))
                                                     (object-display (url (htree:data node))))))
                                      (if (eq node (htree:current history))
                                          `(:b ,title)
                                          title)))))
                         (gethash (id buffer) (buffer-local-histories-table history))
                         :include-root t
                         :collect-function #'(lambda (a b) `(,@a ,(when b `(:ul ,@b))))))))
      (markup:markup
       (:body (:h1 "History")
              (:style (style output-buffer))
              (:style (style mode))
              (:div (markup:raw
                     (markup:markup*
                      tree))))))))

(define-command history-tree ()
  "Open a new buffer displaying the whole history tree."
  (nyxt::with-current-html-buffer (output-buffer "*History*"
                                                 'nyxt/history-tree-mode:history-tree-mode)
    (let* ((markup:*auto-escape* nil)
           (mode (find-submode output-buffer 'nyxt/history-tree-mode:history-tree-mode))
           (history (let ((dummy-buffer (make-buffer)))
                      (prog1
                          (get-data (history-path dummy-buffer))
                        (delete-buffer :id (id dummy-buffer)))))
           (tree `(:ul ,(htree:map-tree
                         #'(lambda (node)
                             `(:li (:a :href ,(object-string (url (htree:data node)))
                                       ,(when (nyxt/history-tree-mode:display-buffer-id-glyphs-p mode)
                                          (integer->unicode-geometric (id (htree:data node))))
                                       ,(let ((title (or (match (title (htree:data node))
                                                           ((guard e (not (str:emptyp e))) e))
                                                         (object-display (url (htree:data node))))))
                                          (if (eq node (htree:current history))
                                              `(:b ,title)
                                              title)))))
                         (htree:root history)
                         :include-root t
                         :collect-function #'(lambda (a b) `(,@a ,(when b `(:ul ,@b))))))))
      (markup:markup
       (:body (:h1 "History")
              (:style (style output-buffer))
              (:style (style mode))
              (:div (markup:raw
                     (markup:markup*
                      tree))))))))

(define-command list-history (&key (limit 100))
  "Print the user history as a list."
  (flet ((list-history (&key (separator " → ") (limit 20))
           (let* ((path (history-path (current-buffer)))
                  (history (when (get-data path)
                             (sort (htree:all-nodes (get-data path))
                                   #'local-time:timestamp>
                                   :key (lambda (i) (nyxt::last-access (htree:data i)))))))
             (loop for item in (mapcar #'htree:data (sera:take limit history))
                   collect (markup:markup
                            (:li (title item) (unless (str:emptyp (title item)) separator)
                                 (:a :href (object-string (url item))
                                     (object-string (url item)))))))))
    (with-current-html-buffer (buffer "*History list*" 'nyxt/history-tree-mode:history-tree-mode)
      (markup:markup
       (:style (style buffer))
       (:style (cl-css:css
                '((a
                   :color "black")
                  ("a:hover"
                   :color "gray"))))
       (:h1 "History")
       (:ul (list-history :limit limit))))))

(define-command paste ()
  "Paste from clipboard into active-element."
  ;; On some systems like Xorg, clipboard pasting happens just-in-time.  So if we
  ;; copy something from the context menu 'Copy' action, upon pasting we will
  ;; retrieve the text from the GTK thread.  This is prone to create
  ;; dead-locks (e.g. when executing a Parenscript that acts upon the clipboard).
  ;;
  ;; To avoid this, we can 'flush' the clipboard to ensure that the copied text
  ;; is present the clipboard and need not be retrieved from the GTK thread.
  ;; TODO: Do we still need to flush now that we have multiple threads?
  ;; (trivial-clipboard:text (trivial-clipboard:text))
  (%paste))

(defun ring-suggestion-filter (ring)
  (let ((ring-items (containers:container->list ring)))
    (lambda (minibuffer)
      (fuzzy-match (input-buffer minibuffer) ring-items))))

(define-command paste-from-ring ()
  "Show `*browser*' clipboard ring and paste selected entry."
  (let ((ring-item (prompt-minibuffer
                    :suggestion-function (ring-suggestion-filter
                                          (nyxt::clipboard-ring *browser*)))))
    (%paste :input-text ring-item)))

(define-command copy ()
  "Copy selected text to clipboard."
  (let ((input (%copy)))
    (copy-to-clipboard input)
    (echo "Text copied.")))

(define-command autofill ()
  "Fill in a field with a value from a saved list."
  (let ((selected-fill (prompt-minibuffer
                        :input-prompt "Autofill"
                        :suggestion-function
                        (lambda (minibuffer)
                          (fuzzy-match (input-buffer minibuffer)
                                       (autofills *browser*))))))
    (cond ((stringp (autofill-fill selected-fill))
           (%paste :input-text (autofill-fill selected-fill)))
          ((functionp (autofill-fill selected-fill))
           (%paste :input-text (funcall (autofill-fill selected-fill)))))))

(defmethod nyxt:on-signal-notify-uri ((mode web-mode) url)
  (declare (type quri:uri url))
  (flet ((history-add (uri &key (title ""))
           "Add URL to the global/buffer-local history.
The `implicit-visits' count is incremented."
           ;; `buffer-load' has its own data syncronization, so we assume that
           ;; history is up-to-date there.  Using `with-data-access' here is not
           ;; an option -- it will cause the new thread and the thread from
           ;; `buffer-load' to mutually deadlock.
           (let ((history (or (get-data (history-path (current-buffer)))
                              (htree:make))))
             (unless (url-empty-p uri)
               (let* ((maybe-entry (make-instance 'history-entry
                                                  :url uri :id (id (current-buffer))
                                                  :title title))
                      (node (htree:find-data maybe-entry history :ensure-p t :test 'equals))
                      (entry (htree:data node)))
                 (incf (nyxt::implicit-visits entry))
                 (setf (nyxt::last-access entry) (local-time:now))
                 ;; Always update the title since it may have changed since last visit.
                 (setf (title entry) title)
                 (setf (htree:current history) node
                       (current-history-node (current-buffer)) node)))
             (setf (get-data (history-path (current-buffer))) history))))
    (unless (or (url-empty-p url)
                (find-if (alex:rcurry #'str:starts-with? (object-string url))
                         (history-blocklist mode)))
      (with-current-buffer (buffer mode)
        (history-add url :title (title (buffer mode))))))

  (store (data-profile (buffer mode)) (history-path (buffer mode)))
  url)

(defmethod nyxt:on-signal-notify-title ((mode web-mode) title)
  ;; Title may be updated after the URI, so we need to set the history entry again
  ;; with `on-signal-notify-uri'.
  (on-signal-notify-uri mode (url (buffer mode)))
  title)

(defmethod nyxt:on-signal-load-committed ((mode web-mode) url)
  (declare (ignore mode url))
  nil)

(defmethod nyxt:on-signal-load-finished ((mode web-mode) url)
  (unzoom-page :buffer (buffer mode)
               :ratio (current-zoom-ratio (buffer mode)))
  url)

(defmethod nyxt:object-string ((node htree:node))
  (object-string (when node (htree:data node))))
(defmethod nyxt:object-display ((node htree:node))
  (object-display (when node (htree:data node))))
