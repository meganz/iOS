import Foundation
import MEGADomain
import MEGASwift
import Network

public final class NetworkMonitorRepository: NetworkMonitorRepositoryProtocol, Sendable {
    public static var newRepo: NetworkMonitorRepository {
        NetworkMonitorRepository(monitor: NetworkMonitorManager.shared)
    }
    public var connectionSequence: AnyAsyncSequence<Bool> {
        monitor
            .networkPathStream
            .map { $0.networkStatus == .satisfied }
            .removeDuplicates()
            .eraseToAnyAsyncSequence()
    }
    
    private let monitor: any NetworkMonitorManaging

    public init(monitor: some NetworkMonitorManaging) {
        self.monitor = monitor
    }

    public func isConnected() -> Bool {
        monitor.currentNetworkPath.networkStatus == .satisfied
    }
    
    public func isConnectedViaWiFi() -> Bool {
        guard let wifiInterface = monitor.currentNetworkPath.availableNetworkInterfaces.first(where: { $0.interfaceType == .wifi }) else {
            return false
        }
        return monitor.currentNetworkPath.usesNetworkInterfaceType(wifiInterface.interfaceType)
    }
}
