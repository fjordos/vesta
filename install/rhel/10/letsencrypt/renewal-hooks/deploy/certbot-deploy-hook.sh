#!/bin/bash
#
DEBUG=""
. /etc/profile.d/vesta.sh
. "$VESTA/conf/vesta.conf"

[[ -n "${RENEWED_DOMAIN}" ]] || RENEWED_DOMAIN="${RENEWED_DOMAINS%% *}"
[[ -n "${RENEWED_DOMAIN}" ]] || (echo "Undefined RENEWED_DOMAINS"; env ; exit 1)
[[ -n "${RENEWED_LINEAGE}" ]] || (echo "Undefined RENEWED_LINEAGE"; env ; exit 1)
[[ -d "${RENEWED_LINEAGE}" ]] || (echo "The RENEWED_LINEAGE is not a valid directory"; env ; exit 1)
RENEWED_USER="$(/bin/grep "DOMAIN='${RENEWED_DOMAIN}'" "${VESTA}"/data/users/*/web.conf | awk -F / '{print $7}')" || (echo "User not found for $RENEWED_DOMAIN"; env ; exit 1)

USER_DATA="${VESTA}/data/users/${RENEWED_USER}"
VESTA_SSL="${USER_DATA}/ssl"
mkdir -p "${VESTA_SSL}"
/bin/cat "${RENEWED_LINEAGE}"/privkey.pem > "${VESTA_SSL}"/"${RENEWED_DOMAIN}".key
/bin/cat "${RENEWED_LINEAGE}"/cert.pem > "${VESTA_SSL}"/"${RENEWED_DOMAIN}".crt
/bin/cat "${RENEWED_LINEAGE}"/chain.pem > "${VESTA_SSL}"/"${RENEWED_DOMAIN}".ca
/bin/cat "${RENEWED_LINEAGE}"/fullchain.pem > "${VESTA_SSL}"/"${RENEWED_DOMAIN}".pem
[[ "$DEBUG" ]] && ls -l "${VESTA_SSL}"

for I in key crt ca pem ; do
  /bin/cp -f "${DEBUG:+-v}" "${VESTA_SSL}"/"${RENEWED_DOMAIN}"."${I}" /home/"${RENEWED_USER}"/conf/web/ssl."${RENEWED_DOMAIN}"."${I}"
done
[[ "$DEBUG" ]] && env
if ! (/bin/grep -E "^DOMAIN='${RENEWED_DOMAIN}' .* SSL='yes' SSL_HOME='same' LETSENCRYPT='yes'" "${USER_DATA}"/web.conf) ; then
  /bin/sed "${DEBUG:+--debug}" -E "s/^(DOMAIN='${RENEWED_DOMAIN}' .*) SSL='(yes|no)' SSL_HOME='.*' LETSENCRYPT='(yes|no)' /\1 SSL='yes' SSL_HOME='same' LETSENCRYPT='yes' /" \
    -i "${USER_DATA}"/web.conf
  [[ "$DEBUG" ]] && /bin/grep -E "^DOMAIN='${RENEWED_DOMAIN}' .* SSL='yes' SSL_HOME='same' LETSENCRYPT='yes'" "${USER_DATA}"/web.conf
fi
"${VESTA}"/bin/v-rebuild-web-domains "${RENEWED_USER}"

if [[ "$VESTA_CERTIFICATE" == "$RENEWED_USER:$RENEWED_DOMAIN" ]] ; then
  "${VESTA}"/bin/v-add-sys-vesta-ssl "$RENEWED_USER" "$RENEWED_DOMAIN"
fi
if [[ "$MAIL_CERTIFICATE" == "$RENEWED_USER:$RENEWED_DOMAIN" ]] ; then
  "${VESTA}"/bin/v-add-sys-mail-ssl "$RENEWED_USER" "$RENEWED_DOMAIN"
fi