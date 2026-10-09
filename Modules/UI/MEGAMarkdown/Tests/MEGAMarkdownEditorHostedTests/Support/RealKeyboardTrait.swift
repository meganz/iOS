import Foundation
import Testing

extension Trait where Self == ConditionTrait {
    /// Runs the test only when `MEGA_REAL_KEYBOARD` is "1". Other test runs skip it.
    /// The software keyboard comes up at a different time in each run, so CI cannot rely on it.
    static var realKeyboard: Self {
        .enabled(if: ProcessInfo.processInfo.environment["MEGA_REAL_KEYBOARD"] == "1", "Run with TEST_RUNNER_MEGA_REAL_KEYBOARD=1")
    }
}
