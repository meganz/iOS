import MEGADomain

/// Define methods to coordinate call actions from CallManagerProtocol
/// When manager triggers an action and it is performed by a provider (CallKit basically, but simulator should manage it in different way),
///  the coordinator implementation will execute the corresponding event in the ChatSDK (start, mute, end call...)
protocol CallsCoordinatorProtocol: AnyObject, Sendable {
    func startCall(_ callActionSync: CallActionSync) async -> Bool
    func answerCall(_ callActionSync: CallActionSync) async -> Bool
    func endCall(_ callActionSync: CallActionSync) async -> Bool
    func muteCall(_ callActionSync: CallActionSync) async -> Bool
    func reportIncomingCall(in chatId: ChatIdEntity, completion: @escaping () -> Void)
    func reportEndCall(_ call: CallEntity)
    func disablePassCodeIfNeeded()
    func configureWebRTCAudioSession()
    var incomingCallForUnknownChat: IncomingCallForUnknownChat? { get set }
}
