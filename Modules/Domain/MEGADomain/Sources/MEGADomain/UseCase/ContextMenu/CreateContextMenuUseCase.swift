import Foundation

public protocol CreateContextMenuUseCaseProtocol {
    func createContextMenu(config: CMConfigEntity) -> CMEntity?
}

public struct CreateContextMenuUseCase: CreateContextMenuUseCaseProtocol {
    private let repo: CreateContextMenuRepositoryProtocol
    
    public init(repo: CreateContextMenuRepositoryProtocol) {
        self.repo = repo
    }
    
    public func createContextMenu(config: CMConfigEntity) -> CMEntity? {
        repo.createContextMenu(config: config)
    }
}
