import CallKit

class MockCXProvider: CXProvider {
    override init(configuration: CXProviderConfiguration) {
        super.init(configuration: configuration)
    }
    override func setDelegate(_ delegate: (any CXProviderDelegate)?, queue: dispatch_queue_t?) { /* not used */ }
    
    var reportNewIncomingCalls = [UUID]()
    override func reportNewIncomingCall(with UUID: UUID, update: CXCallUpdate, completion: @escaping ((any Error)?) -> Void) {
        reportNewIncomingCalls.append(UUID)
        completion(nil)
    }
    
    override func reportCall(with UUID: UUID, updated update: CXCallUpdate) { /* not used */ }
    
    override func reportCall(with UUID: UUID, endedAt dateEnded: Date?, reason endedReason: CXCallEndedReason) { /* not used */ }
    
    override func reportOutgoingCall(with UUID: UUID, startedConnectingAt dateStartedConnecting: Date?) { /* not used */ }
    
    override func reportOutgoingCall(with UUID: UUID, connectedAt dateConnected: Date?) { /* not used */ }
    
    override func invalidate() { /* not used */ }
    
    override func pendingCallActions(of callActionClass: AnyClass, withCall callUUID: UUID) -> [CXCallAction] { [] }
}
