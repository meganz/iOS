protocol FolderLinkLogoutUseCaseProtocol: Sendable {
    func logout()
}

struct FolderLinkLogoutUseCase: FolderLinkLogoutUseCaseProtocol {
    private let folderLinkRepository: any FolderLinkRepositoryProtocol
    
    init(folderLinkRepository: some FolderLinkRepositoryProtocol = FolderLinkRepository.newRepo) {
        self.folderLinkRepository = folderLinkRepository
    }
    
    func logout() {
        folderLinkRepository.logout()
    }
}
