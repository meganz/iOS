import Foundation

public protocol CreateContextMenuUseCaseProtocol {
    func createContextMenu(config: CMConfigEntity) -> CMEntity?
}

public struct CreateContextMenuUseCase: CreateContextMenuUseCaseProtocol {
    private let repo: any CreateContextMenuRepositoryProtocol
    
    public init(repo: any CreateContextMenuRepositoryProtocol) {
        self.repo = repo
    }
    
    public func createContextMenu(config: CMConfigEntity) -> CMEntity? {
        repo.createContextMenu(config: config)
    }
}
