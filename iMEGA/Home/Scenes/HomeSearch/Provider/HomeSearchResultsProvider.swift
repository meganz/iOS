import MEGADomain
import MEGASwift
import Search

final class HomeSearchResultsProvider: SearchResultsProviding {
    private let searchFileUseCase: any SearchFileUseCaseProtocol
    private let nodeDetailUseCase: any NodeDetailUseCaseProtocol
    private let nodeRepository: any NodeRepositoryProtocol
    
    init(
        searchFileUseCase: some SearchFileUseCaseProtocol,
        nodeDetailUseCase: some NodeDetailUseCaseProtocol,
        nodeRepository: some NodeRepositoryProtocol
    ) {
        self.searchFileUseCase = searchFileUseCase
        self.nodeDetailUseCase = nodeDetailUseCase
        self.nodeRepository = nodeRepository
    }
    
    func search(queryRequest: SearchQueryEntity) async throws -> SearchResultsEntity {
        // the requirement is to return children/contents of the
        // folder being searched when query is empty, no chips etc
        if queryRequest.isRootDefaultPreviewRequest {
            return await childrenOfRoot()
        }
        return try await fullSearch(with: queryRequest)
    }
    
    @MainActor
    func childrenOfRoot() async -> SearchResultsEntity {
        guard let root = nodeRepository.rootNode() else {
            return .empty
        }
        let children = await nodeRepository.children(of: root)
        return .init(
            results: children.map { self.mapNodeToSearchResult($0) },
            chips: []
        )
    }
    
    func fullSearch(with queryRequest: SearchQueryEntity) async throws -> SearchResultsEntity {
        try await withAsyncThrowingValue(in: { completion in
            searchFileUseCase.searchFiles(
                withName: queryRequest.query,
                searchPath: .root,
                completion: { result in
                    completion(
                        .success(
                            .init(
                                results: result.map { self.mapNodeToSearchResult($0) },
                                // will implement that in FM-797
                                chips: []
                            )
                        )
                    )
                }
            )
        })
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

extension SearchQueryEntity {
    var isRootDefaultPreviewRequest: Bool {
        query == "" &&
        chips == [] &&
        sorting == .automatic &&
        mode == .home
    }
}

extension SearchResultsEntity {
    static var empty: Self {
        .init(results: [], chips: [])
    }
}
