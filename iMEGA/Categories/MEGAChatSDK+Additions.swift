
extension MEGAChatSdk {
    @objc var mnz_existsActiveCall: Bool {
        return ((self.chatCalls(withState: .undefined)?.size ?? 0) - (self.chatCalls(withState: .userNoPresent)?.size ?? 0)) > 0 ? true : false
    }
}
