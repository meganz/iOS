#!/bin/bash

required_version="3.27.1"

install_cmake() {
    mkdir -p ~/Downloads/CMake
    curl --silent --location --retry 3 "https://github.com/Kitware/CMake/releases/download/v${required_version}/cmake-${required_version}-macos-universal.dmg" --output ~/Downloads/CMake/cmake-${required_version}-macos-universal.dmg
    yes | PAGER=cat hdiutil attach -quiet -mountpoint /Volumes/cmake-${required_version}-macos-universal ~/Downloads/CMake/cmake-${required_version}-macos-universal.dmg
    sudo cp -R /Volumes/cmake-${required_version}-macos-universal/CMake.app /Applications/
    hdiutil detach /Volumes/cmake-${required_version}-macos-universal
    sudo "/Applications/CMake.app/Contents/bin/cmake-gui" --install=/usr/local/bin
    rm -rf ~/Downloads/CMake
}

if command -v cmake &> /dev/null; then
    installed_version=$(cmake --version | awk 'NR==1{print $3}')

    if [ "$installed_version" == "$required_version" ]; then
        echo "CMake version $required_version is already installed."
    else
        echo "CMake version $required_version not found. Updating CMake..."
        sudo rm /usr/local/bin/cmake
        sudo rm /usr/local/bin/ccmake
        sudo rm /usr/local/bin/cmake-gui
        sudo rm /usr/local/bin/cpack
        sudo rm /usr/local/bin/ctest
        sudo rm -rf /Applications/CMake.app
        install_cmake
    fi
else
    echo "CMake is not installed. Installing CMake version $required_version..."
    install_cmake
fi
