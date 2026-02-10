package protocol FolderLinkPendingConnectionsRetryUseCaseProtocol: Sendable {
    func retryPendingConnections()
}

package struct FolderLinkPendingConnectionsRetryUseCase: FolderLinkPendingConnectionsRetryUseCaseProtocol {
    private let folderLinkRepository: any FolderLinkRepositoryProtocol
    
    package init(folderLinkRepository: some FolderLinkRepositoryProtocol = FolderLinkRepository.newRepo) {
        self.folderLinkRepository = folderLinkRepository
    }
    
    package func retryPendingConnections() {
        folderLinkRepository.retryPendingConnections()
    }
}
