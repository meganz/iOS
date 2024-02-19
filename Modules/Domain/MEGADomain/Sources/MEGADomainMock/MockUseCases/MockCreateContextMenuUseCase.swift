import MEGADomain

public final class MockCreateContextMenuUseCase: CreateContextMenuUseCaseProtocol {
    private let contextMenuEntity: CMEntity?

    public init(contextMenuEntity: CMEntity? = .init(children: [])) {
        self.contextMenuEntity = contextMenuEntity
    }

    public func createContextMenu(config: CMConfigEntity) -> CMEntity? {
        contextMenuEntity
    }
}
