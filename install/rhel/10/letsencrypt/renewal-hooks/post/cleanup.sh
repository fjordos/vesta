#!/bin/bash

DEBUG=""
. /etc/profile.d/vesta.sh
${DEBUG:+set -x}
${DEBUG:+env}

RENEWED_USER="$(/bin/grep "DOMAIN='${CERTBOT_DOMAIN}'" "${VESTA}/data/users/*/web.conf" | awk -F / '{print $7}')" || (echo "User not found for $RENEWED_DOMAIN"; env ; exit 1)

rm -f ${DEBUG:+-v} "/home/${RENEWED_USER}/conf/web//home/itdal/conf/web/nginx.${CERTBOT_DOMAIN}.conf_letsencrypt"
