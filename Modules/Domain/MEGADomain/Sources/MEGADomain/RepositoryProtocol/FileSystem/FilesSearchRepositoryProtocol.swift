import Combine

public protocol FilesSearchRepositoryProtocol: RepositoryProtocol, Sendable {
    var nodeUpdatesPublisher: AnyPublisher<[NodeEntity], Never> { get }
    
    func startMonitoringNodesUpdate(callback: (([NodeEntity]) -> Void)?)
    func stopMonitoringNodesUpdate()
    func node(by id: HandleEntity) async -> NodeEntity?
    
    func search(string: String?,
                parent node: NodeEntity?,
                supportCancel: Bool,
                sortOrderType: SortOrderEntity,
                formatType: NodeFormatEntity,
                completion: @escaping ([NodeEntity]?, Bool) -> Void)
    
    func search(string: String?,
                parent node: NodeEntity?,
                supportCancel: Bool,
                sortOrderType: SortOrderEntity,
                formatType: NodeFormatEntity) async throws -> [NodeEntity]
    
    func cancelSearch()
}
