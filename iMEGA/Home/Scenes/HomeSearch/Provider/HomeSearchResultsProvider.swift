import MEGADomain
import MEGAL10n
import MEGASwift
import Search

/// abstraction into a search results 
final class HomeSearchResultsProvider: SearchResultsProviding {
    private let searchFileUseCase: any SearchFileUseCaseProtocol
    private let nodeDetailUseCase: any NodeDetailUseCaseProtocol
    private let nodeRepository: any NodeRepositoryProtocol

    // We only initially fetch the node list when the user triggers search
    // Concrete nodes are then loaded one by one in the pagination
    private var nodeList: NodeListEntity?
    private var currentPage = 0
    private var totalPages = 0
    private var pageSize = 100
    private var loadMorePagesOffset = 20
    private var isLastPageReached = false

    init(
        searchFileUseCase: some SearchFileUseCaseProtocol,
        nodeDetailUseCase: some NodeDetailUseCaseProtocol,
        nodeRepository: some NodeRepositoryProtocol
    ) {
        self.searchFileUseCase = searchFileUseCase
        self.nodeDetailUseCase = nodeDetailUseCase
        self.nodeRepository = nodeRepository
    }

    func search(queryRequest: SearchQuery, lastItemIndex: Int? = nil) async throws -> SearchResultsEntity? {
        if let lastItemIndex {
            return try await loadMore(queryRequest: queryRequest, index: lastItemIndex)
        } else {
            return try await searchInitially(queryRequest: queryRequest)
        }
    }

    func searchInitially(queryRequest: SearchQuery) async throws -> SearchResultsEntity {
        // the requirement is to return children/contents of the
        // folder being searched when query is empty, no chips etc

        currentPage = 0
        isLastPageReached = false

        switch queryRequest {
        case .initial:
            return await childrenOfRoot()
        case .userSupplied(let query):
            if shouldShowRoot(for: query) {
                return await childrenOfRoot()
            } else {
                self.nodeList = try await fullSearch(with: query)
                return await fillResults(query: query)
            }
        }
    }

    func loadMore(queryRequest: SearchQuery, index: Int) async throws -> SearchResultsEntity? {
        let itemsInPage = (currentPage == 0 ? 1 : currentPage)*pageSize
        guard index >= itemsInPage - loadMorePagesOffset else { return nil }

        currentPage+=1

        switch queryRequest {
        case .initial:
            return await fillResults()
        case .userSupplied(let query):
            return await fillResults(query: query)
        }
    }

    func childrenOfRoot() async -> SearchResultsEntity {
        guard let root = nodeRepository.rootNode() else {
            return .empty
        }
        self.nodeList = await nodeRepository.children(of: root)
        return await fillResults()
    }

    func fullSearch(with queryRequest: SearchQueryEntity) async throws -> NodeListEntity? {
        // SDK does not support empty query and MEGANodeFormatType.unknown
        assert(!(queryRequest.query == "" && queryRequest.chips == []))
        return try await withAsyncThrowingValue(in: { completion in
            searchFileUseCase.searchFiles(
                withName: queryRequest.query,
                recursive: true,
                nodeFormat: nodeFormatFrom(chip: queryRequest.chips.first),
                sortOrder: .defaultAsc,
                searchPath: .root,
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

    private func fillResults(query: SearchQueryEntity? = nil) async -> SearchResultsEntity {
        guard let nodeList, nodeList.nodesCount > 0, !isLastPageReached else {
            return .init(
                results: [],
                availableChips: SearchChipEntity.allChips,
                appliedChips: query != nil ? chipsFor(query: query!) : []
            )
        }

        let nodesCount = nodeList.nodesCount
        let previousPageStartIndex = (currentPage-1)*pageSize
        let currentPageStartIndex = currentPage*pageSize
        let nextPageFirstIndex = (currentPage+1)*pageSize

        isLastPageReached = nextPageFirstIndex > nodesCount

        let firstItemIndex = currentPageStartIndex > nodesCount ? previousPageStartIndex : currentPageStartIndex
        let lastItemIndex = isLastPageReached ? nodesCount : nextPageFirstIndex

        var results: [SearchResult] = []
        for i in firstItemIndex...lastItemIndex-1 {
            results.append(mapNodeToSearchResult(nodeList.nodeAt(i)))
        }

        return .init(
            results: results,
            availableChips: SearchChipEntity.allChips,
            appliedChips: query != nil ? chipsFor(query: query!) : []
        )
    }

    private func chipsFor(query: SearchQueryEntity) -> [SearchChipEntity] {
        SearchChipEntity.allChips.filter {
            query.chips.contains($0)
        }
    }
    
    private func nodeFormatFrom(chip: SearchChipEntity?) -> MEGANodeFormatType {
        guard let chip else {
            return .unknown
        }
        let found = SearchChipEntity.allChips.first {
            $0.id == chip.id
        }
        
        guard
            let found,
            let formatType = MEGANodeFormatType(rawValue: found.id)
        else {
            return .unknown
        }
        
        return formatType
    }
    
    private func mapNodeToSearchResult(_ node: NodeEntity) -> SearchResult {
        return .init(
            id: node.handle,
            title: node.name,
            description: nodeDetailUseCase.ownerFolder(of: node.handle)?.name ?? "",
            // We will fill this later on when we do FM-793
            properties: [],
            thumbnailImageData: { await self.loadThumbnail(for: node.handle) },
            type: .node
        )
    }
    
    private func loadThumbnail(for handle: HandleEntity) async -> Data {
        return await withAsyncValue(in: { completion in
            nodeDetailUseCase.loadThumbnail(
                of: handle,
                completion: { image in
                    completion(.success(image?.pngData() ?? Data()))
                }
            )
        })
    }
}
