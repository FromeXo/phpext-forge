#*******************#
# Base dependencies #
#*******************#
FROM debian:bookworm AS base

ARG EXT_NAME=test

ARG PHP_VERSION=8.2.9

RUN mkdir -p /php

RUN apt update -y && apt upgrade -y && apt install -y \
    build-essential autoconf automake libtool bison valgrind \
    make pkg-config re2c libxml2-dev libsqlite3-dev flex gdb \
    procps inotify-tools

ENV EXT_NAME=$EXT_NAME
ENV PHP_VERSION=$PHP_VERSION
ENV PATH="/php/php-${PHP_VERSION}/bin:$PATH"

#*******************#
#    PHP  source    #
#*******************#
FROM base AS php_src

RUN apt update -y && apt install git -y

WORKDIR /php

RUN git clone https://github.com/php/php-src.git

WORKDIR /php/php-src

RUN git checkout PHP-${PHP_VERSION}

FROM base AS php_build

COPY --from=php_src /php/php-src /php/php-src
WORKDIR /php/php-src

RUN ./buildconf
RUN ./configure \
        --prefix=/php/php-${PHP_VERSION} \
        --enable-debug \
        --with-config-file-path=/php/php-${PHP_VERSION}/etc

RUN make -j${nproc} && make install

RUN mkdir -p /php/php-${PHP_VERSION}/etc

COPY ./includes/php.ini /php/php-${PHP_VERSION}/etc

#********************#
# Build dependencies #
#********************#
FROM base AS build

COPY --from=php_build /php/php-${PHP_VERSION} /php/php-${PHP_VERSION}
COPY --from=php_src /php/php-src /php/php-src

RUN mkdir -p /php/server/public
COPY ./includes/index.php /php/server/public/index.php

WORKDIR /php
RUN if [ -n "$EXT_NAME" ]; then php php-src/ext/ext_skel.php --ext ${EXT_NAME} --dir /php; fi
RUN if [ -n "$EXT_NAME" ]; then echo "\nextension=${EXT_NAME}.so" >> /php/php-${PHP_VERSION}/etc/php.ini; fi

RUN mkdir -p ${EXT_NAME}
WORKDIR /php/${EXT_NAME}

#***************#
#  Final Image  #
#***************#
FROM build
COPY ./includes/cmd.sh /root/cmd.sh
RUN chmod +x /root/cmd.sh

WORKDIR /php
EXPOSE 80
CMD [ "/root/cmd.sh" ]