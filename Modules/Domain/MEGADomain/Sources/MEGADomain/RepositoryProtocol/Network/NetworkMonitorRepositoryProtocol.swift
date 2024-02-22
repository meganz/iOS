import MEGASwift

public protocol NetworkMonitorRepositoryProtocol: RepositoryProtocol {
    /// Infinite `AnyAsyncSequence` returning results from network path monitoring
    ///
    /// The stream will finish when repository instance is deallocated
    /// - Returns: `AnyAsyncSequence<Bool>` whether the connection is satisfied
    var connectionChangedStream: AnyAsyncSequence<Bool> { get }
    func networkPathChanged(completion: @escaping (Bool) -> Void)
    func isConnected() -> Bool
    func isConnectedViaWiFi() -> Bool
}
