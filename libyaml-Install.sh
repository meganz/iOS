#!/bin/bash

# This script downloads, compiles, and installs YAML library version 0.2.5.

# Constants
URL="http://pyyaml.org/download/libyaml/yaml-0.2.5.zip"
ZIP_FILE="yaml-0.2.5.zip"
DIR_NAME="yaml-0.2.5"

# Function to display error messages and exit with a non-zero status
function die {
  echo "Error: $1" >&2
  exit 1
}

# Check if 'curl' command is available
if ! command -v curl > /dev/null; then
  die "curl command not found. Please install curl before running this script."
fi

# Check if 'unzip' command is available
if ! command -v unzip > /dev/null; then
  die "unzip command not found. Please install unzip before running this script."
fi

# Check if 'make' command is available
if ! command -v make > /dev/null; then
  die "make command not found. Please install make before running this script."
fi

# Download the YAML library
echo "Downloading YAML library..."
curl -LOJ "$URL" || die "Failed to download YAML library."

# Unzip the downloaded file
echo "Unzipping..."
unzip "$ZIP_FILE" || die "Failed to unzip $ZIP_FILE."

# Enter the YAML directory
cd "$DIR_NAME" || die "Failed to enter $DIR_NAME directory."

# Configure, compile, and install YAML library
echo "Configuring..."
./configure || die "Failed to configure."

echo "Compiling..."
make || die "Failed to compile."

echo "Installing..."
echo "Please enter the login password to run make install as sudo"
sudo make install || die "Failed to install."

# Return to the original directory
cd ..

# Clean up - remove the downloaded zip file and extracted directory
echo "Cleaning up..."
rm "$ZIP_FILE" || die "Failed to remove $ZIP_FILE."
rm -rf "$DIR_NAME" || die "Failed to remove $DIR_NAME."

echo "YAML library installation completed successfully!"