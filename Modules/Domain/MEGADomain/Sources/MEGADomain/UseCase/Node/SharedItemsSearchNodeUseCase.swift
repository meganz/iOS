import MEGAFoundation

public protocol SharedItemsSearchNodeUseCaseProtocol: Sendable {
    func search(type: SharedItemsSearchSourceTypeEntity, text: String, description: String?, tag: String?, sortType: SortOrderEntity) async throws -> [NodeEntity]
    func cancelSearch()
}

public struct SharedItemsSearchNodeUseCase<T: FilesSearchRepositoryProtocol>: SharedItemsSearchNodeUseCaseProtocol {
    private let filesSearchRepository: T
    
    public init(filesSearchRepository: T) {
        self.filesSearchRepository = filesSearchRepository
    }
    
    public func search(type: SharedItemsSearchSourceTypeEntity, text: String, description: String?, tag: String?, sortType: SortOrderEntity) async throws -> [NodeEntity] {
        cancelSearch()
        
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
            searchDescription: description,
            searchTag: tag,
            searchTargetLocation: .folderTarget(folderTargetEntity),
            supportCancel: true,
            sortOrderType: sortType,
            formatType: .unknown
        )
        return try await filesSearchRepository.search(filter: searchFilterEntity)
    }
    
    public func cancelSearch() {
        filesSearchRepository.cancelSearch()
    }
}
