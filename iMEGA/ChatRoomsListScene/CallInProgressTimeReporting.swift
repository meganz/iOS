import Combine
import MEGADomain

protocol CallInProgressTimeReporting: AnyObject {
    var callDurationTotal: TimeInterval? { get set }
    var callDurationCapturedTime: TimeInterval? { get set }
    var timerSubscription: AnyCancellable? { get set }
    var totalCallDuration: TimeInterval { get set }
}

extension CallInProgressTimeReporting {
    func configureCallInProgress(for call: CallEntity) {
        guard call.duration > 0 else {
            timerSubscription?.cancel()
            timerSubscription = nil
            return
        }
        
        callDurationTotal = TimeInterval(call.duration)
        callDurationCapturedTime = Date().timeIntervalSince1970
        
        populateTotalCallDuration()
        
        timerSubscription?.cancel()
        timerSubscription = Timer
            .publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.populateTotalCallDuration()
            }
    }
    
    private func populateTotalCallDuration() {
        guard let callDurationTotal = callDurationTotal,
              let callDurationCapturedTime = callDurationCapturedTime else {
            return
        }
        
        totalCallDuration = Date().timeIntervalSince1970 - callDurationCapturedTime + callDurationTotal
    }
}
