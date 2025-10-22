#!/bin/bash
user="$1"
domain="$2"
ip="$3"
home_dir="$4"
docroot="$5"

chmod 751 "$docroot"
mkdir -p "$home_dir/$user/web/$domain/tmp"
chmod 0700  "$home_dir/$user/web/$domain/tmp"
chown "$user":"$user" "$home_dir/$user/web/$domain/tmp"

phpv=80
if ls /etc/opt/remi/php*/php-fpm.d/"${user}-${domain}.conf" ; then
  oldphpvs="$(ls /etc/opt/remi/php*/php-fpm.d/"${user}-${domain}.conf" | awk -F'/' '{print $5}')"
  for oldphpv in $oldphpvs ; do
    if [[ "$oldphpv" != "$phpv" ]] ; then
      rm -f "/etc/opt/remi/${oldphpv}/php-fpm.d/${user}-${domain}.conf"
      sudo systemctl reload "${oldphpv}-php-fpm" || sudo systemctl start "${oldphpv}-php-fpm"
    fi
  done
fi
cat > "/etc/opt/remi/php$phpv/php-fpm.d/${user}-${domain}.conf" << EOF
[${user}-${domain}]
user = $user
group = $user
listen.owner = $user
listen.group = $user
listen = /home/$user/web/$domain/php.socket
listen.acl_users = nginx,apache
listen.acl_groups = $user
pm = dynamic
pm.max_children = 50
pm.start_servers = 5
pm.min_spare_servers = 5
pm.max_spare_servers = 35
security.limit_extensions = .php
php_admin_flag[log_errors] = on
;php_flag[display_errors] = on
php_value[error_log] = $home_dir/$user/web/$domain/logs/${domain}.error.log
php_value[session.save_handler] = files
php_value[session.save_path]    = $home_dir/$user/tmp
php_value[soap.wsdl_cache_dir]  = $home_dir/$user/tmp
php_value[opcache.file_cache]   = $home_dir/$user/tmp
php_value[memory_limit] = 512M
php_value[post_max_size] = 64M
php_value[upload_max_filesize] = 64M
EOF

sudo systemctl reload "php${phpv}-php-fpm" || sudo systemctl start "php${phpv}-php-fpm"

exit 0
