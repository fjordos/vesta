#!/bin/bash
# Vesta installation wrapper
# https://vestacp.com

#
# Currently Supported Operating Systems:
#
#   RHEL 5, 6, 7, 9, 10
#   CentOS 5, 6, 7, 9, 10
#   Debian 7, 8
#   Ubuntu 12.04 - 18.04
#   Amazon Linux 2017
#

# Am I root?
if [ "x$(id -u)" != 'x0' ]; then
    echo 'Error: this script can only be executed by root'
    exit 1
fi

#----------------------------------------------------------#
#                    Variable&Function                     #
#----------------------------------------------------------#

# Importing system environment
source /etc/profile

# Includes
source $VESTA/func/main.sh
source $VESTA/conf/vesta.conf

# Detect OS
case $(head -n1 /etc/issue | cut -f 1 -d ' ') in
    Debian)     type="debian" ;;
    Ubuntu)     type="ubuntu" ;;
    Amazon)     type="amazon" ;;
    *)          source /etc/os-release
                if [ "${VERSION_ID%%.*}" == '9' ] || [ "${VERSION_ID%%.*}" == '10' ] ; then
                    type="rhel${VERSION_ID%%.*}"
                else
                    type="rhel"
                fi
      ;;
esac

[[ -x "$VESTA/install/vst-update-$type.sh" ]] && source "$VESTA/install/vst-update-$type.sh" 2>&1 | logger >/dev/null || { echo "Error: Failed to run the update script on $VERSION version (STEP 2)"; exit 1; }
[[ -x /root/vst-update-custom.sh ]] && source /root/vst-update-custom.sh 2>&1 | logger >/dev/null || { echo "Error: Failed to run the update script on $VERSION version (STEP 3)"; exit 1; }

exit
