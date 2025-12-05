import Foundation

public enum APMKit: @unchecked Sendable {
    private static let lock = NSLock()
    /// This queue is used for monitoring reporting logic
    static let queue = DispatchQueue(label: "performance_monitoring_queue", qos: .default)
    nonisolated(unsafe) private(set) static var metricMonitors = [APMMetricMonitor]()
    
    // MARK: - public
    public static func start(with reporter: some APMMetricsReporter) {
        lock.lock()
        defer {
            lock.unlock()
        }
        
        guard metricMonitors.isEmpty else {
            return
        }
        
#if arch(arm64)
        APMThreadCallStack.storeMainThreadHandle()
#endif
        metricMonitors = makeMonitors(config: .defaultConfig, monitorFactory: APMMonitorFactory(), reporter: reporter)
        metricMonitors.forEach { $0.start() }
    }
    
    public static func stop() {
        lock.lock()
        defer {
            lock.unlock()
        }
        
        guard !metricMonitors.isEmpty else {
            return
        }
        metricMonitors.forEach { $0.stop() }
        metricMonitors.removeAll()
    }
    
    // MARK: - internal
    static func makeMonitors(config: APMConfiguration, monitorFactory: some APMMonitorFactoryProtocol, reporter: some APMMetricsReporter) -> [APMMetricMonitor] {
        var monitors: [APMMetricMonitor] = []
        if let hangConfig = config.hangConfig, let hangMonitor = monitorFactory.makeHangMonitor(config: hangConfig, reporter: reporter) {
            monitors.append(hangMonitor)
        }
        return monitors
    }
}
