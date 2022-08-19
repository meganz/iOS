import MEGADomain

public struct MockNetworkMonitorUseCase: NetworkMonitorUseCaseProtocol {
    
    public var connected: Bool
    
    public init(connected: Bool = false) {
        self.connected = connected
    }
    
    public func networkPathChanged(completion: @escaping (Bool) -> Void) {
        completion(connected)
    }
}
