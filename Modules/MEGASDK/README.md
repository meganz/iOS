# MEGASDK

Swift package module for the MEGA C++ SDK and Objective-C++ binding.

## Installation

1. Add the MEGASDK as local SPM package module. On Xcode 14, open your project, File -> Add package -> Add local -> Add MEGASDK folder
2. Click on the project in the project navigator
3. Select the target
4. Click general -> Frameworks -> Click add button -> Select MEGASdk
5. Download the prebuilt third party dependencies from this link: https://mega.nz/file/AENVGYjC#HhUgIOBY69zVZZtOa4e6vdySpHefnUo4GcoQYElmEo4
6. Uncompress that file and move the folders webrtc , include and lib into MEGASDK/Sources/MEGASDK/bindings/ios/3rdparty.

The MEGASDK swift package has two target libraries `MEGASdkCpp` and `MEGASdk`. `MEGASdkCpp` compile the SDK c++ code `MEGASdk` compile the Objetive-C++ binding.

## Usage
To check how to use `MEGASDK` you can check the code of the MEGA iOS app aplication.
https://github.com/meganz/ios

## License
BSD 2-Clause "Simplified" License https://github.com/meganz/sdk/blob/master/LICENSE
