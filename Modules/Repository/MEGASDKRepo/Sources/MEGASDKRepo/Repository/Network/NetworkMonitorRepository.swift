import Combine
import Foundation
import MEGADomain
import MEGASwift
import Network

public final class NetworkMonitorRepository: NetworkMonitorRepositoryProtocol {
    public static var newRepo: NetworkMonitorRepository {
        NetworkMonitorRepository()
    }
    
    private let monitor: NWPathMonitor
    private let queue: DispatchQueue
    private let isConnectedPassThroughSubject = PassthroughSubject<Bool, Never>()
    private var networkPathChangedHandler: ((Bool) -> Void)?
    
    public var connectionChangedStream: AnyAsyncSequence<Bool> {
        isConnectedPassThroughSubject
            .values
            .eraseToAnyAsyncSequence()
    }
    
    public init(monitor: NWPathMonitor = NWPathMonitor(),
                queue: DispatchQueue = DispatchQueue(label: "NetworkMonitor")) {
        self.monitor = monitor
        self.queue = queue
        startMonitoring()
    }
    
    deinit {
        monitor.cancel()
    }
    
    public func networkPathChanged(completion: @escaping (Bool) -> Void) {
        networkPathChangedHandler = completion
    }
    
    public func isConnected() -> Bool {
        monitor.currentPath.status == .satisfied
    }
    
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] in
            guard let self else { return }
            let isConnected = $0.status == .satisfied
            isConnectedPassThroughSubject.send(isConnected)
            networkPathChangedHandler?(isConnected)
        }
        monitor.start(queue: queue)
    }
    
    public func isConnectedViaWiFi() -> Bool {
        guard let wifiInterface = monitor.currentPath.availableInterfaces.first(where: { $0.type == .wifi }) else {
            return false
        }
        return monitor.currentPath.usesInterfaceType(wifiInterface.type)
    }
}
