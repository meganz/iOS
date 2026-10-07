import XCTest

/// Helpers for UI tests that measure a scroll with `XCTestCase.measure(metrics:options:)`.
/// The block of `measure` is not main-actor isolated, but UI tests always run it on the main thread.
/// So these helpers assume the main actor.
public enum ScrollBenchmark {
    /// Waits until the list shows a cell. Returns false after `timeout` seconds.
    public static func waitForFirstCell(in list: XCUIElement, timeout: TimeInterval = 30) -> Bool {
        MainActor.assumeIsolated {
            list.cells.firstMatch.waitForExistence(timeout: timeout)
        }
    }

    /// Fast swipes. Each swipe starts a deceleration.
    public static func fling(_ list: XCUIElement, up upCount: Int = 0, down downCount: Int = 0) {
        MainActor.assumeIsolated {
            for _ in 0..<upCount { list.swipeUp(velocity: .fast) }
            for _ in 0..<downCount { list.swipeDown(velocity: .fast) }
        }
    }

    /// Apple's hitch numbers need a device. A simulator returns the deceleration duration only.
    @available(iOS 26.0, *)
    public static func hitchMetrics(for app: XCUIApplication) -> [any XCTMetric] {
        [XCTHitchMetric(application: app), XCTOSSignpostMetric.scrollDecelerationMetric]
    }

    /// With `manualStart`, the test block calls `startMeasuring()` and `stopMeasuring()` around the scroll.
    public static func measureOptions(iterations: Int = 5, manualStart: Bool = false) -> XCTMeasureOptions {
        let options = XCTMeasureOptions()
        options.iterationCount = iterations
        if manualStart { options.invocationOptions = [.manuallyStart, .manuallyStop] }
        return options
    }
}
