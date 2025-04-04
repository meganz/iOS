import Foundation
import MEGASwift
import Network

public protocol NetworkMonitorManaging: Sendable {
    var currentNetworkPath: any NetworkPath { get }
    var networkPathStream: AsyncStream<any NetworkPath> { get }
}

private struct UpdateHandler: Hashable, Sendable {
    private let identifier = UUID()

    let onPathUpdate: @Sendable (any NetworkPath) -> Void
    init(onPathUpdate: @escaping @Sendable (any NetworkPath) -> Void) {
        self.onPathUpdate = onPathUpdate
    }

    static func == (lhs: UpdateHandler, rhs: UpdateHandler) -> Bool {
        return lhs.identifier == rhs.identifier
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }
}

public class NetworkMonitorManager: NetworkMonitorManaging, @unchecked Sendable {
    static let shared = NetworkMonitorManager()

    private let monitor: NWPathMonitor
    @Atomic private var updateHandlers = Set<UpdateHandler>()

    public var currentNetworkPath: any NetworkPath {
        monitor.currentPath
    }
    
    public var networkPathStream: AsyncStream<any NetworkPath> {
        AsyncStream { [weak self] continuation in
            guard let self else { return }
            let handler = UpdateHandler {
                continuation.yield($0)
            }

            self.$updateHandlers.mutate { $0.insert(handler) }

            continuation.onTermination = { @Sendable [weak self] _ in
                self?.$updateHandlers.mutate { $0.remove(handler) }
            }
        }
    }

    private init() {

        self.monitor = .init()
        monitor.start(queue: DispatchQueue(label: "NetworkMonitor"))
        monitor.pathUpdateHandler = { [weak self] path in
            self?.updateHandlers.forEach { $0.onPathUpdate(path) }
        }
    }
}
