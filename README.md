# Docker nginx + php7.0 container

Docker container based on `Ubuntu 18.04.1` version. Using `nginx stable` version with `php 7.0.33`. This is simple container modified version of [https://github.com/navidonskis/nginx-php7.1] my own personally purpose. 

Need PHP 5.6 ? [https://github.com/navidonskis/nginx-php5.6](https://github.com/navidonskis/nginx-php5.6).
Need PHP 7.1 ? [https://github.com/navidonskis/nginx-php7.1](https://github.com/navidonskis/nginx-php7.1).

## Includes packages

 * nginx, ssmtp, memcached, curl, pwgen, supervisor
 * git, composer
 * php 7.0 (fpm, cli, mysql, apc, curl, gd, intl, mcrypt, mbstring, memcache, memcached, sqlite, tidy, xmlrpc, xsl, pgsql,  ldap, sybase, odbc, soap, json, redis)

## Usage

Creating container via `docker-compose` file.

```yaml
  web:
    image: gokhand/nginx-php7.0
    container_name: web
    restart: always
    volumes:
      # 1. mount your workdir path
      - /var/www:/var/www
      # 2. mount your configuration of site
      - /mnt/docker/nginx/sites-enabled:/etc/nginx/sites-enabled
      # 3. if you have settings for ssmtp
      - /mnt/docker/nginx/ssmtp/ssmtp.conf:/etc/ssmtp/ssmtp.conf
      # 4. if you want to override php.ini file
      - /mnt/docker/php/custom.ini:/etc/php/7.1/fpm/conf.d/custom.ini
    # 5. have a cronjob tasks? run the command...
    command:
      # remember to escape variables dollar sign with duplication $$ instead $
      - '* * * * * echo "Hello $$(date)" >> /var/log/cron.log 2>&1'
      - '* * * * * echo "Hello world !" >> /var/log/cron.log 2>&1'
```
