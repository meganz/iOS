import Foundation
import MEGADomain

protocol NodeTagsSearching: Actor {
    func searchTags(for searchText: String?) async -> [String]?
}

actor NodeTagsSearcher: NodeTagsSearching {
    private var allTags: [String] = []
    private let nodeTagsUseCase: any NodeTagsUseCaseProtocol

    init(nodeTagsUseCase: some NodeTagsUseCaseProtocol) {
        self.nodeTagsUseCase = nodeTagsUseCase
    }

    func searchTags(for searchText: String?) async -> [String]? {
        // Searching the repository is unnecessary if all tags have already been fetched.
        guard allTags.isEmpty else {
            return filterAllTags(for: searchText)
        }

        guard let tags = await nodeTagsUseCase.searchTags(for: searchText), !Task.isCancelled else { return nil }
        updateAllTagsIfSearchTextIsNil(with: tags, searchText: searchText)
        return tags
    }

    private func updateAllTagsIfSearchTextIsNil(with tags: [String], searchText: String?) {
        guard searchText == nil else { return }
        allTags = tags
    }

    private func filterAllTags(for searchText: String?) -> [String] {
        if let searchText {
            return allTags.filter { $0.contains(searchText) }
        } else {
            return allTags
        }
    }
}
