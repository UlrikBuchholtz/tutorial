;; emacs org-mode batch configuration
(require 'cask "~/.cask/cask.el")
(cask-initialize "./")
(setq working-dir (f-dirname (f-this-file)))
(add-to-list 'load-path working-dir)
(setq make-backup-files nil)

;;; ORG mode
(require 'org)
(require 'dash)
(require 'dash-functional)
(add-to-list 'load-path (f-join working-dir "elisp"))
(require 'lean-export-util)

(setq org-html-style-include-default nil)
(setq org-html-style-include-scripts nil)

;; set auto load on .org files
(add-to-list 'auto-mode-alist '("\\.org\\'" . org-mode))

;; org mode customisations
'(org-export-blocks (quote ((comment org-export-blocks-format-comment t) (ditaa org-export-blocks-format-ditaa nil) (dot org-export-blocks-format-dot t) (r org-export-blocks-format-R nil) (R org-export-blocks-format-R nil))))
'(org-export-html-inline-images t)
'(org-export-html-use-infojs t)
'(org-export-htmlize-output-type "css")
'(org-export-html-validation-link "<p class=\"xhtml-validation\"><a href=\"http://validator.w3.org/check?uri=referer\">Validate XHTML 1.0</a></p>")
'(org-export-html-with-timestamp nil)
'(org-modules (quote (org-bbdb org-bibtex org-info org-jsinfo org-irc org-w3m org-mouse org-eval org-eval-light org-exp-bibtex org-man org-mtags org-panel org-R org-special-blocks org-exp-blocks)))

;; Return the Lean tutorial example main part
(defun lean-example-main-part (code)
  (car (lean-extract-code code)))

;; Return the Lean tutorial example full code.
(defun lean-example-full (code)
  (cdr (lean-extract-code code)))

(defvar-local lean-src-block-counter 0)

;; Redefine org-html-src-block to use juicy-ace-editor
(eval-after-load "ox-html"
  '(defun org-html-src-block (src-block contents info)
     "Transcode a SRC-BLOCK element from Org to HTML.
CONTENTS holds the contents of the item.  INFO is a plist holding
contextual information."
     (setq lean-src-block-counter (1+ lean-src-block-counter))
     (if (org-export-read-attribute :attr_html src-block :textarea)
         (org-html--textarea-block src-block)
       (let ((lang (org-element-property :language src-block))
             (caption (org-export-get-caption src-block))
             (code (org-html-format-code src-block info))
             (label (let ((lbl (org-element-property :name src-block)))
                      (if (not lbl) ""
                        (format " id=\"%s\""
                                (org-export-solidify-link-text lbl))))))
         (if (not lang) (format "<pre class=\"example\"%s>\n%s</pre>" label code)
           (format
            "<div class=\"org-src-container\">\n%s%s\n</div>"
            (if (not caption) ""
              (format "<label class=\"org-src-name\">%s</label>"
                      (org-export-data caption info)))
            (if (string= lang "lean")
                (let ((juicy-ace-editor-html
                       (format "<juicy-ace-editor id='lean-juicy-ace-editor-%d' mode=\"ace/mode/%s\" readonly=\"true\">%s</juicy-ace-editor>"
                               lean-src-block-counter
                               lang
                               (lean-example-main-part code)))
                      (full-code-html (format "<div id='lean-full-code-%d' style='display:none'>%s</div>"
                                             lean-src-block-counter
                                             (lean-example-full code)))
                      (button-html (format "<div class='no-print' align=\"left\"><button type=\"button\" onclick=\"invoke_leanjs($('#lean-full-code-%d').text());\">Try it yourself &raquo;</button></div>"
                                          lean-src-block-counter)))
                  (concat juicy-ace-editor-html full-code-html button-html))
              (format "\n<pre class=\"src src-%s\"%s>%s</pre>" lang label code))))))))
(setq org-confirm-babel-evaluate nil)
