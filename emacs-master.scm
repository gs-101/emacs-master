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
(define emacs-master-commit "b92cfadc6af3abf773f666bedc571bb85402b001")
(define emacs-master-time "1739183432")
(define emacs-master-hash "0rg87wlgqhaq728kc8j5cgdvjvnwbfsmbvb1q7s7g56bxd3rkn90")
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
        (search-patches "emacs-disable-jit-compilation.patch"
                        "emacs-next-exec-path.patch"
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
    (inherit emacs-next)
    (name (or name
              (and (string-prefix? "emacs-next"
                                   (package-name emacs-next))
                   (string-append "emacs-master"
                                  (string-drop (package-name emacs-next)
                                               (string-length "emacs-next"))))))
    (version version)
    (source source)
    (arguments arguments)))

(define-public emacs-master-no-x-toolkit
  (emacs->emacs-master emacs-no-x-toolkit))

(define-public emacs-master
  (emacs->emacs-master emacs))

(define-public emacs-master-xwidgets
  (emacs->emacs-master emacs-xwidgets))

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
(define-public emacs-master-pgtk-xwidgets
  (emacs->emacs-master emacs-pgtk-xwidgets))

;; Motif
(define-public emacs-master-motif
  (emacs->emacs-master emacs-motif))

;; Lucid
(define-public emacs-master-lucid
  (emacs->emacs-master emacs-lucid))
