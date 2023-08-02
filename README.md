MEGA for iOS
===============

[![Download on the App Store](https://linkmaker.itunes.apple.com/en-us/badge-lrg.svg?releaseDate=2013-11-26&kind=iossoftware&bubble=ios_apps)](https://apps.apple.com/app/mega/id706857885?mt=8)

A fully-featured client to access your Secure Cloud Storage and Communication provided by [MEGA](https://mega.nz).

## Testing MEGA with TestFlight

If you want to be the first one to receive the updates, join the MEGA beta following this link: [MEGA TestFlight](https://testflight.apple.com/join/4x1P5Tnx)

## Build & Run the application

This document will guide you to build the application on a Mac machine with Xcode.

#### Prerequisites
In order to build MEGA for iOS locally, it is necessary to install [Xcode](https://itunes.apple.com/app/xcode/id497799835?mt=12) on the local machine:

#### Configure the project - for public users
1. Open the .gitmodules file and update the URL for the "karere" submodule to https://github.com/meganz/MEGAchat.git, and the URL for the "SDK" submodule to https://github.com/meganz/SDK.git.
2. In the SPM dependencies, replace the current package with the URL https://code.developers.mega.co.nz/mobile/kmm/mobile-analytics-ios and instead use https://github.com/meganz/mobile-analytics-ios.git.

#### Run the project
1. Use the terminal to execute `./configure.sh`
2. Open `iMEGA.xcworkspace`.
3. Make sure the `MEGA` target is selected.
4. Build and run (⌘R).

## Build 3rdparty packages manually (Optional)
If you want to build the third party dependencies by yourself: 
1. Open a terminal in the directory `Modules/DataSource/MEGASDK/Sources/MEGASDK/bindings/ios/3rdparty`. 
2. Run sh build-all.sh --enable-chat (Wait until the process ends, it will take some time, ~30 minutes). 

- To build all third party dependencies, you need to have installed: `autoconf`, `automake`, `cmake` and `libtool`. 
- To build webrtc visit: https://webrtc.github.io/webrtc-org/native-code/ios/
