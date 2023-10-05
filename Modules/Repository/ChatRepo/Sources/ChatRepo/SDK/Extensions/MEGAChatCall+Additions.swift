import MEGAChatSdk

public extension MEGAChatCall {
    var isActiveCall: Bool {
        switch status {
        case .joining, .connecting, .inProgress:
            return true
        default:
            return false
        }
    }
    
    var isCallInProgress: Bool {
        switch status {
        case .userNoPresent, .inProgress:
            return true
        default:
            return false
        }
    }
    
    var isActiveWaitingRoom: Bool {
        switch status {
        case .connecting, .waitingRoom:
            return true
        default:
            return false
        }
    }
}
