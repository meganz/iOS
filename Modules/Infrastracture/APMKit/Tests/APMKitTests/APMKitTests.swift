@testable import APMKit
@testable import APMKitMocks
import Testing

private var isARM64: Bool {
    #if arch(arm64)
    return true
    #else
    return false
    #endif
}

@Suite("APMKit Test Suite", .serialized)
struct APMKitTests {
    @Test("Enable creates and starts monitors")
    func test_enableCreatesAndStartsMonitors() {
        let reporter = MockMetricsReporter()
        APMKit.start(with: reporter)
        
        #expect(!APMKit.metricMonitors.isEmpty)
        APMKit.stop()
    }
    
    @Test("Enable does nothing when already enabled")
    func test_enableDoesNothingWhenAlreadyEnabled() {
        let reporter1 = MockMetricsReporter()
        APMKit.start(with: reporter1)
        let initialMonitorCount = APMKit.metricMonitors.count
        
        let reporter2 = MockMetricsReporter()
        APMKit.start(with: reporter2)
        
        #expect(APMKit.metricMonitors.count == initialMonitorCount)
        APMKit.stop()
    }
    
    @Test("Enable stores main thread on ARM64", .enabled(if: isARM64))
    func test_enableStoresMainThreadOnARM64() async throws {
        let reporter = MockMetricsReporter()
        APMKit.start(with: reporter)
        
        try await Task.sleep(for: .milliseconds(100))
        #expect(APMThreadCallStack.mainThreadMachPort != nil)
        APMKit.stop()
    }
    
    @Test("create hang monitor on ARM64", .enabled(if: isARM64))
    func test_hangMonitorCreatedOnARM64() {
        let reporter = MockMetricsReporter()
        let monitor = APMMonitorFactory().makeHangMonitor(config: APMHangConfiguration.defaultConfig, reporter: reporter)
        
        #expect(monitor != nil)
    }
    
    @Test("Disable stops and removes all monitors")
    func test_disableStopsAndRemovesAllMonitors() {
        let reporter = MockMetricsReporter()
        APMKit.start(with: reporter)
        
        #expect(!APMKit.metricMonitors.isEmpty)
        
        APMKit.stop()
        
        #expect(APMKit.metricMonitors.isEmpty)
    }
    
    @Test("Disable does nothing when no monitors exist")
    func test_disableDoesNothingWhenNoMonitors() {
        #expect(APMKit.metricMonitors.isEmpty)
        
        APMKit.stop()
        
        #expect(APMKit.metricMonitors.isEmpty)
    }
}
