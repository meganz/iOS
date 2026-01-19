import MEGADomain

protocol FolderLinkEditModeUseCaseProtocol: Sendable {
    func canEnterEditModeWhenOpeningFolder(_ nodeHandle: HandleEntity) -> Bool
}

struct FolderLinkEditModeUseCase: FolderLinkEditModeUseCaseProtocol {
    private let folderLinkRepository: any FolderLinkRepositoryProtocol
    
    init(folderLinkRepository: some FolderLinkRepositoryProtocol = FolderLinkRepository.newRepo) {
        self.folderLinkRepository = folderLinkRepository
    }
    
    func canEnterEditModeWhenOpeningFolder(_ nodeHandle: HandleEntity) -> Bool {
        let children = folderLinkRepository.children(of: nodeHandle)
        return !children.isEmpty
    }
}
