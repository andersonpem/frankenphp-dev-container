#FrankenPHP Workshop

# Necessary Build Arguments
ARG PHP_VERSION=8.3
ARG APP_ENV=dev
ARG NODE_VERSION=20

# Stage 1: Use the official Node.js image to get Node.js and npm
FROM --platform=$TARGETPLATFORM node:${NODE_VERSION} AS nodejs

# Update NPM
RUN npm install -g npm@latest

FROM --platform=$TARGETPLATFORM dunglas/frankenphp:1.1.0-php${PHP_VERSION}-bookworm
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ADD --chmod=0755 https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/

ENV PROJECT_ROOT /app
ENV DOCUMENT_ROOT /app/public

ENV XDEBUG_ENABLE=0
ENV OPCAHE_ENABLE=0
ENV PHP_IDE_CONFIG="serverName=frankenphp"
ENV XDEBUG_IDEKEY=frankenphp
ENV FIX_FILE_PERMISSIONS_ON_START=0
ENV XDEBUG_START_WITH_REQUEST=no
ENV XDEBUG_MODE=debug,develop

# Metadata
LABEL org.opencontainers.image.title = 'FrankenPHP Workspace'
LABEL org.opencontainers.image.description = 'The modern PHP app server. With all dev workspace batteries included.'
#LABEL org.opencontainers.image.url=
LABEL org.opencontainers.image.licenses=MIT
LABEL org.opencontainers.image.vendor = 'AndersonPEM <https://github.com/andersonpem>'
LABEL org.opencontainers.image.authors = 'Anderson Souza <sza.andersonsilva@gmail.com>'
LABEL org.opencontainers.image.source=https://github.com/andersonpem/frankenphp-dev-container
#LABEL org.opencontainers.image.documentation=

# Copy Node.js and npm from the Node.js image
COPY --from=nodejs /usr/local/bin /usr/local/bin
COPY --from=nodejs /usr/local/lib /usr/local/lib

# Ensure binaries are executable and node_modules binaries are available
RUN ln -s /usr/local/bin/node /usr/bin/node && \
    ln -s /usr/local/bin/npm /usr/bin/npm && \
    ln -s /usr/local/bin/npx /usr/bin/npx


RUN chmod +x /usr/local/bin/node /usr/local/bin/npm \
  /usr/local/bin/npx

RUN apt update && DEBIAN_FRONTEND=noninteractive apt install apt-utils redis-tools -y

RUN set -eux; \
    DEBIAN_FRONTEND=noninteractive \
    apt install sudo openssl libssl-dev\
    acl iproute2 figlet \
    zsh gawk perl bash-completion \
    inetutils-ping telnet \
    git unzip curl wget locales \
    python3 python3-pip python3-tqdm \
    default-mysql-client \
    libnss3-tools libnss3 procps htop\
    python3-pyfiglet libevent-dev -y > /dev/null

RUN set -eux; \
    docker-php-ext-install sysvmsg sysvsem sysvshm

RUN set -eux; \
    install-php-extensions \
    sockets \
    event \
	pdo_mysql \
	gd \
	intl \
	zip \
	opcache \
    xdebug \
    ssh2 \
    redis \
    yaml \
    gd

WORKDIR /root

ADD docker/sh/aliases.sh .aliases
ADD docker/sh/includes.sh /opt/includes
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

# Let's set up the Docker user's environment :)
USER docker
WORKDIR /home/docker
ADD docker/sh/aliases.sh .aliases
RUN setup_env \
    && sudo sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && \
    sudo locale-gen en_US.UTF-8 \
# Set a home for Node and install Yarn
    && mkdir -p /home/docker/node_modules \
    && echo 'export PATH="/home/docker/node_modules/bin:$PATH"' >> /home/docker/.bashrc \
    && sudo -u docker npm config set prefix '/home/docker/node_modules' \
    && npm install -g yarn@latest \
    && curl -1sLf 'https://dl.cloudsmith.io/public/symfony/stable/setup.deb.sh' | sudo -E bash \
    && sudo apt install symfony-cli -y \
    && COMPOSER_HOME="/home/docker/.config/composer" composer global require laravel/installer

USER root
WORKDIR /root
ENV COMPOSER_ALLOW_SUPERUSER=1
RUN mkdir -p /root/.composer \
    && setup_env \
    && sudo sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen \
    && sudo locale-gen en_US.UTF-8

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

USER docker
WORKDIR ${PROJECT_ROOT}

ENTRYPOINT ["/usr/local/bin/frankenphp-workspace"]
CMD ["--config", "/etc/caddy/Caddyfile", "--adapter", "caddyfile"]
