# Retry in one of two configurations

Native `xcrun xcresulttool get test-results metrics` and `tests` output, Xcode 26.4.1, iPhone 17 simulator (iOS 26.4.1).

The test plan had two configurations, "Measured" and "Assertions", with `"testRepetitionMode": "retryOnFailure"`
and `"maximumTestRepetitions": 2`. In "Assertions" the test failed on the first run and passed on the retry.
In "Measured" it published two clock samples and passed. The test's own result is "Passed".
Its `Repetition` nodes sit under the "Assertions" `Test Plan Configuration` node, not directly under the test.
The metrics output has one run record, from "Measured" only.

Only the simulator name was changed, to "iPhone 17". The reporter must reject this bundle.
