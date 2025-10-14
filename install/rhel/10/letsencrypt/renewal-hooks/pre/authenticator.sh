#!/bin/bash

DEBUG=""
. /etc/profile.d/vesta.sh
${DEBUG:+set -x}
${DEBUG:+env}

RENEWED_USER="$(/bin/grep -E "(DOMAIN='|ALIAS='|,)${RENEWED_DOMAIN}[,']" "${VESTA}/data/users/*/web.conf" | awk -F / '{print $7}')" || (echo "User not found for $RENEWED_DOMAIN"; env ; exit 1)
CERTBOT_DOMAIN_BASE=$(/bin/grep -E "(DOMAIN='|ALIAS='|,)${RENEWED_DOMAIN}[,']" "${VESTA}/data/users/${RENEWED_USER}/web.conf" | awk -F "'" '{print $2}')

cat > "/home/${RENEWED_USER}/conf/web/nginx.${CERTBOT_DOMAIN_BASE}.conf_letsencrypt_${CERTBOT_DOMAIN}" << EOF
location "/.well-known/acme-challenge/$CERTBOT_TOKEN" {
    default_type text/plain;
    return 200 "$CERTBOT_VALIDATION";
}
EOF

nginx -t && nginx -s reload