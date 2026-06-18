;;; org-preexecute-noweb-blocks.el — run before org-babel-tangle when :noweb yes is used.
(require 'org)
(require 'ob-tangle)

(defun my/org-preexecute-noweb-blocks ()
  "Execute emacs-lisp and powershell src blocks so named noweb refs have results."
  (save-excursion
    (goto-char (point-min))
    (condition-case nil
        (while t
          (org-babel-next-src-block)
          (let ((lang (org-element-property :language (org-element-at-point))))
            (when (member lang '("emacs-lisp" "powershell"))
              (condition-case nil
                  (org-babel-execute-src-block nil)
                (error nil)))))
      (user-error nil))))

(provide 'org-preexecute-noweb-blocks)
