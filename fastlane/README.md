fastlane documentation
================
# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```
xcode-select --install
```

Install _fastlane_ using
```
[sudo] gem install fastlane -NV
```
or alternatively using `brew install fastlane`

# Available Actions
## iOS
### ios bump
```
fastlane ios bump
```
Bump and tag version
### ios build_using_adhoc
```
fastlane ios build_using_adhoc
```
Build App using adhoc certificate for Appcenter
### ios upload_to_appcenter
```
fastlane ios upload_to_appcenter
```
Upload to Appcenter
### ios upload_symbols
```
fastlane ios upload_symbols
```
build a app store release version
### ios build_release
```
fastlane ios build_release
```
build a app store release version
### ios upload_to_itunesconnect
```
fastlane ios upload_to_itunesconnect
```
Upload to iTunesConnect
### ios sync_all_code_signing
```
fastlane ios sync_all_code_signing
```

### ios tests
```
fastlane ios tests
```
MEGA unit tests

----

This README.md is auto-generated and will be re-generated every time [fastlane](https://fastlane.tools) is run.
More information about fastlane can be found on [fastlane.tools](https://fastlane.tools).
The documentation of fastlane can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
