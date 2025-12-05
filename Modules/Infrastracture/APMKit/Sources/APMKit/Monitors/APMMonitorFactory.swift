protocol APMMonitorFactoryProtocol: Sendable {
    func makeHangMonitor(
        config: APMHangConfiguration,
        reporter: some APMMetricsReporter
    ) -> APMMetricMonitor?
}

struct APMMonitorFactory: APMMonitorFactoryProtocol {
    public init() {}
    public func makeHangMonitor(
        config: APMHangConfiguration,
        reporter: some APMMetricsReporter
    ) -> APMMetricMonitor? {
#if arch(arm64)
        return APMHangMonitor(config: config, metricsReporter: reporter)
#else
        return nil
#endif
    }
}
