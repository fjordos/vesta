#!/bin/bash -e

if [[ -n "${CERTBOT_DOMAIN}" ]] ; then
  DEBUG=""
  . /etc/profile.d/vesta.sh
  ${DEBUG:+set -x}
  ${DEBUG:+env}

  CERTBOT_USER="$(/bin/grep -E "(DOMAIN='| ALIAS='|,)${CERTBOT_DOMAIN}[,']" "${VESTA}"/data/users/*/web.conf | awk -F / '{print $7}')"
  CERTBOT_DOMAIN_BASE=$(/bin/grep -E "(DOMAIN='| ALIAS='|,)${CERTBOT_DOMAIN}[,']" "${VESTA}/data/users/${CERTBOT_USER}/web.conf" | awk -F "'" '{print $2}')

  for I in nginx snginx ; do
    cat > "/home/${CERTBOT_USER}/conf/web/${I}.${CERTBOT_DOMAIN_BASE}.conf_letsencrypt_${CERTBOT_DOMAIN}" << EOF
location "/.well-known/acme-challenge/$CERTBOT_TOKEN" {
    default_type text/plain;
    return 200 "$CERTBOT_VALIDATION";
}
EOF
  done
  nginx -t && nginx -s reload || { echo "Failed to reload Nginx" ; exit 1; }
  sleep "${S:=1}"s
  while curl --fail --silent --show-error --max-time 5 "http://${CERTBOT_DOMAIN_BASE}/.well-known/acme-challenge/${CERTBOT_TOKEN}" ; do
    if ((S>5)) ; then
      echo "Failed to obtain certificate for ${CERTBOT_DOMAIN_BASE}"
      exit 1
    fi
    sleep "${S:=$((S+1))}"s
  done
else
  echo "CERTBOT_DOMAIN not set, skipping..."
fi