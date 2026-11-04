#!/bin/bash

if [[ -n "${VESTA}" ]] ; then
  source /etc/profile.d/vesta.sh
  source "${VESTA}/conf/vesta.conf"
fi
source /etc/os-release

/bin/cp -f ${DEBUG:+-v} "${VESTA}/install/$ID/$VERSION_ID/sysctl/vesta.conf" "/etc/sysctl.d/vesta.conf"
sysctl -p

# Sync Let's Encrypt files'
/bin/rsync ${DEBUG:+-v} -aH "${VESTA}/install/$ID/$VERSION_ID/letsencrypt/" "/etc/letsencrypt"

# Sync systemd system files and reload if changes were made
if /bin/rsync ${DEBUG:+-v} -aH --itemize-changes "${VESTA}/install/$ID/$VERSION_ID/systemd/system/" "/etc/systemd/system" | grep -q '^[<>ch]'; then
  # Reload systemd daemon
  systemctl daemon-reload
fi
# Sync systemd user files and reload if changes were made
if /bin/rsync ${DEBUG:+-v} -aH --itemize-changes "${VESTA}/install/$ID/$VERSION_ID/systemd/user/" "/etc/systemd/user" | grep -q '^[<>ch]'; then
  # Reload systemd daemon for users with linger enabled
  loginctl list-users --json=pretty | jq -r '.[] | select(.linger == true) | .user' | while read -r username; do
     systemctl --user -M "${username}@.host" daemon-reload
  done
fi

# Set certificate for Cockpit
if [ ! -e "/etc/cockpit/ws-certs.d/000-default.cert" ] || [ ! -e "/etc/cockpit/ws-certs.d/000-default.key" ] ; then
  rm -f "/etc/cockpit/ws-certs.d/000-default.cert" "/etc/cockpit/ws-certs.d/000-default.key" ||:
  ln -sf "${VESTA}/ssl/certificate.crt" "/etc/cockpit/ws-certs.d/000-default.cert"
  ln -sf "${VESTA}/ssl/certificate.key" "/etc/cockpit/ws-certs.d/000-default.key"
  systemctl restart cockpit.socket
fi

/bin/rsync ${DEBUG:+-v} -aH "${VESTA}/install/$ID/$VERSION_ID/templates/" "${VESTA}/data/templates"

# Update CloudFlare IPs
echo '# Cloudflare https://www.cloudflare.com/ips' > /etc/nginx/conf.d/cloudflare.conf
for I in https://www.cloudflare.com/ips-v4/ https://www.cloudflare.com/ips-v6/ ; do
  /bin/curl -s "${I}" | \
    awk '{print "set_real_ip_from " $1 ";"}' >> /etc/nginx/conf.d/cloudflare.conf
    echo >> /etc/nginx/conf.d/cloudflare.conf
done
echo "real_ip_header CF-Connecting-IP;" >> /etc/nginx/conf.d/cloudflare.conf

# secfix
for I in /etc $(find /etc/opt/remi/ -mindepth 1 -maxdepth 1 -type d) ; do echo "session.upload_progress.enabled=0" > "$I/php.d/secfix-CVE-2026-109619.ini" ; done
systemctl restart "php*"

# TODO: Sync Vesta config system files and reload if changes were made
