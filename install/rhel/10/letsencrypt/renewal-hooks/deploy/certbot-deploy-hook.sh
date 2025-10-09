#!/bin/bash
#
. /etc/profile.d/vesta.sh

[[ -n "${RENEWED_DOMAIN}" ]] || RENEWED_DOMAIN="${RENEWED_DOMAINS%% *}"
[[ -n "${RENEWED_DOMAIN}" ]] || (echo "Undefined RENEWED_DOMAINS"; env ; exit 1)
[[ -n "${RENEWED_LINEAGE}" ]] || (echo "Undefined RENEWED_LINEAGE"; env ; exit 1)
[[ -d "${RENEWED_LINEAGE}" ]] || (echo "The RENEWED_LINEAGE is not a valid directory"; env ; exit 1)
RENEWED_USER="$(/bin/ls -d /home/*/web/"${RENEWED_DOMAIN}" | awk -F / '{print $3}')" || (echo "User not found for $RENEWED_DOMAIN"; env ; exit 1)

ssl_dir="$VESTA/data/users/${RENEWED_USER}/ssl"
/bin/cat "${RENEWED_LINEAGE}/privkey.pem" > "$ssl_dir/${RENEWED_DOMAIN}.key"
/bin/cat "${RENEWED_LINEAGE}/cert.pem" > "$ssl_dir/${RENEWED_DOMAIN}.crt"
/bin/cat "${RENEWED_LINEAGE}/chain.pem" > "$ssl_dir/${RENEWED_DOMAIN}.ca"
/bin/cat "${RENEWED_LINEAGE}/fullchain.pem" > "$ssl_dir/${RENEWED_DOMAIN}.pem"

for I in key crt ca pem ; do
  cp -f  "$ssl_dir/${RENEWED_DOMAIN}.${I}" "/home/$RENEWED_USER/conf/web/ssl.${RENEWED_DOMAIN}.${I}"
done

if ! (grep -E "DOMAIN='emails.thermotechnika.eu' .* SSL='yes' SSL_HOME='same' LETSENCRYPT='yes'" "${VESTA}/data/users/${RENEWED_USER}/web.conf") ; then
  sed -E "s/SSL='(yes|no)' SSL_HOME='.*' LETSENCRYPT='(yes|no)'/SSL='yes' SSL_HOME='same' LETSENCRYPT='yes'/" \
    -i "${VESTA}/data/users/${RENEWED_USER}/web.conf"
fi
"${VESTA}/bin/v-rebuild-web-domains" "${RENEWED_USER}"

. "$VESTA/conf/vesta.conf"
if [[ "$VESTA_CERTIFICATE" == "$RENEWED_USER:$RENEWED_DOMAIN" ]] ; then
  "$VESTA/bin/v-add-sys-vesta-ssl" "$RENEWED_USER" "$RENEWED_DOMAIN"
fi
if [[ "$MAIL_CERTIFICATE" == "$RENEWED_USER:$RENEWED_DOMAIN" ]] ; then
  "$VESTA/bin/v-add-sys-mail-ssl" "$RENEWED_USER" "$RENEWED_DOMAIN"
fi
