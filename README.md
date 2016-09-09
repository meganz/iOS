MEGA iOS Client
===============

A fully-featured client to access your Cloud Storage provided by MEGA.

This document will guide you to build the application on a Mac machine with Xcode.

### Setup development environment

* [Xcode](https://itunes.apple.com/app/xcode/id497799835?mt=12)

### Build & Run the application

* Get the source code

```
git clone --recursive https://github.com/meganz/ios.git
cd ios
git submodule update --init --recursive
```

##### Preparation:
1.- Install Xcode in your system

2.- Clone this repo

3.- Download the prebuilt third party dependencies from this link: https://mega.nz/#!hJkQSRwJ!TffjMjC5qIE1tgSk6OdU6uYQtbBHlXKrj-Wskb6Yy7Q

4.- Uncompress that file and move the folder `3rdparty` into `iMEGA/Vendor/sdk/bindings/ios/3rdparty`

5.- Open `iMEGA.xcworkspace`

6.- Make sure the `MEGA` target is selected

7.- Build and run (⌘R)

8.- Enjoy!

If you want to build the third party dependencies by yourself: open a terminal in the directory `iMEGA/sdk/bindings/ios/3rdparty`. Run sh build-all.sh (Wait until the process ends, it will take some minutes ~20)
