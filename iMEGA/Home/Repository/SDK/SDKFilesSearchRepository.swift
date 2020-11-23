

protocol FilesSearchRepositoryProtocol {
    func search(string: String?,
                inNode node: MEGANode?,
                sortOrderType: MEGASortOrderType,
                formatType: MEGANodeFormatType,
                completionBlock: @escaping ([MEGANode]?) -> Void)
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
    
    func search(string: String?,
                inNode node: MEGANode?,
                sortOrderType: MEGASortOrderType,
                formatType: MEGANodeFormatType,
                completionBlock: @escaping ([MEGANode]?) -> Void){
        
        guard let inNode = node ?? sdk.rootNode else {
            return completionBlock(nil)
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

