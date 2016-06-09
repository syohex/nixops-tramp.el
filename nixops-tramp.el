;;; nixops-tramp.el --- TRAMP integration for nixops deployments

;; Copyright (C) 2016 Travis Athougies <travis@athougies.net>

;; Author: Travis Athougies <travis@athougies.net>
;; URL: https://github.com/tathougies/nixops-tramp.el
;; Keywords: nixops, convenience, tramp
;; Version: 0.1
;; Package-Requires: ((emacs "24") (exec-path-from-shell "0"))

;;  This file is NOT part of GNU Emacs.

;;; License:

;; Copyright (c) 2016 Travis Athougies <travis@athougies.net>

;; Permission is hereby granted, free of charge, to any person obtaining a copy
;; of this software and associated documentation files (the "Software"), to deal
;; in the Software without restriction, including without limitation the rights
;; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
;; copies of the Software, and to permit persons to whom the Software is
;; furnished to do so, subject to the following conditions:

;; The above copyright notice and this permission notice shall be included in
;; all copies or substantial portions of the Software.

;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
;; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
;; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
;; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
;; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
;; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
;; SOFTWARE.

;;; Commentary:
;;
;; `nixops-tramp.el' offers a TRAMP method for Nixops deployments.
;;
;; > **NOTE**: `nixops-tramp.el' relies on the nixops ssh command. We use the
;; > `exec-patch-from-shell' to ensure the Emacs PATH matches your shell patch,
;; > but more exotic configurations may require tweaking. Make sure that `M-x
;; > shell-command' can run `nixops'.
;;
;; ## Usage
;;
;; Offers the TRAMP method `nixops` to access running deployments
;;
;;    C-x C-f /nixops:machine@deployment:/path/to/file
;;
;;    where
;;      machine       is the name of the machine you want to use
;;      deployment    is the name of the nixops deployment
;;
;; Both machine and deployment are required.

;;; Code:
(require 'tramp)
(require 'exec-path-from-shell)

(defgroup nixops-tramp nil
  "TRAMP integration for nixops."
  :prefix "nixops-tramp-"
  :group 'applications
  :link '(url-link :tag "Github" "https://github.com/tathougies/nixops-tramp.el")
  :link '(emacs-commentary-link :tag "Commentary" "nixops-tramp"))

;;;###autoload
(defcustom nixops-tramp-nixops-executable "nixops"
  "Path to nixops executable."
  :type 'string
  :group 'nixops-tramp)

(defcustom nixops-tramp-nixops-ssh-options nil
  "List of nixops ssh options."
  :type 'string
  :group 'nixops-tramp)

(defcustom nixops-tramp-nixops-scp-options nil
  "List of nixops scp options."
  :type 'string
  :group 'nixops-tramp)

(defconst nixops-tramp-method "nixops"
  "Method to connect nixops machines")

;;;###autoload
(defconst nixops-tramp-completion-function-alist
  '((nixops-tramp--get-machines-and-deployments ""))
  "Default list of (FUNCTION FILE) pairs to be examined for nixops method.")

(defun nixops-tramp--get-machines-and-deployments (&optional ignored)
  "Return a list of (machine deployment) tuples.

TRAMP calls this function with a filename which we ignore."
  (let* ((info-cmd (concat nixops-tramp-nixops-executable
                           " info --all 2>/dev/null |"
                           " tr -d '[:blank:]' |"
                           " awk 'BEGIN{FS=\"\\\\|\";} NR > 3 {if ($2 != \"\") { print $3 \"\\t\" $2 }}'"))

          (deployments-output (progn (message info-cmd) (shell-command-to-string info-cmd)))

          (deployments (split-string deployments-output "\n")))
    (message deployments-output)
    (delq 'nil
          (mapcar (lambda (deployment-str)
                    (let ( (deployment-info (split-string deployment-str "\t")) )
                      (if (= (length deployment-info) 2) deployment-info nil)))
                  deployments))))

;;;###autoload
(defun nixops-tramp-add-method ()
  "Add nixops tramp method."
  (add-to-list 'tramp-methods
	       `(,nixops-tramp-method
		 (tramp-login-program ,nixops-tramp-nixops-executable)
		 (tramp-login-args ( ("ssh") ,nixops-tramp-nixops-ssh-options ("-d") ("%h") ("%u") ("-p" "%p") ("%c") ("-e" "none") ("-t" "-t") ("/bin/sh")))
		 (tramp-remote-shell "/bin/sh")
		 (tramp-remote-shell-login ("-l"))
		 (tramp-remote-shell-args  ("-c"))
		 (tramp-copy-program "nixops")
		 (tramp-copy-args (("scp") (,nixops-tramp-nixops-scp-options ("-d") ("%h") ("%u")))))))

(exec-path-from-shell-initialize)
(nixops-tramp-add-method)
(tramp-set-completion-function nixops-tramp-method nixops-tramp-completion-function-alist)

(provide 'nixops-tramp)

;; Local Variables:
;; indent-tabs-mode: nil
;; End:

;;; nixops-tramp.el ends here
