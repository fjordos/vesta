#!/bin/bash

if [[ -n "${VESTA}" ]] ; then
  source /etc/profile.d/vesta.sh
  source "${VESTA}/conf/vesta.conf"
fi
DEBUG=""
source /etc/os-release
/bin/bash ${DEBUG:+-v} "${VESTA}/install/$ID/$VERSION_ID/reconfig.sh"