protocol NodeActionRepositoryProtocol {
    func nodeAccessLevel() -> NodeAccessTypeEntity
    func downloadToOffline()
    func labelString(label: NodeLabelTypeEntity) -> String
    func getFilesAndFolders() -> (childFileCount: Int, childFolderCount: Int)
    func hasVersions() -> Bool
    func isDownloaded() -> Bool
}
