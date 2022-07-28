protocol FilesSearchRepositoryProtocol: RepositoryProtocol {
    func search(string: String?,
                inNode node: MEGANode?,
                sortOrderType: MEGASortOrderType,
                formatType: MEGANodeFormatType,
                completionBlock: @escaping ([MEGANode]?, Bool) -> Void)
    
    func search(string: String?,
                inNode node: MEGANode?,
                sortOrderType: MEGASortOrderType,
                formatType: MEGANodeFormatType) async throws -> [MEGANode]
    
    func cancelSearch()
}

final class SDKFilesSearchRepository: FilesSearchRepositoryProtocol {
    static var newRepo: SDKFilesSearchRepository {
        SDKFilesSearchRepository(sdk: MEGASdkManager.sharedMEGASdk())
    }
    
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
                formatType: MEGANodeFormatType) async throws -> [MEGANode] {
        return try await withCheckedThrowingContinuation({ continuation in
            search(string: string, inNode: node, sortOrderType: sortOrderType, formatType: formatType) {
                continuation.resume(with: $0)
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
        
        addSearchOperation(string: string, inNode: inNode, sortOrderType: sortOrderType, formatType: formatType, completionBlock: completionBlock)
    }
    
    func cancelSearch() {
        if searchOperationQueue.operationCount > 0 {
            cancelToken?.cancel()
            searchOperationQueue.cancelAllOperations()
        }
    }
    
    // MARK: - Private
    
    private func search(string: String?,
                        inNode node: MEGANode?,
                        sortOrderType: MEGASortOrderType,
                        formatType: MEGANodeFormatType,
                        completionBlock: @escaping (Result<[MEGANode], Error>) -> Void) {
        
        guard let inNode = node ?? sdk.rootNode else {
            return completionBlock(.failure(NodeSearchResultErrorEntity.noDataAvailable))
        }
        
        addSearchOperation(string: string, inNode: inNode, sortOrderType: sortOrderType, formatType: formatType) { nodes, fail in
            completionBlock(fail ? .failure(NodeSearchResultErrorEntity.noDataAvailable) : .success(nodes ?? []))
        }
    }
    
    private func addSearchOperation(string: String?, inNode: MEGANode, sortOrderType: MEGASortOrderType, formatType: MEGANodeFormatType, completionBlock: @escaping ([MEGANode]?, Bool) -> Void) {
        cancelToken = MEGACancelToken()
        
        if let cancelToken = cancelToken {
            let searchOperation = SearchOperation(parentNode: inNode,
                                                  text: string ?? "",
                                                  cancelToken: cancelToken,
                                                  sortOrderType: sortOrderType,
                                                  nodeFormatType: formatType,
                                                  completion: completionBlock)
            
            searchOperationQueue.addOperation(searchOperation)
        }
    }
}
