@testable import APMKit

final class MockMetricsReporter: APMMetricsReporter, @unchecked Sendable {
    var reportedMetrics: [APMMetrics] = []
    
    func report(hangMetrics: APMHangMetrics) {
        reportedMetrics.append(.hang(hangMetrics))
    }
}
