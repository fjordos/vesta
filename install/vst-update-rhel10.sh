#!/bin/bash

if [[ -n "${VESTA}" ]] ; then
  source /etc/profile.d/vesta.sh
  source "${VESTA}/conf/vesta.conf"
fi
DEBUG=0

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

# TODO: Sync Vesta config system files and reload if changes were made
