(define-module (pixelfed)
  #:use-module (gnu packages imagemagick)
  #:use-module (gnu packages php)
  #:use-module (guix)
  #:use-module (guix build-system copy)
  #:use-module (guix build utils)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module ((guix licenses)
                #:prefix license:)
  #:use-module (guix packages))

(define vcs-file?
  (or (git-predicate "../../..")
      (const #t)))

(define-public pixelfed
  (package
    (name "pixelfed")
    (version "pixelfed-src")
    (source (local-file "../../.."
                        "-checkout"
                        #:recursive? #t
						#:select? vcs-file?))
    (build-system copy-build-system)
    (inputs (list imagemagick))
    (propagated-inputs (list php))
    (arguments
     (list #:phases #~(modify-phases %standard-phases
                        (add-before 'install 'run-tests
                          (lambda _
                            (invoke "php" "artisan" "test")))
                        ;; TODO Switch to allowlist copy
                        (add-after 'run-tests 'cleanup
                          (lambda _
                            (begin
                              (delete-file "composer")
                              (delete-file-recursively "tests")
                              (delete-file-recursively "contrib")
                              (map (lambda (x)
                                     (delete-file-recursively (string-append
                                                               "vendor/" x)))
                                   (list "brianium/paratest"
                                         "fakerphp"
                                         "laravel/telescope"
                                         "mockery"
                                         "nunomaduro/collision"
                                         "phpunit/phpunit"))))))))
    (home-page "")
    (synopsis "")
    (description "")
    (license license:agpl3)))

pixelfed
