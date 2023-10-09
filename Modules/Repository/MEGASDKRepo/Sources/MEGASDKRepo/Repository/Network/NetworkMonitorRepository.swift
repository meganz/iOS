import Foundation
import MEGADomain
import Network

public final class NetworkMonitorRepository: NetworkMonitorRepositoryProtocol {
    public static var newRepo: NetworkMonitorRepository {
        NetworkMonitorRepository()
    }
    
    private let monitor: NWPathMonitor
    private let queue: DispatchQueue
    private let (connectionChangedSourceStream, connectionContinuation) = AsyncStream
        .makeStream(of: Bool.self, bufferingPolicy: .bufferingNewest(1))
    private var networkPathChangedHandler: ((Bool) -> Void)?
    
    public var connectionChangedStream: AsyncStream<Bool> {
        connectionChangedSourceStream
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
            connectionContinuation.yield(isConnected)
            networkPathChangedHandler?(isConnected)
        }
        monitor.start(queue: queue)
    }
}
