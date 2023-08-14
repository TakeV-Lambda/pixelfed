;; What follows is a "manifest" equivalent to the command line you gave.
;; You can store it in a file that you may then pass to any 'guix' command
;; that accepts a '--manifest' (or '-m') option.

(specifications->manifest
 (list "bash"
       "coreutils"
       "git"
       "gnupg"
       "node"
       "nss-certs"
       "openssl"
       "php"
       "postgresql"
       "redis"))

;;; Local Variables:
;;; mode: scheme
;;; End:
