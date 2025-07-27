;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2024 Aleksandr Vityazev <avityazev@posteo.org>
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

(define-module (mps)
  #:use-module (gnu packages autotools)
  #:use-module (gnu packages sqlite)
  #:use-module (guix build-system gnu)
  #:use-module (guix git-download)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix packages)
  #:use-module (guix utils))

(define mps
  (package
    (name "mps")
    (version "1.118.0")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
              (url "https://github.com/Ravenbrook/mps")
              (commit (string-append "release-" version))))
       (file-name (git-file-name name version))
       (sha256
        (base32
         "078iv3fsz0dnfwb7g63apkvcksczbqfxrxm73k80jwnwca6pgafy"))))
    (build-system gnu-build-system)
    (arguments
     '(#:tests? #f
       #:parallel-build? #f
       #:phases
       (modify-phases %standard-phases
         (add-after 'unpack 'remove-werror
           (lambda _
             (substitute* "configure.ac"
               (("-Werror") ""))
             (substitute* (find-files "code")
               (("-Werror") "")))))))
    (inputs (list autoconf automake sqlite))
    (home-page "https://www.ravenbrook.com/project/mps/")
    (synopsis "Memory Pool System")
    (description "The Memory Pool System is a flexible and adaptable
memory manager.")
    (license license:bsd-2)))
