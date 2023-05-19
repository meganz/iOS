import Foundation
import MEGAFoundation
import MEGADomain

enum SearchFileRootPath {
    case root
    case specific(HandleEntity)
}

protocol SearchFileUseCaseProtocol {

    func searchFiles(
        withName name: String,
        searchPath: SearchFileRootPath,
        completion: @escaping ([NodeEntity]) -> Void
    )

    func cancelCurrentSearch()
}

final class SearchFileUseCase: SearchFileUseCaseProtocol {

    private var nodeSearchClient: NodeSearchRepository

    private var searchFileHistoryUseCase: SearchFileHistoryUseCaseProtocol

    private var cancelAction: (() -> Void)?

    // MARK: - Request Debouncer

    private static let REQUESTS_DELAY: TimeInterval = 0.3

    private var debouncer: Debouncer = Debouncer(delay: REQUESTS_DELAY)

    // MARK: - Initializer

    init(
        nodeSearchClient: NodeSearchRepository,
        searchFileHistoryUseCase: SearchFileHistoryUseCaseProtocol
    ) {
        self.nodeSearchClient = nodeSearchClient
        self.searchFileHistoryUseCase = searchFileHistoryUseCase
    }

    // MARK: - SearchFileUseCaseProtocol

    func searchFiles(
        withName fileName: String,
        searchPath: SearchFileRootPath,
        completion: @escaping ([NodeEntity]) -> Void
    ) {
        debouncer.start { [weak self] in
            guard let self = self else { return }

            self.startSearchingFiles(
                withName: fileName,
                searchPath: searchPath,
                completion: completion
            )
        }
    }

    private func startSearchingFiles(
        withName fileName: String,
        searchPath: SearchFileRootPath,
        completion: @escaping ([NodeEntity]) -> Void
    ) {
        cancelAction?()
        switch searchPath {
        case .root:
            return cancelAction = nodeSearchClient.search(fileName, nil, completion)
        case .specific(let searchRootHandle):
            return cancelAction = nodeSearchClient.search(fileName, searchRootHandle, completion)
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
