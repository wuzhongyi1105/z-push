FROM php:7.3-fpm-alpine

ARG ZPUSH_URL=https://github.com/Z-Hub/Z-Push/archive/refs/tags/2.6.3.tar.gz
ARG ZPUSH_CSUM=c47812dc1d28ac4858b9e2717ec4e164
ARG UID=1513
ARG GID=1513

ENV TIMEZONE=Europe/Zurich \
  IMAP_SERVER=localhost \
  IMAP_PORT=143 \
  SMTP_SERVER=tls://localhost \
  SMTP_PORT=465

ADD root /

RUN set -ex \
  # Install important stuff
  && apk add --update --no-cache \
  alpine-sdk \
  autoconf \
  bash \
  ca-certificates \
  imap \
  imap-dev \
  nginx \
  openssl \
  openssl-dev \
  pcre \
  pcre-dev \
  supervisor \
  tar \
  tini \
  wget
  # Install php
RUN docker-php-ext-configure imap --with-imap --with-imap-ssl \
  && docker-php-ext-install imap pcntl sysvmsg sysvsem sysvshm \
  && pecl install apcu \
  && docker-php-ext-enable apcu \
  # Remove dev packages
  && apk del --no-cache \
  alpine-sdk \
  autoconf \
  openssl-dev \
  pcre-dev
  # Add user for z-push
RUN addgroup -g ${GID} zpush \
  && adduser -u ${UID} -h /opt/zpush -H -G zpush -s /sbin/nologin -D zpush \
  && mkdir -p /opt/zpush
  # Install z-push
RUN wget -q -O /tmp/z-push.tar.gz "$ZPUSH_URL" \
  && if [ "$ZPUSH_CSUM" != "$(md5sum /tmp/z-push.tar.gz | awk '{print($1)}')" ]; then echo "Wrong md5sum of downloaded file!"; exit 1; fi \
  && tar -zxf /tmp/z-push.tar.gz \
  && mv Z-Push-2.6.3/src /zpush \
  && rm /tmp/z-push.tar.gz \
  && chmod +x /usr/local/bin/docker-run.sh \
  && mv /zpush/config.php /zpush/config.php.dist \
  && mv /zpush/backend/imap/config.php /zpush/backend/imap/config.php.dist

VOLUME ["/state"]
VOLUME ["/config"]

EXPOSE 80

ENTRYPOINT ["/sbin/tini", "--"]
CMD /usr/local/bin/docker-run.sh
