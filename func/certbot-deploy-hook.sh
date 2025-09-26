#!/bin/bash
#
. /etc/profile.d/vesta.sh

CERTBOT_USER="$(/bin/ls -d /home/*/web/"$CERTBOT_DOMAIN" | awk -F / '{print $3}')"

ssl_dir="$VESTA/data/users/${CERTBOT_USER}/ssl"
ssl_conf=/etc/letsencrypt/renewal/${CERTBOT_DOMAIN}.conf
env
/bin/cat $(crudini --get ${ssl_conf} DEFAULT privkey) > $ssl_dir/${CERTBOT_DOMAIN}.key
/bin/cat $(crudini --get ${ssl_conf} DEFAULT cert) > $ssl_dir/${CERTBOT_DOMAIN}.crt
/bin/cat $(crudini --get ${ssl_conf} DEFAULT chain) > $ssl_dir/${CERTBOT_DOMAIN}.ca
/bin/cat $(crudini --get ${ssl_conf} DEFAULT fullchain) > $ssl_dir/${CERTBOT_DOMAIN}.pem

for I in key crt ca pem ; do
  cp -f  "$ssl_dir/${CERTBOT_DOMAIN}.${I}" /home/$user/conf/web/ssl.${CERTBOT_DOMAIN}.${I}
done

/bin/systemctl reload nginx.service
/bin/systemctl reload httpd.service
