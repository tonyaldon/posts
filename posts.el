(global-set-key
 (kbd "C-<f1>")
 (lambda () (interactive) (switch-to-buffer "posts.org")))

(defun posts-rev-link-store ()
  ""
  (interactive)
  (let* ((store-data (org-rev-store-data))
         (description-name
          (rich-atom-code-name (plist-get store-data :line-content)
                               (plist-get store-data :major-mode)))
         (link-name (format (plist-get store-data :link-format) description-name)))
    (kill-new link-name)))

;; (key-chord-define-global "//" 'posts-rev-link-store)

(defun posts-one-ox-link-org-rev (link description type info)
  "Export `org-rev' links.

See `org-rev-open'."
  (seq-let (rev repo file line) (split-string link ":")
    (let (href)
      (if (string= repo "emacs")
          (setq href
                (concat
                 "https://github.com/emacs-mirror/emacs/blob/"
                 rev "/"
                 file (or (and line (concat "#L" line)) "")))
        (setq href
              (concat
               "https://git.sr.ht/~bzg/org-mode/tree/"
               rev "/item/"
               file (or (and line (concat "#L" line)) ""))))
      (jack-html
       `(:a (@ :href ,href) ,description)
       ))))

;; [[rev:af6f1298b6f613678ba5ccf9592412872743fe54:org-mode:lisp/ob-awk.el:41][org-babel-tangle-lang-exts]]
;; https://git.sr.ht/~bzg/org-mode/tree/af6f1298b6f613678ba5ccf9592412872743fe54/item/lisp/ob-awk.el#L41

;; (split-string "rev:repo:file:line" ":") ; ("rev" "repo" "file" "line")
;; (posts-one-ox-link-org-rev "rev:repo:file:line" "description" nil nil)

;; https://github.com/emacs-mirror/emacs/blob/cb4f4dd89131e5a8956c788fee7ede65f13b2a69/src/alloc.c#L8214
;; (posts-one-ox-link-org-rev "cb4f4dd89131e5a8956c788fee7ede65f13b2a69:emacs:src/alloc.c:8214" "#ifdef HAVE_PGTK" nil nil)

(posts-one-ox-link-org-rev "af6f1298b6f613678ba5ccf9592412872743fe54:org-mode:lisp/ob-awk.el:41"
                           "org-babel-tangle-lang-exts" nil nil)
;; "<a href=\"https://git.sr.ht/~bzg/org-mode/tree/af6f1298b6f613678ba5ccf9592412872743fe54/item/lisp/ob-awk.el#L41\">org-babel-tangle-lang-exts</a>"

(posts-one-ox-link-org-rev "af6f1298b6f613678ba5ccf9592412872743fe54:org-mode:lisp/ob-awk.el:41"
                           "#ifdef HAVE_PGTK" nil nil)
;; "<a href=\"https://github.com/emacs-mirror/emacs/blob/cb4f4dd89131e5a8956c788fee7ede65f13b2a69/src/alloc.c#L8214\">#ifdef HAVE_PGTK</a>"

(org-link-set-parameters "rev"
			                   :export #'posts-one-ox-link-org-rev)
