
import Network
import MEGADomain

final class NetworkMonitorRepository: NetworkMonitorRepositoryProtocol {
    private let monitor: NWPathMonitor
    private let queue: DispatchQueue
    private var pathStatus: NWPath.Status
    
    init(monitor: NWPathMonitor = NWPathMonitor(), queue: DispatchQueue = DispatchQueue(label: "NetworkMonitor")) {
        self.monitor = monitor
        self.queue = queue
        pathStatus = monitor.currentPath.status
        monitor.start(queue: queue)
    }
    
    deinit {
        monitor.cancel()
    }
    
    func networkPathChanged(completion: @escaping (Bool) -> Void) {
        monitor.pathUpdateHandler =  { [weak self] path in
            if self?.pathStatus != path.status {
                self?.pathStatus = path.status
                DispatchQueue.main.async {
                    completion(path.status == .satisfied)
                }
            }
        }
    }
}
