@testable import APMKit
@testable import APMKitMocks
import Foundation
import Testing

@Suite("APMHangMonitor Test Suite", .serialized)
struct APMHangMonitorTests {
    private func makeSUT(
        config: APMHangConfiguration = APMHangConfiguration.defaultConfig,
        reporter: APMMetricsReporter = MockMetricsReporter(),
        ) -> APMHangMonitor {
        return APMHangMonitor(config: config, metricsReporter: reporter)
    }
    
    @Test
    func test_thresholdOfHangMonitor() {
        let config = APMHangConfiguration(threshold: 0.3)
        let monitor = makeSUT(config: config)

        #expect(monitor.threshold == 0.3)
    }

    @Test
    func test_startWithSetsMonitoringFlag() {
        let monitor = makeSUT()

        #expect(monitor.isMonitoring == false)
        monitor.start()
        #expect(monitor.isMonitoring == true)
        monitor.stop()
    }

    @Test
    func test_stopStartWithResetsMonitoringFlag() {
        let monitor = makeSUT()

        monitor.start()
        monitor.stop()
        #expect(monitor.isMonitoring == false)
    }

    @Test
    func test_hangDetectionTriggersReporter() async {
        let cfg = APMHangConfiguration(threshold: 0.5)
        let mockReporter = MockMetricsReporter()
        let monitor = makeSUT(config: cfg, reporter: mockReporter)
        APMThreadCallStack.storeMainThreadHandle()
        monitor.start()
        await MainActor.run {
            Thread.sleep(forTimeInterval: 0.8)
        }
        try? await Task.sleep(nanoseconds: 100_000_000)
        monitor.stop()
        
        #expect(mockReporter.reportedMetrics.count == 1)
        let result = mockReporter.reportedMetrics.first
        if case let .hang(reportedData) = result {
            #expect(reportedData.threshold == 0.5)
        } else {
            Issue.record("Expected .hang but got \(result)")
        }
    }
    
    @Test
    func test_hangDetectionTriggersReporter_oncePerHang() async {
        let cfg = APMHangConfiguration(threshold: 0.5)
        let mockReporter = MockMetricsReporter()
        let monitor = makeSUT(config: cfg, reporter: mockReporter)
        APMThreadCallStack.storeMainThreadHandle()
        monitor.start()
        await MainActor.run {
            Thread.sleep(forTimeInterval: 20)
        }
        try? await Task.sleep(nanoseconds: 100_000_000)
        monitor.stop()
        
        #expect(mockReporter.reportedMetrics.count == 1)
        let result = mockReporter.reportedMetrics.first
        if case let .hang(reportedData) = result {
            #expect(reportedData.threshold == 0.5)
        } else {
            Issue.record("Expected .hang but got \(result)")
        }
    }
}
