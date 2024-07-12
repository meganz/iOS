import MEGAFoundation

public protocol SearchNodeUseCaseProtocol {
    func search(type: SearchNodeTypeEntity, text: String, sortType: SortOrderEntity) async throws -> [NodeEntity]
    func cancelSearch()
}

public struct SearchNodeUseCase<T: FilesSearchRepositoryProtocol>: SearchNodeUseCaseProtocol {
    private let filesSearchRepository: T
    private var debouncer: Debouncer = Debouncer(delay: 0.5)
    
    public init(filesSearchRepository: T) {
        self.filesSearchRepository = filesSearchRepository
    }
    
    public func search(type: SearchNodeTypeEntity, text: String, sortType: SortOrderEntity) async throws -> [NodeEntity] {
        cancelSearch()
        
        try await debouncer.debounce()
        let folderTargetEntity: FolderTargetEntity = switch type {
        case .inShares:
            .inShare
        case .outShares:
            .outShare
        case .publicLinks:
            .publicLink
        }
        let searchFilterEntity: SearchFilterEntity = .recursive(
            searchText: text,
            searchTargetLocation: .folderTarget(folderTargetEntity),
            supportCancel: true,
            sortOrderType: sortType,
            formatType: .unknown
        )
        return try await filesSearchRepository.search(filter: searchFilterEntity)
    }
    
    public func cancelSearch() {
        debouncer.cancel()
        filesSearchRepository.cancelSearch()
    }
}
