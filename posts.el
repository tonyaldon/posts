(global-set-key
 (kbd "C-<f1>")
 (lambda () (interactive) (switch-to-buffer "posts.org")))
(global-set-key
 (kbd "C-<f2>")
 (lambda () (interactive)
   (with-current-buffer "posts.el"
     (eval-buffer))
   (with-current-buffer "posts.org"
     (one-build-only-html))))

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

(posts-one-ox-link-org-rev "cb4f4dd89131e5a8956c788fee7ede65f13b2a69:emacs:lisp/ob-awk.el:41"
                           "#ifdef HAVE_PGTK" nil nil)
;; "<a href=\"https://github.com/emacs-mirror/emacs/blob/cb4f4dd89131e5a8956c788fee7ede65f13b2a69/src/alloc.c#L8214\">#ifdef HAVE_PGTK</a>"

(org-link-set-parameters "rev"
			                   :export #'posts-one-ox-link-org-rev)

(defun posts-one-ox-link-info (link description type info)
  "Export builtin org info links. "
  (jack-html `(:span ,link)))

(org-link-set-parameters "info"
			                   :export #'posts-one-ox-link-info)

(defun posts-one-ox-link-help (link description type info)
  "Export builtin org help links. "
  (jack-html `(:span ,link)))

(org-link-set-parameters "help"
			                   :export #'posts-one-ox-link-help)


(defun posts-one-default-doc (page-tree pages global)
  ""
  (let* ((title (org-element-property :raw-value page-tree))
         (path (org-element-property :CUSTOM_ID page-tree))
         (content (org-export-data-with-backend
                   (org-element-contents page-tree)
                   'one nil))
         (website-name (one-default-website-name pages))
         (pages-list (one-default-pages pages))
         (headlines (cdr (one-default-list-headlines page-tree)))
         (toc (when headlines
                `(:div/toc
                  (:div
                   (:div "Table of content")
                   (:div ,(one-default-toc headlines))))))
         (nav (one-default-nav path pages))
         (date (substring path 1 11))
         (reddit-post (org-element-property :REDDIT_POST page-tree))
         (commit-emacs (org-element-property :COMMIT_EMACS page-tree))
         (commit-org-mode (org-element-property :COMMIT_ORG_MODE page-tree)))
    (jack-html
     "<!DOCTYPE html>"
     `(:html
       (:head
        (:meta (@ :name "viewport" :content "width=device-width,initial-scale=1"))
        (:link (@ :rel "stylesheet" :type "text/css" :href "/one.css"))
        (:title ,title))
       (:body
        ;; sidebar-left and sidebar-main are for small devices
        (:div/sidebar-left (@ :onclick "followSidebarLink()")
         ;; (:div (:div ,website-name))
         (:div (:div "Pages"))
         ,pages-list)
        (:div/sidebar-main)
        (:div/header-doc
         (:svg/hamburger (@ :viewBox "0 0 24 24" :onclick "sidebarShow()")
          (:path (@ :d "M21,6H3V5h18V6z M21,11H3v1h18V11z M21,17H3v1h18V17z")))
         (:a (@ :href "/") ,website-name))
        (:div/content-doc
         (:div/sidebar ,pages-list)
         (:article
          (:div/title (:h1 ,title))
          ,(when (not (string-match-p "questions-and-answers" path))
             `(:div/meta-info
               (:div ,date) "/" (:div "Tony Aldon") "/"
               (:div (:a (@ :href ,reddit-post) "comment on reddit"))
               ,(cond
                 ((and commit-emacs commit-org-mode)
                  (list "/" `(:div "emacs revision: " ,(substring commit-emacs 0 12))
                        "/" `(:div "org-mode revision: " ,(substring commit-org-mode 0 12))))
                 (commit-emacs
                  (list "/" `(:div "emacs revision: " ,(substring commit-emacs 0 12))))
                 (commit-org-mode
                  (list "/" `(:div "org-mode revision: " ,(substring commit-org-mode 0 12)))))))
          ,toc
          ,content
          ,nav)))
       (:script "
function sidebarShow() {
  if (window.innerWidth < 481)
    document.getElementById('sidebar-left').style.width = '75vw';
  else {
    document.getElementById('sidebar-left').style.width = 'min(300px, 34vw)';
  }
  document.getElementById('sidebar-main').setAttribute('onclick', 'sidebarHide()');
  document.getElementById('sidebar-main').style.display = 'block';
}
function sidebarHide() {
  document.getElementById('sidebar-left').style.width = '0';
  document.getElementById('sidebar-main').style.display = 'none';
}
")))))
