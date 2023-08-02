#!/bin/bash

# Constants
desired_version="0.2.5"
url="http://pyyaml.org/download/libyaml/yaml-$desired_version.zip"
zip_file="yaml-$desired_version.zip"
dir_name="yaml-$desired_version"
pc_file="/usr/local/lib/pkgconfig/yaml-0.1.pc" 

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

# Check if the file exists
if [ -f "$pc_file" ]; then
    # Read the version from the file
    version=$(awk '/^Version:/ { print $2 }' "$pc_file")
    
    # Check if the version matches the desired version
    if [ "$version" = "$desired_version" ]; then
        echo "libyaml version is $desired_version."
    else
      # Download the YAML library
      echo "Downloading YAML library..."
      curl -LOJ "$url" || die "Failed to download YAML library."

      # Unzip the downloaded file
      echo "Unzipping..."
      unzip "$zip_file" || die "Failed to unzip $zip_file."

      # Enter the YAML directory
      cd "$dir_name" || die "Failed to enter $dir_name directory."

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
      rm "$zip_file" || die "Failed to remove $zip_file."
      rm -rf "$dir_name" || die "Failed to remove $dir_name."

      echo "YAML library installation completed successfully!"
    fi
else
    echo "yaml-0.1.pc file not found."
fi
