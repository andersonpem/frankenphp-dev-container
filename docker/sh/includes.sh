# Did you know these color nomenclatures are from Delphi (Object Pascal) ? :)
cl_error="\u001b[91m"
cl_status="\u001b[94m"
cl_info="\u001b[93m"
cl_reset="\u001b[0m"
cl_gray="\u001b[90m"
cl_success="\u001b[92m"

# Information is power.
cPrint() {
    local now
    local color="$1"
    local message="$2"
          now=$(date "+%d/%m/%Y %H:%M:%S")
    case "$color" in
        status)
            echo -e "${cl_status}[$now - STATUS]: ${cl_reset}${message}"
            ;;
        info)
            echo -e "${cl_info}[$now - INFO]: ${cl_reset}${message}"
            ;;
        error)
            echo -e "${cl_error}[$now - ERROR]: ${cl_reset}${message}"
            ;;
        success)
          echo -e "${cl_success}[$now - SUCCESS]: ${message}${cl_reset}"
          ;;
        *)
            echo -e "$cl_status [$now]:$cl_reset $message"
            ;;
    esac
}

# A Horizontal line.
printHr(){
  echo -e "$cl_gray=================================================================================================================================================$cl_reset"
}

# Function to set environment variables from a file
set_env_vars() {
    if [ -f "$1" ]; then
        echo "Setting environment variables from $1"
        set -a
        source "$1"
        set +a
    else
        echo "File $1 not found."
    fi
}


# Build functions
# These functions are to be used only during Build stage
setup_locale() {
  grep -qxF 'export LC_ALL=en_US.UTF-8' ~/.bashrc || echo "export LC_ALL=en_US.UTF-8" >> ~/.bashrc
  grep -qxF 'export LANG=en_US.UTF-8' ~/.bashrc || echo "export LANG=en_US.UTF-8" >> ~/.bashrc
}

# Function to add Composer's vendor/bin to PATH
setup_path() {
  local CURRENT_USER
  CURRENT_USER=$(whoami)

  local BASHRC="$HOME/.bashrc"
  local ZSHRC="$HOME/.zshrc"

  # Determine Composer's vendor/bin path based on the user
  if [ "$CURRENT_USER" = "root" ]; then
    COMPOSER_BIN="/root/.config/composer/vendor/bin"
    local BASHRC_ROOT="/root/.bashrc"
    local ZSHRC_ROOT="/root/.zshrc"
  else
    COMPOSER_BIN="/home/$CURRENT_USER/.config/composer/vendor/bin"
  fi

  # Add to PATH in .bashrc
  if ! grep -qxF "export PATH=${COMPOSER_BIN}:\$PATH" "$BASHRC"; then
    echo "export PATH=${COMPOSER_BIN}:\$PATH" >> "$BASHRC"
  fi

  # Add to PATH in .zshrc
  if [ "$CURRENT_USER" = "root" ]; then
    if ! grep -qxF "export PATH=${COMPOSER_BIN}:\$PATH" "$ZSHRC_ROOT"; then
      echo "export PATH=${COMPOSER_BIN}:\$PATH" >> "$ZSHRC_ROOT"
    fi
  else
    if ! grep -qxF "export PATH=${COMPOSER_BIN}:\$PATH" "$ZSHRC"; then
      echo "export PATH=${COMPOSER_BIN}:\$PATH" >> "$ZSHRC"
    fi
  fi

  # Create the Composer vendor/bin directory if it doesn't exist
  mkdir -p "${COMPOSER_BIN}"
}

# Function to install Composer global packages
install_composer_packages() {
  # Install Symfony Console Autocomplete
  if ! composer global show bamarni/symfony-console-autocomplete > /dev/null 2>&1; then
    composer global require bamarni/symfony-console-autocomplete || { echo "Symfony autocomplete install failed"; exit 1; }
  fi

  # Install Laravel Installer
  if ! composer global show laravel/installer > /dev/null 2>&1; then
    composer global require laravel/installer || { echo "Laravel installer install failed"; exit 1; }
  fi
}

install_ble_sh() {
  if ! command -v ble.sh > /dev/null 2>&1; then
    wget -O - https://gitlab.com/snippets/2306021/raw | bash > /dev/null
  fi

  # Create .blerc configuration if it doesn't exist
  if [ ! -f "$HOME/.blerc" ]; then
    cat <<EOF > "$HOME/.blerc"
# Ble.sh configuration file
bleopt char_width_mode=auto
bleopt input_encoding=UTF-8
bleopt edit_abell=1
EOF
  fi
  echo 'eval "$(symfony-autocomplete --shell=bash)"' >> ~/.bashrc
}

install_oh_my_zsh(){
  if ! [ -d "$HOME/.oh-my-zsh" ]; then
    # ZSH goodies for ZSH users
    wget -O - https://gitlab.com/snippets/3622083/raw | bash > /dev/null
    echo 'eval "$(symfony-autocomplete --shell=zsh)"' >> ~/.zshrc
  fi
}