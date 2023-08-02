#!/bin/bash

source install-megacmd.sh
source install-cmake.sh
source install-libyaml.sh
source install-ruby.sh

gem update --system
source install-bundler.sh
bundle install
bundle exec fastlane setup

message='Before running ./configure again, kindly close this terminal and open a new one to ensure that it runs smoothly the next time.'
green='\033[0;32m'
no_color='\033[0m'
echo -e "\n${green}${message}${no_color}"