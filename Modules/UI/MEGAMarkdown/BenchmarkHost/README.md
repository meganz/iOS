# MEGAMarkdown benchmark host

A small iOS app and a UI test bundle that measure scroll hitches in `MarkdownPreview`.
It is not part of the MEGA app target or CI. A simulator cannot give hitch values.

## What it does

- The app opens one generated Markdown file in `MarkdownPreview`.
- The launch argument `-varied-mb <megabytes>` sets the file size. The default is 2.
- `VariedSections` makes the text from a fixed seed. The same seed gives the same text on every run.
  The text is cached in the caches folder, because a 50 MB file takes seconds to make.
- `ScrollHitchUITests` has three tests: new rows, measured rows, and flinging while a 50 MB file loads.
- The UI tests use the helpers of `MEGABenchmarkUI` (`Modules/Infrastracture/MEGABenchmark`).

## Run

Use Release and an iOS 26 destination. `XCTHitchMetric` needs iOS 26.

```sh
xcodebuild build-for-testing -project BenchmarkHost.xcodeproj -scheme BenchmarkHost -configuration Release \
  -destination id=<udid> -derivedDataPath <folder> -allowProvisioningUpdates -skipPackagePluginValidation
xcodebuild test-without-building -project BenchmarkHost.xcodeproj -scheme BenchmarkHost -configuration Release \
  -destination id=<udid> -derivedDataPath <folder> -parallel-testing-enabled NO -enableCodeCoverage NO
```

- On a simulator, only "Duration (Scroll_Deceleration)" has values.
- On a device, the hitch count, hitch time ratio and frame rate have values.
  Apple rates a hitch time ratio under 5 ms/s as good and over 10 ms/s as bad.
