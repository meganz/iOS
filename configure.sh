#!/bin/bash

source libyaml-Install.sh

# Function to add content to a new line in a file
# Usage: add_content_to_new_line "content" "file_path"
function add_content_to_new_line {
  local content_to_add="$1"
  local file_path="$2"

  if grep -qF "$content_to_add" "$file_path"; then
    echo "The content is already present in $file_path. No changes made."
  else
    # Add the content to the file on a new line
    echo -e "\n$content_to_add" >> "$file_path"
    echo "Content added to $file_path successfully."
  fi
}

# Check if rbenv is already installed
rbenv="$(command -v rbenv ~/.rbenv/bin/rbenv | head -1)"
if [ -n "$rbenv" ]; then
    echo "rbenv is already installed"
else 
    echo "Installing rbenv"
    curl -fsSL https://raw.githubusercontent.com/rbenv/rbenv-installer/main/bin/rbenv-installer | bash

    default_shell=$(dscl . -read "/Users/$(whoami)" UserShell | awk '{print $NF}')
    if [ "$default_shell" = "/bin/zsh" ]; then
      add_content_to_new_line 'eval "$(~/.rbenv/bin/rbenv init - zsh)"' ~/.zshrc
    else
      add_content_to_new_line 'eval "$(~/.rbenv/bin/rbenv init - bash)"' ~/.bash_profile
    fi

    eval "$(~/.rbenv/bin/rbenv init -)"
fi

desired_ruby_version=$(rbenv local)

# Install the desired Ruby version if not already installed
if rbenv versions | grep -q "$desired_ruby_version"; then
    echo "Ruby version $desired_ruby_version is already installed."
else
    echo "Installing Ruby $desired_ruby_version"
    if ! rbenv install "$desired_ruby_version"; then
        echo "Failed to install Ruby $desired_ruby_version. Exiting."
        exit 1
    fi
fi

# Update RubyGems and install Bundler
gem update --system
gem install bundler -v '=2.4.17'
bundle install
bundle exec fastlane setup
