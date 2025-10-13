#!/bin/bash

DEBUG=""
. /etc/profile.d/vesta.sh
${DEBUG:+set -x}
${DEBUG:+env}

RENEWED_USER="$(/bin/grep "DOMAIN='${CERTBOT_DOMAIN}'" "${VESTA}/data/users/*/web.conf" | awk -F / '{print $7}')" || (echo "User not found for $RENEWED_DOMAIN"; env ; exit 1)

cat > "/home/${RENEWED_USER}/conf/web//home/itdal/conf/web/nginx.${CERTBOT_DOMAIN}.conf_letsencrypt" << EOF
location "/.well-known/acme-challenge/$CERTBOT_TOKEN" {
    default_type text/plain;
    return 200 "$CERTBOT_VALIDATION";
}
EOF

nginx -t && nginx -s reload