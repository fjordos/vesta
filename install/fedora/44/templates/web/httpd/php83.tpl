<VirtualHost %ip%:%web_port%>

    ServerName %domain_idn%
    %alias_string%
    ServerAdmin %email%
    DocumentRoot %docroot%
    ScriptAlias /cgi-bin/ %home%/%user%/web/%domain%/cgi-bin/
    Alias /vstats/ %home%/%user%/web/%domain%/stats/
    Alias /error/ %home%/%user%/web/%domain%/document_errors/
    #SuexecUserGroup %user% %group%
    CustomLog /var/log/%web_system%/domains/%domain%.bytes bytes
    CustomLog %home%/%user%/web/%domain%/logs/%domain%.log combined
    ErrorLog %home%/%user%/web/%domain%/logs/%domain%.error.log
    <Directory %docroot%>
        AllowOverride All
        Options +Includes -Indexes +ExecCGI
    </Directory>

    RewriteEngine On
    RewriteRule (.*) https://%{HTTP_HOST}%{REQUEST_URI}

    IncludeOptional %home%/%user%/conf/web/%web_system%.%domain_idn%.conf*

</VirtualHost>
