import MEGADomain

final class SharedItemsSearchOperation: MEGAOperation {
    private let sdk: MEGASdk
    private let type: SearchNodeTypeEntity
    private let text: String
    private let cancelToken: MEGACancelToken
    private let sortType: SortOrderEntity
    private let completion: (Result<[NodeEntity], Error>) -> Void
    
    init(sdk: MEGASdk, type: SearchNodeTypeEntity, text: String, cancelToken: MEGACancelToken, sortType: SortOrderEntity, completion: @escaping (Result<[NodeEntity], Error>) -> Void) {
        self.sdk = sdk
        self.type = type
        self.text = text
        self.cancelToken = cancelToken
        self.sortType = sortType
        self.completion = completion
    }
    
    override func start() {
        guard !isCancelled else {
            finishOperation(nodes: nil, error: NodeSearchResultErrorEntity.cancelled)
            return
        }
        
        startExecuting()
        startSearching()
    }
    
    private func startSearching() {
        var searchRequest: (String, MEGACancelToken, MEGASortOrderType) -> MEGANodeList
        switch type {
        case .inShares:
            searchRequest = sdk.nodeListSearchOnInShares
        case .outShares:
            searchRequest = sdk.nodeListSearchOnOutShares
        case .publicLinks:
            searchRequest = sdk.nodeListSearchOnPublicLinks
        }
        
        let nodeList = searchRequest(text, MEGACancelToken(), sortType.toMEGASortOrderType())
        finishOperation(nodes: nodeList.toNodeEntities(), error: nil)
    }
    
    private func finishOperation(nodes: [NodeEntity]?, error: Error?) {
        if let error {
            completion(.failure(error))
        } else {
            completion(.success(nodes ?? []))
        }
    }
}
