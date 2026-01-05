import Foundation

final class APMHangMonitor: APMMetricMonitor, @unchecked Sendable {
    let detectInterval: TimeInterval = 0.25 // the minimal interval of a potential hang could be detected
    let hangReportingThreshold: TimeInterval = 9.0   // the longest interval before reporting a hang
    let semaphore = DispatchSemaphore(value: 0)
    let metricsReporter: any APMMetricsReporter
    let reportQueue: DispatchQueue
    let threshold: TimeInterval // the minimal mainthread unresponsiveness interval which is deemed as a real hang
    
    private(set) var isMonitoring = false
    
    private var consecutiveTimeoutCount: UInt = 0
    private var isHangFiredForCurConsecutiveTimeout: Bool = false
    private var hangMetrics: APMHangMetrics?
    private var consecutiveHangTime: TimeInterval {
        Double(consecutiveTimeoutCount) * detectInterval
    }
    private var isHangStartedInForeground: Bool = true
    
    private var observer: CFRunLoopObserver?
    private var monitorThread: Thread?
    private var currentActivity: CFRunLoopActivity = []
    
    init(config: APMHangConfiguration,
         metricsReporter: some APMMetricsReporter,
         reportQueue: DispatchQueue = APMKit.queue) {
        self.threshold = config.threshold
        self.metricsReporter = metricsReporter
        self.reportQueue = reportQueue
    }
    
    deinit {
        stop()
    }
    
    // MARK: - APMMonitorProtocol
    func start() {
        guard !isMonitoring else { return }
        
    #if arch(arm64)
        isMonitoring = true
        addRunLoopObserver()
        startMonitorThread()
    #else
        assert(false, "arch not supported")
        return
    #endif
    }
    
    func stop() {
        guard isMonitoring else { return }
        isMonitoring = false
        removeRunLoopObserver()
        monitorThread?.cancel()
        monitorThread = nil
    }
    
    // MARK: - RunLoop Observer
    private func addRunLoopObserver() {
        let activities: CFRunLoopActivity = [.entry, .beforeTimers, .beforeSources, .beforeWaiting, .afterWaiting, .exit]
        let obs = CFRunLoopObserverCreateWithHandler(kCFAllocatorDefault,
                                                      activities.rawValue,
                                                      true,
                                                      0) { [weak self] _, activity in
            guard let self else {
                return
            }
            self.handleRunLoopActivity(activity)
        }
        
        CFRunLoopAddObserver(CFRunLoopGetMain(), obs, .commonModes)
        observer = obs
    }
    
    private func handleRunLoopActivity(_ activity: CFRunLoopActivity) {
        currentActivity = activity
        semaphore.signal()
    }
    
    private func removeRunLoopObserver() {
        if let observer = observer {
            CFRunLoopRemoveObserver(CFRunLoopGetMain(), observer, .commonModes)
            self.observer = nil
        }
    }
    
    // MARK: - Monitor Thread
    private func startMonitorThread() {
        monitorThread = Thread { [weak self] in
            guard let self = self else { return }
            
            Thread.current.name = "HangMonitor"
            while self.isMonitoring {
                autoreleasepool {
                    let start = DispatchTime.now()
                    let result = self.semaphore.wait(timeout: .now() + self.detectInterval)
                    
                    // If timeout, main thread might be stalled
                    if result == .timedOut {
                        if [.beforeSources, .afterWaiting, .beforeTimers].contains(currentActivity) {
                            if consecutiveTimeoutCount == 0 {
                                isHangStartedInForeground = APMKit.appStateHolder.isInForeground
                            }
                            consecutiveTimeoutCount += 1
                            if !isHangFiredForCurConsecutiveTimeout {
                                createHangMetricsIfNeeded()
                            }
                            if consecutiveHangTime >= threshold {
                                captureStackIfNeeded()
                            }
                            if consecutiveHangTime >= hangReportingThreshold, !isHangFiredForCurConsecutiveTimeout {
                                emitHangEvent(activity: currentActivity, duration: hangReportingThreshold)
                            }
                        } else {
                            resetConsecutiveInfo()
                        }
                    } else {
                        if self.consecutiveTimeoutCount > 0 {
                            let diff = start.distance(to: DispatchTime.now())
                            let totalHangTime = diff.timeInterval + consecutiveHangTime
                            if totalHangTime >= threshold, !isHangFiredForCurConsecutiveTimeout {
                                emitHangEvent(activity: currentActivity, duration: totalHangTime)
                            }
                        }
                        resetConsecutiveInfo()
                    }
                }
            }
        }
        
        monitorThread?.start()
    }
    
    // MARK: trigger capture stack
    private func createHangMetricsIfNeeded() {
        guard hangMetrics == nil else { return }
        
        hangMetrics = APMHangMetrics(threshold: threshold)
    }
    
    private func captureStackIfNeeded() {
        guard let hangMetrics, hangMetrics.capturedStack.count == 0 else { return }
        
        var stack: [UInt64]?
#if arch(arm64)
        stack = APMThreadCallStack.captureMainThreadStack()
#endif
        if let stack {
            self.hangMetrics?.capturedStack = stack
        }
    }
    
    // MARK: fireEvent
    public func emitHangEvent(
        activity: CFRunLoopActivity,
        duration: TimeInterval
    ) {
        captureStackIfNeeded()
        isHangFiredForCurConsecutiveTimeout = true
        
        guard var hangMetrics else {
            return
        }
        
        hangMetrics.hangDuration = duration
        hangMetrics.runloopActivity = activity
        hangMetrics.deviceLocale = Locale.preferredLanguages.first
        let reporterMetrics = hangMetrics
        self.hangMetrics = nil
        
        guard isHangStartedInForeground else { return }
        
        reportQueue.async {
            self.metricsReporter.report(hangMetrics: reporterMetrics)
        }
    }
    
    private func resetConsecutiveInfo() {
        consecutiveTimeoutCount = 0
        hangMetrics = nil
        isHangFiredForCurConsecutiveTimeout = false
    }
}

extension DispatchTimeInterval {
    var timeInterval: TimeInterval {
        switch self {
        case .seconds(let s):       return TimeInterval(s)
        case .milliseconds(let ms): return TimeInterval(ms) / 1_000
        case .microseconds(let us): return TimeInterval(us) / 1_000_000
        case .nanoseconds(let ns):  return TimeInterval(ns) / 1_000_000_000
        case .never:                return .infinity
        @unknown default:           return 0
        }
    }
}
