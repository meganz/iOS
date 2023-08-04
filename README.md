MEGA for iOS
===============

[![Download on the App Store](https://linkmaker.itunes.apple.com/en-us/badge-lrg.svg?releaseDate=2013-11-26&kind=iossoftware&bubble=ios_apps)](https://apps.apple.com/app/mega/id706857885?mt=8)

A fully-featured client to access your Secure Cloud Storage and Communication provided by [MEGA](https://mega.nz).

## Testing MEGA with TestFlight

If you want to be the first one to receive the updates, join the MEGA beta following this link: [MEGA TestFlight](https://testflight.apple.com/join/4x1P5Tnx)

## Build & Run the application

This document will guide you to build the application on a Mac machine with Xcode.

#### Prerequisites
In order to build MEGA for iOS locally, it is necessary to install the following tools on the local machine:

- Install [Xcode](https://itunes.apple.com/app/xcode/id497799835?mt=12) in your system.
- Install [CMake](https://cmake.org/install/).
- Install [MEGA CMD](https://mega.io/cmd)

#### Clone the project

If you are the general public user, please open .gitmodules file and:

1. Change url for karere submodule, [use this one](https://github.com/meganz/MEGAchat.git)
2. Change url for SDK submodule, [use this one](https://github.com/meganz/SDK.git)

#### Install Ruby, update submodules, download third party libraries and configure pre-commit hook

```
./configure.sh
```

#### Build KMM mobile analytics library
If you are the general public user:
1. Set up KMM build tools
    1. Install [HomeBrew](https://brew.sh/) (if not yet)
    2. Install JDKL17 (if not yet)
        ```shell
        brew install openjdk@17
        ```
    3. Open [Android Command Line tools](https://developer.android.com/studio), scroll down to `Command line tools only`, download commandline tool for Mac and unzip to folder `cmdline-tools`
        ```shell
        mv cmdline-tools/ tools
        mkdir -p ~/android-sdk/cmdline-tools
        mv tools ~/android-sdk/cmdline-tools/
    
        cd ~/android-sdk/cmdline-tools/tools/bin

        ./sdkmanager "platforms;android-33" "platform-tools" "build-tools;33.0.0"
        #    - "y" to accept agreement and finish installation
        ```
    4. Set environment variable
        ```
        export ANDROID_HOME=<YOUR_HOME>/android-sdk
        export JAVA_HOME=<PATH-TO-JDK-INSTALLATION>
        ```
        For Apple Sillicon, your `PATH-TO-JDK-INSTALLATION` would be `/opt/homebrew/opt/openjdk@17`. For Intel chip, change the homebrew installation path accordingly. 
2. Download [Mobile Analytics](https://github.com/meganz/mobile-analytics) source code
    ```shell
    git clone --recursive https://github.com/meganz/mobile-analytics.git
    cd mobile-analytics
    git checkout main
    ```
3. Build Mobile Analytics    
    ```shell
    ./gradlew assemble
    ./gradlew createSwiftPackage
    ```
    Generated Swift Package can be found under `SwiftPackages/MEGAAnalyticsiOS`.

4. In next step, import the Swift Package in XCode

#### Open and Run the project
1. Open `iMEGA.xcworkspace`.
2. Make sure the `MEGA` target is selected.
3. Build and run (⌘R).

## Build 3rdparty packages manually (Optional)
If you want to build the third party dependencies by yourself: 
1. Open a terminal in the directory `Modules/DataSource/MEGASDK/Sources/MEGASDK/bindings/ios/3rdparty`. 
2. Run sh build-all.sh --enable-chat (Wait until the process ends, it will take some time, ~30 minutes). 

- To build all third party dependencies, you need to have installed: `autoconf`, `automake`, `cmake` and `libtool`. 
- To build webrtc visit: https://webrtc.github.io/webrtc-org/native-code/ios/

