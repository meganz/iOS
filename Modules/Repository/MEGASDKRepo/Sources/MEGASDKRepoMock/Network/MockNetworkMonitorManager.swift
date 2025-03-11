import MEGASDKRepo
import MEGASwift
import Network

final public class MockNetworkMonitorManager: NetworkMonitorManaging, @unchecked Sendable {
    public var isStarted = false
    public var currentNetworkPath: NetworkPath
    private var continuation: AsyncStream<NetworkPath>.Continuation?
    private let stream: AsyncStream<NetworkPath>

    public init(currentPath: NetworkPath) {
        self.currentNetworkPath = currentPath
        (stream, continuation) = AsyncStream<NetworkPath>.makeStream()
    }

    public func simulatePathUpdate(newPath: NetworkPath) {
        currentNetworkPath = newPath
        continuation?.yield(newPath)
    }

    public var networkPathStream: AsyncStream<NetworkPath> {
        stream
    }
}
