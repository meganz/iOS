import Foundation

public protocol FileSearchRepositoryProtocol: RepositoryProtocol {
    func allPhotos() async throws -> [NodeEntity]
    func startMonitoringNodesUpdate(callback: @escaping ([NodeEntity]) -> Void)
    func stopMonitoringNodesUpdate()
}
