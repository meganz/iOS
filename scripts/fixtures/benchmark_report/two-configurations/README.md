# Two configurations

Native `xcrun xcresulttool get test-results metrics` and `tests` output, Xcode 26.4.1, iPhone 17 simulator (iOS 26.4.1).

The test plan had two configurations, "Measured" and "Assertions". Both ran `ConfigurationProbeTests/testSelected`.
In "Measured" the test published two clock samples. In "Assertions" it published nothing.
Both passed. The metrics output has one run record, from "Measured" only.
The tests output lists both configurations in `testPlanConfigurations`.

Only the simulator name was changed, to "iPhone 17". The reporter must reject this bundle.
