package enum FolderLinkFetchNodesErrorEntity: Error, Sendable, Equatable {
    case linkUnavailable(LinkUnavailableReason)
    case invalidDecryptionKey
    case missingDecryptionKey
}

package protocol FolderLinkFetchNodesUseCaseProtocol: Sendable {
    func fetchNodes() async throws(FolderLinkFetchNodesErrorEntity)
}

package struct FolderLinkFetchNodesUseCase: FolderLinkFetchNodesUseCaseProtocol {
    private let folderLinkRepository: any FolderLinkRepositoryProtocol
    
    package init(folderLinkRepository: some FolderLinkRepositoryProtocol = FolderLinkRepository.newRepo) {
        self.folderLinkRepository = folderLinkRepository
    }
    
    package func fetchNodes() async throws(FolderLinkFetchNodesErrorEntity) {
        do {
            try await folderLinkRepository.fetchNodes()
        } catch let fetchNodesError as FolderLinkFetchNodesErrorEntity {
            throw fetchNodesError
        } catch {
            throw .linkUnavailable(.generic)
        }
    }
}
