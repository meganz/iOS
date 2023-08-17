#!/bin/bash

bundler_version=$(awk '/^BUNDLED WITH$/{getline; print $1}' ./../Gemfile.lock)

if ! gem list bundler -i -v $bundler_version >/dev/null 2>&1; then
    echo "Bundler $bundler_version is not installed. Installing now..."
    gem install bundler -v $bundler_version
else
    echo "Bundler $bundler_version is already installed."
fi