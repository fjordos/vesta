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

# Check admin user account
if [ ! -z "$(grep ^admin: /etc/passwd)" ] && [ -z "$1" ]; then
    echo "Error: user admin exists"
    echo
    echo 'Please remove admin user before proceeding.'
    echo 'If you want to do it automatically run installer with -f option:'
    echo "Example: bash $0 --force"
    exit 1
fi

# Check admin group
if [ ! -z "$(grep ^admin: /etc/group)" ] && [ -z "$1" ]; then
    echo "Error: group admin exists"
    echo
    echo 'Please remove admin group before proceeding.'
    echo 'If you want to do it automatically run installer with -f option:'
    echo "Example: bash $0 --force"
    exit 1
fi

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

#URL="https://vestacp.com/pub"
URL="https://github.com/fjordos/vesta/raw/refs/heads/master/install"
# Check wget
if [ -e '/usr/bin/wget' ]; then
    wget ${URL}/vst-install-"$type".sh -O vst-install-"$type".sh
    if [ "$?" -eq '0' ]; then
        bash vst-install-"$type".sh $*
        exit
    else
        echo "Error: vst-install-"$type".sh download failed."
        exit 1
    fi
fi

# Check curl
if [ -e '/usr/bin/curl' ]; then
    curl -O "${URL}"/vst-install-"$type".sh
    if [ "$?" -eq '0' ]; then
        bash vst-install-"$type".sh $*
        exit
    else
        echo "Error: vst-install-$type.sh download failed."
        exit 1
    fi
fi

exit
