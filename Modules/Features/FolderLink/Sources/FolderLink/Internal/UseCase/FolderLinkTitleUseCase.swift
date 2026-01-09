import MEGADomain

enum FolderLinkTitleType {
    case file
    case folder
    case named(String)
    case unknown
}

protocol FolderLinkTitleUseCaseProtocol: Sendable {
    func title(for nodeHandle: HandleEntity) -> FolderLinkTitleType
}

struct FolderLinkTitleUseCase: FolderLinkTitleUseCaseProtocol {
    private let folderLinkRepository: any FolderLinkRepositoryProtocol
    
    init(folderLinkRepository: some FolderLinkRepositoryProtocol = FolderLinkRepository.newRepo) {
        self.folderLinkRepository = folderLinkRepository
    }
    
    func title(for nodeHandle: HandleEntity) -> FolderLinkTitleType {
        guard let node = folderLinkRepository.node(for: nodeHandle) else { return .unknown }
        return if node.isNodeKeyDecrypted {
            .named(node.name)
        } else if node.isFile {
            .file
        } else {
            .folder
        }
    }
}
