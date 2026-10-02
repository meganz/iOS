import Foundation
import QuartzCore
import XCTest

/// Late display-link frames during the measured block: a proxy for hitches, measured on the main run loop.
/// A frame is late when its display-link callback comes more than half a frame after the expected time.
/// This sees main-thread delivery delays only. It does not see render-server or GPU hitches; those need
/// `XCTHitchMetric(application:)` in a UI test or Instruments.
/// The block must turn the main run loop the whole time (a scroll). A block that turns it 1 ms per key sees almost
/// no frames, and every one of them counts as late. No frame at all is an error, not a smooth run.
/// XCTest calls the begin and stop hooks on a background queue while the main thread waits,
/// so the display link is added and invalidated from that queue. A sync hop to the main queue deadlocks.
public final class FrameHitchMetric: NSObject, XCTMetric, @unchecked Sendable {
    public static let identifier = "nz.mega.benchmark.lateFrame"

    private let lock = NSLock()
    private var link: CADisplayLink?
    private var lastTimestamp: CFTimeInterval?
    private var lastExpected: CFTimeInterval = 1 / 60
    private var frames = 0
    private var lateFrames = 0
    private var lateness: CFTimeInterval = 0

    public func copy(with zone: NSZone? = nil) -> Any {
        FrameHitchMetric()
    }

    public func willBeginMeasuring() {
        lock.withLock {
            lastTimestamp = nil
            frames = 0
            lateFrames = 0
            lateness = 0
        }
        let link = CADisplayLink(target: self, selector: #selector(tick(_:)))
        link.add(to: .main, forMode: .common)
        lock.withLock { self.link = link }
    }

    public func didStopMeasuring() {
        let link = lock.withLock { self.link }
        link?.invalidate()
        lock.withLock { self.link = nil }
    }

    public func reportMeasurements(
        from startTime: XCTPerformanceMeasurementTimestamp,
        to endTime: XCTPerformanceMeasurementTimestamp
    ) throws -> [XCTPerformanceMeasurement] {
        let (frameCount, lateCount, totalLateness) = lock.withLock { (frames, lateFrames, lateness) }
        guard frameCount > 0 else { throw BenchmarkMetricError.noFrames }
        return [
            XCTPerformanceMeasurement(
                identifier: Self.identifier + ".count", displayName: "Late Frames",
                doubleValue: Double(lateCount), unitSymbol: "count", polarity: .prefersSmaller),
            XCTPerformanceMeasurement(
                identifier: Self.identifier + ".time", displayName: "Late Frame Time",
                doubleValue: totalLateness * 1_000, unitSymbol: "ms", polarity: .prefersSmaller),
            // Shows how many frames were seen. A stall at the end of the block is not counted: no later frame arrived.
            XCTPerformanceMeasurement(
                identifier: Self.identifier + ".frames", displayName: "Frames",
                doubleValue: Double(frameCount), unitSymbol: "count", polarity: .unspecified)
        ]
    }

    @objc private func tick(_ link: CADisplayLink) {
        let timestamp = link.timestamp
        let expected = link.targetTimestamp - link.timestamp
        lock.withLock {
            if let last = lastTimestamp {
                frames += 1
                let delay = timestamp - last - lastExpected
                if delay > lastExpected * 0.5 {
                    lateFrames += 1
                    lateness += delay
                }
            }
            lastTimestamp = timestamp
            lastExpected = expected
        }
    }
}
