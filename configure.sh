#!/bin/bash

run_script() {
    local script="$1"
    cd scripts
    source "$script"
    cd ..
}

run_script install-megacmd.sh
run_script install-cmake.sh
run_script install-libyaml.sh
run_script install-ruby.sh

gem update --system
run_script install-bundler.sh
bundle install
bundle exec fastlane setup

message='Before running ./configure again, kindly close this terminal and open a new one to ensure that it runs smoothly the next time.'
green='\033[0;32m'
no_color='\033[0m'
echo -e "\n${green}${message}${no_color}"