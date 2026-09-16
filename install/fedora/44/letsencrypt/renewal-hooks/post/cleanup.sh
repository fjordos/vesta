#!/bin/bash -e

if [[ -n "${CERTBOT_DOMAIN}" ]] ; then
  DEBUG=""
  . /etc/profile.d/vesta.sh
  ${DEBUG:+set -x}
  ${DEBUG:+env}

  CERTBOT_USER="$(/bin/grep -E "(DOMAIN='| ALIAS='|,)${CERTBOT_DOMAIN}[,']" "${VESTA}"/data/users/*/web.conf | awk -F / '{print $7}')"
  CERTBOT_DOMAIN_BASE=$(/bin/grep -E "(DOMAIN='| ALIAS='|,)${CERTBOT_DOMAIN}[,']" "${VESTA}/data/users/${CERTBOT_USER}/web.conf" | awk -F "'" '{print $2}')
  if [[ "$CERTBOT_USER" ]] || [[ "$CERTBOT_DOMAIN_BASE" ]]; then
    rm -f ${DEBUG:+-v} "/home/${CERTBOT_USER}/conf/web/{s,}nginx.${CERTBOT_DOMAIN_BASE}.conf_letsencrypt_${CERTBOT_DOMAIN}"
  else
    certbot delete -d "${CERTBOT_DOMAIN}"
  fi
else
  echo "CERTBOT_DOMAIN not set, skipping..."
fi
