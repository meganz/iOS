import MEGADomain
import MEGAL10n
import MEGAPresentation
import MEGASdk
import MEGASDKRepo
import MEGASwift
import Search

/// Dedicated actor to isolate loadMore function to prevent data race where multiple cells can trigger loadMore at the same time
@globalActor fileprivate actor LoadMoreActor {
    static var shared = LoadMoreActor()
}

/// abstraction into a search results
final class HomeSearchResultsProvider: SearchResultsProviding {
    
    private let searchFileUseCase: any SearchFileUseCaseProtocol
    private let nodeUseCase: any NodeUseCaseProtocol
    private let mediaUseCase: any MediaUseCaseProtocol
    private let nodeRepository: any NodeRepositoryProtocol
    private var nodesUpdateListenerRepo: any NodesUpdateListenerProtocol
    private var transferListenerRepo: SDKTransferListenerRepository

    private let sdk: MEGASdk

    // We only initially fetch the node list when the user triggers search
    // Concrete nodes are then loaded one by one in the pagination
    private var nodeList: NodeListEntity?
    
    /// Keeps track of how many SearchResult were returned to client's through search queries.
    /// This value plays an important role in pagination and node updates logic: When user query "loadMore" or there are node updates, we use this value incombination with `nodeList` to perform the needed computation.
    private var filledItemsCount = 0
    private var pageSize = 100
    private var loadMorePagesOffset = 20
    private var availableChips: [SearchChipEntity]
    private let onSearchResultUpdated: (SearchResult) -> Void
    
    // The node from which we want start searching from,
    // root node can be nil in case when we start app in offline
    private let parentNodeProvider: () -> NodeEntity?
    private let mapper: SearchResultMapper
    
    init(
        parentNodeProvider: @escaping () -> NodeEntity?,
        searchFileUseCase: some SearchFileUseCaseProtocol,
        nodeDetailUseCase: some NodeDetailUseCaseProtocol,
        nodeUseCase: some NodeUseCaseProtocol,
        mediaUseCase: some MediaUseCaseProtocol,
        nodeRepository: some NodeRepositoryProtocol,
        nodesUpdateListenerRepo: any NodesUpdateListenerProtocol,
        transferListenerRepo: SDKTransferListenerRepository,
        nodeIconUsecase: some NodeIconUsecaseProtocol,
        allChips: [SearchChipEntity],
        sdk: MEGASdk,
        nodeActions: NodeActions,
        onSearchResultUpdated: @escaping (SearchResult) -> Void
    ) {
        self.parentNodeProvider = parentNodeProvider
        self.searchFileUseCase = searchFileUseCase
        self.nodeUseCase = nodeUseCase
        self.mediaUseCase = mediaUseCase
        self.nodeRepository = nodeRepository
        self.nodesUpdateListenerRepo = nodesUpdateListenerRepo
        self.transferListenerRepo = transferListenerRepo
        self.availableChips = allChips
        self.sdk = sdk
        
        mapper = SearchResultMapper(
            sdk: sdk,
            nodeIconUsecase: nodeIconUsecase,
            nodeDetailUseCase: nodeDetailUseCase,
            nodeUseCase: nodeUseCase,
            mediaUseCase: mediaUseCase, 
            nodeActions: nodeActions
        )

        self.onSearchResultUpdated = onSearchResultUpdated
        addNodesUpdateHandler()
        addTransferCompletedHandler()
    }
    
    /// Get the most updated results from data source according to a query.
    /// - Parameter queryRequest: The query
    /// - Returns: The updated results list, paginated based on the current number of results that was filled previously (plus an amount of `loadMorePagesOffset` results to facilite "load more" function)
    func refreshedSearchResults(queryRequest: SearchQuery) async -> SearchResultsEntity? {
        let refreshedNodeList = await nodeListEntity(from: queryRequest)
        
        guard let refreshedNodeList else { return nil }
        
        // After refreshing, the number of nodes can change and we need to update the pagination info
        let newNodesCount = refreshedNodeList.nodesCount
        
        // IMPORTANT NOTES: Here we're using `filledItemsCount + loadMorePagesOffset` instead of merely `filledItemsCount`
        // because we want the refreshed results to contains some more elements than the original list.
        // This is important to solve a edge case: When users already scrolled to be end of the result list and
        // there are update with  many new nodes added to parentNode:
        // if we only return `filledItemsCount`, due to the current `load more` mechanism, user must manually scroll the list to trigger `load more`.
        // By using `filledItemsCount + loadMorePagesOffset` some new element will be
        // added to the end of the list and when user can scroll down to see more content and trigger `load more` in a natural manner.
        let numOfNodesToReturn = min(filledItemsCount + loadMorePagesOffset, newNodesCount)
        self.filledItemsCount = numOfNodesToReturn
        
        var results: [SearchResult] = []
        
        if numOfNodesToReturn > 0 {
            results += (0..<numOfNodesToReturn).compactMap { refreshedNodeList.nodeAt($0) }.map(mapNodeToSearchResult)
        }
        
        self.nodeList = refreshedNodeList
        
        return SearchResultsEntity(
            results: results,
            availableChips: availableChips,
            appliedChips: queryRequest.chips
        )
    }
    
    func search(queryRequest: SearchQuery, lastItemIndex: Int? = nil) async -> SearchResultsEntity? {
        if let lastItemIndex {
            return await loadMore(queryRequest: queryRequest, index: lastItemIndex)
        } else {
            return await searchInitially(queryRequest: queryRequest)
        }
    }
    
    func currentResultIds() -> [Search.ResultId] {
        guard let nodeList else {
            return []
        }
        // need to cache this probably so that subsequent opens are fast for large datasets
        return nodeList.toNodeEntities().map { $0.id }
    }
    /// the requirement is to return children/contents of the
    /// folder being searched when query is empty, no chips etc
    func searchInitially(queryRequest: SearchQuery) async -> SearchResultsEntity {
        
        // Initially, no item is filled yet
        filledItemsCount = 0
        let sorting = queryRequest.sorting

        switch queryRequest {
        case .initial:
            return await childrenOfRoot(with: sorting)
        case .userSupplied(let query):
            if shouldShowRoot(for: query) {
                return await childrenOfRoot(with: sorting)
            } else {
                self.nodeList = await fullSearch(with: query)
                return fillResults(query: query)
            }
        }
    }
    
    @LoadMoreActor
    func loadMore(queryRequest: SearchQuery, index: Int) async -> SearchResultsEntity? {
        guard let nodeList,
                filledItemsCount < nodeList.nodesCount,
              index >= filledItemsCount - loadMorePagesOffset else { return nil }
        switch queryRequest {
        case .initial:
            return fillResults()
        case .userSupplied(let query):
            return fillResults(query: query)
        }
    }
    
    private func nodeListEntity(from queryRequest: SearchQuery) async -> NodeListEntity? {
        guard let parentNode else { return nil }
        let sorting = queryRequest.sorting
        switch queryRequest {
        case .initial:
            return await nodeRepository.asyncChildren(
                of: parentNode,
                sortOrder: sorting.toDomainSortOrderEntity()
            )
        case .userSupplied(let query):
            if shouldShowRoot(for: query) {
                return await nodeRepository.asyncChildren(
                    of: parentNode,
                    sortOrder: sorting.toDomainSortOrderEntity()
                )
            } else {
                return await fullSearch(with: query)
            }
        }
    }
    
    private var parentNode: NodeEntity? {
        parentNodeProvider()
    }
    
    private func childrenOfRoot(with sortOrder: Search.SortOrderEntity) async -> SearchResultsEntity {
        guard let parentNode else {
            return .empty
        }
        self.nodeList = await nodeRepository.asyncChildren(
            of: parentNode,
            sortOrder: sortOrder.toDomainSortOrderEntity()
        )
        return fillResults()
    }
    
    private var searchPath: SearchFileRootPath {
        guard 
            let parentNode,
            parentNode != nodeRepository.rootNode()
        else {
            return .root
        }
        return .specific(parentNode.handle)
    }
    
    private func fullSearch(with queryRequest: SearchQueryEntity) async -> NodeListEntity? {
        // SDK does not support empty query and MEGANodeFormatType.unknown
        assert(!(queryRequest.query == "" && queryRequest.chips == []))
        MEGALogInfo("[search] full search \(queryRequest.query)")

        return await withAsyncValue(in: { completion in
            searchFileUseCase.searchFiles(
                withFilter: queryRequest.searchFilter,
                recursive: true,
                sortOrder: queryRequest.sorting.toMEGASortOrderType(),
                searchPath: searchPath,
                completion: { nodeList in
                    completion(.success(nodeList))
                }
            )
        })
    }

    private func shouldShowRoot(for queryRequest: SearchQueryEntity) -> Bool {
        if queryRequest == .initialRootQuery {
            return true
        }
        if queryRequest.query == "" && queryRequest.chips == [] {
            return true
        }
        return false
    }
    
    private func fillResults(query: SearchQueryEntity? = nil) -> SearchResultsEntity {
        guard let nodeList, filledItemsCount < nodeList.nodesCount else {
            return .init(
                results: [],
                availableChips: availableChips,
                appliedChips: query != nil ? chipsFor(query: query!) : []
            )
        }
        
        let nextPageFirstIndex = filledItemsCount
        let nextPageLastIndex = min(nextPageFirstIndex + pageSize - 1, nodeList.nodesCount - 1)
        
        var results: [SearchResult] = []
        for i in nextPageFirstIndex...nextPageLastIndex {
            if let nodeAt = nodeList.nodeAt(i) {
                results.append(mapNodeToSearchResult(nodeAt))
            }
        }
        
        filledItemsCount = nextPageLastIndex + 1

        return .init(
            results: results,
            availableChips: availableChips,
            appliedChips: query != nil ? chipsFor(query: query!) : []
        )
    }
    
    private func chipsFor(query: SearchQueryEntity) -> [SearchChipEntity] {
        query.chips
    }
    
    private func mapNodeToSearchResult(_ node: NodeEntity) -> SearchResult {
        mapper.map(node: node)
    }
    
    private func addNodesUpdateHandler() {
        // Note: In case of multiple node changes (e.g: Delete/Move multiple nodes), the SDK will emit multiple update signals
        // We should debouce these emission to optimize update performance.
        nodesUpdateListenerRepo.onNodesUpdateHandler = { [weak self] nodes in
            // After update, the first node in nodeList is always the updated one
            guard let self, let node = nodes.first else { return }
            self.onSearchResultUpdated(self.mapNodeToSearchResult(node))
        }
    }

    private func addTransferCompletedHandler() {
        transferListenerRepo.endHandler = { [weak self] megaNode, isStreamingTransfer, transferType in
            guard let self else { return }

            let node = megaNode.toNodeEntity()

            guard nodeList?.toNodeEntities().contains(node) != nil,
                  !isStreamingTransfer,
                  transferType == .download else {
                return
            }

            self.onSearchResultUpdated(self.mapNodeToSearchResult(node))
        }
    }
}
