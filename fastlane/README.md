fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios upload_symbols

```sh
[bundle exec] fastlane ios upload_symbols
```

Upload symbols to crashlytics after running the gym

### ios upload_symbols_with_dsym_path

```sh
[bundle exec] fastlane ios upload_symbols_with_dsym_path
```

Upload symbols to crashlytics with dsym path as parameter

### ios create_temporary_keychain

```sh
[bundle exec] fastlane ios create_temporary_keychain
```

creates temporary keychain

### ios install_certificate_and_profile_to_temp_keychain

```sh
[bundle exec] fastlane ios install_certificate_and_profile_to_temp_keychain
```

installs certificate and profiles for a given profile type to temp keychain created in create_temporary_keychain lane

### ios set_time_as_build_number

```sh
[bundle exec] fastlane ios set_time_as_build_number
```

set the date and time as build number and write it to build_number file

### ios fetch_version_number

```sh
[bundle exec] fastlane ios fetch_version_number
```

fetch the version number and write to file named version_number.txt

### ios archive_appstore

```sh
[bundle exec] fastlane ios archive_appstore
```

archive for app store

### ios delete_temporary_keychain

```sh
[bundle exec] fastlane ios delete_temporary_keychain
```

Delete the temporary created keychain

### ios upload_to_itunesconnect

```sh
[bundle exec] fastlane ios upload_to_itunesconnect
```

Upload to iTunesConnect

### ios sync_all_code_signing

```sh
[bundle exec] fastlane ios sync_all_code_signing
```



### ios tests

```sh
[bundle exec] fastlane ios tests
```

MEGA unit tests

### ios download_metadata

```sh
[bundle exec] fastlane ios download_metadata
```

Download metadata

### ios upload_metadata_to_appstore_connect

```sh
[bundle exec] fastlane ios upload_metadata_to_appstore_connect
```

Uploads metadata to app store connect

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
