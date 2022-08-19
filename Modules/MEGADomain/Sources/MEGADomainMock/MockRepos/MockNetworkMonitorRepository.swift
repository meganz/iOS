import MEGADomain

public struct MockNetworkMonitorRepository: NetworkMonitorRepositoryProtocol {
    
    public var connected: Bool
    
    public init(connected: Bool = false) {
        self.connected = connected
    }
    
    public func networkPathChanged(completion: @escaping (Bool) -> Void) {
        completion(connected)
    }
}
