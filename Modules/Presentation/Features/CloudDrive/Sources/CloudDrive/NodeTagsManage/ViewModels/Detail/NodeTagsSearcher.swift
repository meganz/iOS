import Foundation
import MEGADomain

protocol NodeTagsSearching: Actor {
    func searchTags(for searchText: String?) async -> [String]?
}

actor NodeTagsSearcher: NodeTagsSearching {
    private var allTags: [String]?
    private let nodeTagsUseCase: any NodeTagsUseCaseProtocol
    private let delay: TimeInterval = 0.5
    private var searchTask: Task<[String]?, any Error>?

    init(nodeTagsUseCase: some NodeTagsUseCaseProtocol) {
        self.nodeTagsUseCase = nodeTagsUseCase
    }

    func searchTags(for searchText: String?) async -> [String]? {
        // Searching the repository is unnecessary if all tags have already been fetched.
        guard allTags == nil else {
            return filterAllTags(for: searchText)
        }

        searchTask?.cancel()
        do {
            let task = searchTask(for: searchText)
            self.searchTask = task
            
            let tags = try await task.value
            updateAllTagsIfSearchTextIsNil(with: tags, searchText: searchText)
            return tags
        } catch {
            return nil
        }
    }

    private func searchTask(for searchText: String?) -> Task<[String]?, any Error> {
        Task {
            // Implements debounce functionality with a specified delay.
            // If a new search request is initiated within `delay` seconds,
            // the current request is canceled, and the delay timer restarts for the new request.
            // This debounce is applied only when searching for specific tags (i.e., `searchText` is not nil).
            // Because after all tags have been fetched, no further requests are made to the SDK.
            if searchText != nil {
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }

            let result = await nodeTagsUseCase.searchTags(for: searchText)
            try Task.checkCancellation()
            return result
        }
    }

    private func updateAllTagsIfSearchTextIsNil(with tags: [String]?, searchText: String?) {
        guard searchText == nil, let tags else { return }
        allTags = tags
    }

    private func filterAllTags(for searchText: String?) -> [String] {
        guard let allTags else { return [] }
        if let searchText {
            return allTags.filter {
                $0.range(of: searchText, options: [.diacriticInsensitive, .caseInsensitive]) != nil
            }
        } else {
            return allTags
        }
    }
}
