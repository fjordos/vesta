#!/bin/bash
source /etc/profile.d/vesta.sh

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
if [[ -n "$PHPPOOL" ]] ; then
  echo "The php-fixer found issue with the following pool(s): $PHPPOOL"
  for B in $PHPPOOL ; do
    echo "PHPOOL=\"$B\""
    PHPUSER="${B%@*}"
    echo "PHPUSER=\"$PHPUSER\""
    PHPDOMAIN="${B#*@}"
    echo "PHPDOMAIN=\"$PHPDOMAIN\""
    rm -fv "/etc/opt/remi/${PHPV}/php-fpm.d/${B}.conf" || true
    if grep -qE "^${PHPUSER}:" /etc/passwd ; then
      "$VESTA"/bin/v-rebuild-web-domains "$PHPUSER" no
    fi
  done
fi
exit 0