@preconcurrency import Combine
import Foundation
import MEGADomain
import MEGASwift
import Network

public final class NetworkMonitorRepository: NetworkMonitorRepositoryProtocol, Sendable {
    public static var newRepo: NetworkMonitorRepository {
        NetworkMonitorRepository()
    }
    
    private let monitor: NWPathMonitor
    private let queue: DispatchQueue
    private let isConnectedPassThroughSubject = PassthroughSubject<Bool, Never>()
    
    public var connectionChangedStream: AnyAsyncSequence<Bool> {
        isConnectedPassThroughSubject
            .values
            .eraseToAnyAsyncSequence()
    }
    
    public var networkPathChangedPublisher: AnyPublisher<Bool, Never> {
        isConnectedPassThroughSubject.eraseToAnyPublisher()
    }
    
    public init(
        monitor: NWPathMonitor = NWPathMonitor(),
        queue: DispatchQueue = DispatchQueue(label: "NetworkMonitor")
    ) {
        self.monitor = monitor
        self.queue = queue
        startMonitoring()
    }
    
    deinit {
        monitor.cancel()
    }
    
    public func isConnected() -> Bool {
        monitor.currentPath.status == .satisfied
    }
    
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            let isConnected = path.status == .satisfied
            self.isConnectedPassThroughSubject.send(isConnected)
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
