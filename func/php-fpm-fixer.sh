#!/bin/bash
source /etc/profile.d/vesta.sh
#for F in $(/bin/journalctl -S "1 minutes ago" | /bin/grep 'ERROR: \[pool ' | /bin/sed 's#.*ERROR: \[pool \([a-z0-9]*-.*\)\].*#/etc/opt/remi/*/php-fpm.d/\1.conf#' | /bin/sort | /bin/uniq) ; do
#  U="$(grep "user =" "$F" | sed 's/user = //')"
#  /bin/rm -f "$F"
#  /usr/local/vesta/bin/v-rebuild-web-domains "$U" no
#done

PHPV="${1:=system}"

if [ "$PHPV" = "system" ] ; then
  if [[ -x /usr/sbin/php-fpm ]] ; then
    PHPPOOL="$(/usr/sbin/php-fpm --test 2>&1 | grep 'ERROR: \[pool' | awk '{print $5}' | tr -d ']')"
  else
    echo "No PHP-FPM found."
  fi
else
  if [[ -x "/opt/remi/${PHPV}/root/sbin/php-fpm" ]] ; then
    PHPPOOL="$(/opt/remi/"${PHPV}"/root/sbin/php-fpm --test 2>&1 | grep ' ERROR: \[pool' | awk '{print $5}' | tr -d ']')"
  else
    echo "No PHP-FPM version specified or not found."
  fi
fi
echo "PHPPOOL_ALL=\"$PHPPOOL\""

for B in $PHPPOOL ; do
  echo "PHPOOL=\"$B\""
  PHPUSER="${B%@*}"
  echo "PHPUSER=\"$PHPUSER\""
  PHPDOMAIN="${B#*@}"
  echo "PHPDOMAIN=\"$PHPDOMAIN\""
  rm -f "/etc/opt/remi/${PHPV}/php-fpm.d/${B}.conf" || true
  if grep -qE "^${PHPUSER}:" /etc/passwd ; then
    "$VESTA"/bin/v-rebuild-web-domains "$PHPUSER" no
  fi
done
