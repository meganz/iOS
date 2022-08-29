
import Network
import MEGADomain

public final class NetworkMonitorRepository: NetworkMonitorRepositoryProtocol {
    private let monitor: NWPathMonitor
    private let queue: DispatchQueue
    private var pathStatus: NWPath.Status
    
    public init(monitor: NWPathMonitor = NWPathMonitor(), queue: DispatchQueue = DispatchQueue(label: "NetworkMonitor")) {
        self.monitor = monitor
        self.queue = queue
        pathStatus = monitor.currentPath.status
        monitor.start(queue: queue)
    }
    
    deinit {
        monitor.cancel()
    }
    
    public func networkPathChanged(completion: @escaping (Bool) -> Void) {
        if pathStatus == .unsatisfied && monitor.currentPath.status == .satisfied {
            pathStatus = monitor.currentPath.status
        }
        monitor.pathUpdateHandler =  { [weak self] path in
            if self?.pathStatus != path.status {
                self?.pathStatus = path.status
                DispatchQueue.main.async {
                    completion(path.status == .satisfied)
                }
            }
        }
    }
    
    public func isConnected() -> Bool {
        monitor.currentPath.status == .satisfied
    }
}
