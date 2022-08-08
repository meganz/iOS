import MEGADomain

protocol CreateContextMenuRepositoryProtocol: RepositoryProtocol {
    func createContextMenu(config: CMConfigEntity) -> CMEntity?
}
