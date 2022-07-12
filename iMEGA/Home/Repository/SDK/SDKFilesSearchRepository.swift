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
    
    private let cancelToken: MEGACancelToken
    
    init(sdk: MEGASdk) {
        self.sdk = sdk
        cancelToken = MEGACancelToken()
    }
    
    // MARK: - Protocols
    
    func search(string: String?,
                inNode node: MEGANode?,
                sortOrderType: MEGASortOrderType,
                formatType: MEGANodeFormatType) async throws -> [MEGANode] {
        try await withCheckedThrowingContinuation({ continuation in
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
        
        let searchOperation = SearchOperation(
            parentNode: inNode,
            text: string,
            cancelToken: cancelToken,
            sortOrderType: sortOrderType,
            nodeFormatType: formatType,
            completion: completionBlock)
        
        searchOperationQueue.addOperation(searchOperation)
    }
    
    func cancelSearch() {
        if searchOperationQueue.operationCount > 0 {
            cancelToken.cancel()
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
        
        let searchOperation = SearchOperation(parentNode: inNode,
                                              text: string ?? "",
                                              cancelToken: cancelToken,
                                              sortOrderType: sortOrderType,
                                              nodeFormatType: formatType,
                                              completion: completionBlock)
        
        searchOperationQueue.addOperation(searchOperation)
    }
}
