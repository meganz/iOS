import MEGADomain
import Search

protocol FolderLinkViewModeUseCaseProtocol: Sendable {
    func viewModeForOpeningFolder(_ handle: HandleEntity) -> SearchResultsViewMode
    func shouldEnableMediaDiscoveryMode(for handle: HandleEntity) -> Bool
}

struct FolderLinkViewModeUseCase: FolderLinkViewModeUseCaseProtocol {
    private let folderLinkRepository: any FolderLinkRepositoryProtocol
    
    init(folderLinkRepository: some FolderLinkRepositoryProtocol = FolderLinkRepository.newRepo) {
        self.folderLinkRepository = folderLinkRepository
    }
    
    /// Clone the logic from determineViewMode in FolderLinkViewController.m
    /// Media Discovery mode will be handled separately in IOS-11103.
    func viewModeForOpeningFolder(_ handle: HandleEntity) -> SearchResultsViewMode {
        let children = folderLinkRepository.children(of: handle)
        let (withThumbnail, withoutThumbnail) = children.reduce(into: (withThumbnail: 0, withoutThumbnail: 0)) { counts, node in
            if node.hasThumbnail {
                counts.withThumbnail += 1
            } else {
                counts.withoutThumbnail += 1
            }
        }
        
        return withThumbnail > withoutThumbnail ? .grid : .list
    }
    
    func shouldEnableMediaDiscoveryMode(for handle: HandleEntity) -> Bool {
        let children = folderLinkRepository.children(of: handle)
        return children.contains(where: { $0.mediaType != nil })
    }
}
