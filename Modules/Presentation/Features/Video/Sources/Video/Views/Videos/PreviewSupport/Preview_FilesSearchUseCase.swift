import MEGADomain

struct Preview_FilesSearchUseCase: FilesSearchUseCaseProtocol {
    func search(string: String?, parent node: NodeEntity?, recursive: Bool, supportCancel: Bool, sortOrderType: SortOrderEntity, cancelPreviousSearchIfNeeded: Bool, completion: @escaping ([NodeEntity]?, Bool) -> Void) {
        completion([ NodeEntity.preview ], false)
    }
    
    func search(string: String?, parent node: NodeEntity?, recursive: Bool, supportCancel: Bool, sortOrderType: SortOrderEntity, formatType: NodeFormatEntity, cancelPreviousSearchIfNeeded: Bool) async throws -> [NodeEntity] {
        []
    }
    
    func onNodesUpdate(with nodesUpdateHandler: @escaping ([NodeEntity]) -> Void) {
        nodesUpdateHandler([])
    }
}
