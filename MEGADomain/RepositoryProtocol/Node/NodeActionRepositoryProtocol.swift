protocol NodeActionRepositoryProtocol {
    func nodeAccessLevel(nodeHandle: MEGAHandle) -> NodeAccessTypeEntity
    func downloadToOffline(nodeHandle: MEGAHandle)
}
