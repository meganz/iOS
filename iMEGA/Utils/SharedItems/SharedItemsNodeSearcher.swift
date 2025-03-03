import MEGADomain
import MEGAPresentation
import MEGASDKRepo

@objc final class SharedItemsNodeSearcher: NSObject, Sendable {
    let searchUC = SharedItemsSearchNodeUseCase(filesSearchRepository: FilesSearchRepository.newRepo)
    let featureFlagProvider: some FeatureFlagProviderProtocol = DIContainer.featureFlagProvider

    @objc func searchOnInShares(text: String, sortType: MEGASortOrderType) async throws -> [MEGANode]? {
        try await search(type: .inShares, text: text, sortType: sortType)
    }
    
    @objc func searchOnOutShares(text: String, sortType: MEGASortOrderType) async throws -> [MEGANode]? {
        try await search(type: .outShares, text: text, sortType: sortType)
    }
    
    @objc func searchOnPublicLinks(text: String, sortType: MEGASortOrderType) async throws -> [MEGANode]? {
        try await search(type: .publicLinks, text: text, sortType: sortType)
    }
    
    @objc func cancelSearch() {
        searchUC.cancelSearch()
    }

    private func tagArgument(from searchText: String) -> String? {
        featureFlagProvider.isFeatureFlagEnabled(for: .searchByNodeTags) ? searchText : nil
    }

    private func search(type: SharedItemsSearchSourceTypeEntity, text: String, sortType: MEGASortOrderType) async throws -> [MEGANode]? {
        let nodeArray = try await searchUC.search(
            type: type,
            text: text,
            description: text,
            tag: tagArgument(from: text),
            sortType: sortType.toSortOrderEntity())
        return nodeArray.toMEGANodes(in: MEGASdk.shared)
    }
}
