#!/bin/bash

if [[ -n "${CERTBOT_DOMAIN}" ]] ; then
  DEBUG=""
  . /etc/profile.d/vesta.sh
  ${DEBUG:+set -x}
  ${DEBUG:+env}

  CERTBOT_USER="$(/bin/grep -E "(DOMAIN='| ALIAS='|,)${CERTBOT_DOMAIN}[,']" "${VESTA}/data/users/*/web.conf" | awk -F / '{print $7}')" || (echo "User not found for $CERTBOT_DOMAIN"; env ; exit 1)
  CERTBOT_DOMAIN_BASE=$(/bin/grep -E "(DOMAIN='| ALIAS='|,)${CERTBOT_DOMAIN}[,']" "${VESTA}/data/users/${CERTBOT_USER}/web.conf" | awk -F "'" '{print $2}')

  for I in nginx snginx ; do
    cat > "/home/${CERTBOT_USER}/conf/web/${I}.${CERTBOT_DOMAIN_BASE}.conf_letsencrypt_${CERTBOT_DOMAIN}" << EOF
location "/.well-known/acme-challenge/$CERTBOT_TOKEN" {
    default_type text/plain;
    return 200 "$CERTBOT_VALIDATION";
}
EOF
  done
  nginx -t && nginx -s reload
else
  echo "CERTBOT_DOMAIN not set, skipping..."
fi