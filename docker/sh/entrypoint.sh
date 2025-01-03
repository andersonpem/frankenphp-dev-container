#!/bin/bash
set -e
source /opt/includes

cPrint info "Container version: $cl_success${APP_VERSION:-1.0.0}$cl_reset"
printHr
cPrint status "Running pre-flight checkup, please wait a moment..."
printHr

STATUS_MESSAGES=""

add_status_message() {
    STATUS_MESSAGES="${STATUS_MESSAGES}$1\n"
}

# Let's find the user to use for commands.
# If $DOCKER_USER, let's use this. Otherwise, let's find it.
echo "Checking Docker user permissions..."
if [[ "$DOCKER_USER" == "" ]]; then
    # On MacOSX, the owner of the current directory can be completely random (it can be root or docker depending on what happened previously)
    # But MacOSX does not enforce any rights (the docker user can edit any file owned by root).
    # On Windows, the owner of the current directory is root if mounted
    # But Windows does not enforce any rights either. Windows is extremely permissive.

    # Let's make a test to see if we have those funky rights.
    set +e
    mkdir -p testing_file_system_rights.foo
    chmod 700 testing_file_system_rights.foo
    sudo touch testing_file_system_rights.foo/somefile > /dev/null 2>&1

    HAS_CONSISTENT_RIGHTS=$?

    if [[ "$HAS_CONSISTENT_RIGHTS" != "0" ]]; then
        # If not specified, the DOCKER_USER is the owner of the current working directory (heuristic!)
        DOCKER_USER=`ls -dl $(pwd) | cut -d " " -f 3`
    else
        # we are on a Mac or Windows,
        # Most of the cases, we don't care about the rights (they are not respected)
        FILE_OWNER=`ls -dl testing_file_system_rights.foo/somefile | cut -d " " -f 3`
        if [[ "$FILE_OWNER" == "root" ]]; then
            # if the created user belongs to root, we are likely on a Windows host.
            # all files will belong to root, but it does not matter as everybody can write/delete those (0777 access rights)
            DOCKER_USER=docker
        else
            # In case of a NFS mount (common on MacOS), the created files will belong to the NFS user.
            # Apache should therefore have the ID of this user.
            DOCKER_USER=$FILE_OWNER
        fi
    fi

    rm -rf testing_file_system_rights.foo
    set -e

    unset HAS_CONSISTENT_RIGHTS
fi

# DOCKER_USER is a username if the user exists in the container, otherwise, it is a user ID (from a user on the host).
# If DOCKER_USER is an ID, let's
if [[ "$DOCKER_USER" =~ ^[0-9]+$ ]] ; then
#    echo "Docker user is: $DOCKER_USER"
    # MAIN_DIR_USER is a user ID.
    # Let's change the ID of the docker user to match this free id!
#    echo "Switching docker id to $DOCKER_USER"
    usermod -u $DOCKER_USER -G sudo docker;
    #echo Switching done
    DOCKER_USER=docker
fi

DOCKER_USER_ID=$(id -ur "$DOCKER_USER")

# Fix access rights to stdout and stderr
echo "Setting up std* permissions..."
set +e
sudo chown "$DOCKER_USER" /proc/self/fd/{1,2}
set -e
# |-----------------------------------------------------------------------------
# | File permissions
# |-----------------------------------------------------------------------------
# | File permissions are very important to run any application. However,
# | We have to work with the principle of least privilege. Always.
# | Before we start the container let's make sure everything is as it's
# | Supposed to be.
# |
# | Some key aspects of web applications' permissions:
# | * 777 is the devil. Too permissive. Do not use it. It's tempting, but don't.
# | * Folders should have the permission 755
# | * Files should have the permission 644.
# | * Special folders (like var) should have the permission 770 or 775.
# |

cPrint status "Checking proper file permissions..."
cPrint info "Setting file ownership, please be patient... PROJECT_ROOT: $PROJECT_ROOT"
sudo chown -R $DOCKER_USER:$DOCKER_USER "$PROJECT_ROOT"

# Check if the project root is empty
if [ -z "$(ls -A $PROJECT_ROOT)" ]; then
  cPrint status "Project root is empty, skipping file permission changes."
else
  if [ -n "$FIX_FILE_PERMISSIONS_ON_START" ] && [ "$FIX_FILE_PERMISSIONS_ON_START" = "1" ]; then
    # This part is cool, change the permissions only if they're not set already.
    cPrint status "Setting file permissions, please be patient..."
    sudo webpermissions $PROJECT_ROOT
  fi

  # Let's make sure the var folder is writable by the web server.
  cPrint status "Setting var folder permissions..."
  if [ -d "$PROJECT_ROOT/var" ]; then
    sudo chown -R docker "$PROJECT_ROOT/var"
    sudo chmod -R 775 "$PROJECT_ROOT/var"
  else
    sudo mkdir -m 775 "$PROJECT_ROOT/var"
    sudo chown docker "$PROJECT_ROOT/var"
  fi
fi

# Bin utilities should be executable
[ -d "$PROJECT_ROOT/bin" ] && sudo chmod +x "$PROJECT_ROOT/bin"/*

# |-----------------------------------------------------------------------------
# | Extra extensions
# |-----------------------------------------------------------------------------
# | Here, we enable OpCache and XDebug only if requested. Otherwise, run without.
# | In the case of Opcache, the default is to have it. Otherwise, disable it.
# | This is set in compose or compose override.
# |

if [ -n "$XDEBUG_ENABLE" ] && [ "$XDEBUG_ENABLE" = "1" ]; then
  cPrint status "Env asks to enable XDebug, proceeding to enable..."
  sudo --preserve-env bash -c 'cat <<EOF > $PHP_INI_DIR/conf.d/docker-php-ext-xdebug.ini
zend_extension=xdebug.so
[xdebug]
xdebug.mode = ${XDEBUG_MODE:-debug,develop}
xdebug.client_host = ${XDEBUG_CLIENT_HOST:-host.docker.internal}
xdebug.client_port = ${XDEBUG_CLIENT_PORT:-9003}
xdebug.start_with_request = ${XDEBUG_START_WITH_REQUEST:-trigger}
xdebug.idekey = ${XDEBUG_IDEKEY:-winoui}
xdebug.start_upon_error=${XDEBUG_START_UPON_ERROR:-no}
EOF'
  cPrint success "XDebug config written to $PHP_INI_DIR/conf.d/docker-php-ext-xdebug.ini"
  cPrint info "XDebug IDE key is: $cl_info${XDEBUG_IDEKEY:-winoui}$cl_reset"
  add_status_message "XDebug is enabled! \nPHP_IDE_CONFIG: ${cl_info}$PHP_IDE_CONFIG${cl_reset} \n XDEBUG_IDEKEY: ${cl_info}$XDEBUG_IDEKEY \n ${cl_info}Make sure to set up your PHPStorm/VS code Accordingly.${cl_reset} "
  if [ -f "$PHP_INI_DIR/conf.d/opcache.ini" ]; then
    add_status_message "!!!! XDebug is ENABLED. This will $cl_error DISABLE OPCACHE even if it's set to be active! $cl_reset !!!!"
    sudo rm -f "$PHP_INI_DIR/conf.d/opcache.ini"
  fi

else
  sudo --preserve-env rm -f "$PHP_INI_DIR/conf.d/docker-php-ext-xdebug.ini"
  cPrint status "$cl_info XDebug is disabled$cl_reset. To enable it, set the environment variable XDEBUG_ENABLE to 1"
  add_status_message "XDebug is disabled. To enable it, set XDEBUG_ENABLE to 1"
fi

cPrint info "Cleaning any cache remains..."
sudo rm -Rf $PROJECT_ROOT/var/cache/*


if [ -n "$STATUS_MESSAGES" ]; then
    cPrint status "The startup script reported the following important information:"
    echo -e "$STATUS_MESSAGES"
else
    echo "No relevant information was logged. Proceeding."
fi

if [ -n "$GIT_USER_NAME" ] && [ "$GIT_USER_NAME" != "" ] && [ -n "$GIT_USER_EMAIL" ] && [ "$GIT_USER_EMAIL" != "" ]; then
    cPrint status "Setting up git username and email..."
    git config --global user.name "$GIT_USER_NAME"
    git config --global user.email "$GIT_USER_EMAIL"
    cPrint success "Git username and email set."
fi

cPrint info "Making sure the FrankenPHP folders permissions are okay..."
chown -R docker:docker /config/caddy
chown -R docker:docker /data/caddy

FRANKENPHP_VERSION=$(gosu docker frankenphp version)
cPrint info "FrankenPHP version on this container: $FRANKENPHP_VERSION"

cPrint status "FrankenPHP will now start..."

# first arg is `-f` or `--some-option`
if [ "${1#-}" != "$1" ]; then
       gosu docker set -- frankenphp run "$@"
fi

gosu docker exec "$@"

