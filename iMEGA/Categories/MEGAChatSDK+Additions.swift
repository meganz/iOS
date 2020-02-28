
extension MEGAChatSdk {
    @objc var mnz_existsActiveCall: Bool {
        return self.chatCalls(withState: .inProgress)?.size != 0 || self.chatCalls(withState: .requestSent)?.size != 0 || self.chatCalls(withState: .joining)?.size != 0
    }
}
