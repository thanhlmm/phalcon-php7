FROM ubuntu:xenial
MAINTAINER Antonio Manuel Hernández Sánchez

ENV DEBIAN_FRONTEND noninteractive

RUN PACKAGES_TO_INSTALL="sudo git cron php7.1-dev composer php-xdebug php7.1-mbstring php7.1-curl php7.1-fpm nginx supervisor libyaml-dev php7.1-mysql php7.1-phalcon" && \
    apt-get update && \
    apt-get install -y software-properties-common && \
    apt-add-repository -y ppa:phalcon/stable && \
    apt-get update && \
    apt-get install -y $PACKAGES_TO_INSTALL && \
    apt-get autoremove -y && \
    apt-get clean && \
    apt-get autoclean
    
RUN pecl install yaml-beta && \
    echo 'extension=yaml.so' > /etc/php/7.1/mods-available/yaml.ini && \
    ln -s /etc/php/7.1/mods-available/yaml.ini /etc/php/7.1/cli/conf.d/50-yaml.ini && \
    ln -s /etc/php/7.1/mods-available/yaml.ini /etc/php/7.1/fpm/conf.d/50-yaml.ini

RUN echo 'extension=phalcon.so' > /etc/php/7.1/mods-available/phalcon.ini && \
    ln -s /etc/php/7.1/mods-available/phalcon.ini /etc/php/7.1/cli/conf.d/50-phalcon.ini && \
    ln -s /etc/php/7.1/mods-available/phalcon.ini /etc/php/7.1/fpm/conf.d/50-phalcon.ini

# configure NGINX as non-daemon
RUN echo "daemon off;" >> /etc/nginx/nginx.conf

# configure php-fpm as non-daemon
RUN sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php/7.1/fpm/php-fpm.conf

# clear apt cache and remove unnecessary packages
RUN apt-get autoclean && apt-get -y autoremove

# add a phpinfo script for INFO purposes
RUN echo "<?php phpinfo();" >> /var/www/html/index.php

# NGINX mountable directories for config and logs
VOLUME ["/etc/nginx/sites-enabled", "/etc/nginx/certs", "/etc/nginx/conf.d", "/var/log/nginx"]

# NGINX mountable directory for apps
VOLUME ["/var/www"]

# copy config file for Supervisor
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# backup default default config for NGINX
RUN mv /etc/nginx/sites-available/default /etc/nginx/sites-available/default.bak

# copy local defualt config file for NGINX
COPY nginx-site.conf /etc/nginx/sites-available/default

# php7.1-fpm will not start if this directory does not exist
RUN mkdir /run/php

# NGINX ports
EXPOSE 80 443

CMD ["/usr/bin/supervisord"]
