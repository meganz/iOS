import MEGAAppSDKRepo
import MEGADomain
import Search

package protocol FolderLinkSearchUseCaseProtocol: Sendable {
    func rootFolderLink() -> HandleEntity
    func children(of nodeHandle: HandleEntity, order: SortOrderEntity) async -> [NodeEntity]
    func search(parentHandle: HandleEntity, with query: SearchQuery) async throws -> [NodeEntity]
}

package struct FolderLinkSearchUseCase: FolderLinkSearchUseCaseProtocol {
    private let folderLinkRepository: any FolderLinkRepositoryProtocol
    private let filesSearchUseCase: any FilesSearchUseCaseProtocol
    
    package init(
        folderLinkRepository: some FolderLinkRepositoryProtocol = FolderLinkRepository.newRepo,
        filesSearchUseCase: some FilesSearchUseCaseProtocol = FilesSearchUseCase(repo: FilesSearchRepository(sdk: .sharedFolderLinkSdk), nodeRepository: NodeRepository.newRepo)
    ) {
        self.folderLinkRepository = folderLinkRepository
        self.filesSearchUseCase = filesSearchUseCase
    }
    
    package func rootFolderLink() -> HandleEntity {
        folderLinkRepository.getRootNode()
    }
    
    package func children(of nodeHandle: HandleEntity, order: SortOrderEntity) async -> [NodeEntity] {
        await folderLinkRepository.children(of: nodeHandle, order: order)
    }
    
    package func search(parentHandle: HandleEntity, with searchQuery: SearchQuery) async throws -> [NodeEntity] {
        guard let parent = folderLinkRepository.node(for: parentHandle) else { return [] }
        let searchFilterEntity = SearchFilterEntity
            .nonRecursive(
               searchText: searchQuery.query,
               searchDescription: searchQuery.query,
               searchTag: searchQuery.query.removingFirstLeadingHash(),
               searchTargetNode: parent,
               supportCancel: true,
               sortOrderType: searchQuery.sorting.toDomainSortOrderEntity(),
               formatType: searchQuery.selectedNodeFormat?.toNodeFormatEntity() ?? .unknown,
               sensitiveFilterOption: .disabled,
               nodeTypeEntity: searchQuery.selectedNodeType?.toNodeTypeEntity() ?? .unknown,
               modificationTimeFrame: searchQuery.selectedModificationTimeFrame?.toSearchFilterTimeFrame(),
               useAndForTextQuery: false
           )
        
        return try await filesSearchUseCase.search(filter: searchFilterEntity, cancelPreviousSearchIfNeeded: searchFilterEntity.supportCancel)
    }
}

extension SearchChipEntity.NodeFormat {
    func toNodeFormatEntity() -> NodeFormatEntity {
        switch self {
        case .unknown:
            .unknown
        case .photo:
            .photo
        case .audio:
            .audio
        case .video:
            .video
        case .document:
            .document
        case .pdf:
            .pdf
        case .presentation:
            .presentation
        case .archive:
            .archive
        case .program:
            .program
        case .misc:
            .misc
        case .spreadsheet:
            .spreadsheet
        case .allDocs:
            .allDocs
        }
    }
}

extension SearchChipEntity.TimeFrame {
    func toSearchFilterTimeFrame() -> SearchFilterEntity.TimeFrame {
        SearchFilterEntity.TimeFrame(startDate: startDate, endDate: endDate)
    }
}

extension SearchChipEntity.NodeType {
    func toNodeTypeEntity() -> NodeTypeEntity {
        switch self {
        case .unknown:
            .unknown
        case .file:
            .file
        case .folder:
            .folder
        case .root:
            .root
        case .incoming:
            .incoming
        case .rubbish:
            .rubbish
        }
    }
}
