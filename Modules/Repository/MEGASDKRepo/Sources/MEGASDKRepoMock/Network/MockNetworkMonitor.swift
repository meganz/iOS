import MEGASDKRepo
import MEGASwift
import Network

final public class MockNetworkMonitor: NetworkMonitor, @unchecked Sendable {
    public var isStarted = false
    public var currentPath: NetworkPath
    private var continuation: AsyncStream<NetworkPath>.Continuation?
    private let stream: AsyncStream<NetworkPath>

    public init(currentPath: NetworkPath) {
        self.currentPath = currentPath
        (stream, continuation) = AsyncStream<NetworkPath>.makeStream()
    }

    public func start() {
        isStarted = true
    }

    public func cancel() {
        isStarted = false
        continuation?.finish()
    }

    public func simulatePathUpdate(newPath: NetworkPath) {
        guard isStarted else { return }
        currentPath = newPath
        continuation?.yield(newPath)
    }

    public var networkPathStream: AsyncStream<NetworkPath> {
        stream
    }
}
