import Foundation

@objc public final class Throttler: NSObject {
    private var dispatchQueue: DispatchQueue
    private var dispatchWork: DispatchWorkItem?
    private let workQueue = DispatchQueue(label: "ThrottlerWorkQueue")

    private var previousScheduled: DispatchTime?

    private var lastExecutionTime: DispatchTime?

    private var waitingForPerform: Bool = false

    private var timeInterval: TimeInterval
    
    @objc public init(timeInterval: TimeInterval, dispatchQueue: DispatchQueue) {
        self.timeInterval = timeInterval
        self.dispatchQueue = dispatchQueue
    }
    
    @objc public func start(action: @escaping () -> Void) {
        workQueue.async {
            self.dispatchWork?.cancel()
            let dispatchWork = DispatchWorkItem { [weak self] in
                self?.lastExecutionTime = .now()
                self?.waitingForPerform = false
                action()
            }
            
            self.dispatchWork = dispatchWork
            let (now, dispatchTime) = self.evaluateDispatchTime()
            self.previousScheduled = now
            self.waitingForPerform = true
            
            self.dispatchQueue.asyncAfter(deadline: dispatchTime, execute: dispatchWork)
        }
    }
    
    private func evaluateDispatchTime() -> (now: DispatchTime, evaluated: DispatchTime) {
        let now: DispatchTime = .now()
        
        if let lastExecutionTime = self.lastExecutionTime {
            let evaluatedTime = (lastExecutionTime + self.timeInterval)
            if evaluatedTime > now {
                return (now, evaluatedTime)
            }
        }
        
        guard self.waitingForPerform else {
            return ((now, (now + self.timeInterval)))
        }
        
        if let previousScheduled = self.previousScheduled, previousScheduled > now {
            return (now, previousScheduled)
        }
        return (now, now)
    }
}
