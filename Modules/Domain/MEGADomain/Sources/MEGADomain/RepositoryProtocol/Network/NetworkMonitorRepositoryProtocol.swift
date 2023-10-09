public protocol NetworkMonitorRepositoryProtocol: RepositoryProtocol {
    /// Infinite `AsyncStream` returning results from network path monitoring
    ///
    /// The stream will finish when repository instance is deallocated
    /// - Returns: `AsyncStream` whether the connection is satisfied
    var connectionChangedStream: AsyncStream<Bool> { get }
    func networkPathChanged(completion: @escaping (Bool) -> Void)
    func isConnected() -> Bool
}
