public protocol RecentlyOpenedNodesMEGAStoreProtocol: Sendable {
    func fetchRecentlyOpenedNodes() async throws -> [RecentlyOpenedNodeRepositoryDTO]
    func clearRecentlyOpenedNodes() async throws
    func insertOrUpdateMediaDestination(fingerprint: String, destination: Int, timescale: Int?)
}
