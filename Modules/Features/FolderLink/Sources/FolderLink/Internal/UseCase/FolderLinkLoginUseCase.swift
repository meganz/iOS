package enum FolderLinkLoginErrorEntity: Error, Sendable, Equatable {
    case linkUnavailable(LinkUnavailableReason)
    case invalidDecryptionKey
    case missingDecryptionKey
}

package protocol FolderLinkLoginUseCaseProtocol: Sendable {
    func login(to link: String) async throws(FolderLinkLoginErrorEntity)
}

package struct FolderLinkLoginUseCase: FolderLinkLoginUseCaseProtocol {
    private let folderLinkRepository: any FolderLinkRepositoryProtocol
    
    package init(folderLinkRepository: some FolderLinkRepositoryProtocol = FolderLinkRepository.newRepo) {
        self.folderLinkRepository = folderLinkRepository
    }
    
    package func login(to link: String) async throws(FolderLinkLoginErrorEntity) {
        do {
            try await folderLinkRepository.loginTo(link: link)
        } catch let loginError as FolderLinkLoginErrorEntity {
            throw loginError
        } catch {
            throw .linkUnavailable(.generic)
        }
    }
}
