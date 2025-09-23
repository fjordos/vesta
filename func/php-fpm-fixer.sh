#!/bin/bash
source /etc/profile.d/vesta.sh
for F in \$(/bin/journalctl -S "1 minutes ago" | /bin/grep 'ERROR: \[pool ' | /bin/sed 's#.*ERROR: \[pool \([a-z0-9]*-.*\)\].*#/etc/opt/remi/*/php-fpm.d/\1.conf#' | /bin/sort | /bin/uniq) ; do
  U=\$(grep "user =" \$F | sed 's/user = //')
  /bin/rm -f \$F
  /usr/local/vesta/bin/v-rebuild-web-domains \$U no
done
