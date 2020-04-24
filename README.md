MEGA for iOS
===============

[![Download on the App Store](https://linkmaker.itunes.apple.com/en-us/badge-lrg.svg?releaseDate=2013-11-26&kind=iossoftware&bubble=ios_apps)](https://apps.apple.com/app/mega/id706857885?mt=8)

A fully-featured client to access your Secure Cloud Storage and Communication provided by [MEGA](https://mega.nz).

### Testing MEGA with TestFlight

If you want to be the first one to receive the updates, join the MEGA beta following this link: [MEGA TestFlight](https://testflight.apple.com/join/4x1P5Tnx)

---

This document will guide you to build the application on a Mac machine with Xcode.

### Build & Run the application

Get the source code

```
git clone https://github.com/meganz/ios.git
cd ios
git submodule update --init --recursive
```

##### Preparation:
1. Install [Xcode](https://itunes.apple.com/app/xcode/id497799835?mt=12) in your system.

2. Clone this repo.

3. Download the prebuilt third party dependencies from this link: https://mega.nz/#!ZZlSzKCQ!pCnK7UKbV3bjZvnRxkHkudcHGQcoarEE8bNlN2WDGfM.

4. Uncompress that file and move the folders `webrtc` , `include` and `lib` into `iMEGA/Vendor/sdk/bindings/ios/3rdparty`.

5. Open `iMEGA.xcworkspace`.

6. Make sure the `MEGA` target is selected.

7. Build and run (⌘R).

8. Enjoy!

If you want to build the third party dependencies by yourself: 
- Open a terminal in the directory `iMEGA/sdk/bindings/ios/3rdparty`. 
- Run sh build-all.sh --enable-chat (Wait until the process ends, it will take some time, ~30 minutes). 

To build all third party dependencies, you need to have installed: `autoconf`, `automake`, `cmake` and `libtool`. 

To build webrtc visit: https://webrtc.org/native-code/ios/
