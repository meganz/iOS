import Foundation

public protocol FileSearchRepositoryProtocol: RepositoryProtocol {
    func allPhotos() async throws -> [NodeEntity]
    func allVideos() async throws -> [NodeEntity]
    func startMonitoringNodesUpdate(callback: @escaping ([NodeEntity]) -> Void)
    func stopMonitoringNodesUpdate()
    func fetchNode(by id: HandleEntity) async -> NodeEntity?
}
