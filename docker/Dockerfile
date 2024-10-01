#FrankenPHP Workspace

# Necessary Build Arguments
ARG PHP_VERSION=8.3
ARG APP_ENV=dev
ARG FRANKENPHP_VERSION=1.2


FROM dunglas/frankenphp:${FRANKENPHP_VERSION}-php${PHP_VERSION}-bookworm

# Metadata
LABEL org.opencontainers.image.title = 'FrankenPHP Workspace'
LABEL org.opencontainers.image.description = 'The modern PHP dev server. Batteries included.'
#LABEL org.opencontainers.image.url=
LABEL org.opencontainers.image.licenses=MIT
LABEL org.opencontainers.image.vendor = 'AndersonPEM <https://github.com/andersonpem>'
LABEL org.opencontainers.image.authors = 'Anderson Souza <sza.andersonsilva@gmail.com>'
LABEL org.opencontainers.image.source=https://github.com/andersonpem/frankenphp-dev-container
#LABEL org.opencontainers.image.documentation=

#       Shell    nounset options fail      commands
SHELL ["/bin/bash", "-u", "-o", "pipefail", "-c"]

WORKDIR /root

ADD --chmod=0755 https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/
#Todo: Turso is not thread safe yet. We need to wait for the next release.
#ADD --chmod=0775 https://darkterminal.github.io/turso-php-installer/dist/turso-php-installer.phar /usr/local/bin/turso-php-installer

ARG TARGETARCH

ENV PROJECT_ROOT /var/www/html
ENV DOCUMENT_ROOT /var/www/html/public

ARG WORKSPACE_VERSION=1.0.0
ENV WORKSPACE_VERSION=${WORKSPACE_VERSION}


ENV PHP_INI_MEMORY_LIMIT=1G
ENV PHP_INI_VARIABLES_ORDER=EGPCS
ENV PHP_INI_DISPLAY_ERRORS=off
ENV PHP_INI_ERROR_REPORTING="E_ALL & ~E_DEPRECATED & ~E_STRICT"
ENV PHP_INI_UPLOAD_MAX_FILESIZE=100M
ENV PHP_INI_POST_MAX_SIZE=100M

#XDebug
ENV XDEBUG_MODE=off
ENV XDEBUG_START_WITH_REQUEST=yes
ENV XDEBUG_PORT=9003
ENV XDEBUG_CLIENT_HOST=host.docker.internal
ENV XDEBUG_IDEKEY=frankenphp

ENV XDEBUG_ENABLE=0
ENV OPCAHE_ENABLE=0

ENV PHP_IDE_CONFIG="serverName=frankenphp"
ENV FIX_FILE_PERMISSIONS_ON_START=0
ENV XDEBUG_START_WITH_REQUEST=no

RUN apt update && apt install apt-utils  apt-transport-https -y

ADD docker/ini/php-extra.ini $PHP_INI_DIR/conf.d/php-extra.ini

RUN set -eux; \
    DEBIAN_FRONTEND=noninteractive \
    apt install sudo openssl libssl-dev\
    acl iproute2 figlet apt-transport-https\
    zsh gawk perl bash-completion gnupg \
    inetutils-ping telnet postgresql-client \
    git unzip curl wget locales \
    python3 python3-pip python3-tqdm \
    default-mysql-client libpq-dev \
    libnss3-tools libnss3 procps htop\
    python3-pyfiglet libevent-dev -y

RUN set -eux; \
    docker-php-ext-install sysvmsg sysvsem sysvshm; \
    install-php-extensions \
    sockets \
    event \
	pdo_mysql \
	pdo_pgsql \
	gd \
	intl \
	zip \
	opcache \
    xdebug \
    ssh2 \
    redis \
    yaml

# Todo: Turso is not thread safe yet. We need to wait for the next release.
#    turso-php-installer install; \
#    echo "extension=/root/.turso-client-php/liblibsql_php.so" > ${PHP_INI_DIR}/conf.d/turso-php.ini; \
#    php -m | grep -q libsql

WORKDIR /root

ADD docker/sh/aliases.sh .aliases
ADD docker/sh/includes.sh /opt/includes
ADD --chmod=0755 docker/sh/phpunit /usr/local/bin/phpunit
ADD --chmod=0755 docker/sh/setup_env.sh /usr/local/bin/setup_env
ADD --chmod=0755 docker/sh/lsoct.sh /usr/local/bin/lsoct
ADD --chmod=0755 docker/py/permissions.py /usr/local/bin/webpermissions

COPY --from=composer:2 /usr/bin/composer /usr/local/bin/composer

# |--------------------------------------------------------------------------
# | The Docker user
# |--------------------------------------------------------------------------
# | The Docker user is used to run the application.
# | This allows us not to use root in commands (which is discouraged when not
# | needed) and also allows us to mirror the host user UID/GID to the Docker
# | container, avoiding pesky permission issues.
# | The Docker user can also use Sudo.
# | Remember: with great power, comes great pizza time.

RUN useradd -m -d /home/docker -s /bin/bash docker && adduser docker sudo

# Users in the sudoers group can sudo as root without password.
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

USER root
WORKDIR /root
ENV COMPOSER_ALLOW_SUPERUSER=1
RUN mkdir -p /root/.composer \
    && setup_env \
    && sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen \
    && locale-gen en_US.UTF-8 \
    && curl -1sLf 'https://dl.cloudsmith.io/public/symfony/stable/setup.deb.sh' | sudo -E bash \
    && apt update && apt install symfony-cli -y \
    && mkdir -p /home/docker/.config/composer \
    && chown -R docker:docker /home/docker

# Let's set up the Docker user's environment :)
USER docker
WORKDIR /home/docker
ADD docker/sh/aliases.sh .aliases
ENV COMPOSER_HOME="/home/docker/.config/composer"
RUN setup_env

USER root
# Allow the user Docker to bind to http ports
ARG USER=docker
RUN setcap CAP_NET_BIND_SERVICE=+eip /usr/local/bin/frankenphp \
# Permissions to write in the Caddy directories
    && chown -R docker:docker /data/caddy && chown -R docker:docker /config/caddy

# Add the entrypoint
ADD --chmod=0755 docker/sh/entrypoint.sh /usr/local/bin/frankenphp-workspace
ADD --chmod=600 --chown=docker docker/history /home/docker/.bash_history
ADD --chmod=600 --chown=docker docker/history /home/docker/.zsh_history

RUN mv "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini"

ADD ./docker/Caddyfile /etc/caddy/Caddyfile

RUN chown -R docker:docker ${PROJECT_ROOT}

USER docker
WORKDIR ${PROJECT_ROOT}

ENTRYPOINT ["/usr/local/bin/frankenphp-workspace"]
CMD ["--config", "/etc/caddy/Caddyfile", "--adapter", "caddyfile"]
