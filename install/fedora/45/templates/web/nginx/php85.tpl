server {
    listen      %ip%:%proxy_port%;
    server_name %domain_idn% %alias_idn%;
    #error_log  /var/log/httpd/domains/%domain%.error.log error;
    error_log  %home%/%user%/web/%domain%/logs/%domain%.error.log error;

    location / {
        return 301 https://$host$request_uri;
    }

    location /error/ {
        alias   %home%/%user%/web/%domain%/document_errors/;
    }

    location ~ /\.ht    {return 404;}
    location ~ /\.svn/  {return 404;}
    location ~ /\.git/  {return 404;}
    location ~ /\.hg/   {return 404;}
    location ~ /\.bzr/  {return 404;}

    include %home%/%user%/conf/web/nginx.%domain_idn%.conf*;
}

