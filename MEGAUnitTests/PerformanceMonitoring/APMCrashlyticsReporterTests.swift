@testable import APMKit
@testable import MEGA
import Testing

@Suite("APMCrashlyticsReporter Test Suite")
struct APMCrashlyticsReporterTests {
    private func makeSUT(
        crashlytics: any CrashlyticsReporting = CrashlyticsReportingMocks(),
        reachability: String = "offline"
        ) -> APMCrashlyticsReporter {
        return APMCrashlyticsReporter(crashlytics: crashlytics, reachabilityProvider: { reachability })
    }

    @Test("report a hang with valid stacktrace")
    func test_reportHangWithValidStackTrace() {
        let mockCrashlytics = CrashlyticsReportingMocks()
        let reporter = makeSUT(crashlytics: mockCrashlytics)

        let hangMetrics = APMHangMetrics(
            threshold: 0.25,
            hangDuration: 2.5,
            capturedStack: [0x1234, 0x5678, 0x9ABC],
            runloopActivity: .beforeTimers,
            deviceLocale: "en-NZ"
        )
        
        #expect(mockCrashlytics.reportedCount == 0)
        #expect(mockCrashlytics.reportedException == nil)
        
        reporter.report(hangMetrics: hangMetrics)
        
        #expect(mockCrashlytics.getIntValue(for: CrashlyticsKeys.hangDuration) == 2500)
        #expect(mockCrashlytics.getStringValue(for: CrashlyticsKeys.runloopActivity) == CFRunLoopActivity.beforeTimers.asString)
        #expect(mockCrashlytics.getIntValue(for: CrashlyticsKeys.threshold) == 250)
        #expect(mockCrashlytics.getStringValue(for: CrashlyticsKeys.deviceLocale) == "en-NZ")
        #expect(mockCrashlytics.getStringValue(for: CrashlyticsKeys.reachability) == "offline")
        
        #expect(mockCrashlytics.reportedException != nil)
        #expect(mockCrashlytics.reportedException?.stackTrace.count == 3)
        #expect(mockCrashlytics.reportedError == nil)
        #expect(mockCrashlytics.reportedCount == 1)
    }
    
    @Test("report a hang with empty stacktrace")
    func test_reportHangWithEmptyStackTrace() {
        let mockCrashlytics = CrashlyticsReportingMocks()
        let reporter = makeSUT(crashlytics: mockCrashlytics, reachability: "Wi-Fi")

        let hangMetrics = APMHangMetrics(
            threshold: 1.0,
            hangDuration: 1.5,
            capturedStack: [],
            runloopActivity: .beforeSources,
            deviceLocale: "en-NZ"
        )
        
        #expect(mockCrashlytics.reportedCount == 0)
        #expect(mockCrashlytics.reportedError == nil)
        
        reporter.report(hangMetrics: hangMetrics)
        
        #expect(mockCrashlytics.getIntValue(for: CrashlyticsKeys.hangDuration) == 1500)
        #expect(mockCrashlytics.getStringValue(for: CrashlyticsKeys.runloopActivity) == CFRunLoopActivity.beforeSources.asString)
        #expect(mockCrashlytics.getIntValue(for: CrashlyticsKeys.threshold) == 1000)
        #expect(mockCrashlytics.getStringValue(for: CrashlyticsKeys.deviceLocale) == "en-NZ")
        #expect(mockCrashlytics.getStringValue(for: CrashlyticsKeys.reachability) == "Wi-Fi")
        
        #expect(mockCrashlytics.reportedException == nil)
        let error = mockCrashlytics.reportedError as? NSError
        #expect(error?.domain == "mega.ios.hang")
        #expect(error?.code == 1001)
        #expect(error?.localizedDescription == "Hang detected with empty stack captured")
        #expect(mockCrashlytics.reportedCount == 1)
    }
    
    @Test("test report multiple hang events")
    func test_reportMultipleHangEvents() {
        let mockCrashlytics = CrashlyticsReportingMocks()
        let reporter = makeSUT(crashlytics: mockCrashlytics, reachability: "Wi-Fi")

        let hangMetrics = APMHangMetrics(
            threshold: 1.0,
            hangDuration: 1.5,
            capturedStack: [],
            runloopActivity: .beforeSources,
            deviceLocale: "en-NZ"
        )
        
        #expect(mockCrashlytics.reportedCount == 0)
        
        reporter.report(hangMetrics: hangMetrics)
        reporter.report(hangMetrics: hangMetrics)
        
        #expect(mockCrashlytics.reportedCount == 2)
    }
    
    @Test("test report multiple hang events")
    func test_reportWithMultipleStackAddresses() {
        let mockCrashlytics = CrashlyticsReportingMocks()
        let reporter = makeSUT(crashlytics: mockCrashlytics)
        let addresses: [UInt64] = [0x1000, 0x2000, 0x3000, 0x4000, 0x5000]
        let hangMetrics = APMHangMetrics(
            threshold: 0.25,
            hangDuration: 1.5,
            capturedStack: addresses,
            runloopActivity: .beforeTimers,
            deviceLocale: "en-US"
        )
        
        reporter.report(hangMetrics: hangMetrics)
        #expect(mockCrashlytics.reportedException?.stackTrace.count == 5)
        
        for (index, address) in addresses.enumerated() {
            let frame = mockCrashlytics.reportedException?.stackTrace[index]
            #expect(frame?.value(forKey: "address") as? UInt64 == address)
        }
    }
    
    @Test("different hang durations should be reported with appropriate reasons", arguments: [
        (0.001, "Main thread hang for 0.001s"),
        (0.999, "Main thread hang for 0.999s"),
        (1.0, "Main thread hang for 1.000s"),
        (10.5678, "Main thread hang for 10.568s"),
        (999.999, "Main thread hang for 999.999s")
    ])
    func test_reportWithVariousDurations(duration: TimeInterval, expectedReason: String) {
        let mockCrashlytics = CrashlyticsReportingMocks()
        let reporter = makeSUT(crashlytics: mockCrashlytics)
        let hangMetrics = APMHangMetrics(
            threshold: 0.25,
            hangDuration: duration,
            capturedStack: [0x1234],
            runloopActivity: .afterWaiting
        )
        
        reporter.report(hangMetrics: hangMetrics)
        #expect(mockCrashlytics.reportedException?.value(forKey: "name") as? String == "Hang")
        #expect(mockCrashlytics.reportedException?.value(forKey: "reason") as? String == expectedReason)
    }
    
    @Test("different reachability statuses should be reported", arguments: [
        ("Wi-Fi", "Wi-Fi"),
        ("Cellular", "Cellular"),
        ("offline", "offline")
    ])
    func test_reportWithVariousReachability(reachability: String, expected: String) {
        let mockCrashlytics = CrashlyticsReportingMocks()
        let reporter = makeSUT(crashlytics: mockCrashlytics, reachability: reachability)
        
        let hangMetrics = APMHangMetrics(
            threshold: 0.25,
            hangDuration: 1.5,
            capturedStack: [0x1234],
            runloopActivity: .afterWaiting
        )
        
        reporter.report(hangMetrics: hangMetrics)
        #expect(mockCrashlytics.customValues[CrashlyticsKeys.reachability] as? String == expected)
    }
    
    @Test("report default locale")
    func test_reportWithNilDeviceLocale() {
        let mockCrashlytics = CrashlyticsReportingMocks()
        let reporter = makeSUT(crashlytics: mockCrashlytics)
        
        let hangMetrics = APMHangMetrics(
            threshold: 0.25,
            hangDuration: 1.5,
            capturedStack: [0x1234],
            runloopActivity: .afterWaiting
        )
        
        reporter.report(hangMetrics: hangMetrics)
        #expect(mockCrashlytics.customValues[CrashlyticsKeys.deviceLocale] as? String == "")
    }
    
    @Test("report default locale")
    func test_reportWithNilRunloopActivity() {
        let mockCrashlytics = CrashlyticsReportingMocks()
        let reporter = makeSUT(crashlytics: mockCrashlytics)
        
        let hangMetrics = APMHangMetrics(
            threshold: 0.25,
            hangDuration: 1.5,
            capturedStack: [0x1234]
        )
        
        reporter.report(hangMetrics: hangMetrics)
        #expect(mockCrashlytics.customValues[CrashlyticsKeys.runloopActivity] as? String == "")
    }
}
