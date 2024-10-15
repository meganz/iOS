import Foundation

public protocol RecentlyOpenedNodesMEGAStoreProtocol: Sendable {
    func fetchRecentlyOpenedNodes() async throws -> [RecentlyOpenedNodeRepositoryDTO]
    func clearRecentlyOpenedNodes() async throws
    func insertOrUpdateRecentlyOpenedNode(fingerprint: String, destination: Int, timescale: Int?, lastOpenedDate: Date)
}
