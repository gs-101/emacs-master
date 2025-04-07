;;; GNU Guix --- Functional package management for GNU
;;; Copyright (C) 2025 Gabriel Santos <gabrielsantosdesouza@disroot.org>
;;; Copyright (C) 2024 Divya R. Pattanaik <divya@subvertising.org>
;;; Copyright (C) 2023-2024 Akib Azmain Turja <akib@disroot.org>

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

  #:use-module (gnu packages)
  #:use-module (gnu packages xorg)
  #:use-module (gnu packages emacs)
  #:use-module (gnu packages gtk))

;;; !!! EMACS COMMIT AND HASH BEGIN !!!
(define emacs-master-commit "9663c959c73d6cca0c56f833d80ff1d9e9708b70")
(define emacs-master-time "1744044498")
(define emacs-master-hash "0sgl0sb8jh06bkz4sxyspx0fnz3qwrpciaahxfr0cln4gmmdsia8")
;;; !!! EMACS COMMIT AND HASH END !!!

(define-public emacs-master-minimal
  (package
    (inherit emacs-next-minimal)
    (name "emacs-master-minimal")
    (version (git-version "31.0.50" emacs-master-time emacs-master-commit))
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://git.savannah.gnu.org/cgit/emacs.git/snapshot/emacs-"
             emacs-master-commit ".tar.gz"))
       (sha256
        (base32 emacs-master-hash))
       (patches
        (search-patches "emacs-master-disable-jit-compilation.patch"
                        "emacs-master-exec-path.patch"
                        "emacs-fix-scheme-indent-function.patch"
                        "emacs-next-native-comp-driver-options.patch"
                        "emacs-master-native-comp-fix-filenames.patch"
                        "emacs-native-comp-pin-packages.patch"
                        "emacs-pgtk-super-key-fix.patch"))))))

(define* (emacs->emacs-master emacs
                              #:optional name
                              #:key (version (package-version
                                              emacs-master-minimal))
                              (source (package-source emacs-master-minimal)))
  (package
    (inherit emacs)
    (name (or name
              (and (string-prefix? "emacs"
                                   (package-name emacs))
                   (string-append "emacs-master"
                                  (string-drop (package-name emacs)
                                               (string-length "emacs"))))))
    (version version)
    (source
     source)
    (arguments
     (substitute-keyword-arguments (package-arguments emacs)
       ((#:phases phases)
        #~(modify-phases #$phases
            (delete 'validate-comp-integrity)
            (replace 'patch-program-file-names
              (lambda* (#:key inputs #:allow-other-keys)
                ;; Substitute "sh" command.
                (substitute* '("src/callproc.c" "lisp/term.el"
                               "lisp/htmlfontify.el"
                               "lisp/mail/feedmail.el"
                               "lisp/obsolete/pgg-pgp.el"
                               "lisp/obsolete/pgg-pgp5.el"
                               ;; "lisp/obsolete/terminal.el"
                               "lisp/org/ob-eval.el"
                               "lisp/textmodes/artist.el"
                               "lisp/progmodes/sh-script.el"
                               "lisp/textmodes/artist.el"
                               "lisp/htmlfontify.el"
                               "lisp/term.el")
                  (("\"/bin/sh\"")
                   (format #f "~s"
                           (search-input-file inputs "bin/sh"))))
                (substitute* '("lisp/gnus/mm-uu.el" "lisp/gnus/nnrss.el"
                               "lisp/mail/blessmail.el")
                  (("\"#!/bin/sh\\\n\"")
                   (format #f "\"#!~a~%\""
                           (search-input-file inputs "bin/sh"))))
                (substitute* '("lisp/jka-compr.el" "lisp/man.el")
                  (("\"sh\"")
                   (format #f "~s"
                           (search-input-file inputs "bin/sh"))))

                ;; Substitute "awk" command.
                (substitute* '("lisp/gnus/nnspool.el" "lisp/org/ob-awk.el"
                               "lisp/man.el")
                  (("\"awk\"")
                   (format #f "~s"
                           (search-input-file inputs "bin/awk"))))

                ;; Substitute "find" command.
                (substitute* '("lisp/gnus/gnus-search.el"
                               "lisp/obsolete/nnir.el"
                               "lisp/progmodes/executable.el"
                               "lisp/progmodes/grep.el"
                               "lisp/filecache.el"
                               "lisp/ldefs-boot.el"
                               "lisp/mpc.el")
                  (("\"find\"")
                   (format #f "~s"
                           (search-input-file inputs "bin/find"))))

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
                   (let ((replacement (false-if-exception (search-input-file
                                                           inputs
                                                           (string-append
                                                            "/bin/" what)))))
                     (if replacement
                         (string-append "\"" replacement "\"") all))))
                ;; match ".gvfs-fuse-daemon-real" and ".gvfsd-fuse-real"
                ;; respectively when looking for GVFS processes.
                (substitute* "lisp/net/tramp-gvfs.el"
                  (("\\(tramp-compat-process-running-p \"(.*)\"\\)" all
                    process)
                   (format #f "(or ~a (tramp-compat-process-running-p ~s))"
                           all
                           (string-append "." process "-real"))))))))))))

(define-public emacs-master-no-x-toolkit
  (emacs->emacs-master emacs-no-x-toolkit))

(define-public emacs-master
  (emacs->emacs-master emacs))

;; New Garbage Collector branch for testing
(define-public emacs-master-igc
  (package
    (inherit emacs-master)
    (name "emacs-master-igc")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://git.savannah.gnu.org/git/emacs.git")
             (commit "6f7e916a6c80df11bf169587913fb0443f6b5490")))
       (sha256
        (base32 "1dfh688p1a1njxwa7w9q7jmwxz1fnnxxbciim16dhnlyvbnb9b4d"))
       (patches (origin-patches (package-source emacs-master-minimal)))))))

;; PGTK
(define-public emacs-master-pgtk
  (emacs->emacs-master emacs-pgtk))

;; Motif
(define-public emacs-master-motif
  (emacs->emacs-master emacs-motif))

;; Lucid
(define-public emacs-master-lucid
  (emacs->emacs-master emacs-lucid))
