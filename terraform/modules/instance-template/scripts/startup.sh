#!/bin/bash

yum install -y nginx java

cat <<'EOF' > /etc/nginx/nginx.conf
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    server {
        listen      80 default_server;
        server_name _;
        location / {
            proxy_pass  http://127.0.0.1:1234;
        }
    }
}
EOF

setsebool -P httpd_can_network_connect true

systemctl enable nginx
systemctl start nginx

cat <<'EOF' > /config.properties
db.user=${db_user}
db.password=${db_password}
db.name=${db_name}
db.ip=${db_ip}
EOF

curl -o app.jar https://morisbak.net/files/helloworld-java-app.jar

java -jar app.jar > /dev/null 2>&1 &
