import Darwin
import Foundation
import XCTest

/// Peak memory during the measured block, sampled on its own thread: the footprint every millisecond,
/// the malloc heap every 5 ms. `malloc_zone_statistics` takes the zone locks, so a 1 ms heap read slowed an
/// allocation-heavy parse by 40%. The sampler thread's CPU counts in a process-wide `XCTCPUMetric`.
/// A 1 ms interval is a request, not a guarantee: the thread can be scheduled late, so a very short peak can be missed.
///
/// Three different numbers. "Peak Heap Growth": bytes in use in the malloc zones, peak minus start. It counts every
/// live heap object on every run. "Peak Footprint": the highest `phys_footprint` seen, what a memory kill compares
/// against. On a repeated run in one process it can stay low while the heap grows (see the package README), and it
/// depends on what ran before in the process, so it has no direction: the report shows it, no limit or gate uses it.
/// "Footprint Samples": the number of successful footprint reads in the interval. Values are MiB (1,048,576 bytes).
///
/// Each interval has a generation. `didStopMeasuring` waits for the sampler to end, and a read that started in an
/// earlier interval can never change a later one. A footprint read that fails is dropped and not counted.
/// An interval with no successful footprint read is an error, not a 0.
public final class PeakFootprintMetric: NSObject, XCTMetric, @unchecked Sendable {
    public static let identifier = "nz.mega.benchmark.peakHeapGrowth"
    public static let footprintIdentifier = "nz.mega.benchmark.peakFootprint"

    private let readHeap: @Sendable () -> Double
    private let readFootprint: @Sendable () -> Double?
    private let lock = NSLock()
    private var generation = 0
    private var isSampling = false
    private var startHeapMiB = 0.0
    private var peakHeapMiB = 0.0
    private var startFootprintMiB: Double?
    private var peakFootprintMiB = 0.0
    /// Successful footprint reads inside the interval, the final read included. Failed reads do not count.
    private var footprintSamples = 0
    /// Signalled when the sampler thread of the current generation has ended.
    private var samplerFinished = DispatchSemaphore(value: 0)

    override public convenience init() {
        self.init(heapReader: { Footprint.heapMiB() }, footprintReader: { Footprint.currentMiB() })
    }

    /// Tests inject readers to control when a read completes and whether it fails.
    init(heapReader: @escaping @Sendable () -> Double, footprintReader: @escaping @Sendable () -> Double?) {
        readHeap = heapReader
        readFootprint = footprintReader
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        PeakFootprintMetric(heapReader: readHeap, footprintReader: readFootprint)
    }

    public func willBeginMeasuring() {
        stopSampler()
        let heap = readHeap()
        let footprint = readFootprint()
        let finished = DispatchSemaphore(value: 0)
        let current: Int = lock.withLock {
            generation += 1
            startHeapMiB = heap
            peakHeapMiB = heap
            startFootprintMiB = footprint
            peakFootprintMiB = footprint ?? 0
            footprintSamples = 0
            isSampling = true
            samplerFinished = finished
            return generation
        }
        let thread = Thread { [self] in
            var tick = 0
            while lock.withLock({ isSampling && generation == current }) {
                let heap = tick % 5 == 0 ? readHeap() : nil
                let footprint = readFootprint()
                record(heap: heap, footprint: footprint, generation: current)
                tick += 1
                Thread.sleep(forTimeInterval: 0.001)
            }
            finished.signal()
        }
        thread.qualityOfService = .userInteractive
        thread.start()
    }

    public func didStopMeasuring() {
        let current = lock.withLock { generation }
        stopSampler()
        // The final read belongs to the interval: a block shorter than one tick still has one sample.
        record(heap: readHeap(), footprint: readFootprint(), generation: current, afterStop: true)
    }

    public func reportMeasurements(
        from startTime: XCTPerformanceMeasurementTimestamp,
        to endTime: XCTPerformanceMeasurementTimestamp
    ) throws -> [XCTPerformanceMeasurement] {
        let (heapGrowth, footprintStart, footprintPeak, samples) = lock.withLock {
            (peakHeapMiB - startHeapMiB, startFootprintMiB, peakFootprintMiB, footprintSamples)
        }
        guard footprintStart != nil else { throw BenchmarkMetricError.footprintReadFailed }
        guard samples > 0 else { throw BenchmarkMetricError.noSamples }
        return [
            XCTPerformanceMeasurement(
                identifier: Self.identifier, displayName: "Peak Heap Growth",
                doubleValue: heapGrowth, unitSymbol: "MiB", polarity: .prefersSmaller),
            XCTPerformanceMeasurement(
                identifier: Self.footprintIdentifier, displayName: "Peak Footprint",
                doubleValue: footprintPeak, unitSymbol: "MiB", polarity: .unspecified),
            // Successful footprint reads. A short block has few, a 1 s block hundreds.
            XCTPerformanceMeasurement(
                identifier: Self.identifier + ".samples", displayName: "Footprint Samples",
                doubleValue: Double(samples), unitSymbol: "count", polarity: .unspecified)
        ]
    }

    /// Keeps a reading only when it belongs to the live interval. A read that started before `didStopMeasuring`
    /// and finished after it is dropped. The lock is never held while a reader runs.
    private func record(heap: Double?, footprint: Double?, generation: Int, afterStop: Bool = false) {
        lock.withLock {
            guard self.generation == generation, isSampling || afterStop else { return }
            if let heap { peakHeapMiB = max(peakHeapMiB, heap) }
            if let footprint {
                peakFootprintMiB = max(peakFootprintMiB, footprint)
                footprintSamples += 1
            }
        }
    }

    /// Ends the sampler of the current interval and waits for its thread, without holding the lock.
    private func stopSampler() {
        let finished: DispatchSemaphore? = lock.withLock {
            guard isSampling else { return nil }
            isSampling = false
            return samplerFinished
        }
        finished?.wait()
    }
}
