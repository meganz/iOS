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
        withName name: String,
        recursive: Bool,
        nodeType: MEGANodeType?,
        nodeFormat: MEGANodeFormatType?,
        sortOrder: MEGASortOrderType?,
        searchPath: SearchFileRootPath,
        completion: @escaping ([NodeEntity]) -> Void
    )

    func searchFiles(
        withName name: String,
        recursive: Bool,
        nodeType: MEGANodeType?,
        nodeFormat: MEGANodeFormatType?,
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
        withName fileName: String,
        recursive: Bool,
        nodeType: MEGANodeType?,
        nodeFormat: MEGANodeFormatType?,
        sortOrder: MEGASortOrderType?,
        searchPath: SearchFileRootPath,
        completion: @escaping ([NodeEntity]) -> Void
    ) {
        debouncer.start { [weak self] in
            guard let self else { return }

            self.startSearchingFiles(
                withName: fileName,
                recursive: recursive,
                nodeType: nodeType ?? .unknown,
                nodeFormat: nodeFormat ?? .unknown,
                sortOrder: sortOrder,
                searchPath: searchPath,
                completion: completion
            )
        }
    }

    private func startSearchingFiles(
        withName fileName: String,
        recursive: Bool,
        nodeType: MEGANodeType,
        nodeFormat: MEGANodeFormatType,
        sortOrder: MEGASortOrderType?,
        searchPath: SearchFileRootPath,
        completion: @escaping ([NodeEntity]) -> Void
    ) {
        cancelAction?()
        
        let searchParameters = NodeSearchRepository.Parameter(
            searchText: fileName,
            recursive: recursive,
            nodeType: nodeType,
            nodeFormat: nodeFormat,
            sortOrder: sortOrder,
            rootNodeHandle: searchPath.rootHandle,
            completion: { completion($0?.toNodeEntities() ?? []) }
        )
        
        cancelAction = nodeSearchClient.search(searchParameters)
    }

    func searchFiles(
        withName name: String,
        recursive: Bool,
        nodeType: MEGANodeType?,
        nodeFormat: MEGANodeFormatType?,
        sortOrder: MEGASortOrderType?,
        searchPath: SearchFileRootPath,
        completion: @escaping (NodeListEntity?) -> Void
    ) {
        debouncer.start { [weak self] in
            guard let self else { return }

            self.startSearchingFiles(
                withName: name,
                recursive: recursive,
                nodeType: nodeType ?? .unknown,
                nodeFormat: nodeFormat ?? .unknown,
                sortOrder: sortOrder,
                searchPath: searchPath,
                completion: completion
            )
        }
    }

    private func startSearchingFiles(
        withName fileName: String,
        recursive: Bool,
        nodeType: MEGANodeType,
        nodeFormat: MEGANodeFormatType,
        sortOrder: MEGASortOrderType?,
        searchPath: SearchFileRootPath,
        completion: @escaping (NodeListEntity?) -> Void
    ) {
        cancelAction?()

        let searchParameters = NodeSearchRepository.Parameter(
            searchText: fileName,
            recursive: recursive,
            nodeType: nodeType,
            nodeFormat: nodeFormat,
            sortOrder: sortOrder,
            rootNodeHandle: searchPath.rootHandle,
            completion: { completion($0?.toNodeListEntity()) }
        )

        cancelAction = nodeSearchClient.search(searchParameters)
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
