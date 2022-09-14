;;; ox-org2gemlog.el --- Generate gemini formated documents based in your gemlog  -*- lexical-binding: t; -*-


;; Author: bacardi55 <bac@rdi55.pl>
;; Version: 0.1.0
;; Keywords: multimedia, hypermedia
;; Package-Requires: ((emacs "26.1"))
;; URL: https://example.com/jrhacker/superfrobnicate


;;; Commentary:
;;
;; This package add an org-mode export backend.
;; Its role is to export org-mode entries at the
;; right place within a static gemlog generator.
;; The idea is based upon https://ox-hugo.scripter.co/
;; for the concept and is built upon
;; https://git.sr.ht/~abrahms/ox-gemini/ for
;; the actual export.
;; Thanks to both packages maintainers!
;;
;; TODO:
;; - Fix header depth (eg: if the entry is a level 3
;; entry, it means sublevel will need to go up 3 level)
;; - Footnotes bug

;;; Code:

(require 'org)
(require 'ox-gemini)

;;;###autoload (put 'ox-org2gemlog-base-dir 'safe-local-variable 'stringp)
(defcustom ox-org2gemlog-base-dir nil
  "Base directory for gemlog export.
Set either this value, or the GEMLOG_BASE_DIR global property for
export."
  :group 'org-export-gemlog
  :type 'directory)


(defun ox-org2gemlog-final-output-filter (body _backend _info)
  (setq entry-date (org-entry-get nil "EXPORT_DATE"))
  (setq ret (replace-regexp-in-string
             "^# .*$"
             (lambda (substring)
               (concat "---\ntitle: \"" (replace-regexp-in-string "# " "" substring) "\"\ndate: " entry-date "\n---"))
             body))
  ret)

(org-export-define-derived-backend 'org2gemlog 'gemini
  :menu-entry
  '(?G "Export to Gemlog"
        (lambda (a s v b)
          (ox-org2gemlog-export-to-path a s v b nil)))
  :filters-alist
  '((:filter-final-output . ox-org2gemlog-final-output-filter))
  :options-alist
  '((:gemlog-base-dir "GEMLOG_BASE_DIR" nil ox-org2gemlog-base-dir)))


;;;###autoload
(defun ox-org2gemlog-export-to-path (&optional async subtreep visible-only body-only ext-plist)
  "Export an org mode file or subtree to gemini file(s).
A non-nil optional argument ASYNC means the process should happen
asynchronously.  The resulting buffer should be accessible
through the `org-export-stack' interface.

When optional argument SUBTREEP is non-nil, export the sub-tree
at point, extracting information from the headline properties
first.

When optional argument VISIBLE-ONLY is non-nil, don't export
contents of hidden elements.

When optional argument BODY-ONLY is non-nil, strip title and
table of contents from output.

EXT-PLIST, when provided, is a property list with external
parameters overriding Org default settings, but still inferior to
file-local settings."
  ; If subtreep is nil, export the whole file.
  (if (equal subtreep 'nil)
      (ox-org2gemlog-export-full-buffer))

  (if (equal subtreep 't)
      (ox-org2gemlog-export-to-gmi async subtreep visible-only body-only ext-plist)))

(defun ox-org2gemlog--get-export-dir (streep)
    "TODO Comment"
    (let* ((basedir (if (plist-get (org-export-get-environment 'org2gemlog streep) :gemlog-base-dir)
                        (file-name-as-directory (plist-get (org-export-get-environment 'org2gemlog streep) :gemlog-base-dir))
                     (user-error "It is mandatory to set the GEMLOG_BASE_DIR property or the 'ox-org2gemlog-base-dir' local variable")))
           (section (if (org-entry-get nil "EXPORT_GEMLOG_SECTION" :inherit)
                        (org-entry-get nil "EXPORT_GEMLOG_SECTION" :inherit)
                     (user-error "It is mandatory to set the EXPORT_GEMLOG_SECTION property or the 'ox-org2gemlog-base-dir' local variable")))
           (export-dir (concat basedir section)))
         export-dir))

(defun ox-org2gemlog-export-to-gmi (&optional async subtreep visible-only body-only ext-plist)
  "Export file to gmi at the right place within
the static gemlog generator folder"
  (interactive)
  (let* ((save-silently (unless noninteractive
                         t))))
  (unless (org-entry-get nil "EXPORT_FILE_NAME")
    (if (equal save-silently t)
        (message "Unvalid entry, skipping")
      (user-error "Not in a valid Gemlog post subtree (missing EXPORT_FILE_NAME); try again")))
  (let* ((export-dir (ox-org2gemlog--get-export-dir subtreep))
         (file (org-export-output-file-name ".gmi" subtreep export-dir)))
    (org-export-to-file 'org2gemlog file async subtreep visible-only body-only ext-plist)))

;;;###autoload
(defun ox-org2gemlog-export-full-buffer ()
  "Export all valid entries in the current buffer
to gmi files, leveraging the ox-org2gemlog-export-to-gmi
function"
  (interactive)
  (message "Exporting the whole file")
  (org-map-entries
   (lambda ()
     (ox-org2gemlog-export-to-gmi 'nil 't))
   "EXPORT_FILE_NAME<>\"\""))

(provide 'ox-org2gemlog)
;;; ox-org2gemlog.el ends here
