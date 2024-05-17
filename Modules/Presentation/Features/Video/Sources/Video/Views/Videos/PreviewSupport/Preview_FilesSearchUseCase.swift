import MEGADomain
import MEGASwift

struct Preview_FilesSearchUseCase: FilesSearchUseCaseProtocol {
    
    func search(filter: SearchFilterEntity, cancelPreviousSearchIfNeeded: Bool, completion: @escaping ([NodeEntity]?, Bool) -> Void) {
        completion([ NodeEntity.preview ], false)
    }
    
    func search(filter: SearchFilterEntity, cancelPreviousSearchIfNeeded: Bool) async throws -> [NodeEntity] {
        []
    }
        
    func onNodesUpdate(with nodesUpdateHandler: @escaping ([NodeEntity]) -> Void) {
        nodesUpdateHandler([])
    }
    
    func stopNodesUpdateListener() { }
    
    func startNodesUpdateListener() { }
    
    var nodeUpdates: AnyAsyncSequence<[NodeEntity]> {
        EmptyAsyncSequence()
            .eraseToAnyAsyncSequence()
    }
}

// MARK: - Deprecated searchApi usage
extension Preview_FilesSearchUseCase {
    func search(string: String?, parent node: NodeEntity?, recursive: Bool, supportCancel: Bool, sortOrderType: SortOrderEntity, cancelPreviousSearchIfNeeded: Bool, completion: @escaping ([NodeEntity]?, Bool) -> Void) {
        completion([ NodeEntity.preview ], false)
    }
    
    func search(string: String?, parent node: NodeEntity?, recursive: Bool, supportCancel: Bool, sortOrderType: SortOrderEntity, formatType: NodeFormatEntity, cancelPreviousSearchIfNeeded: Bool) async throws -> [NodeEntity] {
        []
    }
}
