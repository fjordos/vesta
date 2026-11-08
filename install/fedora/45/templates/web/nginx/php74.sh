#!/bin/bash
user="$1"
domain="$2"
#ip="$3"
home_dir="$4"
docroot="$5"

chmod 751 "$docroot"
mkdir -p "$home_dir/$user/web/$domain/{tmp,php}"
chmod 0700  "$home_dir/$user/web/$domain/tmp"
chown "$user":"$user" "$home_dir/$user/web/$domain/{tmp,php}"

phpv=74
if ls /etc/opt/remi/php*/php-fpm.d/"${user}@${domain}.conf" >/dev/null 2>&1 ; then
  oldphpvs="$(ls /etc/opt/remi/php*/php-fpm.d/"${user}@${domain}.conf" | awk -F'/' '{print $5}')"
  for oldphpv in $oldphpvs ; do
    if [[ "$oldphpv" != "$phpv" ]] ; then
      rm -f "/etc/opt/remi/${oldphpv}/php-fpm.d/${user}@${domain}.conf"
      systemctl try-reload-or-restart "${oldphpv}-php-fpm" ||:
    fi
  done
fi

if [[ "$REMOVE" == 1 ]] ; then
  rm -f "/etc/opt/remi/php$phpv/php-fpm.d/${user}@${domain}.conf"
else
  cat > "/etc/opt/remi/php$phpv/php-fpm.d/${user}@${domain}.conf" << EOF
[${user}@${domain}]
user = $user
group = $user
listen = /home/$user/web/$domain/php.socket
listen.acl_users = nginx,apache
listen.acl_groups = $user
pm = dynamic
pm.max_children = 50
pm.start_servers = 5
pm.min_spare_servers = 5
pm.max_spare_servers = 35
pm.max_requests = 500
request_terminate_timeout = 30s
security.limit_extensions = .php
php_admin_flag[log_errors] = on
;php_flag[display_errors] = on
php_value[error_log] = $home_dir/$user/web/$domain/logs/${domain}.error.log
php_value[session.save_handler] = files
php_value[session.save_path]    = $home_dir/$user/tmp
php_value[soap.wsdl_cache_dir]  = $home_dir/$user/tmp
php_value[opcache.file_cache]   = $home_dir/$user/tmp
php_value[memory_limit] = 512M
php_value[post_max_size] = 256M
php_value[upload_max_filesize] = 256M
EOF
fi

systemctl try-reload-or-restart "php${phpv}-php-fpm" ||:

if [[ "$REMOVE" == 1 ]] ; then
  systemctl stop "${user}-${domain}-php.service"
  rm -f /etc/containers/systemd/"${user}-${domain}-php.container" \
    /etc/systemd/system/multi-user.target.wants/"${user}-${domain}-php.service"
  systemctl daemon-reload
else
  if [ ! -e "$home_dir/$user/${domain}-php.ini" ]; then
    echo ";Custom php.ini file for ${domain}. Add own custom PHP settings here." >  "$home_dir/$user/${domain}-php.ini"
    chown "${user}":"${user}" "$home_dir/$user/${domain}-php.ini"
  fi
  if [[ ! -e $home_dir/$user/${domain}-php.env ]] ; then
    echo "#Custom .env file for ${domain}. Add own custom environment variables here." > "$home_dir/$user/${domain}-php.env"
    chown "${user}":"${user}" "$home_dir/$user/${domain}-php.env"
  fi
  cat > /etc/containers/systemd/"${user}-${domain}-php.container" << EOF
[Unit]
Description=PHP-${phpv} application container for ${domain}
Requires=php${phpv}-php-fpm-image.service
Wants=network-online.target
After=network-online.target php${phpv}-php-fpm-image.service

[Container]
Image=ghcr.io/fjordos/simple/php${phpv}-php-fpm:latest
ContainerName=${domain}
HostName=${domain}
User=${user}
Group=${user}
UserNS=keep-id
DNS=9.9.9.9
DNS=1.1.1.1
DNS=8.8.8.8
EnvironmentFile=$home_dir/$user/${domain}-php.env
Volume=/usr/local/vesta/install/fedora/45/vesta/php/php${phpv}.ini:/etc/php.d/vesta.ini:ro,Z
Volume=/usr/local/vesta/install/fedora/45/vesta/php/php${phpv}-tmp.ini:/etc/php.d/vesta-tmp.ini:ro,Z
Volume=$home_dir/$user/${domain}-php.ini:/etc/php.d/ZZ-custom.ini:ro,Z
Volume=$home_dir/$user/web/${domain}/public_html:/var/www/html:rw,Z
Volume=$home_dir/$user/web/${domain}/php:/run/php-fpm:rw,Z
Volume=var-lib-php-${user}-${domain}:/var/lib/php
HealthCmd=/bin/sh -c 'test -S /run/php-fpm/www.sock'
HealthInterval=60s
HealthTimeout=3s
HealthRetries=3
HealthStartPeriod=30s
HealthStartupCmd=/bin/sh -c 'test -S /run/php-fpm/www.sock'
HealthStartupInterval=5s
HealthStartupRetries=10
HealthStartupSuccess=2
HealthStartupTimeout=1m30s
Network=private
StopTimeout=30
RunInit=true
Pull=never
ReloadSignal=SIGHUP

[Service]
Restart=on-failure
RestartSec=10s

[Install]
WantedBy=default.target
EOF
  [[ -L /etc/systemd/system/multi-user.target.wants/"${user}-${domain}-php.service" ]] || \
    ln -s /etc/systemd/system/"${user}-${domain}-php.service" /etc/systemd/system/multi-user.target.wants/"${user}-${domain}-php.service"
  systemctl daemon-reload
  systemctl restart "${user}-${domain}-php.service"
fi

exit 0
