#1008082: deluser --system(?) --lock

- leaves the account intact but makes login impossible (by setting an invalid
password, leaving existing password recoverable, and setting shell to
/usr/sbin/nologin)
- only system accounts?
- adding state (/var/lib/adduser)?
    - or set to nologin, reset shell to default and WARN on unlock

#1008083: deluser --system

- /etc/deluser.conf: DELUSER_SYS_ACTION = (lock*|delete)  *default
- delgroup --system honors the above (lock == NOOP)

- basically: extends --lock to /etc/deluser.conf for system users

#1008084: adduser --system behavior if trying to create existing locked account
  - if system account already exists, just unlock and set shell
  - addgroup --system silently ignore existing also (?)

#?: --homeless
  - couldn't find a bug for this but saw it mentioned; is this something we
    still want to do?

blocked above:
#1006912: is it time to have account deletion in policy?
- anything relevant policy-wise?  (i have not read the whole thread,
  or any list discussion)
