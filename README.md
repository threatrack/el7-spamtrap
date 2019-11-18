# EL7 spamtrap setup

**This installs a high interactive email honeypot style spamtrap. So take the needed pre-caution!** Even though
it is high interactive it is configured to **not** send mail.

This is based on <https://github.com/0x6d696368/el7-server>.

Follow the install instructions of [el7-server]() to install:

- `01_install_base.sh`
- `02_install_ns1.sh` **without** running any post install configuration (to setup a local DNS for RBL queries)
- `02_install_mx.sh` **without** running any post install configuration

Then run `03_install_spamtrap.sh` from **this** repo.

This disables email sending from your mail server as well as sets up your mail server to receive all mails send to whatever recipients into `spamtrap.invalid`. The standard email addresses, e.g., `hostmaster@`, etc. are send to `root`, see `/etc/postfix/vmaps` for where special emails addresses are send.

Then run `/usr/local/sbin/el7-mx_config steelservicescorp.com` to configure your mail domain as `steelservicescorp.com`.

The spam mails will then land in `/home/vmail/spamtrap.invalid/spamtrap/new/`.

Optionally, you can run `/usr/local/sbin/el7-mx_add_user spamtrap@spamtrap.invalid`
then you can connect via POP3s as user `spamtrap@spamtrap.invalid` with the password you configured in that command.

## tl;dr:

Basically you run:

```
01_install_base.sh # from https://github.com/0x6d696368/el7-server
02_install_ns1.sh # from https://github.com/0x6d696368/el7-server
02_install_mx.sh # from https://github.com/0x6d696368/el7-server
03_install_spamtrap.sh # from this repo
/usr/local/sbin/el7-mx_config steelservicescorp.com
```

Then the spam ends up in `/home/vmail/spamtrap.invalid/spamtrap/new/`.

For logging and debugging of the mail system see instructions in <https://github.com/0x6d696368/el7-server>.



