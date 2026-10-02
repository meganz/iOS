@testable import MEGABenchmark
import XCTest

/// The custom metrics are called the way XCTest calls them, and their numbers are checked.
final class MetricTests: XCTestCase {
    private static let mebibyte = 1_048_576

    // MARK: - Peak memory

    func testPeakMetricSeesMemoryFreedInsideTheBlock() throws {
        let metric = PeakFootprintMetric()
        offMain { metric.willBeginMeasuring() }
        let buffer = touchedBuffer(byteCount: 200 * Self.mebibyte)
        Thread.sleep(forTimeInterval: 0.02)
        buffer.deallocate()
        offMain { metric.didStopMeasuring() }

        let measurements = try metric.reportMeasurements(from: .init(), to: .init())
        let growth = try XCTUnwrap(measurements.first { $0.identifier == PeakFootprintMetric.identifier })
        XCTAssertGreaterThanOrEqual(growth.doubleValue, 190, "peak heap growth \(growth.doubleValue) MiB")
        XCTAssertEqual(growth.unitSymbol, "MiB")
        let footprint = try XCTUnwrap(measurements.first { $0.identifier == PeakFootprintMetric.footprintIdentifier })
        XCTAssertGreaterThanOrEqual(footprint.doubleValue, 150, "peak footprint \(footprint.doubleValue) MiB")
        let samples = try XCTUnwrap(measurements.first { $0.identifier.hasSuffix(".samples") })
        XCTAssertGreaterThanOrEqual(samples.doubleValue, 5)
    }

    /// Memory freed before the block and reused inside it must still count. The footprint misses reused pages.
    func testPeakHeapGrowthCountsMemoryFreedBeforeTheBlock() throws {
        touchedBuffer(byteCount: 200 * Self.mebibyte).deallocate()
        let metric = PeakFootprintMetric()
        offMain { metric.willBeginMeasuring() }
        let buffer = touchedBuffer(byteCount: 200 * Self.mebibyte)
        Thread.sleep(forTimeInterval: 0.02)
        buffer.deallocate()
        offMain { metric.didStopMeasuring() }

        let measurements = try metric.reportMeasurements(from: .init(), to: .init())
        let growth = try XCTUnwrap(measurements.first { $0.identifier == PeakFootprintMetric.identifier })
        XCTAssertGreaterThanOrEqual(growth.doubleValue, 190, "peak heap growth \(growth.doubleValue) MiB")
    }

    /// A read that started in interval 1 and finishes after its stop must not change interval 1 or interval 2.
    func testLateReadFromAnEarlierIntervalIsDropped() throws {
        let reader = DelayedReader(blockingCall: 2, blockedValue: 1_000, otherValue: 100)
        let metric = PeakFootprintMetric(heapReader: { reader.read() }, footprintReader: { 100 })
        offMain { metric.willBeginMeasuring() }
        // The sampler's first heap read is call 2. Let it finish after the stop began.
        XCTAssertTrue(reader.waitUntilBlocked(), "the sampler reached the blocking read")
        let releaser = Thread {
            Thread.sleep(forTimeInterval: 0.05)
            reader.release()
        }
        releaser.start()
        offMain { metric.didStopMeasuring() }
        XCTAssertTrue(reader.wasReleased, "the stop waited for the blocked read")
        let first = try metric.reportMeasurements(from: .init(), to: .init())
        XCTAssertEqual(try growth(in: first), 0, "the late 1,000 read was dropped")

        offMain { metric.willBeginMeasuring() }
        Thread.sleep(forTimeInterval: 0.02)
        offMain { metric.didStopMeasuring() }
        let second = try metric.reportMeasurements(from: .init(), to: .init())
        XCTAssertEqual(try growth(in: second), 0, "interval 2 saw only 100")
        let samples = try XCTUnwrap(second.first { $0.identifier.hasSuffix(".samples") })
        XCTAssertGreaterThan(samples.doubleValue, 5)
    }

    func testVeryShortBlockStillHasOneSample() throws {
        let metric = PeakFootprintMetric()
        offMain { metric.willBeginMeasuring() }
        offMain { metric.didStopMeasuring() }
        let samples = try XCTUnwrap(try metric.reportMeasurements(from: .init(), to: .init()).first { $0.identifier.hasSuffix(".samples") })
        XCTAssertGreaterThanOrEqual(samples.doubleValue, 1)
    }

    func testFailedFootprintReadIsAnError() {
        let metric = PeakFootprintMetric(heapReader: { 100 }, footprintReader: { nil })
        offMain { metric.willBeginMeasuring() }
        offMain { metric.didStopMeasuring() }
        XCTAssertThrowsError(try metric.reportMeasurements(from: .init(), to: .init()))
    }

    /// A footprint read that works once at the start and then always fails gives no footprint peak, not a 100.
    func testFootprintReadsThatFailAfterTheStartAreAnError() {
        let reader = CountingReader(firstValue: 100)
        let metric = PeakFootprintMetric(heapReader: { 100 }, footprintReader: { reader.read() })
        offMain { metric.willBeginMeasuring() }
        Thread.sleep(forTimeInterval: 0.02)
        offMain { metric.didStopMeasuring() }
        XCTAssertGreaterThan(reader.calls, 2, "the sampler tried to read")
        XCTAssertThrowsError(try metric.reportMeasurements(from: .init(), to: .init()))
    }

    // MARK: - Main thread stall

    func testMainThreadStallMetricReportsTheLongestGap() throws {
        let metric = MainThreadStallMetric()
        offMain { metric.willBeginMeasuring() }
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.05))
        Thread.sleep(forTimeInterval: 0.15)
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.05))
        offMain { metric.didStopMeasuring() }

        let measurements = try metric.reportMeasurements(from: .init(), to: .init())
        let longest = try XCTUnwrap(measurements.first { $0.identifier.hasSuffix(".longest") })
        XCTAssertGreaterThanOrEqual(longest.doubleValue, 150)
        XCTAssertLessThan(longest.doubleValue, 1_000)
        let over100 = try XCTUnwrap(measurements.first { $0.identifier.hasSuffix(".over100ms") })
        XCTAssertEqual(over100.doubleValue, 1)
    }

    // MARK: - Late frames

    func testFrameHitchMetricCountsALateFrame() throws {
        let metric = FrameHitchMetric()
        offMain { metric.willBeginMeasuring() }
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.2))
        Thread.sleep(forTimeInterval: 0.1)
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.2))
        offMain { metric.didStopMeasuring() }

        let measurements = try metric.reportMeasurements(from: .init(), to: .init())
        let frames = try XCTUnwrap(measurements.first { $0.identifier.hasSuffix(".frames") })
        XCTAssertGreaterThan(frames.doubleValue, 5)
        let late = try XCTUnwrap(measurements.first { $0.identifier.hasSuffix(".count") })
        XCTAssertGreaterThanOrEqual(late.doubleValue, 1)
        let lateness = try XCTUnwrap(measurements.first { $0.identifier.hasSuffix(".time") })
        XCTAssertGreaterThanOrEqual(lateness.doubleValue, 60)
    }

    /// A block that never turns the run loop shows no frame. That is an error, not zero late frames.
    func testFrameHitchMetricWithNoFrameIsAnError() {
        let metric = FrameHitchMetric()
        offMain { metric.willBeginMeasuring() }
        Thread.sleep(forTimeInterval: 0.05)
        offMain { metric.didStopMeasuring() }
        XCTAssertThrowsError(try metric.reportMeasurements(from: .init(), to: .init()))
    }

    func testCopyGivesAFreshMetric() {
        let peak = PeakFootprintMetric()
        let peakCopy = peak.copy() as AnyObject
        XCTAssertTrue(peakCopy is PeakFootprintMetric)
        XCTAssertFalse(peakCopy === peak)
        let stall = MainThreadStallMetric()
        let stallCopy = stall.copy() as AnyObject
        XCTAssertTrue(stallCopy is MainThreadStallMetric)
        XCTAssertFalse(stallCopy === stall)
        let frames = FrameHitchMetric()
        let framesCopy = frames.copy() as AnyObject
        XCTAssertTrue(framesCopy is FrameHitchMetric)
        XCTAssertFalse(framesCopy === frames)
    }

    // MARK: - Helpers

    private func growth(in measurements: [XCTPerformanceMeasurement]) throws -> Double {
        try XCTUnwrap(measurements.first { $0.identifier == PeakFootprintMetric.identifier }).doubleValue
    }

    /// XCTest calls the metric hooks on a background thread and blocks the main thread until they return.
    /// `DispatchQueue.global().sync` can run the body on the calling thread, so a new thread is used.
    private func offMain(_ body: @escaping @Sendable () -> Void) {
        let done = DispatchSemaphore(value: 0)
        let thread = Thread {
            XCTAssertFalse(Thread.isMainThread)
            body()
            done.signal()
        }
        thread.start()
        XCTAssertEqual(done.wait(timeout: .now() + 10), .success, "the metric hook returned")
    }

    /// Writes one byte per 4 KB page, so the system really gives the pages to the process.
    private func touchedBuffer(byteCount: Int) -> UnsafeMutableRawPointer {
        let buffer = UnsafeMutableRawPointer.allocate(byteCount: byteCount, alignment: 16)
        for offset in stride(from: 0, to: byteCount, by: 4096) {
            buffer.storeBytes(of: 1, toByteOffset: offset, as: UInt8.self)
        }
        return buffer
    }
}

/// A footprint reader that answers the first call and fails every call after it.
private final class CountingReader: @unchecked Sendable {
    private let lock = NSLock()
    private let firstValue: Double
    private(set) var calls = 0

    init(firstValue: Double) {
        self.firstValue = firstValue
    }

    func read() -> Double? {
        lock.withLock {
            calls += 1
            return calls == 1 ? firstValue : nil
        }
    }
}

/// A heap reader whose n-th call blocks until `release()`, then returns a high value. Every other call returns a low one.
private final class DelayedReader: @unchecked Sendable {
    private let lock = NSLock()
    private let gate = DispatchSemaphore(value: 0)
    private let entered = DispatchSemaphore(value: 0)
    private let blockingCall: Int
    private let blockedValue: Double
    private let otherValue: Double
    private var calls = 0
    private(set) var wasReleased = false

    init(blockingCall: Int, blockedValue: Double, otherValue: Double) {
        self.blockingCall = blockingCall
        self.blockedValue = blockedValue
        self.otherValue = otherValue
    }

    func read() -> Double {
        let call: Int = lock.withLock {
            calls += 1
            return calls
        }
        guard call == blockingCall else { return otherValue }
        entered.signal()
        gate.wait()
        return blockedValue
    }

    /// Waits until the blocking call started, so a test does not guess with a sleep.
    func waitUntilBlocked() -> Bool {
        entered.wait(timeout: .now() + 10) == .success
    }

    func release() {
        lock.withLock { wasReleased = true }
        gate.signal()
    }
}
