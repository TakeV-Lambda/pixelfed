(define-module (pixelfed-service)
  #:use-module (guix gexp)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix records)
  #:use-module (guix packages)
  #:use-module (gnu services)
  #:use-module (gnu services certbot)
  #:use-module (gnu services configuration)
  #:use-module (gnu services databases)
  #:use-module (gnu services base)
  #:use-module (gnu services shepherd)
  #:use-module (gnu services web)
  #:use-module (gnu system shadow)
  #:use-module (gnu packages admin)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages base)
  #:use-module (pixelfed)
  #:use-module (ice-9 match)
  #:export (pixelfed-service-type
            pixelfed-configuration))

(define-maybe string)
(define-maybe integer)

(define-configuration/no-serialization pixelfed-configuration
  ;; Guix config settings
  (pixelfed
   (package pixelfed)
   "The pixelfed package to use")
  (config-file
   (maybe-string)
   "Path to configuration file, defaults to no configuration file")
  (port
   (integer 8080)
   "Port to listen on, default 8080")
  (work-dir
   (string "/var/lib/pixelfed")
   "Pixelfed work directory")
  (postgres?
   (boolean #t)
   "If true, extends the postgresql service running in the same system")

  ;; App variables
  (app-name
   (string "Pixelfed")
   "Name which appears onn headerbar and other locations")
  (app-url
   (string "https://localhost")
   "Url for the pixelfed instance")
  (app-domain
   (string "localhost")
   "Domain for the app. This should be app-url without the protocol")
  (app-key
   (maybe-string)
   "App key. If not provided, one will be autogenerated")
  (session-domain
   (string "localhost")
   "Domain of session manager")

  ;; Database variables
  (db-database
   (string "pixelfed")
   "The name of the database to connect to")
  (db-host
   (maybe-string)
   "URL to the database host")
  (db-port
   (maybe-integer)
   "Databse host port")
  (db-username
   (maybe-string)
   "The database user to connect as")
  (db-password
   (maybe-string)
   "Password for the database user")

  ;; Nginx/https configuration
  (nginx?
   (boolean #t)
   "Set up reverse proxy via nginx")
  (https?
   (boolean #t)
   "Set up HTTPS via certbot"))

(define (pixelfed-activation config)
  (match-record config <pixelfed-configuration>
	(work-dir pixelfed)))

(define (pixelfed-nginx config)
  (match-record config <pixelfed-configuration>
	(nginx? https? work-dir)
	(if (not nginx?) '()
		(list (nginx-server-configuration
			   (listen (if https? '("443 ssl") '("80")))
			   (server-name (list app-domain))
			   (root work-dir)
			   (ssl-certificate (if https? (string-append "/etc/letsencrypt/live" app-domain "/fullchain.pem") #f))
			   (ssl-certificate-key (if https? (string-append "/etc/letsencrypt/live" app-domain "/fullchain.pem") #f)))))))

(define (pixelfed-postgresql-role config)
  (match-record config <pixelfed-configuration>
	(postgres? db-database db-username db-password)
	(if postgres?
		(list (postgresql-role
			   (name db-database)
			   (create-database? #t)))
		'())))

(define (pixelfed-accounts config)
  (match-record config <pixelfed-configuration>
	(work-dir)
	(list (user-group
		   (name "pixelfed")
		   (system? #t))
		  (user-account
		   (name "pixelfed")
		   (system? #t)
		   (group "pixelfed")
		   (comment "pixelfed server user")
		   (home-directory work-dir)
		   (shell (file-append bash-minimal "/bin/bash"))))))

(define-public pixelfed-service-type
  (service-type
   (name 'pixelfed)
   (extensions
    (list (service-extension account-service-type pixelfed-accounts)
		  (service-extension nginx-service-type pixelfed-nginx)
		  (service-extension postgresql-service-type pixelfed-postgresql-role)))
   (description "Runs pixelfed")
   (default-value (pixelfed-configuration))))
