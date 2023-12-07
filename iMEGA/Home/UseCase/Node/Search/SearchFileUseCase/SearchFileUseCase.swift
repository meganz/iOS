import Foundation
import MEGADomain
import MEGAFoundation

enum SearchFileRootPath {
    case root
    case specific(HandleEntity)
    
    var rootHandle: HandleEntity? {
        switch self {
        case .root:
            nil
        case .specific(let searchRootHandle):
            searchRootHandle
        }
    }
}

protocol SearchFileUseCaseProtocol {
    func searchFiles(
        withFilter filter: MEGASearchFilter,
        recursive: Bool,
        sortOrder: MEGASortOrderType?,
        searchPath: SearchFileRootPath,
        completion: @escaping (NodeListEntity?) -> Void
    )

    func cancelCurrentSearch()
}

final class SearchFileUseCase: SearchFileUseCaseProtocol {

    private var nodeSearchClient: NodeSearchRepository

    private var searchFileHistoryUseCase: any SearchFileHistoryUseCaseProtocol

    private var cancelAction: (() -> Void)?

    // MARK: - Request Debouncer

    private static let REQUESTS_DELAY: TimeInterval = 0.3

    private var debouncer: Debouncer = Debouncer(delay: REQUESTS_DELAY)

    // MARK: - Initializer

    init(
        nodeSearchClient: NodeSearchRepository,
        searchFileHistoryUseCase: some SearchFileHistoryUseCaseProtocol
    ) {
        self.nodeSearchClient = nodeSearchClient
        self.searchFileHistoryUseCase = searchFileHistoryUseCase
    }

    // MARK: - SearchFileUseCaseProtocol
    
    func searchFiles(
        withFilter filter: MEGASearchFilter,
        recursive: Bool,
        sortOrder: MEGASortOrderType?,
        searchPath: SearchFileRootPath,
        completion: @escaping (NodeListEntity?) -> Void
    ) {
        debouncer.start { [weak self] in
            guard let self else { return }

            let searchParameters = NodeSearchRepository.Parameter(
                filter: filter,
                recursive: recursive,
                sortOrder: sortOrder,
                rootNodeHandle: searchPath.rootHandle,
                completion: { completion($0?.toNodeListEntity()) }
            )

            cancelAction = nodeSearchClient.search(searchParameters)
        }
    }

    // MARK: - SearchFileUseCaseProtocol

    func cancelCurrentSearch() {
        cancelAction?()
        debouncer.cancel()
    }
}

// MARK: - SearchFileHistory

struct SearchFileHistoryEntryDomain: Comparable {
    let text: String
    let timeWhenSearchOccur: Date

    static func < (lhs: SearchFileHistoryEntryDomain, rhs: SearchFileHistoryEntryDomain) -> Bool {
        return lhs.timeWhenSearchOccur > rhs.timeWhenSearchOccur
    }
}
