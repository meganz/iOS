import MEGADomain

enum FolderLinkLoginErrorEntity: Error, Sendable, Equatable {
    case linkUnavailable(FolderLinkUnavailableReason)
    case invalidDecryptionKey
    case missingDecryptionKey
}

protocol FolderLinkLoginUseCaseProtocol: Sendable {
    func login(to link: String) async throws(FolderLinkLoginErrorEntity)
}

struct FolderLinkLoginUseCase: FolderLinkLoginUseCaseProtocol {
    private let folderLinkRepository: any FolderLinkRepositoryProtocol
    
    init(folderLinkRepository: some FolderLinkRepositoryProtocol = FolderLinkRepository.newRepo) {
        self.folderLinkRepository = folderLinkRepository
    }
    
    func login(to link: String) async throws(FolderLinkLoginErrorEntity) {
        do {
            try await folderLinkRepository.loginTo(link: link)
        } catch let loginError as FolderLinkLoginErrorEntity {
            throw loginError
        } catch {
            throw .linkUnavailable(.generic)
        }
    }
}
