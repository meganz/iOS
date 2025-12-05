import Foundation

public protocol APMMetricsReporter: Sendable {
    func report(hangMetrics: APMHangMetrics)
}

public extension TimeInterval {
    var milliseconds: Int {
        max(0, Int((self * 1000).rounded()))
    }
}

public extension CFRunLoopActivity {
    var asString: String {
        switch self {
        case .entry: return "Entry"
        case .beforeTimers: return "BeforeTimers"
        case .beforeSources: return "BeforeSources"
        case .beforeWaiting: return "BeforeWaiting"
        case .afterWaiting: return "AfterWaiting"
        case .exit: return "Exit"
        default: return "Unknown"
        }
    }
}
