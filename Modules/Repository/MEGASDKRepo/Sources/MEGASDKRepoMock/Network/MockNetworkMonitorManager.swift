import MEGASDKRepo
import MEGASwift
import Network

final public class MockNetworkMonitorManager: NetworkMonitorManaging, @unchecked Sendable {
    public var isStarted = false
    public var currentNetworkPath: any NetworkPath
    private var continuation: AsyncStream<any NetworkPath>.Continuation?
    private let stream: AsyncStream<any NetworkPath>

    public init(currentPath: some NetworkPath) {
        self.currentNetworkPath = currentPath
        (stream, continuation) = AsyncStream<any NetworkPath>.makeStream()
    }

    public func simulatePathUpdate(newPath: any NetworkPath) {
        currentNetworkPath = newPath
        continuation?.yield(newPath)
    }

    public var networkPathStream: AsyncStream<any NetworkPath> {
        stream
    }
}
