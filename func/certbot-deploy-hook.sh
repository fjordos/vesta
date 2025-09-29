#!/bin/bash
#
. /etc/profile.d/vesta.sh

[[ -n "$CERTBOT_DOMAIN" ]] || CERTBOT_DOMAIN="${RENEWED_DOMAINS%% *}"
[[ -n "$CERTBOT_DOMAIN" ]] || (echo "Undefined RENEWED_DOMAINS"; env ; exit 1)
[[ -n "$RENEWED_LINEAGE" ]] || (echo "Undefined RENEWED_LINEAGE"; env ; exit 1)
CERTBOT_USER="$(/bin/ls -d /home/*/web/"$CERTBOT_DOMAIN" | awk -F / '{print $3}')"

ssl_dir="$VESTA/data/users/${CERTBOT_USER}/ssl"
/bin/cat "${RENEWED_LINEAGE}/privkey.pem" > "$ssl_dir/${CERTBOT_DOMAIN}.key"
/bin/cat "${RENEWED_LINEAGE}/cert.pem" > "$ssl_dir/${CERTBOT_DOMAIN}.crt"
/bin/cat "${RENEWED_LINEAGE}/chain.pem" > "$ssl_dir/${CERTBOT_DOMAIN}.ca"
/bin/cat "${RENEWED_LINEAGE}/fullchain.pem" > "$ssl_dir/${CERTBOT_DOMAIN}.pem"

for I in key crt ca pem ; do
  cp -f  "$ssl_dir/${CERTBOT_DOMAIN}.${I}" "/home/$CERTBOT_USER/conf/web/ssl.${CERTBOT_DOMAIN}.${I}"
done

/bin/systemctl reload nginx.service
/bin/systemctl reload httpd.service
