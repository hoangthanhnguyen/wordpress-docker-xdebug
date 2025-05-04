# How to setup Wordpress docker

## Bước 1: Tạo project docker và folder chứa source code

```bash
mkdir ~/wordpress-docker-xdebug
cd ~/wordpress-docker-xdebug
```

## Bước 2: Tạo `xdebug.ini`

Tự tạo `xdebug.ini` để Dockerfile sẽ ném nó vào wordpress docker

```bash
zend_extension=xdebug

[xdebug]
xdebug.mode=develop,debug
xdebug.client_host=192.168.44.233
xdebug.start_with_request=yes
xdebug.client_port=9003
xdebug.log=/tmp/xdebug.log
```

<aside>
💡

**Chú ý:**
`xdebug.client_host` là địa chỉ của nơi debug.

→ Nếu dùng VSCode ssh lên server và debug trực tiếp trên đó thì phải set `xdebug.client_host` là địa chỉ của gateway (sau khi chạy docker compose thì vào check gateway bằng cách chạy lệnh `docker inspect wordpress | grep Gateway` → do thử [localhost](http://localhost) hay 127.0.0.1 thì xdebug.log trả ra lỗi `[61] [Step Debug] ERR: Could not connect to debugging client. Tried: 127.0.0.1:9003 (through xdebug.client_host/xdebug.client_port).`)

→ Nếu muốn dùng VSCode debug trực tiếp trên local thì do đang listen trên port 9003 của local (client) nên `xdebug.client_host` set về IP của client (địa chỉ IP mà client và vps đều chung gateway), ở đây IP local đang là `192.168.44.233` 

</aside>

## Bước 3: Tạo `custom.ini`

Tự tạo `custom.ini` để Dockerfile sẽ ném nó vào wordpress docker

```bash
[PHP]
upload_max_filesize = 512M
post_max_size = 512M
memory_limit = 256M
max_execution_time = 300
```

## Bước 4: Tạo `Dockerfile` cài đặt `xdebug` và ném config php vào (fix lỗi upload)

```docker
FROM wordpress:latest

   # Install Xdebug
   RUN pecl install xdebug && docker-php-ext-enable xdebug

   # Copy custom xdebug.ini
   COPY xdebug.ini /usr/local/etc/php/conf.d/xdebug.ini

   # Copy custom php.ini settings
   COPY custom.ini /usr/local/etc/php/conf.d/custom.ini
```

## Bước 5: Tạo `docker-compose.yml`

```yaml
version: '3'

services:
  wordpress:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: wordpress
    ports:
      - "80:80"
    environment:
      WORDPRESS_DB_HOST: db
      WORDPRESS_DB_USER: wordpress
      WORDPRESS_DB_PASSWORD: wordpress_password
      WORDPRESS_DB_NAME: wordpress
    depends_on:
      - db
    networks:
      - wordpress-network
    restart: always

  db:
    image: mysql:8.0
    container_name: wordpress_db
    environment:
      MYSQL_DATABASE: wordpress
      MYSQL_USER: wordpress
      MYSQL_PASSWORD: wordpress_password
      MYSQL_ROOT_PASSWORD: root_password
    volumes:
      - db_data:/var/lib/mysql
    networks:
      - wordpress-network
    restart: always

networks:
  wordpress-network:
    driver: bridge

volumes:
  db_data:
```

## Bước 5: Chạy `docker-compose up -d`

## Bước 6: Copy source code ra `/var/www/wordpress` trên host

```bash
docker cp wordpress:/var/www/html /var/www/wordpress
```

## Bước 7: Tạo file cấu hình xdebug để debug trên vscode (`launch.json`)

Tạo folder `.vscode` → file `launch.json` (hoặc trong VSCode vào `Run` → `Add Configuration…` → edit nội dung file)

```json
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Listen for Xdebug",
            "type": "php",
            "request": "launch",
            "port": 9003,
            "pathMappings": {
                "/var/www/html": "${workspaceFolder}"
            }
        }
    ]
}
```

## Bước 8: Copy `.vscode` vào `/var/www/wordpress`

```bash
cp -r .vscode /var/www/wordpress/
```

## Bước 9: Kiểm tra xdebug trong docker (nếu ko hit được breakpoint)

Kiểm tra nội dung `xdebug.ini`

```bash
docker exec -it wordpress cat /usr/local/etc/php/conf.d/xdebug.ini
```

Kiểm tra `xdebug.log`

```bash
docker exec -it wordpress cat /tmp/xdebug.log
```

## Bước 10: Nếu debug tại local thì copy source code về (bao gồm cả `.vscode` có trong folder source code)

Tại máy client dùng `scp` để lôi source code về

```bash
scp -r ubuntu@server:/var/www/wordpress/ wordpress/
```

## Backup

Backup source code và data

```bash
tar -czf wordpress_backup.tar.gz /var/www/wordpress
docker exec wordpress_db mysqldump -u wordpress -p wordpress > backup.sql
```