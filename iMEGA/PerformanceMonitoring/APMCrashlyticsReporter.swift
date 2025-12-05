import APMKit
import FirebaseCrashlytics
import UIKit

public struct APMCrashlyticsReporter: APMMetricsReporter, Sendable {
    private let crashlytics: any CrashlyticsReporting
    private let reachabilityProvider: @Sendable () -> String
    
    init() {
        self.crashlytics = Crashlytics.crashlytics()
        self.reachabilityProvider = {
            var reachability = "offline"
            if MEGAReachabilityManager.isReachableViaWWAN() {
                reachability = "Cellular"
            } else if MEGAReachabilityManager.isReachableViaWiFi() {
                reachability = "Wi‑Fi"
            }
            return reachability
        }
    }

    init(crashlytics: some CrashlyticsReporting,
         reachabilityProvider: @escaping @Sendable () -> String
    ) {
        self.crashlytics = crashlytics
        self.reachabilityProvider = reachabilityProvider
    }

    public func report(hangMetrics: APMHangMetrics) {
        crashlytics.setCustomValue(hangMetrics.hangDuration.milliseconds, forKey: CrashlyticsKeys.hangDuration)
        crashlytics.setCustomValue(hangMetrics.runloopActivity?.asString ?? "", forKey: CrashlyticsKeys.runloopActivity)
        crashlytics.setCustomValue(hangMetrics.threshold.milliseconds, forKey: CrashlyticsKeys.threshold)
        crashlytics.setCustomValue(hangMetrics.deviceLocale ?? "", forKey: CrashlyticsKeys.deviceLocale)
        crashlytics.setCustomValue(reachabilityProvider(), forKey: CrashlyticsKeys.reachability)
        
        if hangMetrics.capturedStack.isEmpty {
            let error = NSError(
                        domain: "mega.ios.hang",
                        code: 1001,
                        userInfo: [NSLocalizedDescriptionKey: "Hang detected with empty stack captured"]
                    )
            crashlytics.record(error: error)
            return
        }
        
        let stackFrames = hangMetrics.capturedStack.map { address -> StackFrame in
            let frame = StackFrame(address: UInt(address))
            return frame
        }
        
        let reason = "Main thread hang for \(String(format: "%.3f", hangMetrics.hangDuration))s"
        let exceptionModel = ExceptionModel(name: "Hang", reason: reason)
        exceptionModel.stackTrace = stackFrames
        crashlytics.record(exceptionModel: exceptionModel)
    }
}

extension UIApplication.State {
    var asString: String {
        switch self {
        case .active:     return "active"
        case .inactive:   return "inactive"
        case .background: return "background"
        @unknown default: return "unknown"
        }
    }
}

enum CrashlyticsKeys {
    static let hangDuration = "hang.duration_ms"
    static let runloopActivity = "runloop.activity"
    static let threshold = "hang.threshold_ms"
    static let deviceLocale = "device.locale"
    static let reachability = "net.reachability"
}
