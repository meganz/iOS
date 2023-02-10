import Foundation

public protocol FilesSearchRepositoryProtocol: RepositoryProtocol, Sendable {
    func startMonitoringNodesUpdate(callback: @escaping ([NodeEntity]) -> Void)
    func stopMonitoringNodesUpdate()
    func node(by id: HandleEntity) async -> NodeEntity?
    
    func search(string: String?,
                parent node: NodeEntity?,
                sortOrderType: SortOrderEntity,
                formatType: NodeFormatEntity,
                completion: @escaping ([NodeEntity]?, Bool) -> Void)
    
    func search(string: String?,
                parent node: NodeEntity?,
                sortOrderType: SortOrderEntity,
                formatType: NodeFormatEntity) async throws -> [NodeEntity]
    
    func cancelSearch()
}
