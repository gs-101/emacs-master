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
  #:use-module (gnu packages)
  #:use-module (gnu packages emacs)
  #:use-module (gnu packages gtk)
  #:use-module (gnu packages xorg)
  #:use-module (guix packages)
  #:use-module (guix utils)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix download))

(define emacs-master-commit "65c110b913f0aa539c34a77be812144c621021f8")
(define emacs-master-igc-commit "51dd41aeeefe9e7d20348d17108bbaa106579f83")

;; Returns the first seven characters of a commit.
(define (shorthand-commit commit)
  (string-drop-right commit 33))

(define emacs-master-hash "0yw5kn37j1k3sc3v7ic51xpk1c7ps5nj54r2c3p50g2r83x4gpy3")
(define emacs-master-igc-hash "03mgmdh917xkx10p2py87ayikxg4hlj6knv5yp71nrrhwnw1fsz9")

(define patches-path "patches/")

(define (from-patches patch)
  (string-append patches-path patch))

;; From emacs.scm.
(define* (emacs-ert-selector excluded-tests #:key run-nativecomp run-expensive run-unstable)
  "Create an ERT selector that excludes tests."
  (string-append
   "(not (or "
   (if run-nativecomp
       ""
       "(tag :nativecomp) ")
   (if run-expensive
       ""
       "(tag :expensive-test) ")
   (if run-unstable
       ""
       "(tag :unstable) ")
   (string-join
    (map
     (lambda (test)
       (string-append "\\\"" test "\\\""))
     excluded-tests))
   "))"))

(define emacs-master-selector
  (emacs-ert-selector
   '("bytecomp--fun-value-as-head"
     "esh-util-test/path/get-remote"
     "esh-var-test/path-var/preserve-across-hosts"
     "ffap-tests--c-path"
     "find-func-tests--locate-macro-generated-symbols"
     "grep-tests--rgrep-abbreviate-properties-darwin"
     "grep-tests--rgrep-abbreviate-properties-gnu-linux"
     "grep-tests--rgrep-abbreviate-properties-windows-nt-dos-semantics"
     "grep-tests--rgrep-abbreviate-properties-windows-nt-sh-semantics"
     "info-xref-test-makeinfo"
     "man-tests-find-header-file"
     "tab-bar-tests-quit-restore-window"
     "tramp-test48-remote-load-path"
     "tramp-test49-remote-load-path"
     ;; For emacs-master-igc.
     "module--test-assertions--call-emacs-from-gc"
     "process-tests/fd-setsize-no-crash/make-process"
     "set-commit-limit-test")))

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
        (base32 emacs-master-hash))))
    (arguments
     (substitute-keyword-arguments (package-arguments emacs-next-minimal)
       ((#:make-flags flags #~'())
        #~(list (string-append "SELECTOR=" #$emacs-master-selector)))))))

(define (masterize-name emacs)
  (when (eq? (package-name emacs) "emacs-next")
    (string-append "emacs-master"
                   (string-drop (package-name emacs)
                                (string-length "emacs-next"))))
  (string-append "emacs-master"
                 (string-drop (package-name emacs)
                              (string-length "emacs"))))

(define* (emacs->emacs-master emacs
                              #:optional name
                              #:key
                              ;; Source and version come from
                              ;; emacs-master-minimal to keep the package updated.
                              (source (package-source emacs-master-minimal))
                              (version (package-version emacs-master-minimal))
                              ;; But the arguments and inputs come from the
                              ;; originals to better fit their quirks.
                              (arguments
                               ;; But only in part. We need to use the text
                               ;; excluder from here!
                               (substitute-keyword-arguments (package-arguments emacs)
                                 ((#:make-flags flags #~'())
                                  #~(list (string-append "SELECTOR=" #$emacs-master-selector)))))
                              (inputs (package-inputs emacs)))
  (package
    (inherit emacs)
    (name (or name (masterize-name emacs)))
    (version version)
    (source source)
    (arguments arguments)
    (inputs inputs)))

(define-public emacs-master (emacs->emacs-master emacs))

;; No graphical elements.
(define-public emacs-master-no-x (emacs->emacs-master emacs-no-x))
(define-public emacs-master-no-x-toolkit (emacs->emacs-master emacs-no-x-toolkit))

;; PGTK
(define-public emacs-master-pgtk
  (emacs->emacs-master emacs-pgtk))

;; Motif
(define-public emacs-master-motif
  (emacs->emacs-master emacs-motif))

;; Lucid
(define-public emacs-master-lucid
  (emacs->emacs-master emacs-lucid))

;; New Garbage Collector branch for testing.
(define-public emacs-master-igc
  (emacs->emacs-master
   emacs
   ;; Necessary, or else the package would have the wrong name.
   "emacs-master-igc"
   #:source
   (origin
     (inherit (package-source emacs-next-minimal))
     (uri (git-reference
            (url "https://github.com/emacs-mirror/emacs.git")
            (commit emacs-master-igc-commit)))
     (sha256
      (base32 emacs-master-igc-hash))
     ;; Patches are cherry-picked because this branch takes some time to
     ;; catch-up with master.
     (patches (search-patches "emacs-fix-scheme-indent-function.patch"
                              "emacs-native-comp-pin-packages.patch"
                              "emacs-pgtk-super-key-fix.patch"
                              "emacs-next-disable-jit-compilation.patch"
                              "emacs-next-exec-path.patch"
                              "emacs-next-native-comp-fix-filenames.patch")))
   #:version ; Different commit, different version.
   (git-version "31.0.50" "1" (shorthand-commit emacs-master-igc-commit))
   #:arguments
   (substitute-keyword-arguments (package-arguments emacs)
     ((#:configure-flags flags #~'())
      #~(cons* "--with-mps=yes" #$flags))
     ((#:make-flags flags #~'())
      #~(list (string-append "SELECTOR=" #$emacs-master-selector))))
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
