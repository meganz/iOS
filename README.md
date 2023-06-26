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

#### Clone the project

If you are the general public user, please open .gitmodules file and:

1. Change url for karere submodule, [use this one](https://github.com/meganz/MEGAchat.git)
2. Change url for SDK submodule, [use this one](https://github.com/meganz/SDK.git)

#### Update submodule

```
git submodule update --init --recursive
```

#### Download 3rdparty packages
1. Download the prebuilt third party dependencies from this link: https://mega.nz/file/MctwABZa#wWoEQLwYV4Vr0i-HxVySkBqVtD8oT5FCnnJXbVqxx2M
2. Uncompress that file and move the folders `webrtc` , `include` and `lib` into `Modules/DataSource/MEGASDK/Sources/MEGASDK/bindings/ios/3rdparty`.

#### Open and Run the project
5. Open `iMEGA.xcworkspace`.
6. Make sure the `MEGA` target is selected.
7. Build and run (⌘R).

## Build 3rdparty packages manually
If you want to build the third party dependencies by yourself: 
1. Open a terminal in the directory `Modules/DataSource/MEGASDK/Sources/MEGASDK/bindings/ios/3rdparty`. 
2. Run sh build-all.sh --enable-chat (Wait until the process ends, it will take some time, ~30 minutes). 

- To build all third party dependencies, you need to have installed: `autoconf`, `automake`, `cmake` and `libtool`. 
- To build webrtc visit: https://webrtc.github.io/webrtc-org/native-code/ios/
