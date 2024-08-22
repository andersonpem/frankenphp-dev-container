#!/usr/bin/env bash

handle_sigint() {
    echo "Received SIGINT, exiting..."
    exit 1
}

# Check if gum is installed
if ! command -v gum &> /dev/null
then
    echo "Gum could not be found. Please install gum on your machine. Please check: https://bit.ly/installgum"
    exit 1
fi

trap handle_sigint SIGINT

export GUM_INPUT_CURSOR_FOREGROUND="#09ED37"
export GUM_INPUT_PROMPT_FOREGROUND="#0FF"
export GUM_INPUT_PROMPT="* "
export GUM_INPUT_WIDTH=80

gum style \
        --foreground "#FFFFFF" --border-foreground "#00FF00" --border double \
        --align center --width 70 --margin "1 2" --padding "2 4" \
        'FrankenPHP Workspace' 'Your modern PHP workspace. Batteries included.'

# Ask for PHP version
echo "Please choose a PHP version"
PHP_VERSION=$(gum choose --height 15 {8.3,8.2,8.1,8.0})
if [ "$PHP_VERSION" = "user aborted" ]; then
    echo "User aborted PHP version selection, exiting..."
    exit 1
fi

# Ask for Node installation
if gum confirm "Do you want to use Node.js?"; then
    echo "Please choose a Node.js version"
    echo "LTS are 18 and 20. 21 is edge."
    NODE_VERSION=$(gum choose --height 15 {18,20,21})
    if [ "$NODE_VERSION" = "user aborted" ]; then
      echo "User aborted on selection, exiting..."
      exit 1
    fi
    NODE_VERSION="node-$NODE_VERSION"
else
    NODE_VERSION="nodeless"
fi


# Ask for Node installation
if gum confirm "Do you want to use a relational DB?"; then
      echo "Relational DBs"
      DATABASE_TYPE=$(gum choose --height 15 {MySQL,MariaDB,Postgres})
      if [ "$DATABASE_TYPE" = "user aborted" ]; then
        echo "User aborted on selection, exiting..."
        exit 1
      fi
      case "$DATABASE_TYPE" in
        MySQL)
          DEFAULT_PORT=3306
          ;;
        MariaDB)MySQL
          DEFAULT_PORT=3306
          ;;
        Postgres)
          DEFAULT_PORT=5432
          ;;
        *)
          DEFAULT_PORT=""
          ;;
      esac
      # Now let's ask the user for a version
      echo "Please choose a version for $DATABASE_TYPE (you can change this later in the docker-compose.yml file)"
      DATABASE_VERSION=""
      while [[ -z $DATABASE_VERSION ]]; do
        case "$DATABASE_TYPE" in
          MySQL)
            DATABASE_VERSION=$(gum choose --height 15 {8.0,latest,5.7})
            ;;
          MariaDB)
            DATABASE_VERSION=$(gum choose --height 15 {10.6,10.5,latest})
            ;;
          Postgres)
            DATABASE_VERSION=$(gum choose --height 15 {13,12,latest})
            ;;
          *)
            DATABASE_VERSION=""
            ;;
        esac
      done
      if [ "$DATABASE_VERSION" = "user aborted" ]; then
        echo "User aborted on selection, exiting..."
        exit 1
      fi
      if gum confirm "Would you like to expose a port from the DB container?"; then
          echo "Choose a port to expose the database on (container port) and the host port to map to the database port."
          DATABASE_PORT=$(gum input --value $DEFAULT_PORT --placeholder "Enter the port to expose the database on (container port):")
          if [ "$DATABASE_PORT" = "user aborted" ]; then
            echo "User aborted on input, exiting..."
            exit 1
          fi
          echo "Choose a host port to map to the database port."
          HOST_PORT=$(gum input --value $DEFAULT_PORT --placeholder "Enter the host port to map to the database port:")
          if [ "$HOST_PORT" = "user aborted" ]; then
            echo "User aborted on input, exiting..."
            exit 1
          fi
      else
          DATABASE_PORT=""
          HOST_PORT=""
      fi
else
    DATABASE_TYPE=""
fi


# Ask for Redis installation
if gum confirm "Do you want to run Redis?"; then
    REDIS_VERSION=latest
    echo "Redis parameters"
    if gum confirm "Do you want to expose any ports for Redis?"; then
        REDIS_PORT=6379
        echo "Choose a host port to map to the Redis."
        REDIS_HOST_PORT=$(gum input --value "6379" --placeholder "Enter the host port to map to the Redis port:")
          if [ "$REDIS_HOST_PORT" = "user aborted" ]; then
            echo "User aborted on input, exiting..."
            exit 1
          fi
    else
        REDIS_PORT=""
        REDIS_HOST_PORT=""
    fi
else
    REDIS_VERSION=""
    REDIS_PORT=""
    REDIS_HOST_PORT=""
fi

# Summarize information
#echo "Configuration Summary:"
#echo "PHP Version: $PHP_VERSION"
#echo "Node.js Version: $NODE_VERSION"
#echo "Database Type: $DATABASE_TYPE"
#echo "Database Container Port: $DATABASE_PORT"
#echo "Database Host Port: $HOST_PORT"
#echo "Redis Version: $REDIS_VERSION"
#echo "Redis Container Port: $REDIS_PORT"
#echo "Redis Host Port: $REDIS_HOST_PORT"

if [ -f docker-compose.yml ]; then
    if gum confirm "docker-compose.yml already exists. Do you want to overwrite it?"; then
        rm docker-compose.yml
    else
        echo "Exiting..."
        exit 0
    fi
fi

echo "services:" >> docker-compose.yml
# Add PHP service
if [ ! -z "$PHP_VERSION" ]; then
  cat <<EOF >> docker-compose.yml
  workspace:
    image: phillarmonic/frankenphp-workspace:$PHP_VERSION-$NODE_VERSION
    environment:
      PROJECT_ROOT: \${PROJECT_ROOT:-/app}
      DOCUMENT_ROOT: \${DOCUMENT_ROOT:-/app/public}
      XDEBUG_ENABLE: \${XDEBUG_ENABLE:-1}
      XDEBUG_MODE: \${XDEBUG_MODE:-develop,debug,profile,coverage}
      XDEBUG_START_WITH_REQUEST: \${XDEBUG_START_WITH_REQUEST:-yes}
      PHP_IDE_CONFIG: \${PHP_IDE_CONFIG:-"serverName=frankenphp"}
      PHP_INI_ERROR_REPORTING: \${PHP_INI_ERROR_REPORTING:-E_ALL & ~E_DEPRECATED & ~E_USER_DEPRECATED}
    volumes:
      - \${HOST_SOURCE_FOLDER:-/app}:\${PROJECT_ROOT:-/app}
    ports:
      - \${HTTP_PORT:-80}:80
      - \${HTTPS_PORT:-443}:443
    extra_hosts:
      - "host.docker.internal:host-gateway"
    networks:
      - default
EOF

fi

# Add database service
if [ ! -z "$DATABASE_TYPE" ]; then
  if [ "$DATABASE_TYPE" = "MySQL" ]; then
cat <<EOF >> docker-compose.yml
  db:
    image: mysql:\${DATABASE_VERSION:-latest}
    environment:
      MYSQL_ROOT_PASSWORD: \${MYSQL_ROOT_PASSWORD:-root}
      MYSQL_DATABASE: \${MYSQL_DATABASE:-homestead}
      MYSQL_USER: \${MYSQL_USER:-admin}
      MYSQL_PASSWORD: \${MYSQL_PASSWORD:-admin}
    ports:
      - "\${PORT_MYSQL:-3307}:3306"
    volumes:
      - db_data:/var/lib/mysql
EOF
  elif [ "$DATABASE_TYPE" = "MariaDB" ]; then
  cat <<EOF >> docker-compose.yml
    db:
      image: mariadb:\${DATABASE_VERSION:-latest}
      environment:
        MYSQL_ROOT_PASSWORD: \${MYSQL_ROOT_PASSWORD:-root}
        MYSQL_DATABASE: \${MYSQL_DATABASE:-homestead}
        MYSQL_USER: \${MYSQL_USER:-admin}
        MYSQL_PASSWORD: \${MYSQL_PASSWORD:-admin}
      ports:
        - "\${PORT_MYSQL:-3307}:3306"
      volumes:
        - db_data:/var/lib/mysql
EOF
  elif [ "$DATABASE_TYPE" = "Postgres" ]; then
  cat <<EOF >> docker-compose.yml
    db:
      image: postgres:\${DATABASE_VERSION:-latest}
      environment:
        POSTGRES_USER: \${POSTGRES_USER:-admin}
        POSTGRES_PASSWORD: \${POSTGRES_PASSWORD:-admin}
        POSTGRES_DB: \${POSTGRES_DB:-homestead}
      ports:
        - "\${PORT_POSTGRES:-5433}:5432"
      volumes:
        - db_data:/var/lib/postgresql/data
EOF
  fi
fi

# Add Redis service
# Add Redis service
if [ ! -z "$REDIS_VERSION" ]; then
  cat <<EOF >> docker-compose.yml
  redis:
    image: valkey/valkey:7.2-alpine
    tty: true
    volumes:
      - redis_data:/data:rw
    networks:
      - default
    ports:
      - "\${REDIS_HOST_PORT:-6379}:\${REDIS_PORT:-6379}"
EOF
fi

# Add volumes block
cat <<EOF >> docker-compose.yml

volumes:
  redis_data:
    driver: local
  db_data:
    driver: local
  caddy_data:
    driver: local
  caddy_config:
    driver: local
EOF

cat <<EOF >> .env
APP_ENV=dev
APP_DEBUG=true

SERVER_NAME=localhost
PROJECT_ROOT=/app
DOCUMENT_ROOT=/app/public

PORT_HTTP=80
PORT_HTTPS=443
PORT_HTTPS3=443

FIX_FILE_PERMISSIONS_ON_START=true

PHP_IDE_CONFIG="serverName=frankenphp"

XDEBUG_ENABLE=1
XDEBUG_START_WITH_REQUEST=yes
XDEBUG_MODE=debug,develop

# Set your db version here
DATABASE_VERSION=8.0

# If using mysql and you need to change the data, do it here
MYSQL_ROOT_PASSWORD=root
MYSQL_DATABASE=homestead
MYSQL_USER=admin
MYSQL_PASSWORD=admin
# This is your externally accessible port
PORT_MYSQL=3307

# If using postgres and you need to change the data, do it here
POSTGRES_USER=homestead
POSTGRES_PASSWORD=secret
POSTGRES_DB=homestead
# This is your externally accessible port
PORT_POSTGRES=5433

# Exposed port
REDIS_HOST_PORT=6380
# Container port
REDIS_PORT=6379
EOF

echo "docker-compose.yml and .env files created successfully."
echo "You can now run 'docker-compose up' to start your FrankenPHP workspace."