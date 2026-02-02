import MEGADomain

enum FolderLinkFetchNodesErrorEntity: Error, Sendable, Equatable {
    case linkUnavailable(FolderLinkUnavailableReason)
    case invalidDecryptionKey
    case missingDecryptionKey
}

protocol FolderLinkFetchNodesUseCaseProtocol: Sendable {
    func fetchNodes() async throws(FolderLinkFetchNodesErrorEntity)
}

struct FolderLinkFetchNodesUseCase: FolderLinkFetchNodesUseCaseProtocol {
    private let folderLinkRepository: any FolderLinkRepositoryProtocol
    
    init(folderLinkRepository: some FolderLinkRepositoryProtocol = FolderLinkRepository.newRepo) {
        self.folderLinkRepository = folderLinkRepository
    }
    
    func fetchNodes() async throws(FolderLinkFetchNodesErrorEntity) {
        do {
            try await folderLinkRepository.fetchNodes()
        } catch let fetchNodesError as FolderLinkFetchNodesErrorEntity {
            throw fetchNodesError
        } catch {
            throw .linkUnavailable(.generic)
        }
    }
}
