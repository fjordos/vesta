#!/bin/bash
user="$1"
domain="$2"
#ip="$3"
#home_dir="$4"
#docroot="$5"


if ls /etc/opt/remi/php*/php-fpm.d/"${user}@${domain}.conf" >/dev/null 2>&1 ; then
  oldphpvs="$(ls /etc/opt/remi/php*/php-fpm.d/"${user}@${domain}.conf" | awk -F'/' '{print $5}')"
  for oldphpv in $oldphpvs ; do
    rm -f "/etc/opt/remi/${oldphpv}/php-fpm.d/${user}@${domain}.conf"
    systemctl try-reload-or-restart "${oldphpv}-php-fpm" ||:
  done
fi

systemctl stop "${user}-${domain}-php.service"
rm -f /etc/containers/systemd/"${user}-${domain}-php.container" \
  /etc/systemd/system/multi-user.target.wants/"${user}-${domain}-php.service"
systemctl daemon-reload

exit 0