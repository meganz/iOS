#!/bin/bash

rbenv="$(command -v rbenv ~/.rbenv/bin/rbenv | head -1)"
if [ -n "$rbenv" ]; then
    echo "rbenv is already installed"
else 
    echo "Installing rbenv"
    curl -fsSL https://raw.githubusercontent.com/rbenv/rbenv-installer/main/bin/rbenv-installer | bash
    default_shell=$(dscl . -read "/Users/$(whoami)" UserShell | awk '{print $NF}')
    if [ "$default_shell" = "/bin/zsh" ]; then
      echo 'eval "$(~/.rbenv/bin/rbenv init - zsh)"' >> ~/.zshrc
    else
      echo 'eval "$(~/.rbenv/bin/rbenv init - bash)"' >> ~/.bash_profile
    fi
    eval "$(~/.rbenv/bin/rbenv init -)"
fi

ruby_version=$(ruby --version)
if [[ "$ruby_version" == *"ruby 3.2.2"* ]]; then
  echo "Ruby version 3.2.2 is already installed."
else
    echo "installing 3.2.2"
    rbenv install 3.2.2
    rbenv global 3.2.2
fi

gem update --system
gem install bundler -v '=2.4.17'
bundle install
bundle exec fastlane setup