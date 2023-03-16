import Foundation
import MEGADomain

struct SearchNodeRepository: SearchNodeRepositoryProtocol {
    static var newRepo: SearchNodeRepository {
        SearchNodeRepository(sdk: MEGASdk.shared)
    }
    
    private let sdk: MEGASdk
    private let searchQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.qualityOfService = .userInteractive
        queue.maxConcurrentOperationCount = OperationQueue.defaultMaxConcurrentOperationCount
        return queue
    }()
    
    init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
    func search(type: SearchNodeTypeEntity, text: String, sortType: SortOrderEntity) async throws -> [NodeEntity] {
        return try await withCheckedThrowingContinuation { continuation in
            guard Task.isCancelled == false else {
                continuation.resume(throwing: CancellationError())
                return
            }
            
            let searchOperation = SharedItemsSearchOperation(sdk: sdk, type: type, text: text, cancelToken: MEGACancelToken(), sortType: sortType) { result in
                guard Task.isCancelled == false else {
                    continuation.resume(throwing: CancellationError())
                    return
                }
                switch result {
                case .success(let nodeEntities):
                    continuation.resume(returning: nodeEntities)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            searchQueue.addOperation(searchOperation)
        }
    }
    
    func cancelSearch() {
        guard searchQueue.operationCount > 0 else { return }
        
        searchQueue.cancelAllOperations()
    }
}
