package protocol FolderLinkLogoutUseCaseProtocol: Sendable {
    func logout()
}

package struct FolderLinkLogoutUseCase: FolderLinkLogoutUseCaseProtocol {
    private let folderLinkRepository: any FolderLinkRepositoryProtocol
    
    package init(folderLinkRepository: some FolderLinkRepositoryProtocol = FolderLinkRepository.newRepo) {
        self.folderLinkRepository = folderLinkRepository
    }
    
    package func logout() {
        folderLinkRepository.logout()
    }
}
