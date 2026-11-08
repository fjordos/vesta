#!/bin/bash
user="$1"
domain="$2"
#ip="$3"
home_dir="$4"
docroot="$5"

chmod 751 "$docroot"
mkdir -p "$home_dir/$user/web/$domain/{tmp,"
chmod 0700  "$home_dir/$user/web/$domain/tmp"
chown "$user":"$user" "$home_dir/$user/web/$domain/tmp"

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
  systemctl disable --now "${user}-${domain}"-php.service
  rm -f /etc/containers/systemd/"${user}-${domain}"-php.container
  systemctl daemon-reload
else
  cat > /etc/containers/systemd/"${user}-${domain}"-php.container << EOF
[Unit]
Description=PHP-${phpv} application container for ${domain}
Requires=php74-php-fpm-image.service
Wants=network-online.target
After=network-online.target php74-php-fpm-image.service

[Container]
Image=ghcr.io/fjordos/simple/php74-php-fpm:latest
ContainerName=${domain}
HostName=${domain}
User=${user}
Group=${user}
UserNS=keep-id
DNS=9.9.9.9
DNS=1.1.1.1
DNS=8.8.8.8
EnvironmentFile=-$home_dir/$user/conf/${domain}-php${phpv}.ini
Volume=/usr/local/vesta/install/fedora/45/vesta/php/php47.ini:/etc/php.d/vesta.ini:ro,Z
Volume=/usr/local/vesta/install/fedora/45/vesta/php/php47-tmp.ini:/etc/php.d/vesta-tmp.ini:ro,Z
Volume=$home_dir/$user/conf/php-${domain}.ini:/etc/php.d/ZZ-custom.ini:ro,Z
Volume=$home_dir/$user/web/${domain}/public_html:/var/www/html:rw,Z
Volume=$home_dir/$user/web/${domain}/php:/run/php-fpm:rw,Z
Volume=var-lib-php-${user}-${domain}:/var/lib/php
HealthCmd=/bin/sh -c 'test -S /run/php-fpm/www.sock'
HealthInterval=60s
HealthTimeout=3s
HealthRetries=3
HealthStartPeriod=30s
HealthStartupCmd=/bin/sh -c 'test -S /run/php-fpm/www.sock'
HealthStartupInterval=5
HealthStartupRetries=10
HealthStartupSuccess=2
HealthStartupTimeout=1m33s
HealthTimeout=20s
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
  systemctl daemon-reload
  systemctl enable --now "${user}-${domain}"-php.service
fi

exit 0
