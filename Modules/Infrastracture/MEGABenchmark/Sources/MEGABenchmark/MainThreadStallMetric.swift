import Foundation
import QuartzCore
import XCTest

/// Main thread stalls during the measured block: the gaps between fires of a 5 ms timer on the main run loop.
/// The block must let the main run loop turn (UI benches). A block that blocks the main thread counts as one stall.
/// XCTest calls the begin and stop hooks on a background queue while the main thread waits, so only
/// thread-safe CoreFoundation calls touch the main run loop here. A sync hop to the main queue deadlocks.
public final class MainThreadStallMetric: NSObject, XCTMetric, @unchecked Sendable {
    public static let identifier = "nz.mega.benchmark.mainThreadStall"

    private let lock = NSLock()
    private var timer: CFRunLoopTimer?
    private var last: CFTimeInterval = 0
    private var longestGap: CFTimeInterval = 0
    private var gapsOver100ms = 0

    public func copy(with zone: NSZone? = nil) -> Any {
        MainThreadStallMetric()
    }

    public func willBeginMeasuring() {
        lock.withLock {
            last = CACurrentMediaTime()
            longestGap = 0
            gapsOver100ms = 0
        }
        let timer = CFRunLoopTimerCreateWithHandler(nil, CFAbsoluteTimeGetCurrent(), 0.005, 0, 0) { [weak self] _ in
            self?.tick()
        }
        CFRunLoopAddTimer(CFRunLoopGetMain(), timer, .commonModes)
        lock.withLock { self.timer = timer }
    }

    public func didStopMeasuring() {
        tick()
        let timer = lock.withLock { self.timer }
        if let timer {
            CFRunLoopTimerInvalidate(timer)
        }
        lock.withLock { self.timer = nil }
    }

    public func reportMeasurements(
        from startTime: XCTPerformanceMeasurementTimestamp,
        to endTime: XCTPerformanceMeasurementTimestamp
    ) throws -> [XCTPerformanceMeasurement] {
        let (longest, count) = lock.withLock { (longestGap, gapsOver100ms) }
        return [
            XCTPerformanceMeasurement(
                identifier: Self.identifier + ".longest", displayName: "Longest Main Thread Stall",
                doubleValue: longest * 1_000, unitSymbol: "ms", polarity: .prefersSmaller),
            XCTPerformanceMeasurement(
                identifier: Self.identifier + ".over100ms", displayName: "Main Thread Stalls Over 100 ms",
                doubleValue: Double(count), unitSymbol: "count", polarity: .prefersSmaller)
        ]
    }

    private func tick() {
        let now = CACurrentMediaTime()
        lock.withLock {
            let gap = now - last
            longestGap = max(longestGap, gap)
            if gap > 0.1 { gapsOver100ms += 1 }
            last = now
        }
    }
}
