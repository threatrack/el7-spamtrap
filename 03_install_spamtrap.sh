#!/bin/bash

# COPY CONFIGURATION FILES
mkdir -p /etc
mkdir -p /etc/postfix
mkdir -p /etc/python-policyd-spf
cat > /etc/postfix/main.cf << PASTECONFIGURATIONFILE
smtpd_banner = \$myhostname ESMTP
biff = no

# stuff
myhostname = mx.example.com
myorigin = \$myhostname
#mydestination = localhost, localhost.localdomain
relayhost =
mynetworks = 127.0.0.0/8
mailbox_size_limit = 0
home_mailbox = Maildir/

virtual_mailbox_domains = regexp:/etc/postfix/vhosts
virtual_mailbox_base = /home/vmail
virtual_mailbox_maps = regexp:/etc/postfix/vmaps
virtual_minimum_uid = 1000
virtual_uid_maps = static:5000
virtual_gid_maps = static:5000

recipient_delimiter = +
inet_interfaces = all

# prevent leaking valid e-mail addresses
disable_vrfy_command = yes
# don't allow illegal syntax in MAIL FROM and RCPT TO
strict_rfc821_envelopes = yes

# appending .domain is the MUA's job.
append_dot_mydomain = no

# Uncomment the next line to generate "delayed mail" warnings
#delay_warning_time = 4h

# try delivery for 1h
bounce_queue_lifetime = 1h
maximal_queue_lifetime = 1h

# incoming
smtpd_tls_cert_file = /etc/letsencrypt/live/mx.example.com/fullchain.pem
smtpd_tls_key_file = /etc/letsencrypt/live/mx.example.com/privkey.pem
smtpd_tls_security_level = may
smtpd_tls_received_header = yes
smtpd_tls_CAfile = /etc/ssl/certs/ca-bundle.trust.crt
smtpd_tls_CApath = /etc/ssl/certs
smtpd_tls_loglevel = 1
smtpd_hard_error_limit = 1
smtpd_helo_required     = yes
smtpd_error_sleep_time = 0
smtpd_tls_auth_only = yes
tls_preempt_cipherlist = yes
smtpd_tls_mandatory_ciphers = high
smtpd_tls_mandatory_protocols = !SSLv2, !SSLv3
smtpd_tls_exclude_ciphers=eNULL:aNULL:LOW:MEDIUM:DES:3DES:RC4:MD5:RSA:SHA1
smtpd_tls_dh1024_param_file = \${config_directory}/dhparams.pem
message_size_limit = 20971520
smtpd_delay_reject = yes
smtpd_relay_restrictions =
	permit_mynetworks,
	permit_sasl_authenticated,
	defer_unauth_destination
smtpd_client_restrictions =
	permit_mynetworks,
	permit_sasl_authenticated,
	check_policy_service unix:private/policyd-spf,
#       check_client_access hash:/etc/postfix/check_client_access,
#       check_sender_access hash:/etc/postfix/check_sender_access,
#       check_recipient_access hash:/etc/postfix/check_recipient_access,
	reject_rbl_client zen.spamhaus.org,
	permit
smtpd_helo_restrictions =
	permit_mynetworks,
	permit_sasl_authenticated,
	reject_invalid_helo_hostname,
	reject_non_fqdn_helo_hostname,
#	reject_unknown_helo_hostname,
	permit
smtpd_sender_restrictions =
	permit_mynetworks,
# reject_known_sender_login_mismatch is only available in >= 2.11
#	reject_known_sender_login_mismatch
	reject_authenticated_sender_login_mismatch,
	permit_sasl_authenticated,
#       check_sender_access hash:/etc/postfix/check_sender_access,
	reject_non_fqdn_sender,
	reject_unknown_sender_domain,
	reject_unlisted_sender,
	permit
smtpd_recipient_restrictions =
	permit_mynetworks,
	permit_sasl_authenticated,
	reject_unauth_destination,
#       check_recipient_access hash:/etc/postfix/check_recipient_access,
	reject_invalid_hostname,
	reject_non_fqdn_hostname,
	reject_non_fqdn_sender,
	reject_non_fqdn_recipient,
	reject_unknown_sender_domain,
	reject_unknown_recipient_domain,
	reject_unknown_sender_domain,
	permit

# prevent non email owner to send under that email address
smtpd_sender_login_maps=regexp:/etc/postfix/smtpd_sender_login_maps.regexp

# SASL
# if you really want noplaintext you need to remove plain and login in /etc/dovecot/dovecot.conf auth_mechansims
# smtpd_sasl_security_options=noplaintext,noanonymous
# we only prevent anonymous logins
smtpd_sasl_security_options=noanonymous
smtpd_sasl_auth_enable = yes
broken_sasl_auth_clients = no
smtpd_sasl_type = dovecot
smtpd_sasl_path = private/auth
smtpd_sasl_authenticated_header = no
#queue_directory = /var/spool/postfix


# outgoing
smtp_tls_CAfile = /etc/ssl/certs/ca-bundle.trust.crt
smtp_tls_CApath = /etc/ssl/certs
smtp_tls_loglevel = 1
smtp_tls_mandatory_ciphers=high
smtp_tls_mandatory_protocols = !SSLv2, !SSLv3
# Unfortunately too many people don't know how to do SSL correctly
#smtp_tls_security_level = verify
# hence we don't verify :(
smtp_tls_security_level = encrypt
# clean private stuff from headers
smtp_header_checks = regexp:/etc/postfix/smtp_header_checks.regexp

# Slowing down SMTP clients that make many errors
smtpd_error_sleep_time = 1s
smtpd_soft_error_limit = 5
smtpd_hard_error_limit = 10
smtpd_junk_command_limit = 3
# Measures against clients that make too many connections
anvil_rate_time_unit = 60s
smtpd_client_connection_count_limit = 30
smtpd_client_connection_rate_limit = 60
smtpd_client_message_rate_limit = 60
# we only have around 3 legit recipients
smtpd_client_recipient_rate_limit = 30
# prevent brute forcing
# only available in postfix > 3.1
#smtpd_client_auth_rate_limit = 6
smtpd_client_event_limit_exceptions = \$mynetworks

# SPF
policyd-spf_time_limit = 3600s

# DKIM, DMARC
milter_default_action = accept
milter_protocol = 2
smtpd_milters = inet:localhost:8891,inet:localhost:8893
non_smtpd_milters = inet:localhost:8891,inet:localhost:8893


alias_maps = hash:/etc/aliases

# DO NOT SEND ANY MAIL AT ALL
default_transport = error
relay_transport = error

PASTECONFIGURATIONFILE
cat > /etc/postfix/master.cf << PASTECONFIGURATIONFILE
#
# Postfix master process configuration file.  For details on the format
# of the file, see the master(5) manual page (command: "man 5 master").
#
# Do not forget to execute "postfix reload" after editing this file.
#
# ==========================================================================
# service type  private unpriv  chroot  wakeup  maxproc command + args
#               (yes)   (yes)   (yes)   (never) (100)
# ==========================================================================
smtp      inet  n       -       n       -       -       smtpd
#smtp      inet  n       -       n       -       1       postscreen
#smtpd     pass  -       -       n       -       -       smtpd
#dnsblog   unix  -       -       n       -       0       dnsblog
#tlsproxy  unix  -       -       n       -       0       tlsproxy
#submission inet n       -       n       -       -       smtpd
#  -o syslog_name=postfix/submission
#  -o smtpd_tls_security_level=encrypt
#  -o smtpd_sasl_auth_enable=yes
#  -o smtpd_sasl_type=dovecot
#  -o smtpd_sasl_path=private/auth
#  -o smtpd_sasl_security_options=noanonymous
#  -o smtpd_client_restrictions=permit_sasl_authenticated,reject
#  -o smtpd_sender_login_maps=hash:/etc/postfix/virtual
#  -o smtpd_sender_restrictions=reject_sender_login_mismatch
#  -o smtpd_recipient_restrictions=reject_non_fqdn_recipient,reject_unknown_recipient_domain,permit_sasl_authenticated,reject
#  -o milter_macro_daemon_name=ORIGINATING
smtps     inet  n       -       n       -       -       smtpd
  -o syslog_name=postfix/smtps
  -o smtpd_tls_wrappermode=yes
  -o smtpd_sasl_auth_enable=yes
  -o smtpd_reject_unlisted_recipient=no
#  -o smtpd_client_restrictions=\$mua_client_restrictions
#  -o smtpd_helo_restrictions=\$mua_helo_restrictions
#  -o smtpd_sender_restrictions=\$mua_sender_restrictions
  -o smtpd_recipient_restrictions=permit_sasl_authenticated,reject
  -o milter_macro_daemon_name=ORIGINATING
#628       inet  n       -       n       -       -       qmqpd
pickup    unix  n       -       n       60      1       pickup
cleanup   unix  n       -       n       -       0       cleanup
qmgr      unix  n       -       n       300     1       qmgr
#qmgr     unix  n       -       n       300     1       oqmgr
tlsmgr    unix  -       -       n       1000?   1       tlsmgr
rewrite   unix  -       -       n       -       -       trivial-rewrite
bounce    unix  -       -       n       -       0       bounce
defer     unix  -       -       n       -       0       bounce
trace     unix  -       -       n       -       0       bounce
verify    unix  -       -       n       -       1       verify
flush     unix  n       -       n       1000?   0       flush
proxymap  unix  -       -       n       -       -       proxymap
proxywrite unix -       -       n       -       1       proxymap
smtp      unix  -       -       n       -       -       smtp
relay     unix  -       -       n       -       -       smtp
#       -o smtp_helo_timeout=5 -o smtp_connect_timeout=5
showq     unix  n       -       n       -       -       showq
error     unix  -       -       n       -       -       error
retry     unix  -       -       n       -       -       error
discard   unix  -       -       n       -       -       discard
local     unix  -       n       n       -       -       local
virtual   unix  -       n       n       -       -       virtual
lmtp      unix  -       -       n       -       -       lmtp
anvil     unix  -       -       n       -       1       anvil
scache    unix  -       -       n       -       1       scache
#
# ====================================================================
# Interfaces to non-Postfix software. Be sure to examine the manual
# pages of the non-Postfix software to find out what options it wants.
#
# Many of the following services use the Postfix pipe(8) delivery
# agent.  See the pipe(8) man page for information about \${recipient}
# and other message envelope options.
# ====================================================================
#
# maildrop. See the Postfix MAILDROP_README file for details.
# Also specify in main.cf: maildrop_destination_recipient_limit=1
#
#maildrop  unix  -       n       n       -       -       pipe
#  flags=DRhu user=vmail argv=/usr/local/bin/maildrop -d \${recipient}
#
# ====================================================================
#
# Recent Cyrus versions can use the existing "lmtp" master.cf entry.
#
# Specify in cyrus.conf:
#   lmtp    cmd="lmtpd -a" listen="localhost:lmtp" proto=tcp4
#
# Specify in main.cf one or more of the following:
#  mailbox_transport = lmtp:inet:localhost
#  virtual_transport = lmtp:inet:localhost
#
# ====================================================================
#
# Cyrus 2.1.5 (Amos Gouaux)
# Also specify in main.cf: cyrus_destination_recipient_limit=1
#
#cyrus     unix  -       n       n       -       -       pipe
#  user=cyrus argv=/usr/lib/cyrus-imapd/deliver -e -r \${sender} -m \${extension} \${user}
#
# ====================================================================
#
# Old example of delivery via Cyrus.
#
#old-cyrus unix  -       n       n       -       -       pipe
#  flags=R user=cyrus argv=/usr/lib/cyrus-imapd/deliver -e -m \${extension} \${user}
#
# ====================================================================
#
# See the Postfix UUCP_README file for configuration details.
#
#uucp      unix  -       n       n       -       -       pipe
#  flags=Fqhu user=uucp argv=uux -r -n -z -a\$sender - \$nexthop!rmail (\$recipient)
#
# ====================================================================
#
# Other external delivery methods.
#
#ifmail    unix  -       n       n       -       -       pipe
#  flags=F user=ftn argv=/usr/lib/ifmail/ifmail -r \$nexthop (\$recipient)
#
#bsmtp     unix  -       n       n       -       -       pipe
#  flags=Fq. user=bsmtp argv=/usr/local/sbin/bsmtp -f \$sender \$nexthop \$recipient
#
#scalemail-backend unix -       n       n       -       2       pipe
#  flags=R user=scalemail argv=/usr/lib/scalemail/bin/scalemail-store
#  \${nexthop} \${user} \${extension}
#
#mailman   unix  -       n       n       -       -       pipe
#  flags=FR user=list argv=/usr/lib/mailman/bin/postfix-to-mailman.py
#  \${nexthop} \${user}
policyd-spf unix - n n - 0 spawn user=nobody argv=/usr/bin/policyd-spf
PASTECONFIGURATIONFILE
cat > /etc/postfix/smtp_header_checks.regexp << PASTECONFIGURATIONFILE
/^\\s*Received:.*with ESMTPSA/ IGNORE
/^\\s*X-Originating-IP:/ IGNORE
/^\\s*X-Enigmail/ IGNORE
/^\\s*X-Mailer:/	IGNORE
/^\\s*User-Agent:/ IGNORE
PASTECONFIGURATIONFILE
cat > /etc/postfix/smtpd_sender_login_maps.regexp << PASTECONFIGURATIONFILE
# allow account user@example.com to spoof for the whole example.com domain
#/^(.*)@example.com\$/	user@example.com
# only allow exact SASL login name matches
/^(.*)\$/	\${1}
PASTECONFIGURATIONFILE
cat > /etc/postfix/vhosts << PASTECONFIGURATIONFILE
/.*/    OK
PASTECONFIGURATIONFILE
cat > /etc/postfix/vmaps << PASTECONFIGURATIONFILE
/^root@spamtrap\\.invalid\$/      spamtrap.invalid/root/
/^root@.*\$/     spamtrap.invalid/root/
/^security@.*\$/ spamtrap.invalid/root/
/^hostmaster@.*\$/       spamtrap.invalid/root/
/^postmaster@.*\$/       spamtrap.invalid/root/
/^webmaster@.*\$/        spamtrap.invalid/root/
/^abuse@.*\$/    spamtrap.invalid/root/
/^dmarc-rua@.*\$/        spamtrap.invalid/dmarc-rua/
/^dmarc-ruf@.*\$/        spamtrap.invalid/dmarc-ruf/
/.*\$/   spamtrap.invalid/spamtrap/
PASTECONFIGURATIONFILE
cat > /etc/python-policyd-spf/policyd-spf.conf << PASTECONFIGURATIONFILE
debugLevel = 1

# WTF?!
# this is confusing, the manpage says "To enable it, set TestOnly = 0"
# so we do not activate it
TestOnly = 1

HELO_reject = False
Mail_From_reject = False
PermError_reject = False
TempError_Defer = False
skip_addresses = 127.0.0.0/8,::ffff:127.0.0.0/104,::1


PASTECONFIGURATIONFILE
# COPY CONFIGURATION FILES

postmap /etc/postfix/vmaps

systemctl restart postfix
systemctl restart dovecot

