
public protocol SearchNodeRepositoryProtocol: RepositoryProtocol {
    func search(type: SearchNodeTypeEntity, text: String, sortType: SortOrderEntity) async throws -> [NodeEntity]
    func cancelSearch()
}
