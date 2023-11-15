import MEGADomain
import MEGAL10n
import MEGASdk
import MEGASDKRepo
import MEGASwift
import Search

/// abstraction into a search results
final class HomeSearchResultsProvider: SearchResultsProviding {
    private let searchFileUseCase: any SearchFileUseCaseProtocol
    private let nodeDetailUseCase: any NodeDetailUseCaseProtocol
    private let nodeUseCase: any NodeUseCaseProtocol
    private let mediaUseCase: any MediaUseCaseProtocol
    private let nodeRepository: any NodeRepositoryProtocol
    private let sdk: MEGASdk
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
        nodeUseCase: some NodeUseCaseProtocol,
        mediaUseCase: some MediaUseCaseProtocol,
        nodeRepository: some NodeRepositoryProtocol,
        sdk: MEGASdk
    ) {
        self.searchFileUseCase = searchFileUseCase
        self.nodeDetailUseCase = nodeDetailUseCase
        self.nodeUseCase = nodeUseCase
        self.mediaUseCase = mediaUseCase
        self.nodeRepository = nodeRepository
        self.sdk = sdk
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
        MEGALogInfo("[search] full search \(queryRequest.query)")
        // For Folders chip, we don't have support for filtering in SDK by using SearchOperation
        // Instead, we use children() method and filter for folder nodes
        if queryRequest.isFolderChipSelected {
            return try await childrenFolders()
        } else {
            return await withAsyncValue(in: { completion in
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
    }

    private func childrenFolders() async throws -> NodeListEntity? {
        guard let root = nodeRepository.rootNode() else { return nil }
        guard let nodeList = await nodeRepository.children(of: root) else { return nil }

        let nodes = nodeList.toNodeEntities().filter { $0.isFolder }

        return .init(nodesCount: nodes.count, nodeAt: { nodes[$0] })
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
        .init(
            id: node.handle,
            thumbnailDisplayMode: node.isFile ? .vertical : .horizontal,
            backgroundDisplayMode: node.hasThumbnail ? .preview : .icon,
            title: node.name,
            description: info(for: node),
            type: .node,
            properties: properties(for: node),
            thumbnailImageData: { await self.loadThumbnail(for: node.handle) }
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
    
    private func info(for node: NodeEntity) -> @Sendable (ResultCellLayout) -> String {
        guard let megaNode = node.toMEGANode(in: sdk) else { return {_ in ""} }
        // Because of the [FM-1406] description is layout dependent, we need
        // to provide a way to customise what is shown for example for files
        // independently for list layout (we show size and creation date)
        // and for thumbnail-vertical where there's no space and we only
        // show the size. Dictionary carries all possible strings for all layouts
        // without retaining nodes or SDK
        let mapping: [ResultCellLayout: String] = {
            if node.isFile {
                return [
                    .list: Helper.sizeAndModificationDate(for: megaNode, api: sdk),
                    .thumbnail(.horizontal): "", // we do not show files in thumbnail horizontal layout
                    .thumbnail(.vertical): Helper.size(for: megaNode, api: sdk)
                ]
                
            } else {
                let value = Helper.filesAndFolders(inFolderNode: megaNode, api: sdk)
                return [
                    .list: value,
                    .thumbnail(.horizontal): value,
                    .thumbnail(.vertical): "" // we do not show folder in thumbnail vertical layout
                ]
            }
        }()
        
        return { layout in
            guard let description = mapping[layout] else {
                MEGALogError("requested invalid description for unhandled layout \(layout)")
                return ""
            }
            return description
        }
    }
    
    private func iconIndicatorPath(for node: NodeEntity) -> String? {
        guard node.label != .unknown else { return nil }
        return nodeUseCase.labelString(label: node.label)
    }
    
    private func duration(for node: NodeEntity) -> String? {
        guard isNodeVideoWithValidDuration(for: node) else { return nil }
        return TimeInterval(node.duration).timeString
    }
    
    private func isDownloaded(for node: NodeEntity) -> Bool {
        guard node.isFile else { return false }
        return nodeUseCase.isDownloaded(nodeHandle: node.handle)
    }
    
    private func isNodeVideoWithValidDuration(for node: NodeEntity) -> Bool {
        mediaUseCase.isVideo(node.name) && node.duration >= 0
    }
    
    private func properties(for node: NodeEntity) -> [ResultProperty] {
        var properties: [ResultProperty] = []
        
        // the ordering of the properties matters for some
        // layouts where more than one property is displayed on the singe line
        // version below is modelled after previous non-customisable implementation
        // one other possible version of this code could use some kind of priority
        // so that properties could be sorted on the usage location
        if let labelImagePath = iconIndicatorPath(for: node) {
            properties.append(.label(path: labelImagePath))
        }
        
        if node.isFavourite {
            properties.append(.favorite)
        }
        
        if nodeLinked(node) {
            properties.append(.linked)
        }
        
        if node.isFile && nodeUseCase.hasVersions(nodeHandle: node.handle) {
            properties.append(.versioned)
        }
        
        if node.isTakenDown {
            properties.append(.takenDown)
        }
        
        if isDownloaded(for: node) {
            properties.append(.downloaded)
        }
        
        if isVideo(node: node), let duration = duration(for: node) {
            properties.append(contentsOf: [
                .playIcon,
                .duration(string: duration)
            ])
        }
        
        return properties
    }
    
    private func isVideo(node: NodeEntity) -> Bool {
        mediaUseCase.isVideo(node.name)
    }
    
    private func nodeLinked(_ node: NodeEntity) -> Bool {
        node.isExported && !nodeUseCase.isInRubbishBin(nodeHandle: node.handle)
    }
}
