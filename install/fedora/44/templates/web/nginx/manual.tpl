server {
    listen      %ip%:%proxy_port%;
    server_name %domain_idn% %alias_idn%;
    error_log  /var/log/nginx/domains/%domain%.error.log error;

    location /error/ {
        alias   %home%/%user%/web/%domain%/document_errors/;
    }

    root           %docroot%;
    index index.html index.htm;
    #return 301 https://$host$request_uri;

    location ~ /\.ht    {return 404;}
    location ~ /\.svn/  {return 404;}
    location ~ /\.git/  {return 404;}
    location ~ /\.hg/   {return 404;}
    location ~ /\.bzr/  {return 404;}

    disable_symlinks if_not_owner from=%docroot%;

    include %home%/%user%/conf/web/nginx.%domain_idn%.conf*;
}

