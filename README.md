# Setup Wordpress docker (all plugins)

## Bước 1: Tạo project docker và folder chứa source code

```bash
mkdir ~/wordpress-docker
cd ~/wordpress-docker

sudo mkdir -p /var/www/wordpress
sudo chown $USER:$USER /var/www/wordpress
```

## Bước 2: Tạo `Dockerfile` cài đặt `xdebug`

```docker
FROM wordpress:latest

   # Install Xdebug
   RUN pecl install xdebug && docker-php-ext-enable xdebug

   # Copy custom xdebug.ini
   COPY xdebug.ini /usr/local/etc/php/conf.d/xdebug.ini
```

## Bước 3: Tạo `xdebug.ini`

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

## Bước 4: Tạo `docker-compose.yml`

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
    volumes:
      - /var/www/wordpress:/var/www/html
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

<aside>
💡

**Chú ý:**

Ở dòng khai báo `volumes`, `/var/www/wordpress:/var/www/html` sẽ hoạt động như sau: Khi docker chạy thành công, source code trong `/var/www/html` sẽ được copy ra `/var/www/wordpress` nếu `/var/www/wordpress` đang ko có file nào, còn nếu `/var/www/wordpress` đang có file thì sẽ sử dụng file đang có để ném vào docker

Tương tự với database, nếu muốn mount kiểu vậy thì sửa như vậy nhưng ở đây đang ko cần.

</aside>

## Bước 5: Chạy `docker-compose up -d`
## Bước 6: Tạo file cấu hình xdebug để debug trên vscode (`launch.json`)

Đảm bảo user có quyền chỉnh sửa file trong source code tại `/var/www/wordpress`

```bash
sudo chown -R $USER:$USER /var/www/wordpress/
```

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

## Bước 7: Kiểm tra xdebug trong docker (nếu ko hit được breakpoint)

Kiểm tra nội dung `xdebug.ini`

```bash
docker exec -it wordpress cat /usr/local/etc/php/conf.d/xdebug.ini
```

Kiểm tra `xdebug.log`

```bash
docker exec -it wordpress cat /tmp/xdebug.log
```

## Bước 8: Nếu debug tại local thì copy source code về (bao gồm cả `.vscode` có trong folder source code)

Tại máy client dùng `scp` để lôi source code về

```bash
scp -r ubuntu@192.168.45.253:/var/www/wordpress/ wordpress/
```

## Backup

Backup source code và data

```bash
tar -czf wordpress_backup.tar.gz /var/www/wordpress
docker exec wordpress_db mysqldump -u wordpress -p wordpress > backup.sql
```
