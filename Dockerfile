# Using the multi-arch build: https://www.docker.com/blog/multi-arch-build-and-images-the-simple-way/
ARG ARCH=
ARG BUILD_FROM=ghcr.io/linuxserver/baseimage-alpine:${ARCH}3.13
# hadolint ignore=DL3006
FROM ${BUILD_FROM} as base
# Based on https://github.com/linuxserver/docker-baseimage-alpine-nginx

COPY base-root /

# hadolint ignore=SC2016
RUN \
    apk add --no-cache \
        php8=8.0.2-r0 \
        php8-fileinfo=8.0.2-r0 \
        php8-fpm=8.0.2-r0 \
        php8-common=8.0.2-r0 \
        php8-mbstring=8.0.2-r0 \
        php8-openssl=8.0.2-r0 \
        php8-session=8.0.2-r0 \
        php8-simplexml=8.0.2-r0 \
        php8-xml=8.0.2-r0 \
        php8-xmlwriter=8.0.2-r0 \
    \
    && apk add --no-cache \
        apache2-utils=2.4.46-r3 \
        git=2.30.2-r0 \
        libressl3.1-libssl=3.1.5-r0 \
        logrotate=3.18.0-r0 \
        nano=5.4-r1 \
        nginx=1.18.0-r13 \
        openssl=1.1.1k-r0 \
    \
    && echo 'fastcgi_param  SCRIPT_FILENAME $document_root$fastcgi_script_name;' >> \
	    /etc/nginx/fastcgi_params \
    \
    && rm -f /etc/nginx/conf.d/default.conf \
    \
    && sed -i "s#/var/log/messages {}.*# #g" /etc/logrotate.conf \
    \
    && sed -i 's#/usr/sbin/logrotate /etc/logrotate.conf#/usr/sbin/logrotate /etc/logrotate.conf -s /config/log/logrotate.status#g' \
	    /etc/periodic/daily/logrotate

FROM base

# Environment variables
ARG BUILD_DATE
ARG VERSION
ARG TT_RSS_VERSION
LABEL build_version="master ${BUILD_DATE}"
LABEL maintainer="lunik1"

# Copy root filesystem
COPY root /

# Set shell
SHELL ["/bin/ash", "-o", "pipefail", "-c"]

RUN \
    set -o pipefail \
    \
    && apk add --no-cache \
        php8-curl=8.0.2-r0 \
        php8-dom=8.0.2-r0 \
        php8-gd=8.0.2-r0 \
        php8-iconv=8.0.2-r0 \
        php8-intl=8.0.2-r0 \
        php8-ldap=8.0.2-r0 \
        php8-mysqli=8.0.2-r0 \
        php8-mysqlnd=8.0.2-r0 \
        php8-pcntl=8.0.2-r0 \
        php8-pdo_mysql=8.0.2-r0 \
        php8-pdo_pgsql=8.0.2-r0 \
        php8-pgsql=8.0.2-r0 \
        php8-posix=8.0.2-r0 \
    \
    && apk add --no-cache \
        php8-pecl-apcu=5.1.20-r0 \
        php8-pecl-mcrypt=1.0.4-r0 \
    \
    && apk add --no-cache \
        curl=7.74.0-r1 \
        tar=1.34-r0 \
		\
 		&& mkdir -p /var/www/html/ \
    \
    && if [ -z ${TT_RSS_VERSION+x} ]; then TT_RSS_VERSION=master; fi \
    \
    && curl -o \
        /tmp/ttrss.tar.gz -L \
        "https://gitlab.com/lunik1/tt-rss/-/archive/master/tt-rss-${TT_RSS_VERSION}.tar.gz" \
    \
    && tar xf \
        /tmp/ttrss.tar.gz -C \
	    /var/www/html/ --strip-components=1 \
    \
    && ln -sf /usr/bin/php8 /usr/bin/php \
    \
    && sed -i 's/^;clear_env/clear_env/i' /etc/php8/php-fpm.d/www.conf \
		\
    && mkdir -p /config \
		\
		&& apk del --no-cache --purge \
    && rm -f -r \
        /tmp/*

# Expose ports and volumes
EXPOSE 80 443
VOLUME /config
