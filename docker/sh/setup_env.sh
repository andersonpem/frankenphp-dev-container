#!/usr/bin/env bash
CURRENT_USER=$(whoami)
set -euo pipefail
source /opt/includes

cd $HOME || exit

# These functions are defined in includes.sh
setup_locale
setup_path
install_composer_packages
install_ble_sh
install_oh_my_zsh


cat <<EOF > "$HOME/.bash_workspace"
source /opt/includes
clear

if [ "$(whoami)" = "docker" ]; then
  figlet "FrankenPHP Workspace"
  cPrint status "Welcome, developer!"
  if [ -d "\$HOME/.ssh" ]; then
    cPrint status "Adding the SSH agent to your container..."
    eval "$(ssh-agent -s)"
      # Find all files in .ssh that start with id_ and do not end with .pub
      for key in \$HOME/.ssh/id_*; do
          if [[ -f "\$key" && ! "\$key" =~ \.pub$ ]]; then
              cPrint info "Adding the SSH key \$key, you might be asked for your SSH key password..."
              ssh-add "\$key"
          fi
      done
    fi
    cPrint status "Dev workspace version: \u001b[93m \$WORKSPACE_VERSION \u001b[0m"
    cPrint status "If you are out of date, run \u001b[92m docker compose pull \u001b[0m to get the latest version."
fi
EOF


# Aliases for both Bash and ZSH
echo "source \$HOME/.aliases" >> ~/.bashrc && echo "source \$HOME/.aliases" >> ~/.zshrc

echo "source \$HOME/.bash_workspace" >> ~/.bashrc && echo "source \$HOME/.bash_workspace" >> ~/.zshrc

# SSH and the Docker user
# Setup SSH directory and known_hosts file
mkdir -p "$HOME/.ssh/" && touch "$HOME/.ssh/known_hosts"
# Makes sure the permissions for SSH are secure
chmod 700 "$HOME/.ssh" && chmod 644 "$HOME/.ssh/known_hosts"
# To prevent SSH to break the process of checking out the repository
# We preemptively add the GitHub.com public key to the container.
ssh-keyscan github.com >> "$HOME/.ssh/known_hosts"
# Validate the keys for security purposes
ssh-keygen -lf "$HOME/.ssh/known_hosts"