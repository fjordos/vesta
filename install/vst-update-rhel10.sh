#!/bin/bash

if [[ -n "${VESTA}" ]] ; then
  source /etc/profile.d/vesta.sh
  source "${VESTA}/conf/vesta.conf"
fi
DEBUG=0

/bin/cp -f ${DEBUG:+-v} "${VESTA}/install/rhel/10/sysctl/vesta.conf" "/etc/sysctl.d/vesta.conf"

# Sync Let's Encrypt files'
/bin/rsync ${DEBUG:+-v} -aH "${VESTA}/install/rhel/10/letsencrypt/" "/etc/letsencrypt"

# Sync systemd system files and reload if changes were made
if /bin/rsync ${DEBUG:+-v} -aH --itemize-changes "${VESTA}/install/rhel/10/systemd/system/" "/etc/systemd/system" | grep -q '^[<>ch]'; then
  # Reload systemd daemon
  systemctl daemon-reload
fi
# Sync systemd user files and reload if changes were made
if /bin/rsync ${DEBUG:+-v} -aH --itemize-changes "${VESTA}/install/rhel/10/systemd/user/" "/etc/systemd/user" | grep -q '^[<>ch]'; then
  # Reload systemd daemon for users with linger enabled
  loginctl list-users --json=pretty | jq -r '.[] | select(.linger == true) | .user' | while read -r username; do
     systemctl --user -M "${username}@.host" daemon-reload
  done
fi

# Temporary Clamav Freshclam fix:
chown -R clam:clam /var/lib/clamav

# Set certificate for Cockpit
if [ ! -e "/etc/cockpit/ws-certs.d/000-default.cert" ] || [ ! -e "/etc/cockpit/ws-certs.d/000-default.key" ] ; then
  rm -f "/etc/cockpit/ws-certs.d/000-default.cert" "/etc/cockpit/ws-certs.d/000-default.key" ||:
  ln -sf "${VESTA}/ssl/certificate.crt" "/etc/cockpit/ws-certs.d/000-default.cert"
  ln -sf "${VESTA}/ssl/certificate.key" "/etc/cockpit/ws-certs.d/000-default.key"
  systemctl restart cockpit.socket
fi

# TODO: Sync Vesta config system files and reload if changes were made
