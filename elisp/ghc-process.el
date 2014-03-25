;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; ghc-process.el
;;;

;; Author:  Kazu Yamamoto <Kazu@Mew.org>
;; Created: Mar  9, 2014

;;; Code:

(require 'ghc-func)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defvar-local ghc-process-running nil)
(defvar-local ghc-process-process-name nil)
(defvar-local ghc-process-original-buffer nil)
(defvar-local ghc-process-original-file nil)
(defvar-local ghc-process-callback nil)

(defvar ghc-interactive-command "ghc-modi")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun ghc-get-process-name ()
  (let ((file (buffer-file-name)))
    (with-temp-buffer
      (ghc-call-process ghc-module-command nil t nil "root" file)
      (goto-char (point-min))
      (when (looking-at "^\\(.*\\)$")
	(match-string-no-properties 1)))))

(defun ghc-with-process (send callback)
  (unless ghc-process-process-name
    (setq ghc-process-process-name (ghc-get-process-name)))
  (when ghc-process-process-name
    (let* ((cbuf (current-buffer))
	   (name ghc-process-process-name)
	   (buf (get-buffer-create (concat " ghc-modi:" name)))
	   (file (buffer-file-name))
	   (cpro (get-process name)))
      (with-current-buffer buf
	(unless ghc-process-running
	  (setq ghc-process-running t)
	  (setq ghc-process-original-buffer cbuf)
	  (setq ghc-process-original-file file)
	  (setq ghc-process-callback callback)
	  (erase-buffer)
	  (let ((pro (ghc-get-process cpro name buf)))
	    (process-send-string pro (funcall send))))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun ghc-get-process (cpro name buf)
  (cond
   ((not cpro)
    (ghc-start-process name buf))
   ((not (eq (process-status cpro) 'run))
    (delete-process cpro)
    (ghc-start-process name buf))
   (t cpro)))

(defun ghc-start-process (name buf)
  (let ((pro (start-file-process name buf ghc-interactive-command)))
    (set-process-filter pro 'ghc-process-filter)
    (set-process-query-on-exit-flag pro nil)
    pro))

(defun ghc-process-filter (process string)
  (with-current-buffer (process-buffer process)
    (goto-char (point-max))
    (insert string)
    (forward-line -1)
    (when (looking-at "^\\(OK\\|NG\\)$")
      (goto-char (point-min))
      (funcall ghc-process-callback)
      (setq ghc-process-running nil))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(provide 'ghc-process)
