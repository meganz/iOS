import MEGADomain

public final class MockFilesSearchUseCase: FilesSearchUseCaseProtocol {
    public private(set) var searchCallCount = 0
    public private(set) var onNodesUpdateCallCount = 0
    
    private let searchResult: Result<[NodeEntity]?, FileSearchResultErrorEntity>
    private var onNodesUpdateResult: [NodeEntity]?
    
    private var nodesUpdateHandlers: [([MEGADomain.NodeEntity]) -> Void] = []
    
    public init(
        searchResult: Result<[NodeEntity]?, FileSearchResultErrorEntity>,
        onNodesUpdateResult: [NodeEntity]? = nil
    ) {
        self.searchResult = searchResult
        self.onNodesUpdateResult = onNodesUpdateResult
    }
    
    public func search(string: String?, parent node: NodeEntity?, recursive: Bool, supportCancel: Bool, sortOrderType: SortOrderEntity, cancelPreviousSearchIfNeeded: Bool, completion: @escaping ([NodeEntity]?, Bool) -> Void) {
        searchCallCount += 1
        switch searchResult {
        case .success(let nodes):
            completion(nodes, false)
        case .failure:
            completion(nil, true)
        }
    }
    
    public func onNodesUpdate(with nodesUpdateHandler: @escaping ([MEGADomain.NodeEntity]) -> Void) {
        onNodesUpdateCallCount += 1
        nodesUpdateHandlers.append(nodesUpdateHandler)
    }
    
    public func simulateOnNodesUpdate(with nodes: [NodeEntity], at index: Int = 0) {
        nodesUpdateHandlers[index](nodes)
    }
}
