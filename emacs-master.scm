;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2023-2024 Akib Azmain Turja <akib@disroot.org>
;;; Copyright © 2024 Divya R. Pattanaik <divya@subvertising.org>
;;; Copyright © 2025 Gabriel Santos <gabrielsantosdesouza@disroot.org>
;;;
;;; This file is not part of GNU Guix.
;;;
;;; This file is free software; you can redistribute it and/or modify it
;;; under the terms of the GNU General Public License as published by
;;; the Free Software Foundation; either version 3 of the License, or (at
;;; your option) any later version.
;;;
;;; This file is distributed in the hope that it will be useful, but
;;; WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with this file.  If not, see <http://www.gnu.org/licenses/>.

(define-module (emacs-master)
  #:use-module (guix packages)
  #:use-module (guix utils)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix download)
  #:use-module (guix status)
  #:use-module (gnu packages)
  #:use-module (gnu packages xorg)
  #:use-module (gnu packages emacs)
  #:use-module (gnu packages gtk))

(define emacs-master-commit "baf0c8220261a71da4b58806eb41dd014709561e")
(define emacs-master-hash "1f2l2svirzhkic0da1df1aykj5xihba4apqqsg77l47qv6ccav3p")

(define patches-path "patches/")

(define (shorthand-commit commit)
  (string-drop-right commit 33))

(define (from-patches patch)
  (string-append patches-path patch))

(define-public emacs-master-minimal
  (package
    (inherit emacs-next-minimal)
    (name "emacs-master-minimal")
    (version (git-version "31.0.50" "1" (shorthand-commit emacs-master-commit)))
    (source
     (origin
       (inherit (package-source emacs-next-minimal))
       (uri (git-reference
              (url "https://github.com/emacs-mirror/emacs.git")
              (commit emacs-master-commit)))
       (sha256
        (base32 emacs-master-hash))
       (patches (cons*
                 (from-patches "emacs-master-disable-tramp-test49.patch")
                 (origin-patches (package-source emacs-next-minimal))))))))

(define (masterize-name package)
  (string-append "emacs-master"
                 (string-drop (package-name package)
                              (string-length "emacs"))))

(define* (emacs->emacs-master emacs-package
                              #:optional name
                              #:key
                              ;; Source and version come from
                              ;; emacs-master-minimal to keep the package updated.
                              (source (package-source emacs-master-minimal))
                              (version (package-version emacs-master-minimal))
                              ;; But the arguments and inputs come from the
                              ;; originals to better fit their quirks.
                              (arguments (package-arguments emacs-package))
                              (inputs (package-inputs emacs-package)))
  (package
    (inherit emacs-package)
    (name (or name (masterize-name emacs-package)))
    (version version)
    (source source)
    (arguments arguments)
    (inputs inputs)))

(define-public emacs-master (emacs->emacs-master emacs-next))

;; No graphical elements.
(define-public emacs-master-no-x (emacs->emacs-master emacs-no-x))
(define-public emacs-master-no-x-toolkit (emacs->emacs-master emacs-no-x-toolkit))

;; PGTK.
(define-public emacs-master-pgtk (emacs->emacs-master emacs-pgtk))

;; Motif.
(define-public emacs-master-motif (emacs->emacs-master emacs-motif))

;; Lucid.
(define-public emacs-master-lucid (emacs->emacs-master emacs-lucid))

(define emacs-master-igc-commit "f1737342518baf6968ad0c09132565cad5f4a645")

;; New Garbage Collector branch for testing.
(define-public emacs-master-igc
  (emacs->emacs-master
   emacs
   ;; Necessary, or else the package would have the wrong name.
   "emacs-master-igc"
   #:source ; Done to remove the tramp patch and to use Savannah.
   (origin
     (method git-fetch)
     (uri (git-reference
            (url "https://git.savannah.gnu.org/git/emacs.git")
            (commit emacs-master-igc-commit)))
     (sha256
      (base32 "07r9cbpd8nhb0ihknc8978prcvszy2dj8xyq3d2wqrafk0jzljm4"))
     (patches (search-patches "emacs-fix-scheme-indent-function.patch"
                              "emacs-native-comp-pin-packages.patch"
                              "emacs-pgtk-super-key-fix.patch")))
   #:version
   (git-version "31.0.50" "1" (shorthand-commit emacs-master-igc-commit))
   #:arguments
   (substitute-keyword-arguments (package-arguments emacs)
     ((#:configure-flags flags #~'())
      #~(cons* "--with-mps=yes" #$flags))
     ((#:phases phases)
      #~(modify-phases #$phases
          (delete 'validate-comp-integrity)
          (replace 'patch-program-file-names
            (lambda* (#:key inputs #:allow-other-keys)
              ;; Substitute "sh" command.
              (substitute* '("src/callproc.c"
                             "lisp/term.el"
                             "lisp/htmlfontify.el"
                             "lisp/mail/feedmail.el"
                             "lisp/obsolete/pgg-pgp.el"
                             "lisp/obsolete/pgg-pgp5.el"
                             "lisp/org/ob-eval.el"
                             "lisp/textmodes/artist.el"
                             "lisp/progmodes/sh-script.el"
                             "lisp/textmodes/artist.el"
                             "lisp/htmlfontify.el"
                             "lisp/term.el")
                (("\"/bin/sh\"")
                 (format #f "~s" (search-input-file inputs "bin/sh"))))
              (substitute* '("lisp/gnus/mm-uu.el"
                             "lisp/gnus/nnrss.el"
                             "lisp/mail/blessmail.el")
                (("\"#!/bin/sh\\\n\"")
                 (format #f "\"#!~a~%\"" (search-input-file inputs "bin/sh"))))
              (substitute* '("lisp/jka-compr.el"
                             "lisp/man.el")
                (("\"sh\"")
                 (format #f "~s" (search-input-file inputs "bin/sh"))))

              ;; Substitute "awk" command.
              (substitute* '("lisp/gnus/nnspool.el"
                             "lisp/org/ob-awk.el"
                             "lisp/man.el")
                (("\"awk\"")
                 (format #f "~s" (search-input-file inputs "bin/awk"))))

              ;; Substitute "find" command.
              (substitute* '("lisp/gnus/gnus-search.el"
                             "lisp/obsolete/nnir.el"
                             "lisp/progmodes/executable.el"
                             "lisp/progmodes/grep.el"
                             "lisp/filecache.el"
                             "lisp/ldefs-boot.el"
                             "lisp/mpc.el")
                (("\"find\"")
                 (format #f "~s" (search-input-file inputs "bin/find"))))

              ;; Substitute "sed" command.
              (substitute* "lisp/org/ob-sed.el"
                (("org-babel-sed-command \"sed\"")
                 (format #f "org-babel-sed-command ~s"
                         (search-input-file inputs "bin/sed"))))
              (substitute* "lisp/man.el"
                (("Man-sed-command \"sed\"")
                 (format #f "Man-sed-command ~s"
                         (search-input-file inputs "bin/sed"))))

              (substitute* "lisp/doc-view.el"
                (("\"(gs|dvipdf|ps2pdf|pdftotext)\"" all what)
                 (let ((replacement (false-if-exception
                                     (search-input-file
                                      inputs
                                      (string-append "/bin/" what)))))
                   (if replacement
                       (string-append "\"" replacement "\"")
                       all))))
              ;; match ".gvfs-fuse-daemon-real" and ".gvfsd-fuse-real"
              ;; respectively when looking for GVFS processes.
              (substitute* "lisp/net/tramp-gvfs.el"
                (("\\(tramp-compat-process-running-p \"(.*)\"\\)" all process)
                 (format #f "(or ~a (tramp-compat-process-running-p ~s))"
                         all (string-append "." process "-real")))))))))
   #:inputs
   (modify-inputs (package-inputs emacs)
     (append (@@ (mps) mps)))))
(define-public emacs-master-pgtk-igc
  (package/inherit emacs-master-igc
    (name "emacs-master-pgtk-igc")
    (arguments
     (substitute-keyword-arguments (package-arguments emacs-master-igc)
       ((#:configure-flags flags #~'())
        #~(cons* "--with-pgtk" #$flags))))))
