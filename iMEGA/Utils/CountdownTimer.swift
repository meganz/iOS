import Combine

@objc class CountdownTimer: NSObject {
    private(set) var timerCancellable: AnyCancellable?
    
    func startCountdown(seconds: Int, interval: TimeInterval = 1.0, completionHandler: @escaping (Int) -> Void) {
        var remainingSeconds = seconds
        
        timerCancellable = Timer.publish(every: interval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                completionHandler(remainingSeconds)
                
                guard remainingSeconds > 0 else {
                    stopCountdown()
                    return
                }
                remainingSeconds -= 1
            }
    }
    
    func stopCountdown() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }
}
