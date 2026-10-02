import Foundation
import XCTest

/// Base class for benchmark tests. They run only with `MEGA_BENCH=1` in the test environment
/// (`TEST_RUNNER_MEGA_BENCH=1` for xcodebuild), so a normal test run skips them.
open class BenchmarkCase: XCTestCase {
    public static let environmentFlag = "MEGA_BENCH"

    override open func setUpWithError() throws {
        try super.setUpWithError()
        try XCTSkipUnless(
            ProcessInfo.processInfo.environment[Self.environmentFlag] == "1",
            "Benchmarks run only with TEST_RUNNER_\(Self.environmentFlag)=1"
        )
    }

    /// 5 iterations: enough for a mean on CI, short enough for the UI benches.
    override open class var defaultMeasureOptions: XCTMeasureOptions {
        let options = XCTMeasureOptions()
        options.iterationCount = 5
        return options
    }
}
