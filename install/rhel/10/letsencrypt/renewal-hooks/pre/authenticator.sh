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
  nginx -t  || { echo "Failed to reload Nginx" ; exit 1; }
  nginx -s reload
  sleep "${S:=1}"s
  until curl --fail --silent --show-error --max-time 5 --write-out '%{http_code}' --output /dev/null "http://${CERTBOT_DOMAIN_BASE}/.well-known/acme-challenge/${CERTBOT_TOKEN}" | grep -q '^200$' ; do
    if ((S>5)) ; then
      echo "Failed to obtain certificate for ${CERTBOT_DOMAIN_BASE}"
      exit 1
    fi
    sleep "${S}"s
    S=$((S+1))
  done
else
  echo "CERTBOT_DOMAIN not set, skipping..."
fi