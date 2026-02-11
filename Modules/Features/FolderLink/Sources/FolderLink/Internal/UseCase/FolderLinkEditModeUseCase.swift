import MEGADomain

protocol FolderLinkEditModeUseCaseProtocol: Sendable {
    func canEnterEditModeWhenOpeningFolder(_ nodeHandle: HandleEntity) -> Bool
}

package struct FolderLinkEditModeUseCase: FolderLinkEditModeUseCaseProtocol {
    private let folderLinkRepository: any FolderLinkRepositoryProtocol
    
    package init(folderLinkRepository: some FolderLinkRepositoryProtocol = FolderLinkRepository.newRepo) {
        self.folderLinkRepository = folderLinkRepository
    }
    
    package func canEnterEditModeWhenOpeningFolder(_ nodeHandle: HandleEntity) -> Bool {
        let children = folderLinkRepository.children(of: nodeHandle)
        return !children.isEmpty
    }
}
