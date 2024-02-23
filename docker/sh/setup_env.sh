#!/bin/bash
cd $HOME || exit
echo "export LC_ALL=en_US.UTF-8" >> ~/.bashrc
echo "export LANG=en_US.UTF-8" >> ~/.bashrc
echo "export PATH=~/.config/composer/vendor/bin:$PATH" >> $HOME/.bashrc
echo "export PATH=~/.config/composer/vendor/bin" >> $HOME/.zshrc

current_user=$(whoami)

composer global require bamarni/symfony-console-autocomplete > /dev/null

# Ble.sh - Let's help our developers command faster
wget -O - https://gitlab.com/snippets/2306021/raw | bash > /dev/null

# Symfony Console autocomplete for Bash
composer global require bamarni/symfony-console-autocomplete > /dev/null \
  && echo 'eval "$(symfony-autocomplete --shell=bash)"' >> ~/.bashrc

# ZSH goodies for ZSH users
wget -O - https://gitlab.com/snippets/3622083/raw | bash > /dev/null
echo 'eval "$(symfony-autocomplete --shell=zsh)"' >> ~/.zshrc


cat <<EOF > "$HOME/.bash_workspace"
source /opt/includes
clear
CONTAINER_VERSION=${CONTAINER_VERSION:-"unknown"}

if [ "$(whoami)" = "docker" ]; then
  figlet "FrankenPHP Workshop"
  cPrint status "Welcome, developer!"
  if [ -d "$HOME/.ssh" ]; then
    cPrint status "Adding the SSH agent to your container..."
    eval "$(ssh-agent -s)"
      # Find all files in .ssh that start with id_ and do not end with .pub
      for key in $HOME/.ssh/id_*; do
          if [[ -f "$key" && ! "$key" =~ \.pub$ ]]; then
              cPrint info "Adding the SSH key $key, you might be asked for your SSH key password..."
              ssh-add "$key"
          fi
      done
    fi
#    cPrint status "Dev workspace version: \u001b[93m $CONTAINER_VERSION \u001b[0m"
#    cPrint status "If you are out of date, run \u001b[92m docker compose pull \u001b[0m to get the latest version."
fi
EOF

cat <<EOF > "$HOME/.blerc"
# Ble.sh configuration file
bleopt char_width_mode=auto
bleopt input_encoding=UTF-8
bleopt edit_abell=1
EOF

# Aliases for both Bash and ZSH
echo 'source $HOME/.aliases' >> ~/.bashrc && echo 'source $HOME/.aliases' >> ~/.zshrc

echo 'source $HOME/.bash_workspace' >> ~/.bashrc && echo 'source $HOME/.bash_workspace' >> ~/.zshrc

# SSH and the Docker user
# Setup SSH directory and known_hosts file
mkdir -p $HOME/.ssh/ && touch $HOME/.ssh/known_hosts
# Makes sure the permissions for SSH are secure
chmod 700 $HOME/.ssh && chmod 644 $HOME/.ssh/known_hosts
# To prevent SSH to break the process of checking out the repository
# We peeemptively add the GitHub.com public key to the container.
ssh-keyscan github.com >> $HOME/.ssh/known_hosts
# Validate the keys for security purposes
ssh-keygen -lf $HOME/.ssh/known_hosts