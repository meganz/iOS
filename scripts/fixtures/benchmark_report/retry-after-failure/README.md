# Retry after a failure

Native `xcrun xcresulttool get test-results metrics` and `tests` output, Xcode 26.4.1, iPhone 17 simulator (iOS 26.4.1).

The test plan used `"testRepetitionMode": "retryOnFailure"` and `"maximumTestRepetitions": 2`.
The test failed before its `measure` block on the first run and measured on the retry.
The test's own result is "Passed". Its two `Repetition` children are "Failed" and "Passed".
The metrics output has one run record, from the retry only.

The simulator name and the failure message were shortened. The reporter must reject this bundle.
