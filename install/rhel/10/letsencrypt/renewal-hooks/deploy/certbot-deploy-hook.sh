#!/bin/bash
#
. /etc/profile.d/vesta.sh

[[ -n "$RENEWED_DOMAIN" ]] || RENEWED_DOMAIN="${RENEWED_DOMAINS%% *}"
[[ -n "$RENEWED_DOMAIN" ]] || (echo "Undefined RENEWED_DOMAINS"; env ; exit 1)
[[ -n "$RENEWED_LINEAGE" ]] || (echo "Undefined RENEWED_LINEAGE"; env ; exit 1)
CERTBOT_USER="$(/bin/ls -d /home/*/web/"$CERTBOT_DOMAIN" | awk -F / '{print $3}')"

ssl_dir="$VESTA/data/users/${CERTBOT_USER}/ssl"
/bin/cat "${RENEWED_LINEAGE}/privkey.pem" > "$ssl_dir/${RENEWED_DOMAIN}.key"
/bin/cat "${RENEWED_LINEAGE}/cert.pem" > "$ssl_dir/${RENEWED_DOMAIN}.crt"
/bin/cat "${RENEWED_LINEAGE}/chain.pem" > "$ssl_dir/${RENEWED_DOMAIN}.ca"
/bin/cat "${RENEWED_LINEAGE}/fullchain.pem" > "$ssl_dir/${RENEWED_DOMAIN}.pem"

for I in key crt ca pem ; do
  cp -f  "$ssl_dir/${RENEWED_DOMAIN}.${I}" "/home/$CERTBOT_USER/conf/web/ssl.${RENEWED_DOMAIN}.${I}"
done

if grep "SSL='yes' SSL_HOME='same' LETSENCRYPT='yes'" "${VESTA}/data/users/${CERTBOT_USER}/web.conf" ; then
  sed -E "s/SSL='(yes|no)' SSL_HOME='.*' LETSENCRYPT='(yes|no)'/SSL='yes' SSL_HOME='same' LETSENCRYPT='yes'/" \
    "${VESTA}/data/users/${CERTBOT_USER}/web.conf"
  v-rebuild-web-domains "${CERTBOT_USER}"
else
  /bin/systemctl reload nginx.service
  /bin/systemctl reload httpd.service
fi

. "$VESTA/conf/vesta.conf"
if [[ "$VESTA_CERTIFICATE" = "$CERTBOT_USER:$RENEWED_DOMAIN" ]] ; then
  "$VESTA/bin/v-add-sys-vesta-ssl" "$CERTBOT_USER" "$RENEWED_DOMAIN"
fi
if [[ "$MAIL_CERTIFICATE" = "$CERTBOT_USER:$RENEWED_DOMAIN" ]] ; then
  "$VESTA/bin/v-add-sys-mail-ssl" "$CERTBOT_USER" "$RENEWED_DOMAIN"
fi