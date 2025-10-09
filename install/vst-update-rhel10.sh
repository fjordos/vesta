#!/bin/bash

if [[ -n "${VESTA}" ]] ; then
  source /etc/profile.d/vesta.sh
  source "${VESTA}/conf/vesta.conf"
fi
DEBUG=1

/bin/rsync ${DEBUG:+-v} -aH "${VESTA}/install/rhel/10/letsencrypt/" "/etc/letsencrypt"
