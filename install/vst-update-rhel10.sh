#!/bin/bash

DEBUG=1

/bin/rsync ${DEBUG:+-v} -aH "${VESTA}/install/rhel/10/letsencrypt/" "/etc/letsencrypt"
