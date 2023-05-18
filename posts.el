(defun posts-one-default-home-list-pages (page-tree pages global)
  ""
  (let* ((title (org-element-property :raw-value page-tree))
         (content (org-export-data-with-backend
                   (org-element-contents page-tree)
                   'one nil))
         (website-name (one-default-website-name pages))
         (pages-list (one-default-pages pages)))
    (jack-html
     "<!DOCTYPE html>"
     `(:html
       (:head
        (:meta (@ :name "viewport" :content "width=device-width,initial-scale=1"))
        (:link (@ :rel "stylesheet" :type "text/css" :href "/one.css"))
        (:title ,title))
       (:body
        (:div.header ,website-name)
        (:div.content
         (:div/home-list-pages ,content)
         (:div/pages (:ul ,(reverse pages-list)))))))))

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
                `(:div.toc
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
          (:div.title (:h1 ,title))
          ,(when (not (string-match-p "questions-and-answers" path))
             `(:div/meta-info
               (:div ,date) "/" (:a (@ :href "https://tonyaldon.com/") "Tony Aldon") "/"
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

;;; export links

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

;;; comments

;; (global-set-key
;;  (kbd "C-<f1>")
;;  (lambda () (interactive) (switch-to-buffer "posts.org")))
;; (global-set-key
;;  (kbd "C-<f2>")
;;  (lambda () (interactive)
;;    (with-current-buffer "posts.el"
;;      (eval-buffer))
;;    (with-current-buffer "posts.org"
;;      (one-build-only-html))))

;; (defun posts-rev-link-store ()
;;   ""
;;   (interactive)
;;   (let* ((store-data (org-rev-store-data))
;;          (description-name
;;           (rich-atom-code-name (plist-get store-data :line-content)
;;                                (plist-get store-data :major-mode)))
;;          (link-name (format (plist-get store-data :link-format) description-name)))
;;     (kill-new link-name)))
;;
;; ;; (key-chord-define-global "//" 'posts-rev-link-store)

;;; feed.xml

(defun posts-feed (pages tree global)
  "Produce file ./public/feed.xml"
  (with-temp-file "./public/feed.xml"
    (insert
     (jack-html
      "<?xml version=\"1.0\" encoding=\"utf-8\"?>"
      `(:feed (@ :xmlns "http://www.w3.org/2005/Atom")
        (:title "Elisp posts")
        (:link (@ :href "https://posts.tonyaldon.com"))
        (:id "urn:posts-tonyaldon-com")
        (:updated "2023-05-18T00:00:00Z")
        (:author (:name "Tony Aldon"))
        ,(mapcar
          (lambda (page)
            (let* ((title (plist-get page :one-title))
                   (path (plist-get page :one-path))
                   (link (concat "https://posts.tonyaldon.com" path)))
              (when (not (or (string= path "/")
                             (string= path "/questions-and-answers/")))
                (let ((date (substring path 1 11)))
                  `(:entry
                    (:title ,title)
                    (:link (@ :href ,link))
                    (:id ,(concat "urn:posts-tonyaldon-com:" date))
                    (:updated ,(concat date "T00:00:00Z")))))))
          pages))))))

(add-hook 'one-hook 'posts-feed)
