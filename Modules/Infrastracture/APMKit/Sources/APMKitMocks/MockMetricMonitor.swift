@testable import APMKit

final class MockMetricMonitor: APMMetricMonitor, @unchecked Sendable {
    private(set) var startCount = 0
    private(set) var stopCount = 0
    private(set) var isRunning = false

    func start() {
        startCount += 1
        isRunning = true
    }

    func stop() {
        stopCount += 1
        isRunning = false
    }
}

final class MockMonitorFactory: APMMonitorFactoryProtocol, @unchecked Sendable {
    private(set) var created: [MockMetricMonitor] = []

    func makeHangMonitor(config: APMHangConfiguration, reporter: some APMMetricsReporter) -> (any APMMetricMonitor)? {
        created.removeAll()
        let monitor = MockMetricMonitor()
        created.append(monitor)
        return monitor
    }
}
