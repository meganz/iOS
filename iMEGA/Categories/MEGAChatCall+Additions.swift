
extension MEGAChatCall {
    var isActiveCall: Bool {
        switch status {
        case .joining, .connecting, .inProgress:
            return true
        default:
            return false
        }
    }
}
