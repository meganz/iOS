import MEGADomain
import Search

public protocol FolderLinkBuilderProtocol: Sendable {
    func build(link: String, with key: String) async -> String
}

public protocol FolderLinkSearchResultMapperProtocol: Sendable {
    func mapToSearchResult(from node: NodeEntity) -> SearchResult
}

@MainActor
public protocol FolderLinkFileNodeOpenerProtocol: Sendable {
    func openNode(handle: HandleEntity, siblings: [HandleEntity])
}
