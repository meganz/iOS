MEGA iOS Client
===============

A fully-featured client to access your Cloud Storage provided by MEGA.

This document will guide you to build the application on a Mac machine with Xcode.

### Setup development environment

* [Xcode](https://itunes.apple.com/app/xcode/id497799835?mt=12)

### Build & Run the application

* Get the source code

```
git clone https://github.com/meganz/ios.git
cd ios
git submodule update --init --recursive
```

##### Preparation:
1.- Install Xcode in your system

2.- Clone this repo

3.- Download the prebuilt third party dependencies from this link: https://mega.nz/#!AJsATRwK!CuOxengJPm_lw1VAJ6_IeBJIFvLUtdOqHNs1dCCCroA

4.- Uncompress that file and move the folders `webrtc` , `include` and `lib` into `iMEGA/Vendor/sdk/bindings/ios/3rdparty`

5.- Open `iMEGA.xcworkspace`

6.- Make sure the `MEGA` target is selected

7.- Build and run (⌘R)

8.- Enjoy!

If you want to build the third party dependencies by yourself: open a terminal in the directory `iMEGA/sdk/bindings/ios/3rdparty`. Run sh build-all.sh --enable-chat (Wait until the process ends, it will take some minutes ~30). To build all third party dependencies, you need to have installed: autoconf, automake, cmake and libtool. To build webrtc visit: https://webrtc.org/native-code/ios/
