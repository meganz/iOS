import MEGADomain
import MEGASwift
import Search

final class HomeSearchResultsProviding: SearchResultsProviding {
    private let searchFileUseCase: any SearchFileUseCaseProtocol
    private let nodeDetailUseCase: any NodeDetailUseCaseProtocol

    init(
        searchFileUseCase: some SearchFileUseCaseProtocol,
        nodeDetailUseCase: some NodeDetailUseCaseProtocol
    ) {
        self.searchFileUseCase = searchFileUseCase
        self.nodeDetailUseCase = nodeDetailUseCase
    }

    func search(queryRequest: SearchQueryEntity) async throws -> SearchResultsEntity {
        return try await withAsyncThrowingValue(in: { completion in
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
            id: .init(stringLiteral: node.base64Handle),
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
