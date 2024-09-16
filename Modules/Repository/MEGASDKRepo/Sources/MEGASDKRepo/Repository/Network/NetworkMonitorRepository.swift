import Foundation
import MEGADomain
import MEGASwift
import Network

public final class NetworkMonitorRepository: NetworkMonitorRepositoryProtocol, Sendable {
    public static var newRepo: NetworkMonitorRepository {
        NetworkMonitorRepository()
    }
    public var connectionSequence: AnyAsyncSequence<Bool> {
        monitor
            .networkPathStream
            .map { $0.networkStatus == .satisfied }
            .removeDuplicates()
            .eraseToAnyAsyncSequence()
    }
    
    private let monitor: NetworkMonitor
    
    public init(monitor: NetworkMonitor = NWPathMonitorWrapper()) {
        self.monitor = monitor
    }
    
    deinit {
        monitor.cancel()
    }
    
    public func isConnected() -> Bool {
        monitor.currentPath.networkStatus == .satisfied
    }
    
    public func isConnectedViaWiFi() -> Bool {
        guard let wifiInterface = monitor.currentPath.availableNetworkInterfaces.first(where: { $0.interfaceType == .wifi }) else {
            return false
        }
        return monitor.currentPath.usesNetworkInterfaceType(wifiInterface.interfaceType)
    }
}
