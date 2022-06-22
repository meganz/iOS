protocol FilesSearchRepositoryProtocol {
    func search(string: String?,
                inNode node: MEGANode?,
                sortOrderType: MEGASortOrderType,
                formatType: MEGANodeFormatType,
                completionBlock: @escaping ([MEGANode]?, Bool) -> Void)
    
    func search(string: String?,
                inNode node: MEGANode?,
                sortOrderType: MEGASortOrderType,
                formatType: MEGANodeFormatType) async throws -> [MEGANode]?
    
    func cancelSearch()
}

final class SDKFilesSearchRepository: FilesSearchRepositoryProtocol {
    private let sdk: MEGASdk
    
    private lazy var searchOperationQueue: OperationQueue = {
        let operationQueue = OperationQueue()
        operationQueue.qualityOfService = .userInteractive
        return operationQueue
    }()
    
    private var cancelToken: MEGACancelToken?
    
    init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
    // MARK: - Protocols
    
    func search(string: String?,
                inNode node: MEGANode?,
                sortOrderType: MEGASortOrderType,
                formatType: MEGANodeFormatType) async throws -> [MEGANode]? {
        try await withCheckedThrowingContinuation({ continuation in
            search(string: string, inNode: node, sortOrderType: sortOrderType, formatType: formatType) { results, fail in
                guard Task.isCancelled == false
                else {
                    continuation.resume(throwing: CancellationError())
                    return
                }
                
                if fail {
                    continuation.resume(throwing: NodeSearchResultErrorEntity.noDataAvailable)
                } else {
                    continuation.resume(returning: results)
                }
            }
        })
    }
    
    func search(string: String?,
                inNode node: MEGANode?,
                sortOrderType: MEGASortOrderType,
                formatType: MEGANodeFormatType,
                completionBlock: @escaping ([MEGANode]?, Bool) -> Void) {
        
        guard let inNode = node ?? sdk.rootNode else {
            return completionBlock(nil, true)
        }
        
        cancelToken = MEGACancelToken()
        
        let searchOperation = SearchOperation(
            parentNode: inNode,
            text: string,
            cancelToken: cancelToken!,
            sortOrderType: sortOrderType,
            nodeFormatType: formatType,
            completion: completionBlock)
        
        searchOperationQueue.addOperation(searchOperation)
    }
    
    func cancelSearch() {
        if searchOperationQueue.operationCount > 0 {
            cancelToken?.cancel(withNewValue: true)
            searchOperationQueue.cancelAllOperations()
        }
    }
}

extension SDKFilesSearchRepository {
    static let `default` = SDKFilesSearchRepository(sdk: MEGASdkManager.sharedMEGASdk())
}
